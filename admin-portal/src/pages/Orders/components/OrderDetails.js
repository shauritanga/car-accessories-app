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
  Divider,
  List,
  ListItem,
  ListItemText,
  IconButton,
  Avatar,
  Stepper,
  Step,
  StepLabel,
  StepContent,
} from '@mui/material';
import {
  ArrowBack,
  Print,
  Email,
  LocalShipping,
  Person,
  LocationOn,
  Phone,
  AttachMoney,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { getOrder } from '../../../services/orderService';
import { format } from 'date-fns';
import LoadingScreen from '../../../components/LoadingScreen/LoadingScreen';

const statusColors = {
  pending: 'warning',
  processing: 'info',
  shipped: 'primary',
  delivered: 'success',
  cancelled: 'error',
};

const OrderDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: order, isLoading, error } = useQuery({
    queryKey: ['order', id],
    queryFn: () => getOrder(id),
  });

  if (isLoading) return <LoadingScreen />;
  if (error) return <Typography>Error loading order</Typography>;
  if (!order) return <Typography>Order not found</Typography>;

  const steps = [
    { label: 'Order Placed', status: 'pending' },
    { label: 'Processing', status: 'processing' },
    { label: 'Shipped', status: 'shipped' },
    { label: 'Delivered', status: 'delivered' },
  ];

  const getActiveStep = () => {
    return steps.findIndex(step => step.status === order.status);
  };

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
        <IconButton onClick={() => navigate('/orders')} sx={{ mr: 2 }}>
          <ArrowBack />
        </IconButton>
        <Box sx={{ flex: 1 }}>
          <Typography variant="h4" fontWeight="bold">
            Order #{order.orderNumber}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Placed on {format(new Date(order.createdAt), 'MMMM dd, yyyy HH:mm')}
          </Typography>
        </Box>
        <Box sx={{ display: 'flex', gap: 2 }}>
          <Button variant="outlined" startIcon={<Print />}>
            Print
          </Button>
          <Button variant="outlined" startIcon={<Email />}>
            Email Customer
          </Button>
          <Chip
            label={order.status}
            color={statusColors[order.status] || 'default'}
            sx={{ textTransform: 'capitalize' }}
          />
        </Box>
      </Box>

      <Grid container spacing={3}>
        {/* Order Status */}
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Order Status
              </Typography>
              <Stepper activeStep={getActiveStep()} orientation="horizontal">
                {steps.map((step, index) => (
                  <Step key={step.label}>
                    <StepLabel>{step.label}</StepLabel>
                  </Step>
                ))}
              </Stepper>
            </CardContent>
          </Card>
        </Grid>

        {/* Customer Information */}
        <Grid item xs={12} md={4}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Customer Information
              </Typography>
              <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
                <Avatar sx={{ mr: 2 }}>
                  <Person />
                </Avatar>
                <Box>
                  <Typography variant="body1" fontWeight="600">
                    {order.customerName}
                  </Typography>
                  <Typography variant="body2" color="text.secondary">
                    {order.customerEmail}
                  </Typography>
                </Box>
              </Box>
              
              {order.shippingAddress && (
                <Box sx={{ mt: 2 }}>
                  <Typography variant="subtitle2" gutterBottom>
                    Shipping Address
                  </Typography>
                  <Box sx={{ display: 'flex', alignItems: 'flex-start', mb: 1 }}>
                    <LocationOn sx={{ mr: 1, mt: 0.5, fontSize: 20, color: 'text.secondary' }} />
                    <Box>
                      <Typography variant="body2">
                        {order.shippingAddress.street}
                      </Typography>
                      <Typography variant="body2">
                        {order.shippingAddress.city}, {order.shippingAddress.state}
                      </Typography>
                      <Typography variant="body2">
                        {order.shippingAddress.country}
                      </Typography>
                    </Box>
                  </Box>
                  {order.shippingAddress.phone && (
                    <Box sx={{ display: 'flex', alignItems: 'center' }}>
                      <Phone sx={{ mr: 1, fontSize: 20, color: 'text.secondary' }} />
                      <Typography variant="body2">
                        {order.shippingAddress.phone}
                      </Typography>
                    </Box>
                  )}
                </Box>
              )}
            </CardContent>
          </Card>
        </Grid>

        {/* Order Items */}
        <Grid item xs={12} md={8}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Order Items
              </Typography>
              <List>
                {order.items?.map((item, index) => (
                  <React.Fragment key={index}>
                    <ListItem sx={{ px: 0 }}>
                      <Avatar
                        src={item.image}
                        variant="rounded"
                        sx={{ width: 60, height: 60, mr: 2 }}
                      >
                        {item.name?.charAt(0)}
                      </Avatar>
                      <ListItemText
                        primary={
                          <Typography variant="body1" fontWeight="600">
                            {item.name}
                          </Typography>
                        }
                        secondary={
                          <Box sx={{ mt: 1 }}>
                            <Typography variant="body2" color="text.secondary">
                              Quantity: {item.quantity}
                            </Typography>
                            <Typography variant="body2" color="text.secondary">
                              Price: TZS {item.price?.toLocaleString()}
                            </Typography>
                          </Box>
                        }
                      />
                      <Box sx={{ textAlign: 'right' }}>
                        <Typography variant="h6" fontWeight="bold">
                          TZS {((item.price || 0) * (item.quantity || 0)).toLocaleString()}
                        </Typography>
                      </Box>
                    </ListItem>
                    {index < (order.items?.length || 0) - 1 && <Divider />}
                  </React.Fragment>
                ))}
              </List>
            </CardContent>
          </Card>
        </Grid>

        {/* Payment Information */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Payment Information
              </Typography>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="body2">Payment Method:</Typography>
                <Typography variant="body2" fontWeight="600">
                  {order.paymentMethod || 'N/A'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="body2">Payment Status:</Typography>
                <Chip
                  label={order.paymentStatus || 'pending'}
                  size="small"
                  color={order.paymentStatus === 'paid' ? 'success' : 'warning'}
                  variant="outlined"
                />
              </Box>
              <Divider sx={{ my: 2 }} />
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography variant="body2">Subtotal:</Typography>
                <Typography variant="body2">
                  TZS {(order.subtotal || 0).toLocaleString()}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography variant="body2">Shipping:</Typography>
                <Typography variant="body2">
                  TZS {(order.shippingCost || 0).toLocaleString()}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 1 }}>
                <Typography variant="body2">Tax:</Typography>
                <Typography variant="body2">
                  TZS {(order.tax || 0).toLocaleString()}
                </Typography>
              </Box>
              <Divider sx={{ my: 1 }} />
              <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                <Typography variant="h6" fontWeight="bold">Total:</Typography>
                <Typography variant="h6" fontWeight="bold" color="primary.main">
                  TZS {(order.total || 0).toLocaleString()}
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* Shipping Information */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Shipping Information
              </Typography>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="body2">Shipping Method:</Typography>
                <Typography variant="body2" fontWeight="600">
                  {order.shippingMethod || 'Standard Delivery'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="body2">Tracking Number:</Typography>
                <Typography variant="body2" fontWeight="600">
                  {order.trackingNumber || 'N/A'}
                </Typography>
              </Box>
              <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
                <Typography variant="body2">Estimated Delivery:</Typography>
                <Typography variant="body2" fontWeight="600">
                  {order.estimatedDelivery 
                    ? format(new Date(order.estimatedDelivery), 'MMM dd, yyyy')
                    : 'N/A'
                  }
                </Typography>
              </Box>
              {order.status === 'shipped' && (
                <Button
                  variant="outlined"
                  startIcon={<LocalShipping />}
                  fullWidth
                  sx={{ mt: 2 }}
                >
                  Track Package
                </Button>
              )}
            </CardContent>
          </Card>
        </Grid>
        
        {/* Complaints and Disputes */}
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Complaints and Disputes
              </Typography>
              <Box sx={{ mb: 2 }}>
                {order.complaints && order.complaints.length > 0 ? (
                  <List>
                    {order.complaints.map((complaint, index) => (
                      <React.Fragment key={index}>
                        <ListItem sx={{ px: 0 }}>
                          <ListItemText
                            primary={
                              <Typography variant="body1" fontWeight="600">
                                {complaint.title}
                              </Typography>
                            }
                            secondary={
                              <Box sx={{ mt: 1 }}>
                                <Typography variant="body2" color="text.secondary">
                                  Status: {complaint.status}
                                </Typography>
                                <Typography variant="body2" color="text.secondary">
                                  Reported on: {complaint.date ? format(new Date(complaint.date), 'MMM dd, yyyy') : 'N/A'}
                                </Typography>
                              </Box>
                            }
                          />
                        </ListItem>
                        {index < (order.complaints.length - 1) && <Divider />}
                      </React.Fragment>
                    ))}
                  </List>
                ) : (
                  <Typography variant="body2" color="text.secondary">
                    No complaints or disputes reported for this order.
                  </Typography>
                )}
              </Box>
              <Button
                variant="outlined"
                fullWidth
                sx={{ mt: 2 }}
              >
                Log New Complaint
              </Button>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default OrderDetails;
