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
  LineChart,
  Line,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  BarChart,
  Bar,
} from 'recharts';

const CustomerAnalytics = ({ timeRange }) => {
  // Mock data - replace with real data from your service
  const customerGrowthData = [
    { month: 'Jan', newCustomers: 45, totalCustomers: 245 },
    { month: 'Feb', newCustomers: 52, totalCustomers: 297 },
    { month: 'Mar', newCustomers: 48, totalCustomers: 345 },
    { month: 'Apr', newCustomers: 61, totalCustomers: 406 },
    { month: 'May', newCustomers: 55, totalCustomers: 461 },
    { month: 'Jun', newCustomers: 67, totalCustomers: 528 },
  ];

  const customerSegmentData = [
    { segment: 'New', customers: 125, percentage: 23.6 },
    { segment: 'Returning', customers: 298, percentage: 56.4 },
    { segment: 'VIP', customers: 105, percentage: 19.9 },
  ];

  return (
    <Grid container spacing={3}>
      {/* Customer Growth */}
      <Grid item xs={12} lg={8}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Customer Growth
            </Typography>
            <Box sx={{ width: '100%', height: 400 }}>
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={customerGrowthData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Line
                    type="monotone"
                    dataKey="newCustomers"
                    stroke="#8884d8"
                    name="New Customers"
                  />
                  <Line
                    type="monotone"
                    dataKey="totalCustomers"
                    stroke="#82ca9d"
                    name="Total Customers"
                  />
                </LineChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Customer Segments */}
      <Grid item xs={12} lg={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Customer Segments
            </Typography>
            <Box sx={{ width: '100%', height: 400 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={customerSegmentData} layout="horizontal">
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis type="number" />
                  <YAxis dataKey="segment" type="category" />
                  <Tooltip />
                  <Bar dataKey="customers" fill="#8884d8" />
                </BarChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Customer Metrics */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Customer Metrics
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="primary.main" fontWeight="bold">
                    528
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Customers
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="success.main" fontWeight="bold">
                    67
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    New This Month
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="info.main" fontWeight="bold">
                    TZS 245,000
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Avg. Customer Value
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="warning.main" fontWeight="bold">
                    76%
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Retention Rate
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

export default CustomerAnalytics;
