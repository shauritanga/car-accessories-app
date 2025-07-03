import { 
  collection, 
  query, 
  getDocs, 
  orderBy, 
  limit, 
  where,
  Timestamp 
} from 'firebase/firestore';
import { db } from '../config/firebase';

// Get dashboard statistics
export const getDashboardStats = async () => {
  try {
    // Get current month data
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);
    const startOfLastMonth = new Date(now.getFullYear(), now.getMonth() - 1, 1);
    const endOfLastMonth = new Date(now.getFullYear(), now.getMonth(), 0);

    // Get orders for current month (without date filter for debugging)
    const currentMonthOrders = await getDocs(
      query(
        collection(db, 'orders')
      )
    );
    console.log('All orders count (no date filter):', currentMonthOrders.docs.length);
    console.log('All orders data (no date filter):', currentMonthOrders.docs.map(doc => ({ id: doc.id, data: doc.data() })));

    // Get orders for last month (without date filter for debugging, same as current for now)
    const lastMonthOrders = await getDocs(
      query(
        collection(db, 'orders')
      )
    );
    console.log('All orders count (no date filter, last month placeholder):', lastMonthOrders.docs.length);
    console.log('All orders data (no date filter, last month placeholder):', lastMonthOrders.docs.map(doc => ({ id: doc.id, data: doc.data() })));

    // Calculate current month stats
    const currentRevenue = currentMonthOrders.docs.reduce(
      (sum, doc) => sum + (doc.data().total || 0), 0
    );
    const currentOrdersCount = currentMonthOrders.docs.length;

    // Calculate last month stats
    const lastRevenue = lastMonthOrders.docs.reduce(
      (sum, doc) => sum + (doc.data().total || 0), 0
    );
    const lastOrdersCount = lastMonthOrders.docs.length;

    // Get total users
    const usersSnapshot = await getDocs(collection(db, 'users'));
    const totalUsers = usersSnapshot.docs.length;

    // Get total products
    const productsSnapshot = await getDocs(collection(db, 'products'));
    const totalProducts = productsSnapshot.docs.length;

    // Calculate percentage changes
    const revenueChange = lastRevenue > 0 
      ? ((currentRevenue - lastRevenue) / lastRevenue * 100).toFixed(1)
      : 0;
    
    const ordersChange = lastOrdersCount > 0
      ? ((currentOrdersCount - lastOrdersCount) / lastOrdersCount * 100).toFixed(1)
      : 0;

    return {
      totalRevenue: currentRevenue,
      totalOrders: currentOrdersCount,
      totalUsers,
      totalProducts,
      revenueChange: parseFloat(revenueChange),
      ordersChange: parseFloat(ordersChange),
      usersChange: 5.2, // Mock data
      productsChange: 2.1, // Mock data
    };
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    // Return mock data on error
    return {
      totalRevenue: 125000,
      totalOrders: 48,
      totalUsers: 1250,
      totalProducts: 156,
      revenueChange: 12.5,
      ordersChange: 8.3,
      usersChange: 5.2,
      productsChange: 2.1,
    };
  }
};

// Get revenue chart data
export const getRevenueData = async () => {
  try {
    // This would typically fetch real data from Firestore
    // For now, returning mock data
    return [
      { month: 'Jan', revenue: 85000, orders: 65000 },
      { month: 'Feb', revenue: 92000, orders: 72000 },
      { month: 'Mar', revenue: 78000, orders: 58000 },
      { month: 'Apr', revenue: 105000, orders: 85000 },
      { month: 'May', revenue: 118000, orders: 95000 },
      { month: 'Jun', revenue: 125000, orders: 102000 },
    ];
  } catch (error) {
    console.error('Error fetching revenue data:', error);
    return [];
  }
};

// Get orders status data
export const getOrdersStatusData = async () => {
  try {
    const ordersSnapshot = await getDocs(collection(db, 'orders'));
    const statusCounts = {};

    ordersSnapshot.docs.forEach(doc => {
      const status = doc.data().status || 'pending';
      statusCounts[status] = (statusCounts[status] || 0) + 1;
    });

    return Object.entries(statusCounts).map(([name, value]) => ({
      name: name.charAt(0).toUpperCase() + name.slice(1),
      value,
    }));
  } catch (error) {
    console.error('Error fetching orders status data:', error);
    // Return mock data on error
    return [
      { name: 'Pending', value: 12 },
      { name: 'Processing', value: 8 },
      { name: 'Shipped', value: 15 },
      { name: 'Delivered', value: 25 },
      { name: 'Cancelled', value: 3 },
    ];
  }
};

// Get top products
export const getTopProducts = async () => {
  try {
    const productsSnapshot = await getDocs(
      query(
        collection(db, 'products'),
        orderBy('totalReviews', 'desc'),
        limit(5)
      )
    );

    return productsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        name: data.name,
        image: data.images?.[0] || '',
        category: data.category,
        sales: data.totalReviews || 0,
        revenue: (data.price || 0) * (data.totalReviews || 0),
      };
    });
  } catch (error) {
    console.error('Error fetching top products:', error);
    // Return mock data on error
    return [
      {
        id: '1',
        name: 'Premium Car Seat Covers',
        image: '',
        category: 'Interior',
        sales: 145,
        revenue: 725000,
      },
      {
        id: '2',
        name: 'LED Headlight Bulbs',
        image: '',
        category: 'Lighting',
        sales: 132,
        revenue: 660000,
      },
      {
        id: '3',
        name: 'Car Phone Mount',
        image: '',
        category: 'Electronics',
        sales: 98,
        revenue: 294000,
      },
      {
        id: '4',
        name: 'Floor Mats Set',
        image: '',
        category: 'Interior',
        sales: 87,
        revenue: 435000,
      },
      {
        id: '5',
        name: 'Dash Camera',
        image: '',
        category: 'Electronics',
        sales: 76,
        revenue: 912000,
      },
    ];
  }
};

// Get recent orders
export const getRecentOrders = async () => {
  try {
    const ordersSnapshot = await getDocs(
      query(
        collection(db, 'orders'),
        orderBy('createdAt', 'desc'),
        limit(5)
      )
    );

    return ordersSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        orderNumber: data.id || doc.id.slice(-6).toUpperCase(),
        customerName: data.customerName || 'Guest Customer',
        status: data.status || 'pending',
        total: data.total || 0,
        itemsCount: data.items?.length || 0,
        createdAt: data.createdAt?.toDate() || new Date(),
      };
    });
  } catch (error) {
    console.error('Error fetching recent orders:', error);
    // Return mock data on error
    return [
      {
        id: '1',
        orderNumber: 'ORD001',
        customerName: 'John Doe',
        status: 'delivered',
        total: 125000,
        itemsCount: 3,
        createdAt: new Date(),
      },
      {
        id: '2',
        orderNumber: 'ORD002',
        customerName: 'Jane Smith',
        status: 'shipped',
        total: 85000,
        itemsCount: 2,
        createdAt: new Date(Date.now() - 86400000),
      },
      {
        id: '3',
        orderNumber: 'ORD003',
        customerName: 'Mike Johnson',
        status: 'processing',
        total: 67000,
        itemsCount: 1,
        createdAt: new Date(Date.now() - 172800000),
      },
    ];
  }
};
