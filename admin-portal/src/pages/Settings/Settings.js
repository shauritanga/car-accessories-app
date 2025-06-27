import React, { useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Typography,
  Tabs,
  Tab,
  Card,
} from '@mui/material';
import GeneralSettings from './components/GeneralSettings';
import NotificationSettings from './components/NotificationSettings';
import SecuritySettings from './components/SecuritySettings';
import AppConfiguration from './components/AppConfiguration';
import { motion } from 'framer-motion';

const Settings = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const getCurrentTab = () => {
    if (location.pathname.includes('/notifications')) return 1;
    if (location.pathname.includes('/security')) return 2;
    if (location.pathname.includes('/app-config')) return 3;
    return 0;
  };

  const currentTab = getCurrentTab();

  const handleTabChange = (event, newValue) => {
    const routes = ['/settings', '/settings/notifications', '/settings/security', '/settings/app-config'];
    navigate(routes[newValue]);
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight="bold" gutterBottom>
          Settings & Configuration
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Manage system settings and application configuration
        </Typography>
      </Box>

      {/* Tabs */}
      <Card sx={{ mb: 3 }}>
        <Tabs
          value={currentTab}
          onChange={handleTabChange}
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="General" />
          <Tab label="Notifications" />
          <Tab label="Security" />
          <Tab label="App Configuration" />
        </Tabs>
      </Card>

      {/* Content */}
      <motion.div
        key={currentTab}
        initial={{ opacity: 0, x: 20 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.3 }}
      >
        <Routes>
          <Route path="/" element={<GeneralSettings />} />
          <Route path="/notifications" element={<NotificationSettings />} />
          <Route path="/security" element={<SecuritySettings />} />
          <Route path="/app-config" element={<AppConfiguration />} />
        </Routes>
      </motion.div>
    </Box>
  );
};

export default Settings;
