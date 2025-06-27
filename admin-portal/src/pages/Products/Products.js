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

  const currentTab = location.pathname.includes('/add') ? 1 : 
                   location.pathname.includes('/edit') ? 1 : 0;

  const handleTabChange = (event, newValue) => {
    if (newValue === 0) {
      navigate('/products');
    } else if (newValue === 1) {
      navigate('/products/add');
    }
  };

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
              Manage your car accessories inventory
            </Typography>
          </Box>
          <Box sx={{ display: 'flex', gap: 2 }}>
            <Button
              variant="outlined"
              startIcon={<Upload />}
              onClick={() => {/* Handle bulk import */}}
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
            <Button
              variant="contained"
              startIcon={<Add />}
              onClick={() => navigate('/products/add')}
            >
              Add Product
            </Button>
          </Box>
        </Box>

        {/* Tabs */}
        <Card>
          <Tabs
            value={currentTab}
            onChange={handleTabChange}
            sx={{ borderBottom: 1, borderColor: 'divider' }}
          >
            <Tab label="All Products" />
            <Tab label="Add/Edit Product" />
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

      {/* Content */}
      <Routes>
        <Route 
          path="/" 
          element={
            <ProductList
              selectedProducts={selectedProducts}
              onSelectionChange={setSelectedProducts}
            />
          } 
        />
        <Route path="/add" element={<ProductForm />} />
        <Route path="/edit/:id" element={<ProductForm />} />
        <Route path="/details/:id" element={<ProductDetails />} />
      </Routes>
    </Box>
  );
};

export default Products;
