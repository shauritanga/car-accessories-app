import React from 'react';
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

const AppConfiguration = () => {
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
                defaultValue="Car Accessories Store"
                fullWidth
              />
              <TextField
                label="App Version"
                defaultValue="1.0.0"
                fullWidth
                disabled
              />
              <FormControl fullWidth>
                <InputLabel>Default Language</InputLabel>
                <Select defaultValue="en" label="Default Language">
                  <MenuItem value="en">English</MenuItem>
                  <MenuItem value="sw">Swahili</MenuItem>
                </Select>
              </FormControl>
              <FormControl fullWidth>
                <InputLabel>Timezone</InputLabel>
                <Select defaultValue="Africa/Dar_es_Salaam" label="Timezone">
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
                defaultValue="18"
                type="number"
                fullWidth
              />
              <TextField
                label="Default Shipping Cost (TZS)"
                defaultValue="5000"
                type="number"
                fullWidth
              />
              <TextField
                label="Free Shipping Threshold (TZS)"
                defaultValue="100000"
                type="number"
                fullWidth
              />
              <FormControl fullWidth>
                <InputLabel>Order Processing Time</InputLabel>
                <Select defaultValue="1-2" label="Order Processing Time">
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
                  control={<Switch defaultChecked />}
                  label="Enable Product Reviews"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Allow customers to leave product reviews
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Enable Wishlist"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Allow customers to save products to wishlist
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch />}
                  label="Enable Live Chat"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Enable customer support live chat
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Enable Push Notifications"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Send push notifications to mobile app users
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch defaultChecked />}
                  label="Enable Order Tracking"
                />
                <Typography variant="caption" color="text.secondary" display="block">
                  Allow customers to track their orders
                </Typography>
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <FormControlLabel
                  control={<Switch />}
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
                  fullWidth
                  placeholder="Enter API key"
                />
              </Grid>
              <Grid item xs={12} sm={6}>
                <TextField
                  label="SMS Service API Key"
                  type="password"
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
          </CardContent>
        </Card>
      </Grid>

      {/* Action Buttons */}
      <Grid item xs={12}>
        <Box sx={{ display: 'flex', gap: 2, justifyContent: 'flex-end' }}>
          <Button variant="outlined" startIcon={<Refresh />}>
            Reset to Defaults
          </Button>
          <Button variant="contained" startIcon={<Save />}>
            Save Configuration
          </Button>
        </Box>
      </Grid>
    </Grid>
  );
};

export default AppConfiguration;
