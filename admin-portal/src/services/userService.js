import {
  collection,
  doc,
  getDocs,
  getDoc,
  updateDoc,
  query,
  where,
  orderBy,
  limit,
} from 'firebase/firestore';
import { db } from '../config/firebase';

// Get all users with filters
export const getUsers = async (filters = {}) => {
  try {
    let q = collection(db, 'users');
    
    // Apply role filter
    if (filters.role) {
      q = query(q, where('role', '==', filters.role));
    }
    
    // Apply status filter
    if (filters.status) {
      const isActive = filters.status === 'active';
      q = query(q, where('isActive', '==', isActive));
    }
    
    // Apply approval filter for sellers
    if (filters.approval) {
      q = query(q, where('approvalStatus', '==', filters.approval));
    }
    
    // Add ordering
    q = query(q, orderBy('createdAt', 'desc'));
    
    const snapshot = await getDocs(q);
    const users = await Promise.all(
      snapshot.docs.map(async (userDoc) => {
        const userData = userDoc.data();
        
        // Get user statistics
        const stats = await getUserStats(userDoc.id, userData.role);
        
        return {
          id: userDoc.id,
          ...userData,
          ...stats,
          createdAt: userData.createdAt?.toDate(),
          updatedAt: userData.updatedAt?.toDate(),
        };
      })
    );
    
    // Apply search filter on client side
    if (filters.search) {
      const searchTerm = filters.search.toLowerCase();
      return users.filter(user =>
        (user.name?.toLowerCase().includes(searchTerm)) ||
        (user.email?.toLowerCase().includes(searchTerm)) ||
        (user.phone?.toLowerCase().includes(searchTerm))
      );
    }
    
    return users;
  } catch (error) {
    console.error('Error fetching users:', error);
    throw new Error('Failed to fetch users');
  }
};

// Get single user
export const getUser = async (id) => {
  try {
    const docRef = doc(db, 'users', id);
    const docSnap = await getDoc(docRef);
    
    if (!docSnap.exists()) {
      throw new Error('User not found');
    }
    
    const userData = docSnap.data();
    const stats = await getUserStats(id, userData.role);
    
    return {
      id: docSnap.id,
      ...userData,
      ...stats,
      createdAt: userData.createdAt?.toDate(),
      updatedAt: userData.updatedAt?.toDate(),
    };
  } catch (error) {
    console.error('Error fetching user:', error);
    throw new Error('Failed to fetch user');
  }
};

// Get user statistics
const getUserStats = async (userId, role) => {
  try {
    if (role === 'customer') {
      // Get customer orders
      const ordersQuery = query(
        collection(db, 'orders'),
        where('customerId', '==', userId)
      );
      const ordersSnapshot = await getDocs(ordersQuery);
      const orders = ordersSnapshot.docs.map(doc => doc.data());
      
      return {
        ordersCount: orders.length,
        totalSpent: orders.reduce((sum, order) => sum + (order.total || 0), 0),
      };
    } else if (role === 'seller') {
      // Get seller products
      const productsQuery = query(
        collection(db, 'products'),
        where('sellerId', '==', userId)
      );
      const productsSnapshot = await getDocs(productsQuery);
      
      // Get seller orders (orders containing seller's products)
      const ordersQuery = query(collection(db, 'orders'));
      const ordersSnapshot = await getDocs(ordersQuery);
      const sellerOrders = ordersSnapshot.docs
        .map(doc => doc.data())
        .filter(order => 
          order.items?.some(item => item.sellerId === userId)
        );
      
      const revenue = sellerOrders.reduce((sum, order) => {
        const sellerItems = order.items?.filter(item => item.sellerId === userId) || [];
        return sum + sellerItems.reduce((itemSum, item) => 
          itemSum + (item.price * item.quantity), 0
        );
      }, 0);
      
      return {
        ordersCount: productsSnapshot.docs.length, // Product count for sellers
        totalSpent: revenue, // Revenue for sellers
      };
    }
    
    return {
      ordersCount: 0,
      totalSpent: 0,
    };
  } catch (error) {
    console.error('Error fetching user stats:', error);
    return {
      ordersCount: 0,
      totalSpent: 0,
    };
  }
};

// Update user status
export const updateUserStatus = async (userId, isActive) => {
  try {
    const docRef = doc(db, 'users', userId);
    await updateDoc(docRef, {
      isActive,
      updatedAt: new Date(),
    });
    
    return userId;
  } catch (error) {
    console.error('Error updating user status:', error);
    throw new Error('Failed to update user status');
  }
};

// Update seller approval status
export const updateSellerApproval = async (userId, approvalStatus) => {
  try {
    const docRef = doc(db, 'users', userId);
    await updateDoc(docRef, {
      approvalStatus,
      updatedAt: new Date(),
    });
    
    return userId;
  } catch (error) {
    console.error('Error updating seller approval status:', error);
    throw new Error('Failed to update seller approval status');
  }
};

// Get user orders
export const getUserOrders = async (userId) => {
  try {
    const q = query(
      collection(db, 'orders'),
      where('customerId', '==', userId),
      orderBy('createdAt', 'desc')
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        orderNumber: data.id || doc.id.slice(-6).toUpperCase(),
        createdAt: data.createdAt?.toDate(),
      };
    });
  } catch (error) {
    console.error('Error fetching user orders:', error);
    throw new Error('Failed to fetch user orders');
  }
};

// Get user statistics summary
export const getUserStatsSummary = async () => {
  try {
    const usersSnapshot = await getDocs(collection(db, 'users'));
    const users = usersSnapshot.docs.map(doc => doc.data());
    
    const stats = {
      totalUsers: users.length,
      activeUsers: users.filter(u => u.isActive).length,
      customers: users.filter(u => u.role === 'customer').length,
      sellers: users.filter(u => u.role === 'seller').length,
      admins: users.filter(u => u.role === 'admin').length,
    };
    
    return stats;
  } catch (error) {
    console.error('Error fetching user stats summary:', error);
    throw new Error('Failed to fetch user statistics');
  }
};

// Get top customers by spending
export const getTopCustomers = async (limitCount = 10) => {
  try {
    const customersQuery = query(
      collection(db, 'users'),
      where('role', '==', 'customer'),
      where('isActive', '==', true)
    );
    
    const customersSnapshot = await getDocs(customersQuery);
    const customers = await Promise.all(
      customersSnapshot.docs.map(async (doc) => {
        const userData = doc.data();
        const stats = await getUserStats(doc.id, 'customer');
        
        return {
          id: doc.id,
          ...userData,
          ...stats,
        };
      })
    );
    
    // Sort by total spent and return top customers
    return customers
      .sort((a, b) => b.totalSpent - a.totalSpent)
      .slice(0, limitCount);
  } catch (error) {
    console.error('Error fetching top customers:', error);
    throw new Error('Failed to fetch top customers');
  }
};
