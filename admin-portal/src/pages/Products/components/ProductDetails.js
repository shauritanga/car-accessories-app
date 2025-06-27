import React from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  Chip,
  Divider,
  Avatar,
  List,
  ListItem,
  ListItemText,
  IconButton,
  ImageList,
  ImageListItem,
} from '@mui/material';
import {
  Edit,
  ArrowBack,
  Inventory,
  AttachMoney,
  Category,
  Star,
} from '@mui/icons-material';
import { useQuery } from '@tanstack/react-query';
import { getProduct } from '../../../services/productService';
import { format } from 'date-fns';
import LoadingScreen from '../../../components/LoadingScreen/LoadingScreen';

const ProductDetails = () => {
  const { id } = useParams();
  const navigate = useNavigate();

  const { data: product, isLoading, error } = useQuery({
    queryKey: ['product', id],
    queryFn: () => getProduct(id),
  });

  if (isLoading) return <LoadingScreen />;
  if (error) return <Typography>Error loading product</Typography>;
  if (!product) return <Typography>Product not found</Typography>;

  return (
    <Box>
      {/* Header */}
      <Box sx={{ display: 'flex', alignItems: 'center', mb: 3 }}>
        <IconButton onClick={() => navigate('/products')} sx={{ mr: 2 }}>
          <ArrowBack />
        </IconButton>
        <Box sx={{ flex: 1 }}>
          <Typography variant="h4" fontWeight="bold">
            {product.name}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Product Details
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Edit />}
          onClick={() => navigate(`/products/edit/${id}`)}
        >
          Edit Product
        </Button>
      </Box>

      <Grid container spacing={3}>
        {/* Main Content */}
        <Grid item xs={12} md={8}>
          {/* Basic Information */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Basic Information
              </Typography>
              <Grid container spacing={2}>
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2" color="text.secondary">
                    Product Name
                  </Typography>
                  <Typography variant="body1" fontWeight="600">
                    {product.name}
                  </Typography>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2" color="text.secondary">
                    SKU
                  </Typography>
                  <Typography variant="body1" fontWeight="600">
                    {product.sku}
                  </Typography>
                </Grid>
                <Grid item xs={12}>
                  <Typography variant="body2" color="text.secondary">
                    Description
                  </Typography>
                  <Typography variant="body1">
                    {product.description}
                  </Typography>
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2" color="text.secondary">
                    Category
                  </Typography>
                  <Chip
                    label={product.category}
                    color="primary"
                    variant="outlined"
                    sx={{ mt: 0.5 }}
                  />
                </Grid>
                <Grid item xs={12} sm={6}>
                  <Typography variant="body2" color="text.secondary">
                    Brand
                  </Typography>
                  <Typography variant="body1" fontWeight="600">
                    {product.brand || 'N/A'}
                  </Typography>
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Pricing & Inventory */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Pricing & Inventory
              </Typography>
              <Grid container spacing={3}>
                <Grid item xs={12} sm={4}>
                  <Box sx={{ textAlign: 'center', p: 2, backgroundColor: '#f5f5f5', borderRadius: 2 }}>
                    <AttachMoney sx={{ fontSize: 40, color: 'primary.main', mb: 1 }} />
                    <Typography variant="h5" fontWeight="bold" color="primary.main">
                      TZS {product.price?.toLocaleString()}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Current Price
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={4}>
                  <Box sx={{ textAlign: 'center', p: 2, backgroundColor: '#f5f5f5', borderRadius: 2 }}>
                    <Inventory sx={{ fontSize: 40, color: 'warning.main', mb: 1 }} />
                    <Typography variant="h5" fontWeight="bold" color="warning.main">
                      {product.stock}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      In Stock
                    </Typography>
                  </Box>
                </Grid>
                <Grid item xs={12} sm={4}>
                  <Box sx={{ textAlign: 'center', p: 2, backgroundColor: '#f5f5f5', borderRadius: 2 }}>
                    <Star sx={{ fontSize: 40, color: 'success.main', mb: 1 }} />
                    <Typography variant="h5" fontWeight="bold" color="success.main">
                      {product.averageRating?.toFixed(1) || 'N/A'}
                    </Typography>
                    <Typography variant="body2" color="text.secondary">
                      Rating
                    </Typography>
                  </Box>
                </Grid>
              </Grid>
            </CardContent>
          </Card>

          {/* Product Images */}
          {product.images && product.images.length > 0 && (
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Product Images
                </Typography>
                <ImageList cols={3} rowHeight={200}>
                  {product.images.map((image, index) => (
                    <ImageListItem key={index}>
                      <img
                        src={image}
                        alt={`${product.name} ${index + 1}`}
                        loading="lazy"
                        style={{ borderRadius: 8 }}
                      />
                    </ImageListItem>
                  ))}
                </ImageList>
              </CardContent>
            </Card>
          )}

          {/* Specifications */}
          {product.specifications && Object.keys(product.specifications).length > 0 && (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Specifications
                </Typography>
                <List>
                  {Object.entries(product.specifications).map(([key, value], index) => (
                    <ListItem key={index} divider>
                      <ListItemText
                        primary={key}
                        secondary={value}
                        primaryTypographyProps={{ fontWeight: 600 }}
                      />
                    </ListItem>
                  ))}
                </List>
              </CardContent>
            </Card>
          )}
        </Grid>

        {/* Sidebar */}
        <Grid item xs={12} md={4}>
          {/* Status */}
          <Card sx={{ mb: 3 }}>
            <CardContent>
              <Typography variant="h6" gutterBottom>
                Product Status
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Status:</Typography>
                  <Chip
                    label={product.isActive ? 'Active' : 'Inactive'}
                    color={product.isActive ? 'success' : 'default'}
                    size="small"
                  />
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Created:</Typography>
                  <Typography variant="body2">
                    {product.createdAt ? format(new Date(product.createdAt), 'MMM dd, yyyy') : 'N/A'}
                  </Typography>
                </Box>
                <Box sx={{ display: 'flex', justifyContent: 'space-between' }}>
                  <Typography variant="body2">Updated:</Typography>
                  <Typography variant="body2">
                    {product.updatedAt ? format(new Date(product.updatedAt), 'MMM dd, yyyy') : 'N/A'}
                  </Typography>
                </Box>
              </Box>
            </CardContent>
          </Card>

          {/* Compatibility */}
          {product.compatibility && product.compatibility.length > 0 && (
            <Card sx={{ mb: 3 }}>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Car Compatibility
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {product.compatibility.map((model, index) => (
                    <Chip
                      key={index}
                      label={model}
                      variant="outlined"
                      size="small"
                    />
                  ))}
                </Box>
              </CardContent>
            </Card>
          )}

          {/* Tags */}
          {product.tags && product.tags.length > 0 && (
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Tags
                </Typography>
                <Box sx={{ display: 'flex', flexWrap: 'wrap', gap: 1 }}>
                  {product.tags.map((tag, index) => (
                    <Chip
                      key={index}
                      label={tag}
                      color="secondary"
                      variant="outlined"
                      size="small"
                    />
                  ))}
                </Box>
              </CardContent>
            </Card>
          )}
        </Grid>
      </Grid>
    </Box>
  );
};

export default ProductDetails;
