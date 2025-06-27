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

// Get all orders with filters
export const getOrders = async (filters = {}) => {
  try {
    let q = collection(db, 'orders');
    
    // Apply status filter
    if (filters.status) {
      q = query(q, where('status', '==', filters.status));
    }
    
    // Add ordering
    q = query(q, orderBy('createdAt', 'desc'));
    
    const snapshot = await getDocs(q);
    const orders = snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        orderNumber: data.id || doc.id.slice(-6).toUpperCase(),
        customerName: data.customerName || data.shippingAddress?.fullName || 'Guest Customer',
        customerEmail: data.customerEmail || data.email || 'N/A',
        itemsCount: data.items?.length || 0,
        paymentStatus: data.paymentStatus || 'pending',
        createdAt: data.createdAt?.toDate(),
        updatedAt: data.updatedAt?.toDate(),
      };
    });
    
    // Apply search filter on client side
    if (filters.search) {
      const searchTerm = filters.search.toLowerCase();
      return orders.filter(order =>
        order.orderNumber.toLowerCase().includes(searchTerm) ||
        order.customerName.toLowerCase().includes(searchTerm) ||
        order.customerEmail.toLowerCase().includes(searchTerm)
      );
    }
    
    return orders;
  } catch (error) {
    console.error('Error fetching orders:', error);
    throw new Error('Failed to fetch orders');
  }
};

// Get single order
export const getOrder = async (id) => {
  try {
    const docRef = doc(db, 'orders', id);
    const docSnap = await getDoc(docRef);
    
    if (!docSnap.exists()) {
      throw new Error('Order not found');
    }
    
    const data = docSnap.data();
    return {
      id: docSnap.id,
      ...data,
      orderNumber: data.id || docSnap.id.slice(-6).toUpperCase(),
      customerName: data.customerName || data.shippingAddress?.fullName || 'Guest Customer',
      customerEmail: data.customerEmail || data.email || 'N/A',
      itemsCount: data.items?.length || 0,
      createdAt: data.createdAt?.toDate(),
      updatedAt: data.updatedAt?.toDate(),
    };
  } catch (error) {
    console.error('Error fetching order:', error);
    throw new Error('Failed to fetch order');
  }
};

// Update order status
export const updateOrderStatus = async (orderId, status) => {
  try {
    const docRef = doc(db, 'orders', orderId);
    
    // Create status update entry
    const statusUpdate = {
      status,
      timestamp: new Date(),
      updatedBy: 'admin', // You can get this from auth context
    };
    
    // Get current order to append to status history
    const orderDoc = await getDoc(docRef);
    const currentData = orderDoc.data();
    const statusHistory = currentData.statusHistory || [];
    
    await updateDoc(docRef, {
      status,
      statusHistory: [...statusHistory, statusUpdate],
      updatedAt: new Date(),
    });
    
    return orderId;
  } catch (error) {
    console.error('Error updating order status:', error);
    throw new Error('Failed to update order status');
  }
};

// Get order statistics
export const getOrderStats = async () => {
  try {
    const ordersSnapshot = await getDocs(collection(db, 'orders'));
    const orders = ordersSnapshot.docs.map(doc => doc.data());
    
    const stats = {
      total: orders.length,
      pending: orders.filter(o => o.status === 'pending').length,
      processing: orders.filter(o => o.status === 'processing').length,
      shipped: orders.filter(o => o.status === 'shipped').length,
      delivered: orders.filter(o => o.status === 'delivered').length,
      cancelled: orders.filter(o => o.status === 'cancelled').length,
      totalRevenue: orders.reduce((sum, order) => sum + (order.total || 0), 0),
    };
    
    return stats;
  } catch (error) {
    console.error('Error fetching order stats:', error);
    throw new Error('Failed to fetch order statistics');
  }
};

// Get recent orders
export const getRecentOrders = async (limitCount = 10) => {
  try {
    const q = query(
      collection(db, 'orders'),
      orderBy('createdAt', 'desc'),
      limit(limitCount)
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        orderNumber: data.id || doc.id.slice(-6).toUpperCase(),
        customerName: data.customerName || data.shippingAddress?.fullName || 'Guest Customer',
        itemsCount: data.items?.length || 0,
        createdAt: data.createdAt?.toDate(),
      };
    });
  } catch (error) {
    console.error('Error fetching recent orders:', error);
    throw new Error('Failed to fetch recent orders');
  }
};

// Get orders by date range
export const getOrdersByDateRange = async (startDate, endDate) => {
  try {
    const q = query(
      collection(db, 'orders'),
      where('createdAt', '>=', startDate),
      where('createdAt', '<=', endDate),
      orderBy('createdAt', 'desc')
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
    }));
  } catch (error) {
    console.error('Error fetching orders by date range:', error);
    throw new Error('Failed to fetch orders by date range');
  }
};

// Get top customers by order value
export const getTopCustomers = async (limitCount = 10) => {
  try {
    const ordersSnapshot = await getDocs(collection(db, 'orders'));
    const orders = ordersSnapshot.docs.map(doc => doc.data());
    
    // Group orders by customer
    const customerStats = {};
    orders.forEach(order => {
      const customerId = order.customerId || order.customerEmail || 'guest';
      const customerName = order.customerName || order.shippingAddress?.fullName || 'Guest Customer';
      
      if (!customerStats[customerId]) {
        customerStats[customerId] = {
          id: customerId,
          name: customerName,
          totalOrders: 0,
          totalSpent: 0,
        };
      }
      
      customerStats[customerId].totalOrders += 1;
      customerStats[customerId].totalSpent += order.total || 0;
    });
    
    // Convert to array and sort by total spent
    return Object.values(customerStats)
      .sort((a, b) => b.totalSpent - a.totalSpent)
      .slice(0, limitCount);
  } catch (error) {
    console.error('Error fetching top customers:', error);
    throw new Error('Failed to fetch top customers');
  }
};
