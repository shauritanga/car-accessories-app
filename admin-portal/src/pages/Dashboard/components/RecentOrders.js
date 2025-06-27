import React from 'react';
import {
  Box,
  List,
  ListItem,
  ListItemText,
  Typography,
  Chip,
  Avatar,
  Skeleton,
  IconButton,
} from '@mui/material';
import { MoreVert, Person } from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { getRecentOrders } from '../../../services/dashboardService';

const statusColors = {
  pending: 'warning',
  processing: 'info',
  shipped: 'primary',
  delivered: 'success',
  cancelled: 'error',
};

const RecentOrders = () => {
  const { data: orders, isLoading } = useQuery({
    queryKey: ['recent-orders'],
    queryFn: getRecentOrders,
  });

  if (isLoading) {
    return (
      <List>
        {[...Array(5)].map((_, index) => (
          <ListItem key={index} sx={{ px: 0 }}>
            <Skeleton variant="circular" width={40} height={40} sx={{ mr: 2 }} />
            <ListItemText
              primary={<Skeleton variant="text" width="60%" />}
              secondary={<Skeleton variant="text" width="40%" />}
            />
            <Skeleton variant="rectangular" width={80} height={24} />
          </ListItem>
        ))}
      </List>
    );
  }

  return (
    <List sx={{ maxHeight: 400, overflow: 'auto' }}>
      {orders?.map((order, index) => (
        <ListItem
          key={order.id}
          sx={{
            px: 0,
            py: 2,
            borderBottom: index < orders.length - 1 ? '1px solid #f0f0f0' : 'none',
          }}
        >
          <Avatar sx={{ mr: 2, bgcolor: 'primary.light' }}>
            <Person />
          </Avatar>
          <ListItemText
            primary={
              <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                <Typography variant="body1" fontWeight="600">
                  Order #{order.orderNumber}
                </Typography>
                <Chip
                  label={order.status}
                  size="small"
                  color={statusColors[order.status] || 'default'}
                  sx={{ textTransform: 'capitalize' }}
                />
              </Box>
            }
            secondary={
              <Box sx={{ mt: 0.5 }}>
                <Typography variant="body2" color="text.secondary">
                  {order.customerName}
                </Typography>
                <Typography variant="caption" color="text.secondary">
                  {format(new Date(order.createdAt), 'MMM dd, yyyy HH:mm')}
                </Typography>
              </Box>
            }
          />
          <Box sx={{ textAlign: 'right', ml: 2 }}>
            <Typography variant="h6" fontWeight="bold" color="primary.main">
              TZS {order.total.toLocaleString()}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {order.itemsCount} items
            </Typography>
          </Box>
          <IconButton size="small" sx={{ ml: 1 }}>
            <MoreVert />
          </IconButton>
        </ListItem>
      ))}
    </List>
  );
};

export default RecentOrders;
