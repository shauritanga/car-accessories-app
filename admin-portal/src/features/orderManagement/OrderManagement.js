// Order Management main component
import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getOrders, handleComplaint, getSystemPerformance } from './orderManagementService';
import { Box, Typography, Button, Table, TableHead, TableRow, TableCell, TableBody, Chip, CircularProgress, Stack } from '@mui/material';

// TODO: Implement order management UI and logic for:
// - Monitor orders placed and deliveries made
// - Handle complaints/disputes between buyers and sellers
// - Track delivery status or system performance
// Use orderManagementService.js for API calls

const OrderManagement = () => {
  const queryClient = useQueryClient();
  // Fetch orders
  const { data: orders = [], isLoading: loadingOrders } = useQuery({
    queryKey: ['orders'],
    queryFn: getOrders,
  });
  // Mutation for handling complaints
  const complaintMutation = useMutation({
    mutationFn: ({ orderId, action }) => handleComplaint(orderId, action),
    onSuccess: () => {
      queryClient.invalidateQueries(['orders']);
    },
  });

  const handleComplaintAction = (orderId, action) => {
    complaintMutation.mutate({ orderId, action });
  };

  if (loadingOrders) return <CircularProgress />;

  return (
    <Box>
      <Typography variant="h5" fontWeight="bold" mb={2}>Orders & Deliveries</Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Order ID</TableCell>
            <TableCell>Buyer</TableCell>
            <TableCell>Seller</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Delivery</TableCell>
            <TableCell>Complaint</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {orders.length === 0 && (
            <TableRow><TableCell colSpan={7}>No orders found</TableCell></TableRow>
          )}
          {orders.map((order) => (
            <TableRow key={order.id}>
              <TableCell>{order.id}</TableCell>
              <TableCell>{order.buyerName}</TableCell>
              <TableCell>{order.sellerName}</TableCell>
              <TableCell><Chip label={order.status} color={order.status === 'completed' ? 'success' : order.status === 'pending' ? 'warning' : 'default'} /></TableCell>
              <TableCell>{order.deliveryStatus}</TableCell>
              <TableCell>{order.complaint ? <Chip label="Yes" color="error" /> : <Chip label="No" color="success" />}</TableCell>
              <TableCell>
                <Stack direction="row" spacing={1}>
                  {order.complaint && (
                    <Button size="small" color="warning" variant="outlined" onClick={() => handleComplaintAction(order.id, 'resolve')}>Resolve</Button>
                  )}
                  <Button size="small" color="primary" variant="outlined" onClick={() => handleComplaintAction(order.id, 'details')}>Details</Button>
                </Stack>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
};

export default OrderManagement;
