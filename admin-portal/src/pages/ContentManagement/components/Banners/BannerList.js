import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  CardMedia,
  IconButton,
  Chip,
} from '@mui/material';
import { Add, Edit, Delete, ArrowUpward, ArrowDownward } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { getBanners, updateBannerOrder } from '../../../../services/contentService';

const BannerList = () => {
  const navigate = useNavigate();
  const [banners, setBanners] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchBanners();
  }, []);

  const fetchBanners = async () => {
    setLoading(true);
    try {
      const data = await getBanners();
      setBanners(data.sort((a, b) => a.order - b.order));
      setLoading(false);
    } catch (err) {
      setError('Failed to load banners');
      setLoading(false);
    }
  };

  const handleAddBanner = () => {
    navigate('/content-management/banners/add');
  };

  const handleEditBanner = (id) => {
    navigate(`/content-management/banners/edit/${id}`);
  };

  const handleDeleteBanner = (id) => {
    // Placeholder for delete functionality
    console.log(`Delete banner with id: ${id}`);
  };

  const handleMoveUp = async (index) => {
    if (index > 0) {
      const newBanners = [...banners];
      [newBanners[index], newBanners[index - 1]] = [newBanners[index - 1], newBanners[index]];
      setBanners(newBanners);
      try {
        await updateBannerOrder(newBanners.map((banner, idx) => ({ id: banner.id, order: idx })));
      } catch (err) {
        console.error('Failed to update banner order', err);
        fetchBanners(); // Revert on error
      }
    }
  };

  const handleMoveDown = async (index) => {
    if (index < banners.length - 1) {
      const newBanners = [...banners];
      [newBanners[index], newBanners[index + 1]] = [newBanners[index + 1], newBanners[index]];
      setBanners(newBanners);
      try {
        await updateBannerOrder(newBanners.map((banner, idx) => ({ id: banner.id, order: idx })));
      } catch (err) {
        console.error('Failed to update banner order', err);
        fetchBanners(); // Revert on error
      }
    }
  };

  if (loading) return <Typography>Loading banners...</Typography>;
  if (error) return <Typography color="error">{error}</Typography>;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h6" gutterBottom>
            Homepage Banners
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage banners displayed on the mobile app homepage. Adjust the order to control their display sequence.
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={handleAddBanner}
        >
          Add Banner
        </Button>
      </Box>

      {banners.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <Typography variant="h6" color="text.secondary">
            No banners found
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Get started by adding your first banner.
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleAddBanner}
          >
            Add Banner
          </Button>
        </Box>
      ) : (
        <Grid container spacing={3}>
          {banners.map((banner, index) => (
            <Grid item xs={12} md={6} key={banner.id}>
              <Card>
                <CardMedia
                  component="img"
                  height="140"
                  image={banner.imageUrl}
                  alt={banner.title || 'Banner'}
                />
                <CardContent>
                  <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 1 }}>
                    <Typography variant="h6">{banner.title || 'Untitled Banner'}</Typography>
                    <Chip
                      label={banner.isVisible ? 'Visible' : 'Hidden'}
                      color={banner.isVisible ? 'success' : 'default'}
                      size="small"
                    />
                  </Box>
                  <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
                    Order: {index + 1} | {banner.linkTo ? `Links to: ${banner.linkTo}` : 'No link'}
                  </Typography>
                  <Box sx={{ display: 'flex', gap: 1 }}>
                    <IconButton
                      onClick={() => handleMoveUp(index)}
                      disabled={index === 0}
                      size="small"
                    >
                      <ArrowUpward fontSize="small" />
                    </IconButton>
                    <IconButton
                      onClick={() => handleMoveDown(index)}
                      disabled={index === banners.length - 1}
                      size="small"
                    >
                      <ArrowDownward fontSize="small" />
                    </IconButton>
                    <Button
                      variant="outlined"
                      size="small"
                      startIcon={<Edit />}
                      onClick={() => handleEditBanner(banner.id)}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="outlined"
                      color="error"
                      size="small"
                      startIcon={<Delete />}
                      onClick={() => handleDeleteBanner(banner.id)}
                    >
                      Delete
                    </Button>
                  </Box>
                </CardContent>
              </Card>
            </Grid>
          ))}
        </Grid>
      )}
    </Box>
  );
};

export default BannerList;
