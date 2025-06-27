import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  Chip,
  Avatar,
  IconButton,
  List,
  ListItem,
  ListItemText,
  Divider,
} from '@mui/material';
import {
  ArrowBack,
  Email,
  Phone,
  LocationOn,
  CalendarToday,
  ShoppingCart,
  AttachMoney,
  CheckCircle,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { getUser, getUserOrders } from '../../../services/userService';
import { format } from 'date-fns';
import LoadingScreen from '../../../components/LoadingScreen/LoadingScreen';

const UserDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: user, isLoading: userLoading } = useQuery({
    queryKey: ['user', id],
    queryFn: () => getUser(id),
  });

  const { data: orders = [], isLoading: ordersLoading } = useQuery({
    queryKey: ['user-orders', id],
    queryFn: () => getUserOrders(id),
  });

  if (userLoading) return <LoadingScreen />;
  if (!user) return <Typography>User not found</Typography>;

  const totalSpent = orders.reduce((sum, order) => sum + (order.total || 0), 0);
  const completedOrders = orders.filter(order => order.status === 'delivered').length;

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
        <IconButton onClick={() => navigate('/users')} sx={{ mr: 2 }}>
          <ArrowBack />
        </IconButton>
        <Box sx={{ flex: 1 }}>
          <Typography variant="h4" fontWeight="bold">
            {user.name || 'User Details'}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {user.role === 'customer' ? 'Customer' : 'Seller'} Information
          </Typography>
        </Box>
        <Chip
          label={user.isActive ? 'Active' : 'Inactive'}
          color={user.isActive ? 'success' : 'default'}
          variant={user.isActive ? 'filled' : 'outlined'}
        />
      </Box>

      <Grid container spacing={3}>
        {/* User Information */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent sx={{ textAlign: 'center' }}>
              <Avatar
                src={user.profileImageUrl}
                sx={{ width: 100, height: 100, mx: 'auto', mb: 2 }}
              >
                {user.name?.charAt(0)}
              </Avatar>
              <Typography variant="h5" fontWeight="bold" gutterBottom>
                {user.name || 'N/A'}
              </Typography>
              <Typography variant="body2" color="text.secondary" gutterBottom>
                {user.email}
              </Typography>
              <Chip
                label={user.role}
                color="primary"
                variant="outlined"
                sx={{ textTransform: 'capitalize' }}
              />
            </CardContent>
          </Card>

          {/* Contact Information */}
          <Card sx={{ mt: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Contact Information
              </Typography>
              <List>
                <ListItem>
                  <Email sx={{ mr: 2, color: 'text.secondary' }} />
                  <ListItemText
                    primary="Email"
                    secondary={user.email}
                  />
                </ListItem>
                <ListItem>
                  <Phone sx={{ mr: 2, color: 'text.secondary' }} />
                  <ListItemText
                    primary="Phone"
                    secondary={user.phone || 'N/A'}
                  />
                </ListItem>
                <ListItem>
                  <LocationOn sx={{ mr: 2, color: 'text.secondary' }} />
                  <ListItemText
                    primary="Location"
                    secondary={user.city || 'N/A'}
                  />
                </ListItem>
                <ListItem>
                  <CalendarToday sx={{ mr: 2, color: 'text.secondary' }} />
                  <ListItemText
                    primary="Joined"
                    secondary={user.createdAt ? format(new Date(user.createdAt), 'MMMM dd, yyyy') : 'N/A'}
                  />
                </ListItem>
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Statistics and Orders */}
        <Grid item xs={12} md={8}>
          {/* Statistics */}
          <Grid container spacing={3} sx={{ mb: 3 }}>
            <Grid item xs={12} sm={4}>
              <Card>
                <CardContent sx={{ textAlign: 'center' }}>
                  <ShoppingCart sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                  <Typography variant="h4" fontWeight="bold" color="primary.main">
                    {orders.length}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Orders
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={4}>
              <Card>
                <CardContent sx={{ textAlign: 'center' }}>
                  <AttachMoney sx={{ fontSize: 40, color: 'success.main', mb: 1 }} />
                  <Typography variant="h4" fontWeight="bold" color="success.main">
                    TZS {totalSpent.toLocaleString()}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Total Spent
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
            <Grid item xs={12} sm={4}>
              <Card>
                <CardContent sx={{ textAlign: 'center' }}>
                  <CheckCircle sx={{ fontSize: 40, color: 'info.main', mb: 1 }} />
                  <Typography variant="h4" fontWeight="bold" color="info.main">
                    {completedOrders}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    Completed Orders
                  </Typography>
                </CardContent>
              </Card>
            </Grid>
          </Grid>

          {/* Recent Orders */}
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Recent Orders
              </Typography>
              {ordersLoading ? (
                <Typography>Loading orders...</Typography>
              ) : orders.length > 0 ? (
                <List>
                  {orders.slice(0, 5).map((order, index) => (
                    <React.Fragment key={order.id}>
                      <ListItem>
                        <ListItemText
                          primary={
                            <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                              <Typography variant="body1" fontWeight="600">
                                Order #{order.orderNumber}
                              </Typography>
                              <Chip
                                label={order.status}
                                size="small"
                                color={
                                  order.status === 'delivered' ? 'success' :
                                  order.status === 'shipped' ? 'primary' :
                                  order.status === 'processing' ? 'info' :
                                  order.status === 'cancelled' ? 'error' : 'warning'
                                }
                                sx={{ textTransform: 'capitalize' }}
                              />
                            </Box>
                          }
                          secondary={
                            <Box sx={{ mt: 1 }}>
                              <Typography variant="body2" color="text.secondary">
                                {order.createdAt ? format(new Date(order.createdAt), 'MMM dd, yyyy HH:mm') : 'N/A'}
                              </Typography>
                              <Typography variant="body2" fontWeight="600" color="primary.main">
                                TZS {(order.total || 0).toLocaleString()}
                              </Typography>
                            </Box>
                          }
                        />
                      </ListItem>
                      {index < Math.min(orders.length, 5) - 1 && <Divider />}
                    </React.Fragment>
                  ))}
                </List>
              ) : (
                <Typography color="text.secondary">No orders found</Typography>
              )}
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default UserDetails;
