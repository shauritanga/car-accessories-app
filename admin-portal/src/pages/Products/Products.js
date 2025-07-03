import React, { useState } from 'react';
import { Routes, Route, useNavigate, useLocation } from 'react-router-dom';
import {
  Box,
  Typography,
  Button,
  Tabs,
  Tab,
  Card,
} from '@mui/material';
import { Add, Upload, Download } from '@mui/icons-material';
import ProductList from './components/ProductList';
import ProductForm from './components/ProductForm';
import ProductDetails from './components/ProductDetails';
import BulkActions from './components/BulkActions';
import { motion } from 'framer-motion';

const Products = () => {
  const navigate = useNavigate();
  const location = useLocation();
  const [selectedProducts, setSelectedProducts] = useState([]);

  // Only one tab: All Products
  const currentTab = 0;
  const handleTabChange = () => {};

  return (
    <Box>
      {/* Header */}
      <Box sx={{ mb: 4 }}>
        <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 2 }}>
          <Box>
            <Typography variant="h4" fontWeight="bold" gutterBottom>
              Product Management
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Review and manage products submitted by sellers. Only approved products are visible in the mobile app.
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<Upload />}
              onClick={() => {/* Handle bulk import */}}
              disabled
            >
              Import
            </Button>
            <Button
              variant="outlined"
              startIcon={<Download />}
              onClick={() => {/* Handle export */}}
            >
              Export
            </Button>
          </Box>
        </Box>
        {/* Only one tab: All Products */}
        <Card>
          <Tabs
            value={currentTab}
            onChange={handleTabChange}
            sx={{ borderBottom: 1, borderColor: 'divider' }}
          >
            <Tab label="All Products" />
          </Tabs>
        </Card>
      </Box>
      {/* Bulk Actions */}
      {selectedProducts.length > 0 && (
        <motion.div
          initial={{ opacity: 0, y: -20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: 0.3 }}
        >
          <BulkActions
            selectedProducts={selectedProducts}
            onClearSelection={() => setSelectedProducts([])}
          />
        </motion.div>
      )}
      {/* Nested Routes for Product List and Details */}
      <Routes>
        <Route path="/" element={
          <ProductList
            selectedProducts={selectedProducts}
            onSelectionChange={setSelectedProducts}
            adminMode
          />
        } />
        <Route path="details/:id" element={<ProductDetails />} />
      </Routes>
    </Box>
  );
};

export default Products;
