import React from 'react';
import {
  Box,
  Card,
  CardContent,
  Typography,
  Button,
  Grid,
  TextField,
  Switch,
  FormControlLabel,
  Divider,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
} from '@mui/material';
import { Save, Delete, Security } from '@mui/icons-material';

const SecuritySettings = () => {
  return (
    <Grid container spacing={3}>
      {/* Password Settings */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Password Settings
            </Typography>
            <Divider sx={{ mb: 3 }} />
            
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <TextField
                type="password"
                label="Current Password"
                fullWidth
              />
              <TextField
                type="password"
                label="New Password"
                fullWidth
              />
              <TextField
                type="password"
                label="Confirm New Password"
                fullWidth
              />
              <Button variant="contained" startIcon={<Save />} sx={{ mt: 2 }}>
                Update Password
              </Button>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Security Options */}
      <Grid item xs={12} md={6}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Security Options
            </Typography>
            <Divider sx={{ mb: 3 }} />
            
            <Box sx={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Two-Factor Authentication"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Add an extra layer of security to your account
              </Typography>
              
              <FormControlLabel
                control={<Switch defaultChecked />}
                label="Login Notifications"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Get notified of new login attempts
              </Typography>
              
              <FormControlLabel
                control={<Switch />}
                label="Session Timeout"
              />
              <Typography variant="caption" color="text.secondary" sx={{ ml: 4, mt: -1 }}>
                Automatically log out after 30 minutes of inactivity
              </Typography>
            </Box>
          </CardContent>
        </Card>
      </Grid>

      {/* Active Sessions */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Active Sessions
            </Typography>
            <Divider sx={{ mb: 3 }} />
            
            <List>
              <ListItem>
                <ListItemText
                  primary="Current Session"
                  secondary="MacBook Pro - Chrome - Dar es Salaam, Tanzania"
                />
                <ListItemSecondaryAction>
                  <Typography variant="body2" color="success.main">
                    Active
                  </Typography>
                </ListItemSecondaryAction>
              </ListItem>
              <ListItem>
                <ListItemText
                  primary="Mobile Session"
                  secondary="iPhone - Safari - Last seen 2 hours ago"
                />
                <ListItemSecondaryAction>
                  <IconButton edge="end">
                    <Delete />
                  </IconButton>
                </ListItemSecondaryAction>
              </ListItem>
            </List>
          </CardContent>
        </Card>
      </Grid>

      {/* Security Log */}
      <Grid item xs={12}>
        <Card>
          <CardContent>
            <Typography variant="h6" gutterBottom>
              Recent Security Activity
            </Typography>
            <Divider sx={{ mb: 3 }} />
            
            <List>
              <ListItem>
                <Security sx={{ mr: 2, color: 'success.main' }} />
                <ListItemText
                  primary="Successful login"
                  secondary="Today at 9:30 AM from 192.168.1.100"
                />
              </ListItem>
              <ListItem>
                <Security sx={{ mr: 2, color: 'info.main' }} />
                <ListItemText
                  primary="Password changed"
                  secondary="Yesterday at 3:45 PM"
                />
              </ListItem>
              <ListItem>
                <Security sx={{ mr: 2, color: 'warning.main' }} />
                <ListItemText
                  primary="Failed login attempt"
                  secondary="2 days ago at 11:20 PM from unknown IP"
                />
              </ListItem>
            </List>
          </CardContent>
        </Card>
      </Grid>
    </Grid>
  );
};

export default SecuritySettings;
