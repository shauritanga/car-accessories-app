import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
} from '@mui/material';
import {
  ResponsiveContainer,
  PieChart,
  Pie,
  Cell,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from 'recharts';
import { useQuery } from '@tanstack/react-query';
import { getOrderStats } from '../../../services/orderService';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

const OrderAnalytics = () => {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['order-stats'],
    queryFn: getOrderStats,
  });

  if (isLoading) {
    return (
      <Box>
        <Typography>Loading analytics...</Typography>
      </Box>
    );
  }

  const statusData = [
    { name: 'Pending', value: stats?.pending || 0, color: '#FFBB28' },
    { name: 'Processing', value: stats?.processing || 0, color: '#0088FE' },
    { name: 'Shipped', value: stats?.shipped || 0, color: '#00C49F' },
    { name: 'Delivered', value: stats?.delivered || 0, color: '#8884D8' },
    { name: 'Cancelled', value: stats?.cancelled || 0, color: '#FF8042' },
  ];

  const monthlyData = [
    { month: 'Jan', orders: 45, revenue: 125000 },
    { month: 'Feb', orders: 52, revenue: 142000 },
    { month: 'Mar', orders: 48, revenue: 138000 },
    { month: 'Apr', orders: 61, revenue: 165000 },
    { month: 'May', orders: 55, revenue: 158000 },
    { month: 'Jun', orders: 67, revenue: 182000 },
  ];

  return (
    <Grid container spacing={3}>
      {/* Order Status Distribution */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Order Status Distribution
            </Typography>
            <Box sx={{ width: '100%', height: 300 }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={statusData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {statusData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={entry.color} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Monthly Trends */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Monthly Order Trends
            </Typography>
            <Box sx={{ width: '100%', height: 300 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={monthlyData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="orders" fill="#8884d8" name="Orders" />
                </BarChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Summary Stats */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Order Summary
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="primary.main" fontWeight="bold">
                    {stats?.total || 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Orders
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="success.main" fontWeight="bold">
                    TZS {(stats?.totalRevenue || 0).toLocaleString()}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Revenue
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="info.main" fontWeight="bold">
                    TZS {stats?.totalRevenue && stats?.total ? 
                      Math.round(stats.totalRevenue / stats.total).toLocaleString() : 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Average Order Value
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="warning.main" fontWeight="bold">
                    {stats?.pending || 0}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Pending Orders
                  </Typography>
                </Box>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
};

export default OrderAnalytics;
