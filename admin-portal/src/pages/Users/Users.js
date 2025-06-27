import React, { useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Typography,
  Button,
  Tabs,
  Tab,
  Card,
} from '@mui/material';
import { Add, Download, Refresh } from '@mui/icons-material';
import UserList from './components/UserList';
import UserDetails from './components/UserDetails';
import { motion } from 'framer-motion';

const Users = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [refreshTrigger, setRefreshTrigger] = useState(0);

  const currentTab = location.pathname.includes('/customers') ? 0 : 
                   location.pathname.includes('/sellers') ? 1 : 0;

  const handleTabChange = (event, newValue) => {
    if (newValue === 0) {
      navigate('/users/customers');
    } else if (newValue === 1) {
      navigate('/users/sellers');
    }
  };

  const handleRefresh = () => {
    setRefreshTrigger(prev => prev + 1);
  };

  const handleExport = () => {
    console.log('Exporting users...');
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box>
            <Typography variant="h4" fontWeight="bold" gutterBottom>
              User Management
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Manage customers and sellers
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
            <Tab label="Customers" />
            <Tab label="Sellers" />
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
            element={<UserList userType="customer" refreshTrigger={refreshTrigger} />} 
          />
          <Route 
            path="/customers" 
            element={<UserList userType="customer" refreshTrigger={refreshTrigger} />} 
          />
          <Route 
            path="/sellers" 
            element={<UserList userType="seller" refreshTrigger={refreshTrigger} />} 
          />
          <Route path="/details/:id" element={<UserDetails />} />
        </Routes>
      </motion.div>
    </Box>
  );
};

export default Users;
