import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  IconButton,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
} from '@mui/material';
import { Add, Edit, Delete } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { getLegalContents, deleteLegalContent } from '../../../../services/contentService';

const LegalContent = () => {
  const navigate = useNavigate();
  const [legalContents, setLegalContents] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    fetchLegalContents();
  }, []);

  const fetchLegalContents = async () => {
    setLoading(true);
    try {
      const data = await getLegalContents();
      setLegalContents(data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load legal content');
      setLoading(false);
    }
  };

  const handleAddLegalContent = () => {
    navigate('/content-management/legal/add');
  };

  const handleEditLegalContent = (id) => {
    navigate(`/content-management/legal/edit/${id}`);
  };

  const handleDeleteLegalContent = async (id) => {
    try {
      await deleteLegalContent(id);
      setLegalContents(legalContents.filter(content => content.id !== id));
    } catch (err) {
      console.error('Failed to delete legal content', err);
      setError('Failed to delete legal content');
    }
  };

  const getContentTypeLabel = (type) => {
    switch (type) {
      case 'terms':
        return 'Terms & Conditions';
      case 'privacy':
        return 'Privacy Policy';
      case 'return':
        return 'Return Policy';
      case 'shipping':
        return 'Shipping Policy';
      default:
        return 'Other Legal Document';
    }
  };

  if (loading) return <Typography>Loading legal content...</Typography>;
  if (error) return <Typography color="error">{error}</Typography>;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h6" gutterBottom>
            Legal Content
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage terms & conditions, policies, and other legal documents displayed on the mobile app.
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={handleAddLegalContent}
        >
          Add Legal Document
        </Button>
      </Box>

      {legalContents.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <Typography variant="h6" color="text.secondary">
            No legal content found
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Get started by adding your first legal document.
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleAddLegalContent}
          >
            Add Legal Document
          </Button>
        </Box>
      ) : (
        <Grid container spacing={3}>
          <Grid item xs={12}>
            <Card>
              <CardContent sx={{ p: 0 }}>
                <List>
                  {legalContents.map((content) => (
                    <ListItem key={content.id} divider>
                      <ListItemText
                        primary={getContentTypeLabel(content.type)}
                        secondary={`Version: ${content.version || '1.0'} | Effective: ${content.effectiveDate || 'N/A'} | Last Updated: ${content.lastUpdated || 'N/A'}`}
                      />
                      <ListItemSecondaryAction>
                        <IconButton
                          edge="end"
                          aria-label="edit"
                          onClick={() => handleEditLegalContent(content.id)}
                          size="small"
                          sx={{ mr: 1 }}
                        >
                          <Edit fontSize="small" />
                        </IconButton>
                        <IconButton
                          edge="end"
                          aria-label="delete"
                          onClick={() => handleDeleteLegalContent(content.id)}
                          size="small"
                          color="error"
                        >
                          <Delete fontSize="small" />
                        </IconButton>
                      </ListItemSecondaryAction>
                    </ListItem>
                  ))}
                </List>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      )}
    </Box>
  );
};

export default LegalContent;
