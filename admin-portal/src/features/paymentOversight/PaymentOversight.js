// Payment Oversight main component
import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getTransactions, handleRefund } from './paymentOversightService';
import { Box, Typography, Table, TableHead, TableRow, TableCell, TableBody, Button, Chip, CircularProgress, Stack } from '@mui/material';

// TODO: Implement payment oversight UI and logic for:
// - Track payment transactions
// - Handle refund requests or payment issues
// Use paymentOversightService.js for API calls

const PaymentOversight = () => {
  const queryClient = useQueryClient();
  // Fetch transactions
  const { data: transactions = [], isLoading, isError } = useQuery({
    queryKey: ['transactions'],
    queryFn: getTransactions,
  });
  // Mutation for handling refunds
  const refundMutation = useMutation({
    mutationFn: ({ transactionId, action }) => handleRefund(transactionId, action),
    onSuccess: () => {
      queryClient.invalidateQueries(['transactions']);
    },
  });
  const handleRefundAction = (transactionId, action) => {
    refundMutation.mutate({ transactionId, action });
  };
  if (isLoading) return <CircularProgress />;
  if (isError) return <div style={{ color: 'red' }}>Failed to load transactions.</div>;
  return (
    <Box>
      <Typography variant="h5" fontWeight="bold" mb={2}>Payment Transactions</Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Transaction ID</TableCell>
            <TableCell>User</TableCell>
            <TableCell>Amount</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Refund Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {transactions.length === 0 && (
            <TableRow><TableCell colSpan={6}>No transactions found</TableCell></TableRow>
          )}
          {transactions.map((tx) => (
            <TableRow key={tx.id}>
              <TableCell>{tx.id}</TableCell>
              <TableCell>{tx.userName}</TableCell>
              <TableCell>{tx.amount}</TableCell>
              <TableCell><Chip label={tx.status} color={tx.status === 'success' ? 'success' : 'error'} /></TableCell>
              <TableCell><Chip label={tx.refundStatus || 'none'} color={tx.refundStatus === 'approved' ? 'success' : tx.refundStatus === 'rejected' ? 'error' : 'default'} /></TableCell>
              <TableCell>
                <Stack direction="row" spacing={1}>
                  <Button size="small" color="success" variant="contained" disabled={tx.refundStatus === 'approved'} onClick={() => handleRefundAction(tx.id, 'approved')}>Approve Refund</Button>
                  <Button size="small" color="error" variant="outlined" disabled={tx.refundStatus === 'rejected'} onClick={() => handleRefundAction(tx.id, 'rejected')}>Reject Refund</Button>
                </Stack>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
};

export default PaymentOversight;
