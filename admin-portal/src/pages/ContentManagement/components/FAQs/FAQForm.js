import React, { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  TextField,
  Button,
  Grid,
  Card,
  CardContent,
  CircularProgress,
} from '@mui/material';
import { Save, ArrowBack } from '@mui/icons-material';
import { useNavigate, useParams } from 'react-router-dom';
import { addFAQ, updateFAQ, getFAQById } from '../../../../services/contentService';

const FAQForm = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditing = Boolean(id);
  const [faq, setFAQ] = useState({
    question: '',
    answer: '',
    category: '',
  });
  const [loading, setLoading] = useState(isEditing);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isEditing) {
      fetchFAQ();
    }
  }, [id]);

  const fetchFAQ = async () => {
    setLoading(true);
    try {
      const data = await getFAQById(id);
      setFAQ(data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load FAQ details');
      setLoading(false);
    }
  };

  const handleChange = (field, value) => {
    setFAQ(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async () => {
    setSaving(true);
    setError(null);
    try {
      if (isEditing) {
        await updateFAQ(id, faq);
      } else {
        await addFAQ(faq);
      }
      navigate('/content-management/faqs');
    } catch (err) {
      setError(isEditing ? 'Failed to update FAQ' : 'Failed to add FAQ');
      setSaving(false);
    }
  };

  const handleCancel = () => {
    navigate('/content-management/faqs');
  };

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}><CircularProgress /></Box>;
  if (error && !saving) return <Typography color="error" sx={{ py: 4 }}>{error}</Typography>;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h6" gutterBottom>
            {isEditing ? 'Edit FAQ' : 'Add New FAQ'}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {isEditing ? 'Update the details of this FAQ entry.' : 'Add a new FAQ to assist users on the mobile app.'}
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
        <Grid item xs={12}>
          <Card>
            <CardContent>
              <Typography variant="subtitle1" gutterBottom fontWeight="bold">
                FAQ Details
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
                <TextField
                  label="Question"
                  value={faq.question}
                  onChange={(e) => handleChange('question', e.target.value)}
                  fullWidth
                  required
                  placeholder="e.g., How do I track my order?"
                />
                <TextField
                  label="Category (optional)"
                  value={faq.category}
                  onChange={(e) => handleChange('category', e.target.value)}
                  fullWidth
                  placeholder="e.g., Orders, Payments, Returns"
                  helperText="Group similar FAQs under a category for better organization."
                />
                <TextField
                  label="Answer"
                  value={faq.answer}
                  onChange={(e) => handleChange('answer', e.target.value)}
                  fullWidth
                  required
                  multiline
                  rows={6}
                  placeholder="Provide a detailed answer to the question."
                />
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
              disabled={saving || !faq.question || !faq.answer}
            >
              {saving ? 'Saving...' : isEditing ? 'Update FAQ' : 'Add FAQ'}
            </Button>
          </Box>
        </Grid>
      </Grid>
    </Box>
  );
};

export default FAQForm;
