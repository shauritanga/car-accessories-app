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
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from '@mui/material';
import { Save, ArrowBack } from '@mui/icons-material';
import { useNavigate, useParams } from 'react-router-dom';
import { addLegalContent, updateLegalContent, getLegalContentById } from '../../../../services/contentService';

const LegalForm = () => {
  const navigate = useNavigate();
  const { id } = useParams();
  const isEditing = Boolean(id);
  const [legalContent, setLegalContent] = useState({
    type: 'terms',
    content: '',
    version: '1.0',
    effectiveDate: '',
  });
  const [loading, setLoading] = useState(isEditing);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    if (isEditing) {
      fetchLegalContent();
    }
  }, [id]);

  const fetchLegalContent = async () => {
    setLoading(true);
    try {
      const data = await getLegalContentById(id);
      setLegalContent(data);
      setLoading(false);
    } catch (err) {
      setError('Failed to load legal content details');
      setLoading(false);
    }
  };

  const handleChange = (field, value) => {
    setLegalContent(prev => ({ ...prev, [field]: value }));
  };

  const handleSubmit = async () => {
    setSaving(true);
    setError(null);
    try {
      if (isEditing) {
        await updateLegalContent(id, legalContent);
      } else {
        await addLegalContent(legalContent);
      }
      navigate('/content-management/legal');
    } catch (err) {
      setError(isEditing ? 'Failed to update legal content' : 'Failed to add legal content');
      setSaving(false);
    }
  };

  const handleCancel = () => {
    navigate('/content-management/legal');
  };

  if (loading) return <Box sx={{ display: 'flex', justifyContent: 'center', py: 8 }}><CircularProgress /></Box>;
  if (error && !saving) return <Typography color="error" sx={{ py: 4 }}>{error}</Typography>;

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 4 }}>
        <Box>
          <Typography variant="h6" gutterBottom>
            {isEditing ? 'Edit Legal Document' : 'Add New Legal Document'}
          </Typography>
          <Typography variant="body1" color="text.secondary">
            {isEditing ? 'Update the details of this legal document.' : 'Add a new legal document for display on the mobile app.'}
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
                Legal Document Details
              </Typography>
              <Box sx={{ display: 'flex', flexDirection: 'column', gap: 3, mt: 2 }}>
                <FormControl fullWidth required>
                  <InputLabel>Type</InputLabel>
                  <Select
                    value={legalContent.type}
                    label="Type"
                    onChange={(e) => handleChange('type', e.target.value)}
                  >
                    <MenuItem value="terms">Terms & Conditions</MenuItem>
                    <MenuItem value="privacy">Privacy Policy</MenuItem>
                    <MenuItem value="return">Return Policy</MenuItem>
                    <MenuItem value="shipping">Shipping Policy</MenuItem>
                    <MenuItem value="other">Other Legal Document</MenuItem>
                  </Select>
                </FormControl>
                <TextField
                  label="Version"
                  value={legalContent.version}
                  onChange={(e) => handleChange('version', e.target.value)}
                  fullWidth
                  required
                  placeholder="e.g., 1.0"
                />
                <TextField
                  label="Effective Date"
                  type="date"
                  value={legalContent.effectiveDate}
                  onChange={(e) => handleChange('effectiveDate', e.target.value)}
                  fullWidth
                  InputLabelProps={{
                    shrink: true,
                  }}
                />
                <TextField
                  label="Content"
                  value={legalContent.content}
                  onChange={(e) => handleChange('content', e.target.value)}
                  fullWidth
                  required
                  multiline
                  rows={12}
                  placeholder="Enter the full text of the legal document here. You can use HTML formatting if needed."
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
              disabled={saving || !legalContent.type || !legalContent.content || !legalContent.version}
            >
              {saving ? 'Saving...' : isEditing ? 'Update Legal Document' : 'Add Legal Document'}
            </Button>
          </Box>
        </Grid>
      </Grid>
    </Box>
  );
};

export default LegalForm;
