import React, { useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Chip,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogActions,
  TextField,
} from '@mui/material';
import {
  Delete,
  Edit,
  Visibility,
  VisibilityOff,
  LocalOffer,
  Close,
  CheckCircle,
  Cancel,
} from '@mui/icons-material';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { bulkUpdateProducts, bulkDeleteProducts, updateProductStatus } from '../../../services/productService';
import toast from 'react-hot-toast';

const BulkActions = ({ selectedProducts, onClearSelection }) => {
  const [action, setAction] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [bulkPrice, setBulkPrice] = useState('');
  const [bulkDiscount, setBulkDiscount] = useState('');
  const [approveDialogOpen, setApproveDialogOpen] = useState(false);
  const [rejectDialogOpen, setRejectDialogOpen] = useState(false);
  const queryClient = useQueryClient();

  const bulkUpdateMutation = useMutation({
    mutationFn: bulkUpdateProducts,
    onSuccess: () => {
      toast.success('Products updated successfully');
      queryClient.invalidateQueries(['products']);
      onClearSelection();
      setDialogOpen(false);
      setAction('');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to update products');
    },
  });

  const bulkDeleteMutation = useMutation({
    mutationFn: bulkDeleteProducts,
    onSuccess: () => {
      toast.success('Products deleted successfully');
      queryClient.invalidateQueries(['products']);
      onClearSelection();
      setDialogOpen(false);
      setAction('');
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to delete products');
    },
  });

  const handleAction = () => {
    switch (action) {
      case 'activate':
        bulkUpdateMutation.mutate({
          productIds: selectedProducts,
          updates: { isActive: true },
        });
        break;
      case 'deactivate':
        bulkUpdateMutation.mutate({
          productIds: selectedProducts,
          updates: { isActive: false },
        });
        break;
      case 'delete':
        setDialogOpen(true);
        break;
      case 'price':
        setDialogOpen(true);
        break;
      case 'discount':
        setDialogOpen(true);
        break;
      case 'approve':
        setApproveDialogOpen(true);
        break;
      case 'reject':
        setRejectDialogOpen(true);
        break;
      default:
        break;
    }
  };

  const handleConfirmAction = () => {
    switch (action) {
      case 'delete':
        bulkDeleteMutation.mutate(selectedProducts);
        break;
      case 'price':
        if (bulkPrice) {
          bulkUpdateMutation.mutate({
            productIds: selectedProducts,
            updates: { price: parseFloat(bulkPrice) },
          });
        }
        break;
      case 'discount':
        if (bulkDiscount) {
          bulkUpdateMutation.mutate({
            productIds: selectedProducts,
            updates: { discount: parseFloat(bulkDiscount) },
          });
        }
        break;
      default:
        break;
    }
  };

  const handleBulkApprove = async () => {
    await Promise.all(selectedProducts.map(id => updateProductStatus(id, 'approved')));
    toast.success('Selected products approved');
    queryClient.invalidateQueries(['products']);
    onClearSelection();
    setApproveDialogOpen(false);
    setAction('');
  };

  const handleBulkReject = async () => {
    await Promise.all(selectedProducts.map(id => updateProductStatus(id, 'rejected')));
    toast.success('Selected products rejected');
    queryClient.invalidateQueries(['products']);
    onClearSelection();
    setRejectDialogOpen(false);
    setAction('');
  };

  const getDialogContent = () => {
    switch (action) {
      case 'delete':
        return {
          title: 'Delete Products',
          content: `Are you sure you want to delete ${selectedProducts.length} selected products? This action cannot be undone.`,
          confirmText: 'Delete',
          confirmColor: 'error',
        };
      case 'price':
        return {
          title: 'Update Price',
          content: (
            <TextField
              fullWidth
              label="New Price (TZS)"
              type="number"
              value={bulkPrice}
              onChange={(e) => setBulkPrice(e.target.value)}
              sx={{ mt: 2 }}
            />
          ),
          confirmText: 'Update',
          confirmColor: 'primary',
        };
      case 'discount':
        return {
          title: 'Apply Discount',
          content: (
            <TextField
              fullWidth
              label="Discount Percentage"
              type="number"
              value={bulkDiscount}
              onChange={(e) => setBulkDiscount(e.target.value)}
              sx={{ mt: 2 }}
              inputProps={{ min: 0, max: 100 }}
            />
          ),
          confirmText: 'Apply',
          confirmColor: 'primary',
        };
      default:
        return {};
    }
  };

  const dialogContent = getDialogContent();

  return (
    <>
      <Card sx={{ mb: 3, backgroundColor: '#e3f2fd' }}>
        <CardContent>
          <Box sx={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <Typography variant="h6">
                Bulk Actions
              </Typography>
              <Chip
                label={`${selectedProducts.length} selected`}
                color="primary"
                size="small"
              />
            </Box>
            
            <Box sx={{ display: 'flex', alignItems: 'center', gap: 2 }}>
              <FormControl size="small" sx={{ minWidth: 150 }}>
                <InputLabel>Choose Action</InputLabel>
                <Select
                  value={action}
                  onChange={(e) => setAction(e.target.value)}
                  label="Choose Action"
                >
                  <MenuItem value="activate">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Visibility fontSize="small" />
                      Activate
                    </Box>
                  </MenuItem>
                  <MenuItem value="deactivate">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <VisibilityOff fontSize="small" />
                      Deactivate
                    </Box>
                  </MenuItem>
                  <MenuItem value="price">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <LocalOffer fontSize="small" />
                      Update Price
                    </Box>
                  </MenuItem>
                  <MenuItem value="discount">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <LocalOffer fontSize="small" />
                      Apply Discount
                    </Box>
                  </MenuItem>
                  <MenuItem value="delete">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Delete fontSize="small" />
                      Delete
                    </Box>
                  </MenuItem>
                  <MenuItem value="approve">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <CheckCircle fontSize="small" />
                      Approve
                    </Box>
                  </MenuItem>
                  <MenuItem value="reject">
                    <Box sx={{ display: 'flex', alignItems: 'center', gap: 1 }}>
                      <Cancel fontSize="small" />
                      Reject
                    </Box>
                  </MenuItem>
                </Select>
              </FormControl>
              
              <Button
                variant="contained"
                onClick={handleAction}
                disabled={!action || bulkUpdateMutation.isPending || bulkDeleteMutation.isPending}
              >
                Apply
              </Button>
              
              <Button
                variant="outlined"
                onClick={onClearSelection}
                startIcon={<Close />}
              >
                Clear
              </Button>
            </Box>
          </Box>
        </CardContent>
      </Card>

      {/* Confirmation Dialog */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>{dialogContent.title}</DialogTitle>
        <DialogContent>
          {typeof dialogContent.content === 'string' ? (
            <Typography>{dialogContent.content}</Typography>
          ) : (
            dialogContent.content
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>
            Cancel
          </Button>
          <Button
            onClick={handleConfirmAction}
            color={dialogContent.confirmColor}
            variant="contained"
            disabled={bulkUpdateMutation.isPending || bulkDeleteMutation.isPending}
          >
            {bulkUpdateMutation.isPending || bulkDeleteMutation.isPending
              ? 'Processing...'
              : dialogContent.confirmText
            }
          </Button>
        </DialogActions>
      </Dialog>

      {/* Approve Confirmation Dialog */}
      <Dialog open={approveDialogOpen} onClose={() => setApproveDialogOpen(false)}>
        <DialogTitle>Approve Products</DialogTitle>
        <DialogContent>Are you sure you want to approve {selectedProducts.length} selected products?</DialogContent>
        <DialogActions>
          <Button onClick={() => setApproveDialogOpen(false)}>Cancel</Button>
          <Button color="success" variant="contained" onClick={handleBulkApprove}>Approve</Button>
        </DialogActions>
      </Dialog>

      {/* Reject Confirmation Dialog */}
      <Dialog open={rejectDialogOpen} onClose={() => setRejectDialogOpen(false)}>
        <DialogTitle>Reject Products</DialogTitle>
        <DialogContent>Are you sure you want to reject {selectedProducts.length} selected products?</DialogContent>
        <DialogActions>
          <Button onClick={() => setRejectDialogOpen(false)}>Cancel</Button>
          <Button color="error" variant="contained" onClick={handleBulkReject}>Reject</Button>
        </DialogActions>
      </Dialog>
    </>
  );
};

export default BulkActions;
