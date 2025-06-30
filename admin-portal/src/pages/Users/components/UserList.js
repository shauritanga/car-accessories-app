import React, { useState } from 'react';
import {
  Box,
  Card,
  TextField,
  InputAdornment,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Chip,
  IconButton,
  Menu,
  ListItemIcon,
  ListItemText,
  MenuItem as MenuItemComponent,
  Avatar,
} from '@mui/material';
import {
  Search,
  Visibility,
  Block,
  CheckCircle,
  MoreVert,
  Person,
} from '@mui/icons-material';
import { DataGrid } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getUsers, updateUserStatus, updateSellerApproval } from '../../../services/userService';
import { format } from 'date-fns';
import toast from 'react-hot-toast';

const UserList = ({ userType, refreshTrigger }) => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [approvalFilter, setApprovalFilter] = useState(''); // For seller approval status
  const [anchorEl, setAnchorEl] = useState(null);
  const [selectedUser, setSelectedUser] = useState(null);

  const { data: users = [], isLoading } = useQuery({
    queryKey: ['users', userType, searchTerm, statusFilter, approvalFilter, refreshTrigger],
    queryFn: async () => {
      const filters = { role: userType, search: searchTerm, status: statusFilter };
      if (userType === 'seller' && approvalFilter) {
        filters.approval = approvalFilter; // Assuming 'approval' field exists or can be added in userService.js
      }
      const result = await getUsers(filters);
      console.log('Fetched users:', result);
      return result;
    },
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ userId, isActive }) => updateUserStatus(userId, isActive),
    onSuccess: () => {
      toast.success('User status updated successfully');
      queryClient.invalidateQueries(['users']);
      handleMenuClose();
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to update user status');
    },
  });

  const updateApprovalMutation = useMutation({
    mutationFn: ({ userId, approvalStatus }) => updateSellerApproval(userId, approvalStatus),
    onSuccess: () => {
      toast.success('Seller approval status updated successfully');
      queryClient.invalidateQueries(['users']);
      handleMenuClose();
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to update seller approval status');
    },
  });

  const handleMenuOpen = (event, user) => {
    setAnchorEl(event.currentTarget);
    setSelectedUser(user);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedUser(null);
  };

  const handleView = () => {
    navigate(`/users/details/${selectedUser.id}`);
    handleMenuClose();
  };

  const handleToggleStatus = () => {
    if (selectedUser) {
      updateStatusMutation.mutate({
        userId: selectedUser.id,
        isActive: !selectedUser.isActive,
      });
    }
  };

  const handleApprovalStatus = (status) => {
    if (selectedUser) {
      updateApprovalMutation.mutate({
        userId: selectedUser.id,
        approvalStatus: status,
      });
    }
  };

  const columns = [
    {
      field: 'avatar',
      headerName: '',
      width: 60,
      renderCell: (params) => (
        <Avatar
          src={params.row.profileImageUrl}
          sx={{ width: 32, height: 32 }}
        >
          {params.row.name?.charAt(0) || <Person />}
        </Avatar>
      ),
    },
    {
      field: 'name',
      headerName: 'Name',
      flex: 1,
      minWidth: 150,
      renderCell: (params) => (
        <Box>
          <Box sx={{ fontWeight: 600 }}>{params.value || 'N/A'}</Box>
          <Box sx={{ fontSize: '0.75rem', color: 'text.secondary' }}>
            {params.row.email}
          </Box>
        </Box>
      ),
    },
    {
      field: 'phone',
      headerName: 'Phone',
      width: 130,
      renderCell: (params) => params.value || 'N/A',
    },
    {
      field: 'location',
      headerName: 'Location',
      width: 150,
      renderCell: (params) => params.row.city || 'N/A',
    },
    {
      field: 'ordersCount',
      headerName: userType === 'customer' ? 'Orders' : 'Products',
      width: 100,
      align: 'center',
      renderCell: (params) => (
        <Chip
          label={params.value || 0}
          size="small"
          color="primary"
          variant="outlined"
        />
      ),
    },
    {
      field: 'totalSpent',
      headerName: userType === 'customer' ? 'Total Spent' : 'Revenue',
      width: 130,
      renderCell: (params) => (
        <Box sx={{ fontWeight: 600 }}>
          TZS {(params.value || 0).toLocaleString()}
        </Box>
      ),
    },
    {
      field: 'isActive',
      headerName: 'Status',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value ? 'Active' : 'Inactive'}
          size="small"
          color={params.value ? 'success' : 'default'}
          variant={params.value ? 'filled' : 'outlined'}
        />
      ),
    },
    {
      field: 'createdAt',
      headerName: 'Joined',
      width: 120,
      renderCell: (params) => (
        params.value ? format(new Date(params.value), 'MMM dd, yyyy') : '-'
      ),
    },
    {
      field: 'actions',
      headerName: 'Actions',
      width: 80,
      sortable: false,
      renderCell: (params) => (
        <IconButton
          size="small"
          onClick={(e) => handleMenuOpen(e, params.row)}
        >
          <MoreVert />
        </IconButton>
      ),
    },
  ];

  return (
    <Box>
      {/* Filters */}
      <Card sx={{ p: 3, mb: 3 }}>
        <Box sx={{ display: 'flex', gap: 2, flexWrap: 'wrap' }}>
          <TextField
            placeholder={`Search ${userType}s...`}
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            InputProps={{
              startAdornment: (
                <InputAdornment position="start">
                  <Search />
                </InputAdornment>
              ),
            }}
            sx={{ minWidth: 300 }}
          />
          
          <FormControl sx={{ minWidth: 150 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              label="Status"
            >
              <MenuItem value="">All Status</MenuItem>
              <MenuItem value="active">Active</MenuItem>
              <MenuItem value="inactive">Inactive</MenuItem>
            </Select>
          </FormControl>
          
          {userType === 'seller' && (
            <FormControl sx={{ minWidth: 150 }}>
              <InputLabel>Approval</InputLabel>
              <Select
                value={approvalFilter}
                onChange={(e) => setApprovalFilter(e.target.value)}
                label="Approval"
              >
                <MenuItem value="">All Approvals</MenuItem>
                <MenuItem value="pending">Pending</MenuItem>
                <MenuItem value="approved">Approved</MenuItem>
                <MenuItem value="rejected">Rejected</MenuItem>
              </Select>
            </FormControl>
          )}
        </Box>
      </Card>

      {/* Data Grid */}
      <Card>
        <DataGrid
          rows={users}
          columns={columns}
          loading={isLoading}
          disableRowSelectionOnClick
          pageSizeOptions={[10, 25, 50]}
          initialState={{
            pagination: {
              paginationModel: { pageSize: 10 },
            },
          }}
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
      </Card>

      {/* Action Menu */}
      <Menu
        anchorEl={anchorEl}
        open={Boolean(anchorEl)}
        onClose={handleMenuClose}
      >
        <MenuItemComponent onClick={handleView}>
          <ListItemIcon>
            <Visibility fontSize="small" />
          </ListItemIcon>
          <ListItemText>View Details</ListItemText>
        </MenuItemComponent>
        
        <MenuItemComponent onClick={handleToggleStatus}>
          <ListItemIcon>
            {selectedUser?.isActive ? (
              <Block fontSize="small" />
            ) : (
              <CheckCircle fontSize="small" />
            )}
          </ListItemIcon>
          <ListItemText>
            {selectedUser?.isActive ? 'Deactivate' : 'Activate'}
          </ListItemText>
        </MenuItemComponent>
        {userType === 'seller' && (
          <MenuItemComponent onClick={() => handleApprovalStatus('approved')}>
            <ListItemIcon>
              <CheckCircle fontSize="small" color="success" />
            </ListItemIcon>
            <ListItemText>Approve Seller</ListItemText>
          </MenuItemComponent>
        )}
        {userType === 'seller' && (
          <MenuItemComponent onClick={() => handleApprovalStatus('rejected')}>
            <ListItemIcon>
              <Block fontSize="small" color="error" />
            </ListItemIcon>
            <ListItemText>Reject Seller</ListItemText>
          </MenuItemComponent>
        )}
      </Menu>
    </Box>
  );
};

export default UserList;
