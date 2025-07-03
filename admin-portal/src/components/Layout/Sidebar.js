import React from 'react';
import { useQuery } from '@tanstack/react-query';
import { getOrderStats } from '../../services/orderService';
import { getUserStatsSummary } from '../../services/userService';
import {
  Box,
  List,
  ListItem,
  ListItemButton,
  ListItemIcon,
  ListItemText,
  Typography,
  Divider,
  Chip,
} from '@mui/material';
import {
  Dashboard,
  Inventory,
  ShoppingCart,
  People,
  Analytics,
  Settings,
  DirectionsCar,
  TrendingUp,
  Assignment,
  AttachMoney,
  Security,
  RateReview,
  ListAlt,
} from '@mui/icons-material';
import { useLocation, useNavigate } from 'react-router-dom';

const getMenuItems = (pendingOrders) => [
  {
    text: 'Dashboard',
    icon: <Dashboard />,
    path: '/dashboard',
  },
  {
    text: 'Products',
    icon: <Inventory />,
    path: '/products',
  },
  
  {
    text: 'Orders',
    icon: <ShoppingCart />,
    path: '/orders',
    badge: pendingOrders > 0 ? pendingOrders.toString() : '',
  },
  {
    text: 'Users',
    icon: <People />,
    path: '/users',
  },
  {
    text: 'Reviews',
    icon: <RateReview />,
    path: '/feedback-reviews',
  },
  {
    text: 'Content Management',
    icon: <Assignment />,
    path: '/content-management',
  },
  {
    text: 'Analytics & Reports',
    icon: <Analytics />,
    path: '/analytics',
  },
  {
    text: 'Payment Oversight',
    icon: <AttachMoney />,
    path: '/payment-oversight',
  },
  
  {
    text: 'Settings',
    icon: <Settings />,
    path: '/settings',
  },
];

const quickActions = [
  {
    text: 'Add Product',
    icon: <Inventory />,
    path: '/products/add',
  },
  {
    text: 'View Reports',
    icon: <TrendingUp />,
    path: '/analytics',
  },
  {
    text: 'Manage Orders',
    icon: <Assignment />,
    path: '/orders',
  },
];

const Sidebar = () => {
  const location = useLocation();
  const navigate = useNavigate();

  const { data: orderStats = { pending: 0 }, isLoading: ordersLoading } = useQuery({
    queryKey: ['orderStats'],
    queryFn: getOrderStats,
  });

  // Removed notification-related code as it's already in the header

  const isActive = (path) => {
    return location.pathname.startsWith(path);
  };

  return (
    <Box sx={{ height: '100%', display: 'flex', flexDirection: 'column' }}>
      {/* Logo */}
      <Box
        sx={{
          p: 3,
          display: 'flex',
          alignItems: 'center',
          borderBottom: '1px solid #e0e0e0',
        }}
      >
        <DirectionsCar
          sx={{
            fontSize: 32,
            color: 'primary.main',
            mr: 1,
          }}
        />
        <Box>
          <Typography variant="h6" fontWeight="bold">
            CarParts
          </Typography>
          <Typography variant="caption" color="text.secondary">
            Admin Portal
          </Typography>
        </Box>
      </Box>

      {/* Main Navigation */}
      <Box sx={{ flex: 1, overflow: 'auto' }}>
        <List sx={{ px: 2, py: 1 }}>
          {getMenuItems(orderStats.pending).map((item) => (
            <ListItem key={item.text} disablePadding sx={{ mb: 0.5 }}>
              <ListItemButton
                onClick={() => navigate(item.path)}
                sx={{
                  borderRadius: 2,
                  backgroundColor: isActive(item.path)
                    ? 'primary.main'
                    : 'transparent',
                  color: isActive(item.path) ? 'white' : 'text.primary',
                  '&:hover': {
                    backgroundColor: isActive(item.path)
                      ? 'primary.dark'
                      : 'action.hover',
                  },
                }}
              >
                <ListItemIcon
                  sx={{
                    color: isActive(item.path) ? 'white' : 'text.secondary',
                    minWidth: 40,
                  }}
                >
                  {item.icon}
                </ListItemIcon>
                <ListItemText
                  primary={item.text}
                  primaryTypographyProps={{
                    fontWeight: isActive(item.path) ? 600 : 400,
                  }}
                />
                {item.badge && (
                  <Chip
                    label={item.badge}
                    size="small"
                    color={item.badge === 'New' ? 'success' : 'error'}
                    sx={{ ml: 1, height: 20, fontSize: '0.7rem' }}
                  />
                )}
              </ListItemButton>
            </ListItem>
          ))}
        </List>

        <Divider sx={{ mx: 2, my: 2 }} />

        {/* Quick Actions */}
        <Box sx={{ px: 2 }}>
          <Typography
            variant="overline"
            sx={{
              color: 'text.secondary',
              fontWeight: 600,
              fontSize: '0.7rem',
              px: 1,
            }}
          >
            Quick Actions
          </Typography>
          <List sx={{ py: 1 }}>
            {quickActions.map((item) => (
              <ListItem key={item.text} disablePadding sx={{ mb: 0.5 }}>
                <ListItemButton
                  onClick={() => navigate(item.path)}
                  sx={{
                    borderRadius: 2,
                    py: 1,
                    '&:hover': {
                      backgroundColor: 'action.hover',
                    },
                  }}
                >
                  <ListItemIcon
                    sx={{
                      color: 'text.secondary',
                      minWidth: 36,
                    }}
                  >
                    {item.icon}
                  </ListItemIcon>
                  <ListItemText
                    primary={item.text}
                    primaryTypographyProps={{
                      fontSize: '0.875rem',
                    }}
                  />
                </ListItemButton>
              </ListItem>
            ))}
          </List>
        </Box>
      </Box>

      {/* Footer */}
      <Box
        sx={{
          p: 2,
          borderTop: '1px solid #e0e0e0',
          backgroundColor: '#fafafa',
        }}
      >
        <Typography variant="caption" color="text.secondary" align="center">
          Version 1.0.0
        </Typography>
      </Box>
    </Box>
  );
};

export default Sidebar;
