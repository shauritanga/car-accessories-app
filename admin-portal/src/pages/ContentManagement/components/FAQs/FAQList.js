import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Button,
  Grid,
  Card,
  CardContent,
  IconButton,
  Accordion,
  AccordionSummary,
  AccordionDetails,
} from '@mui/material';
import { Add, Edit, Delete, ExpandMore } from '@mui/icons-material';
import { useNavigate } from 'react-router-dom';
import { getFAQs, deleteFAQ } from '../../../../services/contentService';

const FAQList = () => {
  const navigate = useNavigate();
  const [faqs, setFAQs] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [expanded, setExpanded] = useState(false);

  useEffect(() => {
    fetchFAQs();
  }, []);

  const fetchFAQs = async () => {
    setLoading(true);
    try {
      const data = await getFAQs();
      setFAQs(data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load FAQs');
      setLoading(false);
    }
  };

  const handleAddFAQ = () => {
    navigate('/content-management/faqs/add');
  };

  const handleEditFAQ = (id) => {
    navigate(`/content-management/faqs/edit/${id}`);
  };

  const handleDeleteFAQ = async (id) => {
    try {
      await deleteFAQ(id);
      setFAQs(faqs.filter(faq => faq.id !== id));
    } catch (err) {
      console.error('Failed to delete FAQ', err);
      setError('Failed to delete FAQ');
    }
  };

  const handleExpandChange = (panel) => (event, isExpanded) => {
    setExpanded(isExpanded ? panel : false);
  };

  if (loading) return <Typography>Loading FAQs...</Typography>;
  if (error) return <Typography color="error">{error}</Typography>;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h6" gutterBottom>
            Frequently Asked Questions
          </Typography>
          <Typography variant="body1" color="text.secondary">
            Manage FAQs displayed on the mobile app to assist users with common queries.
          </Typography>
        </Box>
        <Button
          variant="contained"
          startIcon={<Add />}
          onClick={handleAddFAQ}
        >
          Add FAQ
        </Button>
      </Box>

      {faqs.length === 0 ? (
        <Box sx={{ textAlign: 'center', py: 8 }}>
          <Typography variant="h6" color="text.secondary">
            No FAQs found
          </Typography>
          <Typography variant="body2" color="text.secondary" sx={{ mb: 2 }}>
            Get started by adding your first FAQ.
          </Typography>
          <Button
            variant="contained"
            startIcon={<Add />}
            onClick={handleAddFAQ}
          >
            Add FAQ
          </Button>
        </Box>
      ) : (
        <Grid container spacing={3}>
          <Grid item xs={12}>
            {faqs.map((faq, index) => (
              <Accordion
                key={faq.id}
                expanded={expanded === `panel${index}`}
                onChange={handleExpandChange(`panel${index}`)}
                disableGutters
                elevation={0}
                sx={{ border: `1px solid #e0e0e0`, '&:not(:last-child)': { mb: 2 }, borderRadius: 1, overflow: 'hidden' }}
              >
                <AccordionSummary
                  expandIcon={<ExpandMore />}
                  sx={{ backgroundColor: 'rgba(0, 0, 0, 0.02)' }}
                >
                  <Typography variant="h6" sx={{ flexGrow: 1 }}>
                    {faq.question}
                  </Typography>
                </AccordionSummary>
                <AccordionDetails>
                  <Typography variant="body1" sx={{ mb: 2 }}>
                    {faq.answer}
                  </Typography>
                  <Box sx={{ display: 'flex', gap: 1, justifyContent: 'flex-end' }}>
                    <Button
                      variant="outlined"
                      size="small"
                      startIcon={<Edit />}
                      onClick={() => handleEditFAQ(faq.id)}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="outlined"
                      color="error"
                      size="small"
                      startIcon={<Delete />}
                      onClick={() => handleDeleteFAQ(faq.id)}
                    >
                      Delete
                    </Button>
                  </Box>
                </AccordionDetails>
              </Accordion>
            ))}
          </Grid>
        </Grid>
      )}
    </Box>
  );
};

export default FAQList;
