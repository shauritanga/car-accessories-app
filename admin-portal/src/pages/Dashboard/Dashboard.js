import React from 'react';
import {
  Box,
  Grid,
  Card,
  CardContent,
  Typography,
  Avatar,
  IconButton,
  LinearProgress,
  Chip,
} from '@mui/material';
import {
  TrendingUp,
  TrendingDown,
  ShoppingCart,
  People,
  Inventory,
  AttachMoney,
  MoreVert,
  ArrowUpward,
  ArrowDownward,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import StatsCard from './components/StatsCard';
import RevenueChart from './components/RevenueChart';
import OrdersChart from './components/OrdersChart';
import TopProducts from './components/TopProducts';
import RecentOrders from './components/RecentOrders';
import { getDashboardStats } from '../../services/dashboardService';

const Dashboard = () => {
  const { data: stats, isLoading } = useQuery({
    queryKey: ['dashboard-stats'],
    queryFn: getDashboardStats,
  });

  const statsCards = [
    {
      title: 'Total Revenue',
      value: stats?.totalRevenue || 0,
      change: stats?.revenueChange || 0,
      icon: <AttachMoney />,
      color: '#4caf50',
      format: 'currency',
    },
    {
      title: 'Total Orders',
      value: stats?.totalOrders || 0,
      change: stats?.ordersChange || 0,
      icon: <ShoppingCart />,
      color: '#2196f3',
      format: 'number',
    },
    {
      title: 'Total Users',
      value: stats?.totalUsers || 0,
      change: stats?.usersChange || 0,
      icon: <People />,
      color: '#ff9800',
      format: 'number',
    },
    {
      title: 'Total Products',
      value: stats?.totalProducts || 0,
      change: stats?.productsChange || 0,
      icon: <Inventory />,
      color: '#9c27b0',
      format: 'number',
    },
  ];

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight="bold" gutterBottom>
          Dashboard Overview
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Welcome back! Here's what's happening with your store today.
        </Typography>
      </Box>

      {/* Stats Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {statsCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <StatsCard
              title={card.title}
              value={card.value}
              change={card.change}
              icon={card.icon}
              color={card.color}
              format={card.format}
              isLoading={isLoading}
            />
          </Grid>
        ))}
      </Grid>

      {/* Charts Row */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} md={8}>
          <Card sx={{ height: 400 }}>
            <CardContent>
              <Box
                sx={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  mb: 2,
                }}
              >
                <Typography variant="h6" fontWeight="600">
                  Revenue Overview
                </Typography>
                <IconButton size="small">
                  <MoreVert />
                </IconButton>
              </Box>
              <RevenueChart />
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={4}>
          <Card sx={{ height: 400 }}>
            <CardContent>
              <Box
                sx={{
                  display: 'flex',
                  justifyContent: 'space-between',
                  alignItems: 'center',
                  mb: 2,
                }}
              >
                <Typography variant="h6" fontWeight="600">
                  Orders Status
                </Typography>
                <IconButton size="small">
                  <MoreVert />
                </IconButton>
              </Box>
              <OrdersChart />
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Bottom Row */}
      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card sx={{ height: 500 }}>
            <CardContent>
              <Typography variant="h6" fontWeight="600" gutterBottom>
                Top Selling Products
              </Typography>
              <TopProducts />
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} md={6}>
          <Card sx={{ height: 500 }}>
            <CardContent>
              <Typography variant="h6" fontWeight="600" gutterBottom>
                Recent Orders
              </Typography>
              <RecentOrders />
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
