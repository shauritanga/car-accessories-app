import React from 'react';
import {
  Card,
  CardContent,
  Typography,
  Box,
  Avatar,
  Skeleton,
  Chip,
} from '@mui/material';
import { TrendingUp, TrendingDown } from '@mui/icons-material';
import { motion } from 'framer-motion';

const StatsCard = ({
  title,
  value,
  change,
  icon,
  color,
  format = 'number',
  isLoading = false,
}) => {
  const formatValue = (val) => {
    if (format === 'currency') {
      return new Intl.NumberFormat('en-TZ', {
        style: 'currency',
        currency: 'TZS',
        minimumFractionDigits: 0,
      }).format(val);
    }
    return new Intl.NumberFormat().format(val);
  };

  const isPositive = change >= 0;

  if (isLoading) {
    return (
      <Card className="hover-card">
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <Skeleton variant="circular" width={48} height={48} />
            <Box sx={{ ml: 2, flex: 1 }}>
              <Skeleton variant="text" width="60%" />
              <Skeleton variant="text" width="40%" />
            </Box>
          </Box>
          <Skeleton variant="text" width="80%" height={32} />
          <Skeleton variant="text" width="50%" />
        </CardContent>
      </Card>
    );
  }

  return (
    <motion.div
      whileHover={{ y: -2 }}
      transition={{ duration: 0.2 }}
    >
      <Card className="hover-card">
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', mb: 2 }}>
            <Avatar
              sx={{
                backgroundColor: color,
                width: 48,
                height: 48,
              }}
            >
              {icon}
            </Avatar>
            <Box sx={{ ml: 2, flex: 1 }}>
              <Typography variant="body2" color="text.secondary">
                {title}
              </Typography>
              <Chip
                icon={isPositive ? <TrendingUp /> : <TrendingDown />}
                label={`${isPositive ? '+' : ''}${change}%`}
                size="small"
                color={isPositive ? 'success' : 'error'}
                variant="outlined"
                sx={{ mt: 0.5 }}
              />
            </Box>
          </Box>
          <Typography variant="h4" fontWeight="bold" color="text.primary">
            {formatValue(value)}
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mt: 1 }}>
            vs last month
          </Typography>
        </CardContent>
      </Card>
    </motion.div>
  );
};

export default StatsCard;
