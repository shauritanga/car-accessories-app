// Analytics & Reports main component
import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { getAnalyticsData } from '../../services/analyticsService';
import { Box, Typography, Card, CardContent, Grid, CircularProgress } from '@mui/material';

// TODO: Implement analytics & reports UI and logic for:
// - View sales reports, platform usage, top sellers, most searched items
// - Generate performance reports for business insights
// Use analyticsService.js for API calls

const AnalyticsReports = () => {
  // Example: Use 30d as default time range
  const { data: analytics, isLoading } = useQuery({
    queryKey: ['analytics', '30d'],
    queryFn: () => getAnalyticsData('30d'),
  });

  if (isLoading) return <CircularProgress />;

  return (
    <Box>
      <Typography variant="h5" fontWeight="bold" mb={2}>Analytics & Reports</Typography>
      <Grid container spacing={3} sx={{ mb: 4 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary">Total Revenue</Typography>
              <Typography variant="h6">TZS {analytics?.totalRevenue?.toLocaleString() || 0}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary">Total Orders</Typography>
              <Typography variant="h6">{analytics?.totalOrders || 0}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary">Active Customers</Typography>
              <Typography variant="h6">{analytics?.activeCustomers || 0}</Typography>
            </CardContent>
          </Card>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Card>
            <CardContent>
              <Typography variant="body2" color="text.secondary">Conversion Rate</Typography>
              <Typography variant="h6">{analytics?.conversionRate?.toFixed(1) || 0}%</Typography>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
      {/* TODO: Add more detailed reports, charts, and export options as needed */}
    </Box>
  );
};

export default AnalyticsReports;
