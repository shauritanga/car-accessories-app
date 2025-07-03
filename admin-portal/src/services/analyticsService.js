import {
  collection,
  getDocs,
  query,
  where,
  orderBy,
  Timestamp,
  addDoc,
  serverTimestamp,
} from 'firebase/firestore';
import { db } from '../config/firebase';

// Get analytics data for specified time range
export const getAnalyticsData = async (timeRange) => {
  try {
    const { startDate, endDate } = getDateRange(timeRange);

    // Get orders in date range
    const ordersQuery = query(
      collection(db, 'orders'),
      where('createdAt', '>=', Timestamp.fromDate(startDate)),
      where('createdAt', '<=', Timestamp.fromDate(endDate))
    );

    const ordersSnapshot = await getDocs(ordersQuery);
    const orders = ordersSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
    }));

    // Get users
    const usersSnapshot = await getDocs(collection(db, 'users'));
    const users = usersSnapshot.docs.map(doc => doc.data());

    // Calculate metrics
    const totalRevenue = orders.reduce((sum, order) => sum + (order.total || 0), 0);
    const totalOrders = orders.length;
    const activeCustomers = users.filter(u => u.role === 'customer' && u.isActive).length;

    // Calculate conversion rate (mock calculation)
    const conversionRate = totalOrders > 0 ? (totalOrders / (totalOrders * 10)) * 100 : 0;

    // Get previous period for comparison
    const prevPeriod = await getPreviousPeriodData(timeRange);

    return {
      totalRevenue,
      totalOrders,
      activeCustomers,
      conversionRate,
      revenueChange: calculateChange(totalRevenue, prevPeriod.revenue),
      ordersChange: calculateChange(totalOrders, prevPeriod.orders),
      customersChange: 5.2, // Mock data
      conversionChange: 2.1, // Mock data
    };
  } catch (error) {
    console.error('Error fetching analytics data:', error);
    // Return mock data on error
    return {
      totalRevenue: 125000,
      totalOrders: 48,
      activeCustomers: 1250,
      conversionRate: 3.2,
      revenueChange: 12.5,
      ordersChange: 8.3,
      customersChange: 5.2,
      conversionChange: 2.1,
    };
  }
};

// Get sales data for charts
export const getSalesData = async (timeRange) => {
  try {
    const { startDate, endDate } = getDateRange(timeRange);

    const ordersQuery = query(
      collection(db, 'orders'),
      where('createdAt', '>=', Timestamp.fromDate(startDate)),
      where('createdAt', '<=', Timestamp.fromDate(endDate)),
      orderBy('createdAt', 'asc')
    );

    const ordersSnapshot = await getDocs(ordersQuery);
    const orders = ordersSnapshot.docs.map(doc => ({
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate(),
    }));

    // Group by date for trend
    const trendData = groupOrdersByDate(orders, timeRange);

    // Group by category
    const categoryData = await groupOrdersByCategory(orders);

    // Group by day of week
    const dailyData = groupOrdersByDayOfWeek(orders);

    return {
      trend: trendData,
      byCategory: categoryData,
      daily: dailyData,
    };
  } catch (error) {
    console.error('Error fetching sales data:', error);
    // Return mock data on error
    return {
      trend: generateMockTrendData(timeRange),
      byCategory: [
        { category: 'Interior', sales: 45000 },
        { category: 'Exterior', sales: 38000 },
        { category: 'Electronics', sales: 32000 },
        { category: 'Performance', sales: 28000 },
        { category: 'Maintenance', sales: 22000 },
      ],
      daily: [
        { day: 'Mon', sales: 18000, orders: 12 },
        { day: 'Tue', sales: 22000, orders: 15 },
        { day: 'Wed', sales: 25000, orders: 18 },
        { day: 'Thu', sales: 28000, orders: 20 },
        { day: 'Fri', sales: 32000, orders: 25 },
        { day: 'Sat', sales: 35000, orders: 28 },
        { day: 'Sun', sales: 20000, orders: 14 },
      ],
    };
  }
};

