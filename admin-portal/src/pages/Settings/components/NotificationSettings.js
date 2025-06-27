import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Switch,
  FormControlLabel,
  Divider,
  Grid,
  Button,
} from '@mui/material';
import { Save } from '@mui/icons-material';

const NotificationSettings = () => {
  return (
    <Grid container spacing={3}>
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Email Notifications
            </Typography>
            <Divider sx={{ mb: 3 }} />
            
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="New Order Notifications"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Receive email when new orders are placed
              </Typography>
              
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Low Stock Alerts"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Get notified when products are running low on stock
              </Typography>
              
              <FormControlLabel
                control={<Switch />}
                label="Daily Sales Report"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Receive daily sales summary via email
              </Typography>
              
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Customer Support Tickets"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Get notified about new customer support requests
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              SMS Notifications
            </Typography>
            <Divider sx={{ mb: 3 }} />
            
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <FormControlLabel
                control={<Switch />}
                label="Critical System Alerts"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Receive SMS for critical system issues
              </Typography>
              
              <FormControlLabel
                control={<Switch />}
                label="High-Value Orders"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Get SMS alerts for orders above TZS 500,000
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      <Grid item xs={12}>
        <Box sx={{ display: 'flex', justifyContent: 'flex-end' }}>
          <Button variant="contained" startIcon={<Save />}>
            Save Notification Settings
          </Button>
        </Box>
      </Grid>
    </Grid>
  );
};

export default NotificationSettings;
