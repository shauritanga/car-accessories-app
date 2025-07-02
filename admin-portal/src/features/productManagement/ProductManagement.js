// Product Management main component
import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPendingProducts, updateProductStatus, getProductCategories } from './productManagementService';
import { Box, Typography, Button, Table, TableHead, TableRow, TableCell, TableBody, Chip, CircularProgress, Stack, Select, MenuItem } from '@mui/material';

// TODO: Implement product management UI and logic for:
// - Review/approve products listed by sellers
// - Remove inappropriate/low-quality listings
// - Monitor product categories and descriptions
// Use productManagementService.js for API calls

const ProductManagement = () => {
  const queryClient = useQueryClient();
  // Fetch pending products
  const { data: pendingProducts = [], isLoading: loadingProducts } = useQuery({
    queryKey: ['pendingProducts'],
    queryFn: getPendingProducts,
  });
  // Fetch product categories
  const { data: categories = [] } = useQuery({
    queryKey: ['productCategories'],
    queryFn: getProductCategories,
  });
  // Mutation for updating product status
  const mutation = useMutation({
    mutationFn: ({ productId, status }) => updateProductStatus(productId, status),
    onSuccess: () => {
      queryClient.invalidateQueries(['pendingProducts']);
    },
  });

  const handleProductAction = (productId, status) => {
    mutation.mutate({ productId, status });
  };

  if (loadingProducts) return <CircularProgress />;

  return (
    <Box>
      <Typography variant="h5" fontWeight="bold" mb={2}>Pending Product Listings</Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Product</TableCell>
            <TableCell>Seller</TableCell>
            <TableCell>Category</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {pendingProducts.length === 0 && (
            <TableRow><TableCell colSpan={5}>No pending products</TableCell></TableRow>
          )}
          {pendingProducts.map((product) => (
            <TableRow key={product.id}>
              <TableCell>{product.name}</TableCell>
              <TableCell>{product.sellerName}</TableCell>
              <TableCell>{product.category}</TableCell>
              <TableCell><Chip label={product.status} color={product.status === 'pending' ? 'warning' : 'default'} /></TableCell>
              <TableCell>
                <Stack direction="row" spacing={1}>
                  <Button size="small" color="success" variant="contained" onClick={() => handleProductAction(product.id, 'approved')}>Approve</Button>
                  <Button size="small" color="error" variant="outlined" onClick={() => handleProductAction(product.id, 'rejected')}>Reject</Button>
                  <Button size="small" color="error" variant="contained" onClick={() => handleProductAction(product.id, 'removed')}>Remove</Button>
                </Stack>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <Typography variant="h5" fontWeight="bold" mt={4} mb={2}>Product Categories</Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Category</TableCell>
            <TableCell>Description</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {categories.length === 0 && (
            <TableRow><TableCell colSpan={2}>No categories found</TableCell></TableRow>
          )}
          {categories.map((cat) => (
            <TableRow key={cat.id}>
              <TableCell>{cat.name}</TableCell>
              <TableCell>{cat.description}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
};

export default ProductManagement;
