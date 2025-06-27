import React, { useState } from 'react';
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
  Avatar,
  IconButton,
} from '@mui/material';
import { Save, Edit, CloudUpload } from '@mui/icons-material';
import { useForm, Controller } from 'react-hook-form';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { useAuth } from '../../../contexts/AuthContext';
import toast from 'react-hot-toast';

const GeneralSettings = () => {
  const { userProfile } = useAuth();
  const queryClient = useQueryClient();
  const [isEditing, setIsEditing] = useState(false);

  const {
    control,
    handleSubmit,
    formState: { errors },
    reset,
  } = useForm({
    defaultValues: {
      companyName: 'Car Accessories Store',
      companyEmail: 'admin@caraccessories.com',
      companyPhone: '+255 123 456 789',
      companyAddress: 'Dar es Salaam, Tanzania',
      currency: 'TZS',
      timezone: 'Africa/Dar_es_Salaam',
      language: 'en',
      maintenanceMode: false,
      allowRegistration: true,
      emailNotifications: true,
      smsNotifications: false,
    },
  });

  const updateSettingsMutation = useMutation({
    mutationFn: async (data) => {
      // Mock API call - replace with actual implementation
      await new Promise(resolve => setTimeout(resolve, 1000));
      return data;
    },
    onSuccess: () => {
      toast.success('Settings updated successfully');
      setIsEditing(false);
      queryClient.invalidateQueries(['settings']);
    },
    onError: (error) => {
      toast.error(error.message || 'Failed to update settings');
    },
  });

  const onSubmit = (data) => {
    updateSettingsMutation.mutate(data);
  };

  const handleCancel = () => {
    reset();
    setIsEditing(false);
  };

  return (
    <Box>
      <form onSubmit={handleSubmit(onSubmit)}>
        <Grid container spacing={3}>
          {/* Company Information */}
          <Grid item xs={12} md={8}>
            <Card>
              <CardContent>
                <Box sx={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', mb: 3 }}>
                  <Typography variant="h6">Company Information</Typography>
                  {!isEditing && (
                    <Button
                      startIcon={<Edit />}
                      onClick={() => setIsEditing(true)}
                    >
                      Edit
                    </Button>
                  )}
                </Box>

                <Grid container spacing={2}>
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="companyName"
                      control={control}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="Company Name"
                          disabled={!isEditing}
                          error={!!errors.companyName}
                          helperText={errors.companyName?.message}
                        />
                      )}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="companyEmail"
                      control={control}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="Company Email"
                          type="email"
                          disabled={!isEditing}
                          error={!!errors.companyEmail}
                          helperText={errors.companyEmail?.message}
                        />
                      )}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="companyPhone"
                      control={control}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="Company Phone"
                          disabled={!isEditing}
                          error={!!errors.companyPhone}
                          helperText={errors.companyPhone?.message}
                        />
                      )}
                    />
                  </Grid>
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="currency"
                      control={control}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="Default Currency"
                          disabled={!isEditing}
                          error={!!errors.currency}
                          helperText={errors.currency?.message}
                        />
                      )}
                    />
                  </Grid>
                  <Grid item xs={12}>
                    <Controller
                      name="companyAddress"
                      control={control}
                      render={({ field }) => (
                        <TextField
                          {...field}
                          fullWidth
                          label="Company Address"
                          multiline
                          rows={3}
                          disabled={!isEditing}
                          error={!!errors.companyAddress}
                          helperText={errors.companyAddress?.message}
                        />
                      )}
                    />
                  </Grid>
                </Grid>

                {isEditing && (
                  <Box sx={{ display: 'flex', gap: 2, mt: 3 }}>
                    <Button
                      type="submit"
                      variant="contained"
                      startIcon={<Save />}
                      disabled={updateSettingsMutation.isPending}
                    >
                      {updateSettingsMutation.isPending ? 'Saving...' : 'Save Changes'}
                    </Button>
                    <Button
                      variant="outlined"
                      onClick={handleCancel}
                    >
                      Cancel
                    </Button>
                  </Box>
                )}
              </CardContent>
            </Card>
          </Grid>

          {/* Admin Profile */}
          <Grid item xs={12} md={4}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  Admin Profile
                </Typography>
                <Box sx={{ textAlign: 'center', mb: 3 }}>
                  <Avatar
                    src={userProfile?.profileImageUrl}
                    sx={{ width: 80, height: 80, mx: 'auto', mb: 2 }}
                  >
                    {userProfile?.name?.charAt(0)}
                  </Avatar>
                  <IconButton
                    color="primary"
                    component="label"
                    disabled={!isEditing}
                  >
                    <CloudUpload />
                    <input type="file" hidden accept="image/*" />
                  </IconButton>
                </Box>
                <TextField
                  fullWidth
                  label="Name"
                  value={userProfile?.name || ''}
                  disabled={!isEditing}
                  sx={{ mb: 2 }}
                />
                <TextField
                  fullWidth
                  label="Email"
                  value={userProfile?.email || ''}
                  disabled
                  sx={{ mb: 2 }}
                />
                <TextField
                  fullWidth
                  label="Role"
                  value="Administrator"
                  disabled
                />
              </CardContent>
            </Card>
          </Grid>

          {/* System Preferences */}
          <Grid item xs={12}>
            <Card>
              <CardContent>
                <Typography variant="h6" gutterBottom>
                  System Preferences
                </Typography>
                <Divider sx={{ mb: 3 }} />
                
                <Grid container spacing={3}>
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="maintenanceMode"
                      control={control}
                      render={({ field }) => (
                        <FormControlLabel
                          control={
                            <Switch
                              {...field}
                              checked={field.value}
                              disabled={!isEditing}
                            />
                          }
                          label="Maintenance Mode"
                        />
                      )}
                    />
                    <Typography variant="caption" color="text.secondary" display="block">
                      Enable to temporarily disable the application for maintenance
                    </Typography>
                  </Grid>
                  
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="allowRegistration"
                      control={control}
                      render={({ field }) => (
                        <FormControlLabel
                          control={
                            <Switch
                              {...field}
                              checked={field.value}
                              disabled={!isEditing}
                            />
                          }
                          label="Allow User Registration"
                        />
                      )}
                    />
                    <Typography variant="caption" color="text.secondary" display="block">
                      Allow new users to register accounts
                    </Typography>
                  </Grid>
                  
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="emailNotifications"
                      control={control}
                      render={({ field }) => (
                        <FormControlLabel
                          control={
                            <Switch
                              {...field}
                              checked={field.value}
                              disabled={!isEditing}
                            />
                          }
                          label="Email Notifications"
                        />
                      )}
                    />
                    <Typography variant="caption" color="text.secondary" display="block">
                      Send email notifications for important events
                    </Typography>
                  </Grid>
                  
                  <Grid item xs={12} sm={6}>
                    <Controller
                      name="smsNotifications"
                      control={control}
                      render={({ field }) => (
                        <FormControlLabel
                          control={
                            <Switch
                              {...field}
                              checked={field.value}
                              disabled={!isEditing}
                            />
                          }
                          label="SMS Notifications"
                        />
                      )}
                    />
                    <Typography variant="caption" color="text.secondary" display="block">
                      Send SMS notifications for critical alerts
                    </Typography>
                  </Grid>
                </Grid>
              </CardContent>
            </Card>
          </Grid>
        </Grid>
      </form>
    </Box>
  );
};

export default GeneralSettings;
