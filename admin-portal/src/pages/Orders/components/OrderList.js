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
  Button,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
} from '@mui/material';
import {
  Search,
  Visibility,
  Edit,
  LocalShipping,
  CheckCircle,
  Cancel,
  MoreVert,
} from '@mui/icons-material';
import { DataGrid } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getOrders, updateOrderStatus } from '../../../services/orderService';
import { format } from 'date-fns';
import toast from 'react-hot-toast';

const statusColors = {
  pending: 'warning',
  processing: 'info',
  shipped: 'primary',
  delivered: 'success',
  cancelled: 'error',
};

const OrderList = ({ refreshTrigger }) => {
  const navigate = useNavigate();
  const queryClient = useQueryClient();
  const [searchTerm, setSearchTerm] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [anchorEl, setAnchorEl] = useState(null);
  const [selectedOrder, setSelectedOrder] = useState(null);
  const [statusDialog, setStatusDialog] = useState(false);
  const [newStatus, setNewStatus] = useState('');

  const { data: orders = [], isLoading } = useQuery({
    queryKey: ['orders', searchTerm, statusFilter, refreshTrigger],
    queryFn: () => getOrders({ search: searchTerm, status: statusFilter }),
  });

  const updateStatusMutation = useMutation({
    mutationFn: ({ orderId, status }) => updateOrderStatus(orderId, status),
    onSuccess: () => {
      toast.success('Order status updated successfully');
      queryClient.invalidateQueries(['orders']);
      setStatusDialog(false);
      setSelectedOrder(null);
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to update order status');
    },
  });

  const handleMenuOpen = (event, order) => {
    setAnchorEl(event.currentTarget);
    setSelectedOrder(order);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedOrder(null);
  };

  const handleView = () => {
    navigate(`/orders/details/${selectedOrder.id}`);
    handleMenuClose();
  };

  const handleStatusChange = (status) => {
    setNewStatus(status);
    setStatusDialog(true);
    handleMenuClose();
  };

  const confirmStatusChange = () => {
    if (selectedOrder && newStatus) {
      updateStatusMutation.mutate({
        orderId: selectedOrder.id,
        status: newStatus,
      });
    }
  };

  const columns = [
    {
      field: 'orderNumber',
      headerName: 'Order #',
      width: 120,
      renderCell: (params) => (
        <Box sx={{ fontWeight: 600, color: 'primary.main' }}>
          #{params.value}
        </Box>
      ),
    },
    {
      field: 'customerName',
      headerName: 'Customer',
      flex: 1,
      minWidth: 150,
    },
    {
      field: 'customerEmail',
      headerName: 'Email',
      flex: 1,
      minWidth: 200,
    },
    {
      field: 'total',
      headerName: 'Total',
      width: 120,
      renderCell: (params) => (
        <Box sx={{ fontWeight: 600 }}>
          TZS {params.value?.toLocaleString()}
        </Box>
      ),
    },
    {
      field: 'itemsCount',
      headerName: 'Items',
      width: 80,
      align: 'center',
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          color={statusColors[params.value] || 'default'}
          sx={{ textTransform: 'capitalize' }}
        />
      ),
    },
    {
      field: 'paymentStatus',
      headerName: 'Payment',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          color={params.value === 'paid' ? 'success' : 'warning'}
          variant="outlined"
          sx={{ textTransform: 'capitalize' }}
        />
      ),
    },
    {
      field: 'createdAt',
      headerName: 'Date',
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
            placeholder="Search orders..."
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
              <MenuItem value="pending">Pending</MenuItem>
              <MenuItem value="processing">Processing</MenuItem>
              <MenuItem value="shipped">Shipped</MenuItem>
              <MenuItem value="delivered">Delivered</MenuItem>
              <MenuItem value="cancelled">Cancelled</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </Card>

      {/* Data Grid */}
      <Card>
        <DataGrid
          rows={orders}
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
        
        {selectedOrder?.status === 'pending' && (
          <MenuItemComponent onClick={() => handleStatusChange('processing')}>
            <ListItemIcon>
              <Edit fontSize="small" />
            </ListItemIcon>
            <ListItemText>Mark Processing</ListItemText>
          </MenuItemComponent>
        )}
        
        {selectedOrder?.status === 'processing' && (
          <MenuItemComponent onClick={() => handleStatusChange('shipped')}>
            <ListItemIcon>
              <LocalShipping fontSize="small" />
            </ListItemIcon>
            <ListItemText>Mark Shipped</ListItemText>
          </MenuItemComponent>
        )}
        
        {selectedOrder?.status === 'shipped' && (
          <MenuItemComponent onClick={() => handleStatusChange('delivered')}>
            <ListItemIcon>
              <CheckCircle fontSize="small" />
            </ListItemIcon>
            <ListItemText>Mark Delivered</ListItemText>
          </MenuItemComponent>
        )}
        
        {['pending', 'processing'].includes(selectedOrder?.status) && (
          <MenuItemComponent onClick={() => handleStatusChange('cancelled')}>
            <ListItemIcon>
              <Cancel fontSize="small" />
            </ListItemIcon>
            <ListItemText>Cancel Order</ListItemText>
          </MenuItemComponent>
        )}
      </Menu>

      {/* Status Change Dialog */}
      <Dialog open={statusDialog} onClose={() => setStatusDialog(false)}>
        <DialogTitle>Update Order Status</DialogTitle>
        <DialogContent>
          Are you sure you want to change the order status to "{newStatus}"?
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setStatusDialog(false)}>Cancel</Button>
          <Button
            onClick={confirmStatusChange}
            variant="contained"
            disabled={updateStatusMutation.isPending}
          >
            {updateStatusMutation.isPending ? 'Updating...' : 'Confirm'}
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default OrderList;
