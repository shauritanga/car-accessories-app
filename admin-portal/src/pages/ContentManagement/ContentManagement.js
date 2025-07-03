import React, { useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Typography,
  Tabs,
  Tab,
  Card,
} from '@mui/material';
import Banners from './components/Banners/BannerList';
import BannerForm from './components/Banners/BannerForm';
import FAQs from './components/FAQs/FAQList';
import FAQForm from './components/FAQs/FAQForm';
import LegalContent from './components/Legal/LegalContent';
import LegalForm from './components/Legal/LegalForm';
import { motion } from 'framer-motion';

const ContentManagement = () => {
  const navigate = useNavigate();
  const location = useLocation();

  const getCurrentTab = () => {
    if (location.pathname.includes('/banners')) return 1;
    if (location.pathname.includes('/faqs')) return 2;
    if (location.pathname.includes('/legal')) return 3;
    return 0;
  };

  const currentTab = getCurrentTab();

  const handleTabChange = (event, newValue) => {
    const routes = ['/content-management', '/content-management/banners', '/content-management/faqs', '/content-management/legal'];
    navigate(routes[newValue]);
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Typography variant="h4" fontWeight="bold" gutterBottom>
          Content Management
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Manage homepage banners, FAQs, terms & conditions, and policies for the mobile app.
        </Typography>
      </Box>

      {/* Tabs */}
      <Card sx={{ mb: 3 }}>
        <Tabs
          value={currentTab}
          onChange={handleTabChange}
          sx={{ borderBottom: 1, borderColor: 'divider' }}
        >
          <Tab label="Overview" />
          <Tab label="Homepage Banners" />
          <Tab label="FAQs" />
          <Tab label="Legal Content" />
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
          <Route path="/" element={
            <Box>
              <Typography variant="h6" gutterBottom>
                Content Management Overview
              </Typography>
              <Typography variant="body1" color="text.secondary">
                Use the tabs to manage different types of content for the mobile app. This includes homepage banners, frequently asked questions, and legal documents such as terms & conditions and policies.
              </Typography>
            </Box>
          } />
          <Route path="/banners" element={<Banners />} />
          <Route path="/banners/add" element={<BannerForm />} />
          <Route path="/banners/edit/:id" element={<BannerForm />} />
          <Route path="/faqs" element={<FAQs />} />
          <Route path="/faqs/add" element={<FAQForm />} />
          <Route path="/faqs/edit/:id" element={<FAQForm />} />
          <Route path="/legal" element={<LegalContent />} />
          <Route path="/legal/add" element={<LegalForm />} />
          <Route path="/legal/edit/:id" element={<LegalForm />} />
        </Routes>
      </motion.div>
    </Box>
  );
};

export default ContentManagement;
