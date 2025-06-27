import React, { useCallback } from 'react';
import {
  Box,
  Typography,
  IconButton,
  Grid,
  Card,
  CardMedia,
  Button,
} from '@mui/material';
import { CloudUpload, Delete, Add } from '@mui/icons-material';
import { useDropzone } from 'react-dropzone';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { storage } from '../../config/firebase';
import toast from 'react-hot-toast';

const ImageUpload = ({ images = [], onImagesChange, maxImages = 5 }) => {
  const onDrop = useCallback(async (acceptedFiles) => {
    if (images.length + acceptedFiles.length > maxImages) {
      toast.error(`Maximum ${maxImages} images allowed`);
      return;
    }

    const uploadPromises = acceptedFiles.map(async (file) => {
      try {
        // Create a unique filename
        const filename = `products/${Date.now()}_${file.name}`;
        const storageRef = ref(storage, filename);
        
        // Upload file
        await uploadBytes(storageRef, file);
        
        // Get download URL
        const downloadURL = await getDownloadURL(storageRef);
        return downloadURL;
      } catch (error) {
        console.error('Error uploading image:', error);
        toast.error(`Failed to upload ${file.name}`);
        return null;
      }
    });

    const uploadedUrls = await Promise.all(uploadPromises);
    const validUrls = uploadedUrls.filter(url => url !== null);
    
    if (validUrls.length > 0) {
      onImagesChange([...images, ...validUrls]);
      toast.success(`${validUrls.length} image(s) uploaded successfully`);
    }
  }, [images, maxImages, onImagesChange]);

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    accept: {
      'image/*': ['.jpeg', '.jpg', '.png', '.webp']
    },
    multiple: true,
  });

  const removeImage = (index) => {
    const newImages = images.filter((_, i) => i !== index);
    onImagesChange(newImages);
  };

  return (
    <Box>
      {/* Upload Area */}
      {images.length < maxImages && (
        <Box
          {...getRootProps()}
          sx={{
            border: '2px dashed #ccc',
            borderRadius: 2,
            p: 3,
            textAlign: 'center',
            cursor: 'pointer',
            backgroundColor: isDragActive ? '#f5f5f5' : 'transparent',
            '&:hover': {
              backgroundColor: '#f9f9f9',
            },
            mb: 2,
          }}
        >
          <input {...getInputProps()} />
          <CloudUpload sx={{ fontSize: 48, color: 'text.secondary', mb: 1 }} />
          <Typography variant="h6" gutterBottom>
            {isDragActive ? 'Drop images here' : 'Upload Product Images'}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Drag & drop images here, or click to select files
          </Typography>
          <Typography variant="caption" color="text.secondary" display="block" sx={{ mt: 1 }}>
            Supported formats: JPEG, PNG, WebP (Max {maxImages} images)
          </Typography>
        </Box>
      )}

      {/* Image Preview Grid */}
      {images.length > 0 && (
        <Grid container spacing={2}>
          {images.map((image, index) => (
            <Grid item xs={6} sm={4} md={3} key={index}>
              <Card sx={{ position: 'relative' }}>
                <CardMedia
                  component="img"
                  height="120"
                  image={image}
                  alt={`Product image ${index + 1}`}
                  sx={{ objectFit: 'cover' }}
                />
                <IconButton
                  size="small"
                  onClick={() => removeImage(index)}
                  sx={{
                    position: 'absolute',
                    top: 4,
                    right: 4,
                    backgroundColor: 'rgba(255, 255, 255, 0.8)',
                    '&:hover': {
                      backgroundColor: 'rgba(255, 255, 255, 0.9)',
                    },
                  }}
                >
                  <Delete fontSize="small" />
                </IconButton>
                {index === 0 && (
                  <Box
                    sx={{
                      position: 'absolute',
                      bottom: 4,
                      left: 4,
                      backgroundColor: 'primary.main',
                      color: 'white',
                      px: 1,
                      py: 0.5,
                      borderRadius: 1,
                      fontSize: '0.7rem',
                    }}
                  >
                    Main
                  </Box>
                )}
              </Card>
            </Grid>
          ))}
          
          {/* Add More Button */}
          {images.length < maxImages && (
            <Grid item xs={6} sm={4} md={3}>
              <Card
                sx={{
                  height: 120,
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  cursor: 'pointer',
                  border: '2px dashed #ccc',
                  '&:hover': {
                    backgroundColor: '#f9f9f9',
                  },
                }}
                {...getRootProps()}
              >
                <input {...getInputProps()} />
                <Box sx={{ textAlign: 'center' }}>
                  <Add sx={{ fontSize: 32, color: 'text.secondary' }} />
                  <Typography variant="caption" color="text.secondary">
                    Add More
                  </Typography>
                </Box>
              </Card>
            </Grid>
          )}
        </Grid>
      )}

      {/* Image Count */}
      <Typography variant="caption" color="text.secondary" sx={{ mt: 1, display: 'block' }}>
        {images.length} of {maxImages} images uploaded
      </Typography>
    </Box>
  );
};

export default ImageUpload;
