import React, { useState } from 'react';
import { Routes, Route, Navigate, useNavigate, useLocation } from 'react-router-dom';
import { Box, Typography, Tab, Tabs } from '@mui/material';
import ReviewList from './components/ReviewList';
import ModerationQueue from './components/ModerationQueue';

function FeedbackReviews() {
  const navigate = useNavigate();
  const location = useLocation();
  const currentTab = location.pathname.includes('/moderation') ? 'moderation' : 'all';

  const handleTabChange = (event, newValue) => {
    navigate(`/feedback-reviews/${newValue}`);
  };

  return (
    <Box sx={{ width: '100%' }}>
      <Typography variant="h4" gutterBottom>
        Feedback & Reviews
      </Typography>
      <Box sx={{ borderBottom: 1, borderColor: 'divider' }}>
        <Tabs value={currentTab} onChange={handleTabChange} aria-label="feedback tabs">
          <Tab label="All Reviews" value="all" />
          <Tab label="Moderation Queue" value="moderation" />
        </Tabs>
      </Box>
      <Box sx={{ mt: 2 }}>
        <Routes>
          <Route path="all" element={<ReviewList />} />
          <Route path="moderation" element={<ModerationQueue />} />
          <Route path="/" element={<Navigate to="all" replace />} />
        </Routes>
      </Box>
    </Box>
  );
}

export default FeedbackReviews;
