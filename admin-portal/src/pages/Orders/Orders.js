import React, { useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Typography,
  Button,
  Tabs,
  Tab,
  Card,
  Grid,
} from '@mui/material';
import { Download, Refresh, FilterList } from '@mui/icons-material';
import OrderList from './components/OrderList';
import OrderDetails from './components/OrderDetails';
import OrderAnalytics from './components/OrderAnalytics';
import { motion } from 'framer-motion';

const Orders = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  const currentTab = location.pathname.includes('/analytics') ? 1 : 0;

  const handleTabChange = (event, newValue) => {
    if (newValue === 0) {
      navigate('/orders');
    } else if (newValue === 1) {
      navigate('/orders/analytics');
    }
  };

  const handleRefresh = () => {
    setRefreshTrigger(prev => prev + 1);
  };

  const handleExport = () => {
    // Handle export functionality
    console.log('Exporting orders...');
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box>
            <Typography variant="h4" fontWeight="bold" gutterBottom>
              Order Management
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Track and manage customer orders
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<Refresh />}
              onClick={handleRefresh}
            >
              Refresh
            </Button>
            <Button
              variant="outlined"
              startIcon={<Download />}
              onClick={handleExport}
            >
              Export
            </Button>
          </Box>
        </Box>

        {/* Tabs */}
        <Card>
          <Tabs
            value={currentTab}
            onChange={handleTabChange}
            sx={{ borderBottom: 1, borderColor: 'divider' }}
          >
            <Tab label="All Orders" />
            <Tab label="Analytics" />
          </Tabs>
        </Card>
      </Box>

      {/* Content */}
      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: 0.3 }}
      >
        <Routes>
          <Route 
            path="/" 
            element={<OrderList refreshTrigger={refreshTrigger} />} 
          />
          <Route path="/details/:id" element={<OrderDetails />} />
          <Route path="/analytics" element={<OrderAnalytics />} />
        </Routes>
      </motion.div>
    </Box>
  );
};

export default Orders;
