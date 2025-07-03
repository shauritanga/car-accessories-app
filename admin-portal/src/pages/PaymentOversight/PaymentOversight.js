import React, { useState } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  Chip,
  TextField,
  MenuItem,
  Select,
  FormControl,
  InputLabel,
  Dialog,
  DialogActions,
  DialogContent,
  DialogTitle,
} from '@mui/material';
import { DataGrid } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPayments, processRefund } from '../../services/paymentService';
import { format } from 'date-fns';
import LoadingScreen from '../../components/LoadingScreen/LoadingScreen';

const PaymentOversight = () => {
  const [filterStatus, setFilterStatus] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');
  const [openRefundDialog, setOpenRefundDialog] = useState(false);
  const [selectedPayment, setSelectedPayment] = useState(null);

  const queryClient = useQueryClient();
  
  const { data: payments, isLoading, error } = useQuery({
    queryKey: ['payments'],
    queryFn: getPayments,
  });

  const refundMutation = useMutation({
    mutationFn: ({ paymentId, refundData }) => processRefund(paymentId, refundData),
    onSuccess: () => {
      queryClient.invalidateQueries(['payments']);
      handleCloseRefundDialog();
    },
    onError: (error) => {
      console.error('Error processing refund:', error);
      alert('Failed to process refund. Please try again.');
    },
  });

  const handleFilterChange = (event) => {
    setFilterStatus(event.target.value);
  };

  const handleSearchChange = (event) => {
    setSearchTerm(event.target.value);
  };

  const handleRefundClick = (payment) => {
    setSelectedPayment(payment);
    setOpenRefundDialog(true);
  };

  const handleCloseRefundDialog = () => {
    setOpenRefundDialog(false);
    setSelectedPayment(null);
  };

  const handleConfirmRefund = () => {
    if (selectedPayment) {
      refundMutation.mutate({
        paymentId: selectedPayment.id,
        refundData: {
          amount: selectedPayment.amount,
          reason: 'Customer request',
        },
      });
    }
  };

  if (isLoading) return <LoadingScreen />;
  if (error) return <Typography>Error loading payments: {error.message}</Typography>;

  const filteredPayments = payments?.filter((payment) => {
    const matchesStatus = filterStatus === 'all' || payment.status === filterStatus;
    const matchesSearch = 
      payment.orderNumber?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      payment.customerName?.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesStatus && matchesSearch;
  }) || [];

  const columns = [
    { field: 'orderNumber', headerName: 'Order #', width: 120 },
    { field: 'customerName', headerName: 'Customer', width: 200 },
    { 
      field: 'amount', 
      headerName: 'Amount', 
      width: 120,
      valueFormatter: (params) => `TZS ${params.value.toLocaleString()}`,
    },
    { field: 'method', headerName: 'Method', width: 150 },
    { 
      field: 'status', 
      headerName: 'Status', 
      width: 120,
      renderCell: (params) => (
        <Chip 
          label={params.value} 
          color={params.value === 'paid' ? 'success' : params.value === 'pending' ? 'warning' : 'error'}
          size="small"
        />
      ),
    },
    { 
      field: 'date', 
      headerName: 'Date', 
      width: 150,
      valueFormatter: (params) => format(new Date(params.value), 'MMM dd, yyyy'),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 200,
      renderCell: (params) => (
        <Box sx={{ display: 'flex', gap: 1 }}>
          <Button 
            variant="outlined" 
            size="small" 
            onClick={() => handleRefundClick(params.row)}
            disabled={params.row.status !== 'paid'}
          >
            Refund
          </Button>
          <Button 
            variant="outlined" 
            size="small"
            onClick={() => console.log(`View details for payment ID: ${params.row.id}`)}
          >
            Details
          </Button>
        </Box>
      ),
    },
  ];

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" gutterBottom>
        Payment Oversight
      </Typography>
      <Typography variant="body1" color="text.secondary" sx={{ mb: 3 }}>
        Manage payment transactions, process refunds, and resolve payment issues.
      </Typography>

      <Grid container spacing={3}>
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 2, mb: 3 }}>
                <TextField 
                  placeholder="Search by order # or customer"
                  variant="outlined"
                  size="small"
                  sx={{ flexGrow: 1, minWidth: '200px' }}
                  value={searchTerm}
                  onChange={handleSearchChange}
                />
                <FormControl sx={{ minWidth: '120px' }} size="small">
                  <InputLabel>Status</InputLabel>
                  <Select
                    value={filterStatus}
                    onChange={handleFilterChange}
                    label="Status"
                  >
                    <MenuItem value="all">All</MenuItem>
                    <MenuItem value="paid">Paid</MenuItem>
                    <MenuItem value="pending">Pending</MenuItem>
                    <MenuItem value="failed">Failed</MenuItem>
                    <MenuItem value="refunded">Refunded</MenuItem>
                  </Select>
                </FormControl>
              </Box>
              
              <DataGrid
                rows={filteredPayments}
                columns={columns}
                pageSizeOptions={[5, 10, 20]}
                initialState={{
                  pagination: {
                    paginationModel: { pageSize: 10 },
                  },
                }}
                disableRowSelectionOnClick
                sx={{
                  border: 'none',
                  '& .MuiDataGrid-cell': {
                    borderBottom: '1px solid #f0f0f0',
                  },
                  '& .MuiDataGrid-columnHeaders': {
                    backgroundColor: '#fafafa',
                    borderBottom: '2px solid #e0e0e0',
                  },
                }}
              />
            </CardContent>
          </Card>
        </Grid>
      </Grid>

      {/* Refund Dialog */}
      <Dialog open={openRefundDialog} onClose={handleCloseRefundDialog}>
        <DialogTitle>Process Refund</DialogTitle>
        <DialogContent>
          {selectedPayment && (
            <Box>
              <Typography variant="body1" gutterBottom>
                Are you sure you want to process a refund for Order #{selectedPayment.orderNumber}?
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Amount: TZS {selectedPayment.amount.toLocaleString()}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Customer: {selectedPayment.customerName}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                Payment Method: {selectedPayment.method}
              </Typography>
            </Box>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseRefundDialog}>Cancel</Button>
          <Button onClick={handleConfirmRefund} color="primary" variant="contained">
            Confirm Refund
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default PaymentOversight;
