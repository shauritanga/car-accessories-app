import React from 'react';
import {
  ResponsiveContainer,
  AreaChart,
  Area,
  XAxis,
  YAxis,
  CartesianGrid,
  Tooltip,
  Legend,
} from 'recharts';
import { useQuery } from '@tanstack/react-query';
import { Box, Skeleton } from '@mui/material';
import { getRevenueData } from '../../../services/dashboardService';

const RevenueChart = () => {
  const { data: revenueData, isLoading } = useQuery({
    queryKey: ['revenue-chart'],
    queryFn: getRevenueData,
  });

  if (isLoading) {
    return <Skeleton variant="rectangular" width="100%" height={300} />;
  }

  const formatCurrency = (value) => {
    return new Intl.NumberFormat('en-TZ', {
      style: 'currency',
      currency: 'TZS',
      minimumFractionDigits: 0,
    }).format(value);
  };

  return (
    <Box sx={{ width: '100%', height: 300 }}>
      <ResponsiveContainer width="100%" height="100%">
        <AreaChart
          data={revenueData}
          margin={{
            top: 10,
            right: 30,
            left: 0,
            bottom: 0,
          }}
        >
          <defs>
            <linearGradient id="colorRevenue" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#1976d2" stopOpacity={0.8} />
              <stop offset="95%" stopColor="#1976d2" stopOpacity={0.1} />
            </linearGradient>
            <linearGradient id="colorOrders" x1="0" y1="0" x2="0" y2="1">
              <stop offset="5%" stopColor="#dc004e" stopOpacity={0.8} />
              <stop offset="95%" stopColor="#dc004e" stopOpacity={0.1} />
            </linearGradient>
          </defs>
          <CartesianGrid strokeDasharray="3 3" stroke="#f0f0f0" />
          <XAxis
            dataKey="month"
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 12, fill: '#666' }}
          />
          <YAxis
            axisLine={false}
            tickLine={false}
            tick={{ fontSize: 12, fill: '#666' }}
            tickFormatter={formatCurrency}
          />
          <Tooltip
            contentStyle={{
              backgroundColor: '#fff',
              border: '1px solid #e0e0e0',
              borderRadius: '8px',
              boxShadow: '0 4px 12px rgba(0,0,0,0.1)',
            }}
            formatter={(value, name) => [formatCurrency(value), name]}
          />
          <Legend />
          <Area
            type="monotone"
            dataKey="revenue"
            stroke="#1976d2"
            fillOpacity={1}
            fill="url(#colorRevenue)"
            strokeWidth={2}
            name="Revenue"
          />
          <Area
            type="monotone"
            dataKey="orders"
            stroke="#dc004e"
            fillOpacity={1}
            fill="url(#colorOrders)"
            strokeWidth={2}
            name="Orders Value"
          />
        </AreaChart>
      </ResponsiveContainer>
    </Box>
  );
};

export default RevenueChart;
