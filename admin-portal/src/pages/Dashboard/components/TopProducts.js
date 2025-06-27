import React from 'react';
import {
  Box,
  List,
  ListItem,
  ListItemAvatar,
  ListItemText,
  Avatar,
  Typography,
  Chip,
  Skeleton,
  LinearProgress,
} from '@mui/material';
import { useQuery } from '@tanstack/react-query';
import { getTopProducts } from '../../../services/dashboardService';

const TopProducts = () => {
  const { data: products, isLoading } = useQuery({
    queryKey: ['top-products'],
    queryFn: getTopProducts,
  });

  if (isLoading) {
    return (
      <List>
        {[...Array(5)].map((_, index) => (
          <ListItem key={index} sx={{ px: 0 }}>
            <ListItemAvatar>
              <Skeleton variant="circular" width={48} height={48} />
            </ListItemAvatar>
            <ListItemText
              primary={<Skeleton variant="text" width="60%" />}
              secondary={<Skeleton variant="text" width="40%" />}
            />
            <Skeleton variant="text" width={60} />
          </ListItem>
        ))}
      </List>
    );
  }

  const maxSales = Math.max(...(products?.map(p => p.sales) || [1]));

  return (
    <List sx={{ maxHeight: 400, overflow: 'auto' }}>
      {products?.map((product, index) => (
        <ListItem
          key={product.id}
          sx={{
            px: 0,
            py: 2,
            borderBottom: index < products.length - 1 ? '1px solid #f0f0f0' : 'none',
          }}
        >
          <ListItemAvatar>
            <Avatar
              src={product.image}
              sx={{ width: 48, height: 48, mr: 2 }}
            >
              {product.name.charAt(0)}
            </Avatar>
          </ListItemAvatar>
          <ListItemText
            primary={
              <Typography variant="body1" fontWeight="600" noWrap>
                {product.name}
              </Typography>
            }
            secondary={
              <Box sx={{ mt: 1 }}>
                <Box sx={{ display: 'flex', alignItems: 'center', mb: 1 }}>
                  <Typography variant="body2" color="text.secondary" sx={{ mr: 1 }}>
                    Sales: {product.sales}
                  </Typography>
                  <Chip
                    label={`TZS ${product.revenue.toLocaleString()}`}
                    size="small"
                    color="primary"
                    variant="outlined"
                  />
                </Box>
                <LinearProgress
                  variant="determinate"
                  value={(product.sales / maxSales) * 100}
                  sx={{
                    height: 4,
                    borderRadius: 2,
                    backgroundColor: '#f0f0f0',
                    '& .MuiLinearProgress-bar': {
                      borderRadius: 2,
                    },
                  }}
                />
              </Box>
            }
          />
          <Box sx={{ textAlign: 'right', ml: 2 }}>
            <Typography variant="h6" fontWeight="bold" color="primary.main">
              #{index + 1}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              {product.category}
            </Typography>
          </Box>
        </ListItem>
      ))}
    </List>
  );
};

export default TopProducts;
