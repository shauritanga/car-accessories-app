import React from 'react';
import { PieChart, Pie, Cell, ResponsiveContainer, Tooltip, Legend } from 'recharts';
import { useQuery } from '@tanstack/react-query';
import { Box, Skeleton, Typography } from '@mui/material';
import { getOrdersStatusData } from '../../../services/dashboardService';

const COLORS = {
  pending: '#ff9800',
  processing: '#2196f3',
  shipped: '#9c27b0',
  delivered: '#4caf50',
  cancelled: '#f44336',
};

const OrdersChart = () => {
  const { data: ordersData, isLoading } = useQuery({
    queryKey: ['orders-status-chart'],
    queryFn: getOrdersStatusData,
  });

  if (isLoading) {
    return <Skeleton variant="rectangular" width="100%" height={300} />;
  }

  const total = ordersData?.reduce((sum, item) => sum + item.value, 0) || 0;

  const CustomTooltip = ({ active, payload }) => {
    if (active && payload && payload.length) {
      const data = payload[0];
      const percentage = ((data.value / total) * 100).toFixed(1);
      return (
        <Box
          sx={{
            backgroundColor: 'white',
            p: 2,
            border: '1px solid #e0e0e0',
            borderRadius: 1,
            boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
          }}
        >
          <Typography variant="body2" fontWeight="600">
            {data.payload.name}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            {data.value} orders ({percentage}%)
          </Typography>
        </Box>
      );
    }
    return null;
  };

  return (
    <Box sx={{ width: '100%', height: 300 }}>
      <ResponsiveContainer width="100%" height="100%">
        <PieChart>
          <Pie
            data={ordersData}
            cx="50%"
            cy="50%"
            innerRadius={60}
            outerRadius={100}
            paddingAngle={5}
            dataKey="value"
          >
            {ordersData?.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={COLORS[entry.name.toLowerCase()] || '#8884d8'}
              />
            ))}
          </Pie>
          <Tooltip content={<CustomTooltip />} />
        </PieChart>
      </ResponsiveContainer>
      
      {/* Legend */}
      <Box sx={{ mt: 2 }}>
        {ordersData?.map((entry, index) => (
          <Box
            key={entry.name}
            sx={{
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'space-between',
              mb: 1,
            }}
          >
            <Box sx={{ display: 'flex', alignItems: 'center' }}>
              <Box
                sx={{
                  width: 12,
                  height: 12,
                  borderRadius: '50%',
                  backgroundColor: COLORS[entry.name.toLowerCase()],
                  mr: 1,
                }}
              />
              <Typography variant="body2" color="text.secondary">
                {entry.name}
              </Typography>
            </Box>
            <Typography variant="body2" fontWeight="600">
              {entry.value}
            </Typography>
          </Box>
        ))}
      </Box>
    </Box>
  );
};

export default OrdersChart;
