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
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  Button,
  TableContainer,
  Table,
  TableHead,
  TableBody,
  TableRow,
  TableCell,
  Paper,
} from '@mui/material';
import {
  Search,
  FilterList,
  Edit,
  Delete,
  Visibility,
  MoreVert,
  CheckCircle,
  Cancel,
} from '@mui/icons-material';
import { DataGrid } from '@mui/x-data-grid';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getProducts, deleteProduct, updateProductStatus } from '../../../services/productService';
import { format } from 'date-fns';
import Snackbar from '@mui/material/Snackbar';

const ProductList = ({ selectedProducts, onSelectionChange, adminMode }) => {
  const navigate = useNavigate();
  const [searchTerm, setSearchTerm] = useState('');
  const [categoryFilter, setCategoryFilter] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [anchorEl, setAnchorEl] = useState(null);
  const [selectedProduct, setSelectedProduct] = useState(null);
  const [snackbar, setSnackbar] = useState({ open: false, message: '', severity: 'success' });
  const [deleteDialogOpen, setDeleteDialogOpen] = useState(false);
  const [productToDelete, setProductToDelete] = useState(null);
  const [approveDialogOpen, setApproveDialogOpen] = useState(false);
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false);
  const [productToApprove, setProductToApprove] = useState(null);
  const [productToReject, setProductToReject] = useState(null);
  const queryClient = useQueryClient();

  const { data: products = [], isLoading } = useQuery({
    queryKey: ['products', searchTerm, categoryFilter, statusFilter],
    queryFn: () => getProducts({ search: searchTerm, category: categoryFilter, status: statusFilter }),
  });

  const statusMutation = useMutation({
    mutationFn: ({ productId, status }) => updateProductStatus(productId, status),
    onSuccess: () => {
      setSnackbar({ open: true, message: 'Product status updated', severity: 'success' });
      queryClient.invalidateQueries(['products']);
    },
    onError: (error) => {
      setSnackbar({ open: true, message: error.message || 'Failed to update status', severity: 'error' });
    },
  });

  const handleMenuOpen = (event, product) => {
    setAnchorEl(event.currentTarget);
    setSelectedProduct(product);
  };

  const handleMenuClose = () => {
    setAnchorEl(null);
    setSelectedProduct(null);
  };

  const handleView = (id) => {
    navigate(`/products/details/${id}`);
    handleMenuClose();
  };

  const handleDelete = (id) => {
    setDeleteDialogOpen(true);
    setProductToDelete(id);
    handleMenuClose();
  };

  const confirmDelete = async () => {
    try {
      await deleteProduct(productToDelete);
      setSnackbar({ open: true, message: 'Product deleted successfully', severity: 'success' });
      setDeleteDialogOpen(false);
      setProductToDelete(null);
      // Optionally refresh the product list (if not using React Query's refetch)
      // refetch();
    } catch (error) {
      setSnackbar({ open: true, message: error.message || 'Failed to delete product', severity: 'error' });
    }
  };

  const handleApprove = (id) => {
    setProductToApprove(id);
    setApproveDialogOpen(true);
  };

  const handleReject = (id) => {
    setProductToReject(id);
    setRejectDialogOpen(true);
  };

  const confirmApprove = () => {
    statusMutation.mutate({ productId: productToApprove, status: 'approved' }, {
      onSuccess: () => setSnackbar({ open: true, message: 'Product approved', severity: 'success' })
    });
    setApproveDialogOpen(false);
    setProductToApprove(null);
  };

  const confirmReject = () => {
    statusMutation.mutate({ productId: productToReject, status: 'rejected' }, {
      onSuccess: () => setSnackbar({ open: true, message: 'Product rejected', severity: 'info' })
    });
    setRejectDialogOpen(false);
    setProductToReject(null);
  };

  const columns = [
    {
      field: 'image',
      headerName: 'Image',
      width: 80,
      renderCell: (params) => (
        <Box
          component="img"
          src={params.value || '/placeholder-product.jpg'}
          alt={params.row.name}
          sx={{
            width: 40,
            height: 40,
            borderRadius: 1,
            objectFit: 'cover',
          }}
        />
      ),
    },
    {
      field: 'name',
      headerName: 'Product Name',
      flex: 1,
      minWidth: 200,
    },
    {
      field: 'category',
      headerName: 'Category',
      width: 150,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          variant="outlined"
          color="primary"
        />
      ),
    },
    {
      field: 'price',
      headerName: 'Price',
      width: 120,
      renderCell: (params) => (
        <Box sx={{ fontWeight: 600 }}>
          TZS {params.value?.toLocaleString()}
        </Box>
      ),
    },
    {
      field: 'stock',
      headerName: 'Stock',
      width: 100,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          color={params.value > 10 ? 'success' : params.value > 0 ? 'warning' : 'error'}
        />
      ),
    },
    {
      field: 'status',
      headerName: 'Status',
      width: 120,
      renderCell: (params) => (
        <Chip
          label={params.value}
          size="small"
          color={params.value === 'active' ? 'success' : 'default'}
          variant={params.value === 'active' ? 'filled' : 'outlined'}
        />
      ),
    },
    {
      field: 'createdAt',
      headerName: 'Created',
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
            placeholder="Search products..."
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
            <InputLabel>Category</InputLabel>
            <Select
              value={categoryFilter}
              onChange={(e) => setCategoryFilter(e.target.value)}
              label="Category"
            >
              <MenuItem value="">All Categories</MenuItem>
              <MenuItem value="interior">Interior</MenuItem>
              <MenuItem value="exterior">Exterior</MenuItem>
              <MenuItem value="electronics">Electronics</MenuItem>
              <MenuItem value="performance">Performance</MenuItem>
              <MenuItem value="maintenance">Maintenance</MenuItem>
            </Select>
          </FormControl>

          <FormControl sx={{ minWidth: 120 }}>
            <InputLabel>Status</InputLabel>
            <Select
              value={statusFilter}
              onChange={(e) => setStatusFilter(e.target.value)}
              label="Status"
            >
              <MenuItem value="">All Status</MenuItem>
              <MenuItem value="pending">Pending</MenuItem>
              <MenuItem value="approved">Approved</MenuItem>
              <MenuItem value="rejected">Rejected</MenuItem>
              <MenuItem value="inactive">Inactive</MenuItem>
            </Select>
          </FormControl>
        </Box>
      </Card>

      {/* Data Grid */}
      <Card>
        <DataGrid
          rows={products}
          columns={columns}
          loading={isLoading}
          checkboxSelection
          disableRowSelectionOnClick
          onRowSelectionModelChange={(newSelection) => {
            onSelectionChange(newSelection);
          }}
          rowSelectionModel={selectedProducts}
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
        <MenuItemComponent onClick={() => handleView(selectedProduct.id)}>
          <ListItemIcon>
            <Visibility fontSize="small" />
          </ListItemIcon>
          <ListItemText>View Details</ListItemText>
        </MenuItemComponent>
        {selectedProduct && selectedProduct.status === 'pending' && (
          <>
            <MenuItemComponent onClick={() => handleApprove(selectedProduct.id)}>
              <ListItemIcon>
                <CheckCircle fontSize="small" />
              </ListItemIcon>
              <ListItemText>Approve</ListItemText>
            </MenuItemComponent>
            <MenuItemComponent onClick={() => handleReject(selectedProduct.id)}>
              <ListItemIcon>
                <Cancel fontSize="small" />
              </ListItemIcon>
              <ListItemText>Reject</ListItemText>
            </MenuItemComponent>
          </>
        )}
        <MenuItemComponent onClick={() => handleDelete(selectedProduct.id)}>
          <ListItemIcon>
            <Delete fontSize="small" color="error" />
          </ListItemIcon>
          <ListItemText>Delete</ListItemText>
        </MenuItemComponent>
      </Menu>

      {/* Delete Confirmation Dialog */}
      <Dialog open={deleteDialogOpen} onClose={() => setDeleteDialogOpen(false)}>
        <DialogTitle>Delete Product</DialogTitle>
        <DialogContent>Are you sure you want to delete this product?</DialogContent>
        <DialogActions>
          <Button onClick={() => setDeleteDialogOpen(false)}>Cancel</Button>
          <Button color="error" variant="contained" onClick={confirmDelete}>Delete</Button>
        </DialogActions>
      </Dialog>

      {/* Approve Confirmation Dialog */}
      <Dialog open={approveDialogOpen} onClose={() => setApproveDialogOpen(false)}>
        <DialogTitle>Approve Product</DialogTitle>
        <DialogContent>Are you sure you want to approve this product?</DialogContent>
        <DialogActions>
          <Button onClick={() => setApproveDialogOpen(false)}>Cancel</Button>
          <Button color="success" variant="contained" onClick={confirmApprove}>Approve</Button>
        </DialogActions>
      </Dialog>

      {/* Reject Confirmation Dialog */}
      <Dialog open={rejectDialogOpen} onClose={() => setRejectDialogOpen(false)}>
        <DialogTitle>Reject Product</DialogTitle>
        <DialogContent>Are you sure you want to reject this product?</DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectDialogOpen(false)}>Cancel</Button>
          <Button color="error" variant="contained" onClick={confirmReject}>Reject</Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar for feedback */}
      <Snackbar
        open={snackbar.open}
        autoHideDuration={3000}
        onClose={() => setSnackbar({ ...snackbar, open: false })}
        message={snackbar.message}
      />
    </Box>
  );
};

export default ProductList;
