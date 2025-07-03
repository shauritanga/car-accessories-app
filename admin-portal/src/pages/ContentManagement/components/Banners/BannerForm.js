import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  Button,
  Grid,
  Card,
  CardContent,
  FormControlLabel,
  Switch,
  CircularProgress,
} from '@mui/material';
import { Save, ArrowBack } from '@mui/icons-material';
import { useNavigate, useParams } from 'react-router-dom';
import { addBanner, updateBanner, getBannerById } from '../../../../services/contentService';

const BannerForm = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditing = Boolean(id);
  const [banner, setBanner] = useState({
    title: '',
    imageUrl: '',
    isVisible: true,
    linkTo: '',
    order: 0,
  });
  const [loading, setLoading] = useState(isEditing);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);
  const [imageUploading, setImageUploading] = useState(false);

  useEffect(() => {
    if (isEditing) {
      fetchBanner();
    }
  }, [id]);

  const fetchBanner = async () => {
    setLoading(true);
    try {
      const data = await getBannerById(id);
      setBanner(data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load banner details');
      setLoading(false);
    }
  };

  const handleChange = (field, value) => {
    setBanner(prev => ({ ...prev, [field]: value }));
  };

  const handleImageUpload = (event) => {
    // Placeholder for image upload logic
    setImageUploading(true);
    const file = event.target.files[0];
    if (file) {
      // Simulate upload delay
      setTimeout(() => {
        const mockImageUrl = URL.createObjectURL(file);
        setBanner(prev => ({ ...prev, imageUrl: mockImageUrl }));
        setImageUploading(false);
      }, 1000);
    }
  };

  const handleSubmit = async () => {
    setSaving(true);
    setError(null);
    try {
      if (isEditing) {
        await updateBanner(id, banner);
      } else {
        await addBanner(banner);
      }
      navigate('/content-management/banners');
    } catch (err) {
      setError(isEditing ? 'Failed to update banner' : 'Failed to add banner');
      setSaving(false);
    }
  };

  const handleCancel = () => {
    navigate('/content-management/banners');
  };

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}><CircularProgress /></Box>;
  if (error && !saving) return <Typography color="error" sx={{ py: 4 }}>{error}</Typography>;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h6" gutterBottom>
            {isEditing ? 'Edit Banner' : 'Add New Banner'}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {isEditing ? 'Update the details of this homepage banner.' : 'Add a new banner to display on the mobile app homepage.'}
          </Typography>
        </Box>
        <Button
          variant="outlined"
          startIcon={<ArrowBack />}
          onClick={handleCancel}
        >
          Back
        </Button>
      </Box>

      <Grid container spacing={3}>
        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" gutterBottom fontWeight="bold">
                Banner Details
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
                <TextField
                  label="Banner Title"
                  value={banner.title}
                  onChange={(e) => handleChange('title', e.target.value)}
                  fullWidth
                  required
                />
                <TextField
                  label="Link To (optional)"
                  value={banner.linkTo}
                  onChange={(e) => handleChange('linkTo', e.target.value)}
                  fullWidth
                  placeholder="e.g., /products/123 or https://example.com"
                  helperText="Where the banner should redirect when clicked."
                />
                <TextField
                  label="Order"
                  type="number"
                  value={banner.order}
                  onChange={(e) => handleChange('order', Number(e.target.value))}
                  fullWidth
                  helperText="Lower numbers appear first on the homepage."
                />
                <FormControlLabel
                  control={
                    <Switch
                      checked={banner.isVisible}
                      onChange={(e) => handleChange('isVisible', e.target.checked)}
                    />
                  }
                  label="Visible on Homepage"
                />
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12} md={6}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" gutterBottom fontWeight="bold">
                Banner Image
              </Typography>
              <Box sx={{ mt: 2 }}>
                {banner.imageUrl ? (
                  <Box sx={{ mb: 2 }}>
                    <img
                      src={banner.imageUrl}
                      alt="Banner Preview"
                      style={{ width: '100%', height: 'auto', maxHeight: '200px', objectFit: 'cover', borderRadius: '4px' }}
                    />
                    <Button
                      variant="outlined"
                      color="error"
                      size="small"
                      onClick={() => handleChange('imageUrl', '')}
                      sx={{ mt: 1 }}
                    >
                      Remove Image
                    </Button>
                  </Box>
                ) : (
                  <Box sx={{ mb: 2, textAlign: 'center', py: 4, border: '1px dashed #ccc', borderRadius: '4px' }}>
                    <Typography variant="body2" color="text.secondary">
                      No image uploaded
                    </Typography>
                  </Box>
                )}
                <Button
                  variant="contained"
                  component="label"
                  disabled={imageUploading}
                  fullWidth
                >
                  {imageUploading ? <CircularProgress size={24} /> : 'Upload Banner Image'}
                  <input
                    type="file"
                    accept="image/*"
                    hidden
                    onChange={handleImageUpload}
                  />
                </Button>
                <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
                  Recommended size: 1200x400px. Formats: JPG, PNG.
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>

        <Grid item xs={12}>
          <Box sx={{ display: 'flex', justifyContent: 'flex-end', gap: 2 }}>
            <Button
              variant="outlined"
              onClick={handleCancel}
            >
              Cancel
            </Button>
            <Button
              variant="contained"
              startIcon={<Save />}
              onClick={handleSubmit}
              disabled={saving || !banner.title || !banner.imageUrl}
            >
              {saving ? 'Saving...' : isEditing ? 'Update Banner' : 'Add Banner'}
            </Button>
          </Box>
        </Grid>
      </Grid>
    </Box>
  );
};

export default BannerForm;
