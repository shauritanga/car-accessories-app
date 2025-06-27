import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Grid,
  List,
  ListItem,
  ListItemText,
  Avatar,
  Chip,
} from '@mui/material';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
  PieChart,
  Pie,
  Cell,
} from 'recharts';

const COLORS = ['#0088FE', '#00C49F', '#FFBB28', '#FF8042', '#8884D8'];

const ProductAnalytics = ({ timeRange }) => {
  // Mock data - replace with real data from your service
  const topProductsData = [
    { name: 'Car Seat Covers', sales: 145, revenue: 725000 },
    { name: 'LED Headlights', sales: 132, revenue: 660000 },
    { name: 'Phone Mount', sales: 98, revenue: 294000 },
    { name: 'Floor Mats', sales: 87, revenue: 435000 },
    { name: 'Dash Camera', sales: 76, revenue: 912000 },
  ];

  const categoryData = [
    { name: 'Interior', value: 35, sales: 2450000 },
    { name: 'Exterior', value: 28, sales: 1980000 },
    { name: 'Electronics', value: 22, sales: 1540000 },
    { name: 'Performance', value: 15, sales: 1050000 },
  ];

  const inventoryData = [
    { category: 'Interior', inStock: 245, lowStock: 12, outOfStock: 3 },
    { category: 'Exterior', inStock: 189, lowStock: 8, outOfStock: 2 },
    { category: 'Electronics', inStock: 156, lowStock: 15, outOfStock: 5 },
    { category: 'Performance', inStock: 98, lowStock: 6, outOfStock: 1 },
  ];

  return (
    <Grid container spacing={3}>
      {/* Top Products */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Top Selling Products
            </Typography>
            <List>
              {topProductsData.map((product, index) => (
                <ListItem key={index}>
                  <Avatar sx={{ mr: 2, bgcolor: 'primary.main' }}>
                    {index + 1}
                  </Avatar>
                  <ListItemText
                    primary={product.name}
                    secondary={
                      <Box sx={{ display: 'flex', gap: 1, mt: 1 }}>
                        <Chip
                          label={`${product.sales} sold`}
                          size="small"
                          color="primary"
                          variant="outlined"
                        />
                        <Chip
                          label={`TZS ${product.revenue.toLocaleString()}`}
                          size="small"
                          color="success"
                          variant="outlined"
                        />
                      </Box>
                    }
                  />
                </ListItem>
              ))}
            </List>
          </CardContent>
        </Card>
      </Grid>

      {/* Category Distribution */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Sales by Category
            </Typography>
            <Box sx={{ width: '100%', height: 300 }}>
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={categoryData}
                    cx="50%"
                    cy="50%"
                    labelLine={false}
                    label={({ name, percent }) => `${name} ${(percent * 100).toFixed(0)}%`}
                    outerRadius={80}
                    fill="#8884d8"
                    dataKey="value"
                  >
                    {categoryData.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip />
                </PieChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Inventory Status */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Inventory Status by Category
            </Typography>
            <Box sx={{ width: '100%', height: 300 }}>
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={inventoryData}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="category" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="inStock" stackId="a" fill="#4caf50" name="In Stock" />
                  <Bar dataKey="lowStock" stackId="a" fill="#ff9800" name="Low Stock" />
                  <Bar dataKey="outOfStock" stackId="a" fill="#f44336" name="Out of Stock" />
                </BarChart>
              </ResponsiveContainer>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Product Metrics */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Product Performance Metrics
            </Typography>
            <Grid container spacing={3}>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="primary.main" fontWeight="bold">
                    156
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Products
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="success.main" fontWeight="bold">
                    145
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Active Products
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="warning.main" fontWeight="bold">
                    41
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Low Stock Items
                  </Typography>
                </Box>
              </Grid>
              <Grid item xs={12} sm={6} md={3}>
                <Box sx={{ textAlign: 'center', p: 2 }}>
                  <Typography variant="h4" color="error.main" fontWeight="bold">
                    11
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Out of Stock
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

export default ProductAnalytics;
