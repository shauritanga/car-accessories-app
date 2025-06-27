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
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  BarChart,
  Bar,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042'];

const RevenueBreakdown = ({ timeRange }) => {
  // Mock data - replace with real data from your service
  const revenueData = [
    { month: 'Jan', product: 85000, shipping: 8500, tax: 12750 },
    { month: 'Feb', product: 92000, shipping: 9200, tax: 13800 },
    { month: 'Mar', product: 78000, shipping: 7800, tax: 11700 },
    { month: 'Apr', product: 105000, shipping: 10500, tax: 15750 },
    { month: 'May', product: 118000, shipping: 11800, tax: 17700 },
    { month: 'Jun', product: 125000, shipping: 12500, tax: 18750 },
  ];

  const revenueSourceData = [
    { name: 'Product Sales', value: 603000, percentage: 85.2 },
    { name: 'Shipping', value: 60300, percentage: 8.5 },
    { name: 'Tax', value: 44550, percentage: 6.3 },
  ];

  const paymentMethodData = [
    { method: 'Mobile Money', amount: 425000, orders: 245 },
    { method: 'Bank Transfer', amount: 185000, orders: 89 },
    { method: 'Cash on Delivery', amount: 98000, orders: 67 },
    { method: 'Credit Card', amount: 45000, orders: 23 },
  ];

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('en-TZ', {
      style: 'currency',
      currency: 'TZS',
      minimumFractionDigits: 0,
    }).format(value);
  };

  return (
    <Grid container spacing={3}>
      {/* Revenue Trend */}
      <Grid item xs={12} lg={8}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Revenue Breakdown Over Time
            </Typography>
            <Box sx={{ width: '100%', height: 400 }}>
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={revenueData}>
                  <defs>
                    <linearGradient id="colorProduct" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#8884d8" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#8884d8" stopOpacity={0}/>
                    </linearGradient>
                    <linearGradient id="colorShipping" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#82ca9d" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#82ca9d" stopOpacity={0}/>
                    </linearGradient>
                    <linearGradient id="colorTax" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#ffc658" stopOpacity={0.8}/>
                      <stop offset="95%" stopColor="#ffc658" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="month" />
                  <YAxis tickFormatter={formatCurrency} />
                  <Tooltip formatter={(value) => formatCurrency(value)} />
                  <Legend />
                  <Area
                    type="monotone"
                    dataKey="product"
                    stackId="1"
                    stroke="#8884d8"
                    fillOpacity={1}
                    fill="url(#colorProduct)"
                    name="Product Sales"
                  />
                  <Area
                    type="monotone"
                    dataKey="shipping"
                    stackId="1"
                    stroke="#82ca9d"
                    fillOpacity={1}
                    fill="url(#colorShipping)"
                    name="Shipping"
                  />
                  <Area
                    type="monotone"
                    dataKey="tax"
                    stackId="1"
                    stroke="#ffc658"
                    fillOpacity={1}
                    fill="url(#colorTax)"
                    name="Tax"
                  />
                </AreaChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Revenue Sources */}
      <Grid item xs={12} lg={4}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Revenue Sources
            </Typography>
            <Box sx={{ width: '100%', height: 400 }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={revenueSourceData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percentage }) => `${name} ${percentage}%`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {revenueSourceData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value) => formatCurrency(value)} />
                </PieChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Payment Methods */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Revenue by Payment Method
            </Typography>
            <Box sx={{ width: '100%', height: 300 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={paymentMethodData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="method" />
                  <YAxis tickFormatter={formatCurrency} />
                  <Tooltip 
                    formatter={(value, name) => [
                      name === 'amount' ? formatCurrency(value) : value,
                      name === 'amount' ? 'Revenue' : 'Orders'
                    ]}
                  />
                  <Legend />
                  <Bar dataKey="amount" fill="#8884d8" name="Revenue" />
                </BarChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Revenue Metrics */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Revenue Metrics Summary
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="primary.main" fontWeight="bold">
                    TZS 707,850
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Revenue
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="success.main" fontWeight="bold">
                    TZS 603,000
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Product Sales
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="info.main" fontWeight="bold">
                    TZS 60,300
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Shipping Revenue
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="warning.main" fontWeight="bold">
                    TZS 44,550
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Tax Collected
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

export default RevenueBreakdown;
