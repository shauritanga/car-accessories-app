// User Management main component
import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPendingSellers, updateUserStatus, getUserProfiles } from './userManagementService';
import { Box, Typography, Button, Table, TableHead, TableRow, TableCell, TableBody, Chip, CircularProgress, Stack } from '@mui/material';

// TODO: Implement user management UI and logic for:
// - Approve/reject seller registrations
// - Manage buyer/seller accounts (activate, deactivate, suspend)
// - View user profiles and activities
// Use userManagementService.js for API calls

const UserManagement = () => {
  const queryClient = useQueryClient();
  // Fetch pending sellers
  const { data: pendingSellers = [], isLoading: loadingSellers } = useQuery({
    queryKey: ['pendingSellers'],
    queryFn: getPendingSellers,
  });
  // Fetch user profiles
  const { data: userProfiles = [], isLoading: loadingProfiles } = useQuery({
    queryKey: ['userProfiles'],
    queryFn: getUserProfiles,
  });
  // Mutation for updating user status
  const mutation = useMutation({
    mutationFn: ({ userId, status }) => updateUserStatus(userId, status),
    onSuccess: () => {
      queryClient.invalidateQueries(['pendingSellers']);
      queryClient.invalidateQueries(['userProfiles']);
    },
  });

  // Approve/reject seller
  const handleSellerAction = (userId, status) => {
    mutation.mutate({ userId, status });
  };

  // Render loading
  if (loadingSellers || loadingProfiles) return <CircularProgress />;

  return (
    <Box>
      <Typography variant="h5" fontWeight="bold" mb={2}>Pending Seller Registrations</Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Name</TableCell>
            <TableCell>Email</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {pendingSellers.length === 0 && (
            <TableRow><TableCell colSpan={4}>No pending sellers</TableCell></TableRow>
          )}
          {pendingSellers.map((seller) => (
            <TableRow key={seller.id}>
              <TableCell>{seller.name}</TableCell>
              <TableCell>{seller.email}</TableCell>
              <TableCell><Chip label={seller.status} color={seller.status === 'pending' ? 'warning' : 'default'} /></TableCell>
              <TableCell>
                <Stack direction="row" spacing={1}>
                  <Button size="small" color="success" variant="contained" onClick={() => handleSellerAction(seller.id, 'approved')}>Approve</Button>
                  <Button size="small" color="error" variant="outlined" onClick={() => handleSellerAction(seller.id, 'rejected')}>Reject</Button>
                </Stack>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <Typography variant="h5" fontWeight="bold" mt={4} mb={2}>User Accounts</Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Name</TableCell>
            <TableCell>Email</TableCell>
            <TableCell>Role</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {userProfiles.length === 0 && (
            <TableRow><TableCell colSpan={5}>No users found</TableCell></TableRow>
          )}
          {userProfiles.map((user) => (
            <TableRow key={user.id}>
              <TableCell>{user.name}</TableCell>
              <TableCell>{user.email}</TableCell>
              <TableCell>{user.role}</TableCell>
              <TableCell><Chip label={user.status} color={user.status === 'active' ? 'success' : user.status === 'suspended' ? 'warning' : 'default'} /></TableCell>
              <TableCell>
                <Stack direction="row" spacing={1}>
                  <Button size="small" color="success" variant="contained" onClick={() => handleSellerAction(user.id, 'active')}>Activate</Button>
                  <Button size="small" color="warning" variant="outlined" onClick={() => handleSellerAction(user.id, 'suspended')}>Suspend</Button>
                  <Button size="small" color="error" variant="outlined" onClick={() => handleSellerAction(user.id, 'deactivated')}>Deactivate</Button>
                </Stack>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
};

export default UserManagement;