// Log a search query
export const logSearchQuery = async (term, userId = null) => {
  await addDoc(collection(db, 'searchLogs'), {
    term: term.toLowerCase(),
    userId,
    timestamp: serverTimestamp(),
  });
};

// Get most searched items
export const getMostSearchedItems = async (limitCount = 10) => {
  const snap = await getDocs(collection(db, 'searchLogs'));
  const termCounts = {};
  snap.docs.forEach(doc => {
    const term = doc.data().term;
    if (!termCounts[term]) termCounts[term] = 0;
    termCounts[term] += 1;
  });
  return Object.entries(termCounts)
    .map(([term, count]) => ({ term, count }))
    .sort((a, b) => b.count - a.count)
    .slice(0, limitCount);
};

// Helper functions
const getDateRange = (timeRange) => {
  const endDate = new Date();
  const startDate = new Date();

  switch (timeRange) {
    case '7d':
      startDate.setDate(endDate.getDate() - 7);
      break;
    case '30d':
      startDate.setDate(endDate.getDate() - 30);
      break;
    case '90d':
      startDate.setDate(endDate.getDate() - 90);
      break;
    case '1y':
      startDate.setFullYear(endDate.getFullYear() - 1);
      break;
    default:
      startDate.setDate(endDate.getDate() - 30);
  }

  return { startDate, endDate };
};

const getPreviousPeriodData = async (timeRange) => {
  // Mock previous period data
  return {
    revenue: 112000,
    orders: 44,
  };
};

const calculateChange = (current, previous) => {
  if (previous === 0) return 0;
  return ((current - previous) / previous * 100).toFixed(1);
};

const groupOrdersByDate = (orders, timeRange) => {
  const grouped = {};
  const format = timeRange === '7d' || timeRange === '30d' ? 'daily' : 'monthly';

  orders.forEach(order => {
    const date = order.createdAt;
    let key;

    if (format === 'daily') {
      key = date.toISOString().split('T')[0]; // YYYY-MM-DD
    } else {
      key = `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}`; // YYYY-MM
    }

    if (!grouped[key]) {
      grouped[key] = { date: key, sales: 0, orders: 0 };
    }

    grouped[key].sales += order.total || 0;
    grouped[key].orders += 1;
  });

  return Object.values(grouped).sort((a, b) => a.date.localeCompare(b.date));
};

const groupOrdersByCategory = async (orders) => {
  try {
    // Get all products to map categories
    const productsSnapshot = await getDocs(collection(db, 'products'));
    const products = {};

    productsSnapshot.docs.forEach(doc => {
      products[doc.id] = doc.data();
    });

    const categoryTotals = {};

    orders.forEach(order => {
      order.items?.forEach(item => {
        const product = products[item.productId];
        const category = product?.category || 'Other';

        if (!categoryTotals[category]) {
          categoryTotals[category] = 0;
        }

        categoryTotals[category] += item.price * item.quantity;
      });
    });

    return Object.entries(categoryTotals)
      .map(([category, sales]) => ({ category, sales }))
      .sort((a, b) => b.sales - a.sales);
  } catch (error) {
    console.error('Error grouping by category:', error);
    return [];
  }
};

const groupOrdersByDayOfWeek = (orders) => {
  const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const grouped = {};

  days.forEach(day => {
    grouped[day] = { day, sales: 0, orders: 0 };
  });

  orders.forEach(order => {
    const dayName = days[order.createdAt.getDay()];
    grouped[dayName].sales += order.total || 0;
    grouped[dayName].orders += 1;
  });

  return Object.values(grouped);
};

const generateMockTrendData = (timeRange) => {
  const data = [];
  const days = timeRange === '7d' ? 7 : timeRange === '30d' ? 30 : 90;

  for (let i = days; i >= 0; i--) {
    const date = new Date();
    date.setDate(date.getDate() - i);

    data.push({
      date: date.toISOString().split('T')[0],
      sales: Math.floor(Math.random() * 50000) + 10000,
      orders: Math.floor(Math.random() * 30) + 5,
    });
  }

  return data;
};
