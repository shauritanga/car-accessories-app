import React, { useEffect, useState } from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  TextField,
  Button,
  Grid,
  Switch,
  FormControlLabel,
  Divider,
  Select,
  MenuItem,
  FormControl,
  InputLabel,
} from '@mui/material';
import { Save, Refresh } from '@mui/icons-material';
import { getSettings, saveSettings } from '../../../services/settingsService';

const AppConfiguration = () => {
  const [settings, setSettings] = useState(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    setLoading(true);
    getSettings()
      .then(data => {
        setSettings(data);
        setLoading(false);
      })
      .catch(err => {
        setError('Failed to load settings');
        setLoading(false);
      });
  }, []);

  const handleChange = (field, value) => {
    setSettings(prev => ({ ...prev, [field]: value }));
  };
  const handleToggle = (toggle, value) => {
    setSettings(prev => ({
      ...prev,
      featureToggles: { ...prev.featureToggles, [toggle]: value }
    }));
  };
  const handleApiKeyChange = (key, value) => {
    setSettings(prev => ({
      ...prev,
      apiKeys: { ...prev.apiKeys, [key]: value }
    }));
  };
  const handleSave = async () => {
    setSaving(true);
    setError(null);
    try {
      await saveSettings(settings);
      setSaving(false);
    } catch (err) {
      setError('Failed to save settings');
      setSaving(false);
    }
  };
  if (loading) return <div>Loading...</div>;
  if (error) return <div style={{ color: 'red' }}>{error}</div>;
  return (
    <Grid container spacing={3}>
      {/* App Settings */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Application Settings
            </Typography>
            <Divider sx={{ mb: 3 }} />

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                label="App Name"
                value={settings.appName}
                onChange={e => handleChange('appName', e.target.value)}
                fullWidth
              />
              <TextField
                label="App Version"
                value={settings.appVersion}
                fullWidth
                disabled
              />
              <FormControl fullWidth>
                <InputLabel>Default Language</InputLabel>
                <Select
                  value={settings.defaultLanguage}
                  label="Default Language"
                  onChange={e => handleChange('defaultLanguage', e.target.value)}
                >
                  <MenuItem value="en">English</MenuItem>
                  <MenuItem value="sw">Swahili</MenuItem>
                </Select>
              </FormControl>
              <FormControl fullWidth>
                <InputLabel>Timezone</InputLabel>
                <Select
                  value={settings.timezone}
                  label="Timezone"
                  onChange={e => handleChange('timezone', e.target.value)}
                >
                  <MenuItem value="Africa/Dar_es_Salaam">Africa/Dar_es_Salaam</MenuItem>
                  <MenuItem value="UTC">UTC</MenuItem>
                </Select>
              </FormControl>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Business Settings */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Business Configuration
            </Typography>
            <Divider sx={{ mb: 3 }} />

            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                label="Tax Rate (%)"
                type="number"
                value={settings.taxRate}
                onChange={e => handleChange('taxRate', Number(e.target.value))}
                fullWidth
              />
              <TextField
                label="Default Shipping Cost (TZS)"
                type="number"
                value={settings.shippingCost}
                onChange={e => handleChange('shippingCost', Number(e.target.value))}
                fullWidth
              />
              <TextField
                label="Free Shipping Threshold (TZS)"
                type="number"
                value={settings.freeShippingThreshold}
                onChange={e => handleChange('freeShippingThreshold', Number(e.target.value))}
                fullWidth
              />
              <FormControl fullWidth>
                <InputLabel>Order Processing Time</InputLabel>
                <Select
                  value={settings.orderProcessingTime}
                  label="Order Processing Time"
                  onChange={e => handleChange('orderProcessingTime', e.target.value)}
                >
                  <MenuItem value="same-day">Same Day</MenuItem>
                  <MenuItem value="1-2">1-2 Business Days</MenuItem>
                  <MenuItem value="3-5">3-5 Business Days</MenuItem>
                </Select>
              </FormControl>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Feature Toggles */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Feature Configuration
            </Typography>
            <Divider sx={{ mb: 3 }} />

            <Grid container spacing={3}>
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch checked={settings.featureToggles.reviews} onChange={e => handleToggle('reviews', e.target.checked)} />}
                  label="Enable Product Reviews"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Allow customers to leave product reviews
                </Typography>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch checked={settings.featureToggles.wishlist} onChange={e => handleToggle('wishlist', e.target.checked)} />}
                  label="Enable Wishlist"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Allow customers to save products to wishlist
                </Typography>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch checked={settings.featureToggles.liveChat} onChange={e => handleToggle('liveChat', e.target.checked)} />}
                  label="Enable Live Chat"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Enable customer support live chat
                </Typography>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch checked={settings.featureToggles.pushNotifications} onChange={e => handleToggle('pushNotifications', e.target.checked)} />}
                  label="Enable Push Notifications"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Send push notifications to mobile app users
                </Typography>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch checked={settings.featureToggles.orderTracking} onChange={e => handleToggle('orderTracking', e.target.checked)} />}
                  label="Enable Order Tracking"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Allow customers to track their orders
                </Typography>
              </Grid>

              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch checked={settings.featureToggles.loyalty} onChange={e => handleToggle('loyalty', e.target.checked)} />}
                  label="Enable Loyalty Program"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Enable customer loyalty points system
                </Typography>
              </Grid>
            </Grid>
          </CardContent>
        </Card>
      </Grid>

      {/* API Configuration */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              API Configuration
            </Typography>
            <Divider sx={{ mb: 3 }} />

            <Grid container spacing={2}>
              <Grid item xs={12} sm={6}>
                <TextField
                  label="Payment Gateway API Key"
                  type="password"
                  value={settings.apiKeys.paymentGateway}
                  onChange={e => handleApiKeyChange('paymentGateway', e.target.value)}
                  fullWidth
                  placeholder="Enter API key"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  label="SMS Service API Key"
                  type="password"
                  value={settings.apiKeys.smsService}
                  onChange={e => handleApiKeyChange('smsService', e.target.value)}
                  fullWidth
                  placeholder="Enter API key"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  label="Email Service API Key"
                  type="password"
                  fullWidth
                  placeholder="Enter API key"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  label="Analytics Tracking ID"
                  fullWidth
                  placeholder="Enter tracking ID"
                />
              </Grid>
            </Grid>
            <Box sx={{ mt: 3, display: 'flex', gap: 2 }}>
              <Button variant="contained" color="primary" startIcon={<Save />} onClick={handleSave} disabled={saving}>
                {saving ? 'Saving...' : 'Save Settings'}
              </Button>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Action Buttons */}
      <Grid item xs={12}>
        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
          <Button variant="outlined" startIcon={<Refresh />}>
            Reset to Defaults
          </Button>
        </Box>
      </Grid>
    </Grid>
  );
};

export default AppConfiguration;
