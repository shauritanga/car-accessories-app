import React, { useState } from 'react';
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Button,
  Tabs,
  Tab,
} from '@mui/material';
import {
  Download,
  TrendingUp,
  People,
  ShoppingCart,
  AttachMoney,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import SalesChart from './components/SalesChart';
import CustomerAnalytics from './components/CustomerAnalytics';
import ProductAnalytics from './components/ProductAnalytics';
import RevenueBreakdown from './components/RevenueBreakdown';
import { getAnalyticsData } from '../../services/analyticsService';
import { motion } from 'framer-motion';

const Analytics = () => {
  const [timeRange, setTimeRange] = useState('30d');
  const [currentTab, setCurrentTab] = useState(0);

  const { data: analytics, isLoading } = useQuery({
    queryKey: ['analytics', timeRange],
    queryFn: () => getAnalyticsData(timeRange),
  });

  const handleExport = () => {
    console.log('Exporting analytics data...');
  };

  const kpiCards = [
    {
      title: 'Total Revenue',
      value: analytics?.totalRevenue || 0,
      change: analytics?.revenueChange || 0,
      icon: <AttachMoney />,
      color: '#4caf50',
      format: 'currency',
    },
    {
      title: 'Total Orders',
      value: analytics?.totalOrders || 0,
      change: analytics?.ordersChange || 0,
      icon: <ShoppingCart />,
      color: '#2196f3',
      format: 'number',
    },
    {
      title: 'Active Customers',
      value: analytics?.activeCustomers || 0,
      change: analytics?.customersChange || 0,
      icon: <People />,
      color: '#ff9800',
      format: 'number',
    },
    {
      title: 'Conversion Rate',
      value: analytics?.conversionRate || 0,
      change: analytics?.conversionChange || 0,
      icon: <TrendingUp />,
      color: '#9c27b0',
      format: 'percentage',
    },
  ];

  const formatValue = (value, format) => {
    switch (format) {
      case 'currency':
        return `TZS ${value.toLocaleString()}`;
      case 'percentage':
        return `${value.toFixed(1)}%`;
      default:
        return value.toLocaleString();
    }
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box>
            <Typography variant="h4" fontWeight="bold" gutterBottom>
              Analytics & Reports
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Comprehensive business insights and performance metrics
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 2, alignItems: 'center' }}>
            <FormControl size="small" sx={{ minWidth: 120 }}>
              <InputLabel>Time Range</InputLabel>
              <Select
                value={timeRange}
                onChange={(e) => setTimeRange(e.target.value)}
                label="Time Range"
              >
                <MenuItem value="7d">Last 7 days</MenuItem>
                <MenuItem value="30d">Last 30 days</MenuItem>
                <MenuItem value="90d">Last 90 days</MenuItem>
                <MenuItem value="1y">Last year</MenuItem>
              </Select>
            </FormControl>
            <Button
              variant="outlined"
              startIcon={<Download />}
              onClick={handleExport}
            >
              Export Report
            </Button>
          </Box>
        </Box>
      </Box>

      {/* KPI Cards */}
      <Grid container spacing={3} sx={{ mb: 4 }}>
        {kpiCards.map((card, index) => (
          <Grid item xs={12} sm={6} md={3} key={index}>
            <motion.div
              initial={{ opacity: 0, y: 20 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ duration: 0.3, delay: index * 0.1 }}
            >
              <Card className="hover-card">
                <CardContent>
                  <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                    <Box
                      sx={{
                        backgroundColor: card.color,
                        color: 'white',
                        borderRadius: '50%',
                        width: 48,
                        height: 48,
                        display: 'flex',
                        alignItems: 'center',
                        justifyContent: 'center',
                        mr: 2,
                      }}
                    >
                      {card.icon}
                    </Box>
                    <Box>
                      <Typography variant="body2" color="text.secondary">
                        {card.title}
                      </Typography>
                      <Typography
                        variant="caption"
                        color={card.change >= 0 ? 'success.main' : 'error.main'}
                        sx={{ fontWeight: 600 }}
                      >
                        {card.change >= 0 ? '+' : ''}{card.change}% vs last period
                      </Typography>
                    </Box>
                  </Box>
                  <Typography variant="h4" fontWeight="bold">
                    {formatValue(card.value, card.format)}
                  </Typography>
                </CardContent>
              </Card>
            </motion.div>
          </Grid>
        ))}
      </Grid>

      {/* Tabs */}
      <Card sx={{ mb: 3 }}>
        <Tabs
          value={currentTab}
          onChange={(e, newValue) => setCurrentTab(newValue)}
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="Sales Overview" />
          <Tab label="Customer Analytics" />
          <Tab label="Product Performance" />
          <Tab label="Revenue Breakdown" />
        </Tabs>
      </Card>

      {/* Tab Content */}
      <motion.div
        key={currentTab}
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.3 }}
      >
        {currentTab === 0 && <SalesChart timeRange={timeRange} />}
        {currentTab === 1 && <CustomerAnalytics timeRange={timeRange} />}
        {currentTab === 2 && <ProductAnalytics timeRange={timeRange} />}
        {currentTab === 3 && <RevenueBreakdown timeRange={timeRange} />}
      </motion.div>
    </Box>
  );
};

export default Analytics;
