// Content Management main component
import React, { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Box, Typography, Button, Table, TableHead, TableRow, TableCell, TableBody, TextField, CircularProgress, Stack, Dialog, DialogTitle, DialogContent, DialogActions, IconButton, Card, CardHeader, CardContent, Avatar, useTheme } from '@mui/material';
import DeleteIcon from '@mui/icons-material/Delete';
import AddIcon from '@mui/icons-material/Add';
import AddPhotoAlternateIcon from '@mui/icons-material/AddPhotoAlternate';
import ImageIcon from '@mui/icons-material/DirectionsCar';
import {
  getBanners,
  addBanner,
  updateBanner,
  deleteBanner,
  getFAQs,
  addFAQ,
  updateFAQ,
  deleteFAQ,
  getDataProtectionPolicy,
  updateDataProtectionPolicy
} from './contentManagementService';
import {
  getAccessoryCategories,
  addAccessoryCategory,
  updateAccessoryCategory,
  deleteAccessoryCategory
} from './accessoryCategoriesService';
import {
  getCarModels,
  addCarModel,
  updateCarModel,
  deleteCarModel
} from './carModelsService';

const ContentManagement = () => {
  const theme = useTheme();
  const queryClient = useQueryClient();
  // Fetch banners
  const { data: banners = [], isLoading: loadingBanners } = useQuery({
    queryKey: ['banners'],
    queryFn: getBanners,
  });
  // Fetch FAQs
  const { data: faqs = [], isLoading: loadingFaqs } = useQuery({
    queryKey: ['faqs'],
    queryFn: getFAQs,
  });
  // Accessory Categories
  const { data: accessoryCategories = [], isLoading: loadingAccessoryCategories } = useQuery({
    queryKey: ['accessoryCategories'],
    queryFn: getAccessoryCategories,
  });
  // Car Models
  const { data: carModels = [], isLoading: loadingCarModels } = useQuery({
    queryKey: ['carModels'],
    queryFn: getCarModels,
  });
  // Data Protection Policy
  const { data: dataProtectionPolicy = { content: '' }, isLoading: loadingPolicy } = useQuery({
    queryKey: ['dataProtectionPolicy'],
    queryFn: getDataProtectionPolicy,
  });
  // Mutations
  const bannerMutation = useMutation({
    mutationFn: ({ bannerId, data }) => updateBanner(bannerId, data),
    onSuccess: () => queryClient.invalidateQueries(['banners']),
  });
  const bannerAddMutation = useMutation({
    mutationFn: addBanner,
    onSuccess: () => queryClient.invalidateQueries(['banners']),
  });
  const bannerDeleteMutation = useMutation({
    mutationFn: ({ bannerId }) => deleteBanner(bannerId),
    onSuccess: () => queryClient.invalidateQueries(['banners']),
  });
  const faqMutation = useMutation({
    mutationFn: ({ faqId, data }) => updateFAQ(faqId, data),
    onSuccess: () => queryClient.invalidateQueries(['faqs']),
  });
  const faqAddMutation = useMutation({
    mutationFn: addFAQ,
    onSuccess: () => queryClient.invalidateQueries(['faqs']),
  });
  const faqDeleteMutation = useMutation({
    mutationFn: ({ faqId }) => deleteFAQ(faqId),
    onSuccess: () => queryClient.invalidateQueries(['faqs']),
  });
  const accessoryCategoryAddMutation = useMutation({
    mutationFn: addAccessoryCategory,
    onSuccess: () => queryClient.invalidateQueries(['accessoryCategories']),
  });
  const accessoryCategoryUpdateMutation = useMutation({
    mutationFn: ({ id, data }) => updateAccessoryCategory(id, data),
    onSuccess: () => queryClient.invalidateQueries(['accessoryCategories']),
  });
  const accessoryCategoryDeleteMutation = useMutation({
    mutationFn: deleteAccessoryCategory,
    onSuccess: () => queryClient.invalidateQueries(['accessoryCategories']),
  });
  const carModelAddMutation = useMutation({
    mutationFn: addCarModel,
    onSuccess: () => queryClient.invalidateQueries(['carModels']),
  });
  const carModelUpdateMutation = useMutation({
    mutationFn: ({ id, data }) => updateCarModel(id, data),
    onSuccess: () => queryClient.invalidateQueries(['carModels']),
  });
  const carModelDeleteMutation = useMutation({
    mutationFn: deleteCarModel,
    onSuccess: () => queryClient.invalidateQueries(['carModels']),
  });
  const updatePolicyMutation = useMutation({
    mutationFn: updateDataProtectionPolicy,
    onSuccess: () => queryClient.invalidateQueries(['dataProtectionPolicy']),
  });
  // State for dialogs
  const [editFaq, setEditFaq] = useState(null);
  const [faqText, setFaqText] = useState('');
  const [addFaqOpen, setAddFaqOpen] = useState(false);
  const [newFaq, setNewFaq] = useState({ question: '', answer: '' });
  const [addBannerOpen, setAddBannerOpen] = useState(false);
  const [newBanner, setNewBanner] = useState({ title: '', imageUrl: '' });
  const [addAccessoryCategoryOpen, setAddAccessoryCategoryOpen] = useState(false);
  const [newAccessoryCategory, setNewAccessoryCategory] = useState({ name: '', imageUrl: '' });
  const [editAccessoryCategory, setEditAccessoryCategory] = useState(null);
  const [editAccessoryCategoryData, setEditAccessoryCategoryData] = useState({ name: '', imageUrl: '' });
  const [addCarModelOpen, setAddCarModelOpen] = useState(false);
  const [newCarModel, setNewCarModel] = useState({ name: '', manufacturer: '' });
  const [editCarModel, setEditCarModel] = useState(null);
  const [editCarModelData, setEditCarModelData] = useState({ name: '', manufacturer: '' });
  const [editPolicy, setEditPolicy] = useState(false);
  const [policyText, setPolicyText] = useState('');

  if (loadingBanners || loadingFaqs || loadingAccessoryCategories || loadingCarModels || loadingPolicy) return <CircularProgress />;

  return (
    <Box>
      <Typography variant="h4" fontWeight="bold" mb={3} color="primary.main">
        Content Management
      </Typography>
      {/* Banners Section */}
      <Card sx={{ mb: 4, boxShadow: 3 }}>
        <CardHeader
          avatar={<Avatar sx={{ bgcolor: theme.palette.primary.main }}><AddPhotoAlternateIcon /></Avatar>}
          title={<Typography variant="h6">Homepage Banners</Typography>}
          action={<Button startIcon={<AddIcon />} variant="contained" onClick={() => setAddBannerOpen(true)}>Add Banner</Button>}
        />
        <CardContent>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Title</TableCell>
                <TableCell>Image</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {banners.length === 0 && (
                <TableRow><TableCell colSpan={3}>No banners found</TableCell></TableRow>
              )}
              {banners.map((banner) => (
                <TableRow key={banner.id}>
                  <TableCell>{banner.title}</TableCell>
                  <TableCell><img src={banner.imageUrl} alt={banner.title} width={120} style={{ borderRadius: 8, boxShadow: theme.shadows[1] }} /></TableCell>
                  <TableCell>
                    <Stack direction="row" spacing={1}>
                      <Button size="small" variant="outlined" onClick={() => bannerMutation.mutate({ bannerId: banner.id, data: { ...banner, title: banner.title + ' (Updated)' } })}>Update</Button>
                      <IconButton color="error" onClick={() => bannerDeleteMutation.mutate({ bannerId: banner.id })}><DeleteIcon /></IconButton>
                    </Stack>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
      {/* Add Banner Dialog */}
      <Dialog open={addBannerOpen} onClose={() => setAddBannerOpen(false)}>
        <DialogTitle>Add Banner</DialogTitle>
        <DialogContent>
          <TextField label="Title" fullWidth sx={{ mb: 2 }} value={newBanner.title} onChange={e => setNewBanner({ ...newBanner, title: e.target.value })} />
          <TextField label="Image URL" fullWidth value={newBanner.imageUrl} onChange={e => setNewBanner({ ...newBanner, imageUrl: e.target.value })} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddBannerOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => { bannerAddMutation.mutate(newBanner); setAddBannerOpen(false); setNewBanner({ title: '', imageUrl: '' }); }}>Add</Button>
        </DialogActions>
      </Dialog>

      {/* FAQs Section */}
      <Card sx={{ mb: 4, boxShadow: 3 }}>
        <CardHeader
          avatar={<Avatar sx={{ bgcolor: theme.palette.secondary.main }}>F</Avatar>}
          title={<Typography variant="h6">FAQs, Terms & Policies</Typography>}
          action={<Button startIcon={<AddIcon />} variant="contained" color="secondary" onClick={() => setAddFaqOpen(true)}>Add FAQ</Button>}
        />
        <CardContent>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Question/Section</TableCell>
                <TableCell>Content</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {faqs.length === 0 && (
                <TableRow><TableCell colSpan={3}>No FAQs or policies found</TableCell></TableRow>
              )}
              {faqs.map((faq) => (
                <TableRow key={faq.id}>
                  <TableCell sx={{ fontWeight: 600 }}>{faq.question || faq.section}</TableCell>
                  <TableCell>
                    {editFaq === faq.id ? (
                      <TextField
                        value={faqText}
                        onChange={e => setFaqText(e.target.value)}
                        multiline
                        fullWidth
                      />
                    ) : faq.answer || faq.content}
                  </TableCell>
                  <TableCell>
                    <Stack direction="row" spacing={1}>
                      {editFaq === faq.id ? (
                        <>
                          <Button size="small" color="success" variant="contained" onClick={() => { faqMutation.mutate({ faqId: faq.id, data: { ...faq, answer: faqText } }); setEditFaq(null); }}>Save</Button>
                          <Button size="small" color="error" variant="outlined" onClick={() => setEditFaq(null)}>Cancel</Button>
                        </>
                      ) : (
                        <Button size="small" variant="outlined" onClick={() => { setEditFaq(faq.id); setFaqText(faq.answer || faq.content); }}>Edit</Button>
                      )}
                      <IconButton color="error" onClick={() => faqDeleteMutation.mutate({ faqId: faq.id })}><DeleteIcon /></IconButton>
                    </Stack>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
      {/* Add FAQ Dialog */}
      <Dialog open={addFaqOpen} onClose={() => setAddFaqOpen(false)}>
        <DialogTitle>Add FAQ</DialogTitle>
        <DialogContent>
          <TextField label="Question/Section" fullWidth sx={{ mb: 2 }} value={newFaq.question} onChange={e => setNewFaq({ ...newFaq, question: e.target.value })} />
          <TextField label="Answer/Content" fullWidth multiline value={newFaq.answer} onChange={e => setNewFaq({ ...newFaq, answer: e.target.value })} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddFaqOpen(false)}>Cancel</Button>
          <Button variant="contained" color="secondary" onClick={() => { faqAddMutation.mutate(newFaq); setAddFaqOpen(false); setNewFaq({ question: '', answer: '' }); }}>Add</Button>
        </DialogActions>
      </Dialog>

      {/* Accessory Categories Section */}
      <Card sx={{ mb: 4, boxShadow: 3 }}>
        <CardHeader
          avatar={<Avatar sx={{ bgcolor: theme.palette.warning.main }}>A</Avatar>}
          title={<Typography variant="h6">Accessory Categories</Typography>}
          action={<Button startIcon={<AddIcon />} variant="contained" color="warning" onClick={() => setAddAccessoryCategoryOpen(true)}>Add Category</Button>}
        />
        <CardContent>
          <Table size="small">
            <TableHead>
              <TableRow>
                <TableCell>Name</TableCell>
                <TableCell>Image</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {accessoryCategories.length === 0 && (
                <TableRow><TableCell colSpan={3}>No accessory categories found</TableCell></TableRow>
              )}
              {accessoryCategories.map((cat) => (
                <TableRow key={cat.id}>
                  <TableCell>{editAccessoryCategory === cat.id ? (
                    <TextField value={editAccessoryCategoryData.name} onChange={e => setEditAccessoryCategoryData({ ...editAccessoryCategoryData, name: e.target.value })} />
                  ) : cat.name}</TableCell>
                  <TableCell>{editAccessoryCategory === cat.id ? (
                    <TextField value={editAccessoryCategoryData.imageUrl} onChange={e => setEditAccessoryCategoryData({ ...editAccessoryCategoryData, imageUrl: e.target.value })} />
                  ) : <img src={cat.imageUrl} alt={cat.name} width={80} style={{ borderRadius: 8 }} />}</TableCell>
                  <TableCell>
                    <Stack direction="row" spacing={1}>
                      {editAccessoryCategory === cat.id ? (
                        <>
                          <Button size="small" color="success" variant="contained" onClick={() => { accessoryCategoryUpdateMutation.mutate({ id: cat.id, data: editAccessoryCategoryData }); setEditAccessoryCategory(null); }}>Save</Button>
                          <Button size="small" color="error" variant="outlined" onClick={() => setEditAccessoryCategory(null)}>Cancel</Button>
                        </>
                      ) : (
                        <Button size="small" variant="outlined" onClick={() => { setEditAccessoryCategory(cat.id); setEditAccessoryCategoryData({ name: cat.name, imageUrl: cat.imageUrl }); }}>Edit</Button>
                      )}
                      <IconButton color="error" onClick={() => accessoryCategoryDeleteMutation.mutate(cat.id)}><DeleteIcon /></IconButton>
                    </Stack>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
      {/* Add Accessory Category Dialog */}
      <Dialog open={addAccessoryCategoryOpen} onClose={() => setAddAccessoryCategoryOpen(false)}>
        <DialogTitle>Add Accessory Category</DialogTitle>
        <DialogContent>
          <TextField label="Name" fullWidth sx={{ mb: 2 }} value={newAccessoryCategory.name} onChange={e => setNewAccessoryCategory({ ...newAccessoryCategory, name: e.target.value })} />
          <TextField label="Image URL" fullWidth value={newAccessoryCategory.imageUrl} onChange={e => setNewAccessoryCategory({ ...newAccessoryCategory, imageUrl: e.target.value })} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddAccessoryCategoryOpen(false)}>Cancel</Button>
          <Button variant="contained" color="warning" onClick={() => { accessoryCategoryAddMutation.mutate(newAccessoryCategory); setAddAccessoryCategoryOpen(false); setNewAccessoryCategory({ name: '', imageUrl: '' }); }}>Add</Button>
        </DialogActions>
      </Dialog>

      {/* Car Models Section */}
      {loadingCarModels ? <CircularProgress /> : (
        <Card sx={{ mb: 4, boxShadow: 3 }}>
          <CardHeader
            avatar={<Avatar sx={{ bgcolor: theme.palette.info.main }}><ImageIcon /></Avatar>}
            title={<Typography variant="h6">Car Models</Typography>}
            action={<Button startIcon={<AddIcon />} variant="contained" color="info" onClick={() => setAddCarModelOpen(true)}>Add Car Model</Button>}
          />
          <CardContent>
            <Table size="small">
              <TableHead>
                <TableRow>
                  <TableCell>Name</TableCell>
                  <TableCell>Manufacturer</TableCell>
                  <TableCell>Actions</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {carModels.length === 0 && (
                  <TableRow><TableCell colSpan={3}>No car models found</TableCell></TableRow>
                )}
                {carModels.map((model) => (
                  <TableRow key={model.id}>
                    <TableCell>{editCarModel === model.id ? (
                      <TextField value={editCarModelData.name} onChange={e => setEditCarModelData({ ...editCarModelData, name: e.target.value })} />
                    ) : model.name}</TableCell>
                    <TableCell>{editCarModel === model.id ? (
                      <TextField value={editCarModelData.manufacturer} onChange={e => setEditCarModelData({ ...editCarModelData, manufacturer: e.target.value })} />
                    ) : model.manufacturer}</TableCell>
                    <TableCell>
                      <Stack direction="row" spacing={1}>
                        {editCarModel === model.id ? (
                          <>
                            <Button size="small" color="success" variant="contained" onClick={() => { carModelUpdateMutation.mutate({ id: model.id, data: editCarModelData }); setEditCarModel(null); }}>Save</Button>
                            <Button size="small" color="error" variant="outlined" onClick={() => setEditCarModel(null)}>Cancel</Button>
                          </>
                        ) : (
                          <Button size="small" variant="outlined" onClick={() => { setEditCarModel(model.id); setEditCarModelData({ name: model.name, manufacturer: model.manufacturer }); }}>Edit</Button>
                        )}
                        <IconButton color="error" onClick={() => carModelDeleteMutation.mutate(model.id)}><DeleteIcon /></IconButton>
                      </Stack>
                    </TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </CardContent>
        </Card>
      )}
      {/* Add Car Model Dialog */}
      <Dialog open={addCarModelOpen} onClose={() => setAddCarModelOpen(false)}>
        <DialogTitle>Add Car Model</DialogTitle>
        <DialogContent>
          <TextField label="Name" fullWidth sx={{ mb: 2 }} value={newCarModel.name} onChange={e => setNewCarModel({ ...newCarModel, name: e.target.value })} />
          <TextField label="Manufacturer" fullWidth value={newCarModel.manufacturer} onChange={e => setNewCarModel({ ...newCarModel, manufacturer: e.target.value })} />
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setAddCarModelOpen(false)}>Cancel</Button>
          <Button variant="contained" onClick={() => { carModelAddMutation.mutate(newCarModel); setAddCarModelOpen(false); setNewCarModel({ name: '', manufacturer: '' }); }}>Add</Button>
        </DialogActions>
      </Dialog>

      {/* Data Protection Policy Section */}
      {loadingPolicy ? <CircularProgress /> : (
        <Card sx={{ mb: 4, boxShadow: 3 }}>
          <CardHeader
            avatar={<Avatar sx={{ bgcolor: theme.palette.error.main }}>P</Avatar>}
            title={<Typography variant="h6">Data Protection Policy</Typography>}
            action={<Button startIcon={<AddIcon />} variant="contained" color="error" onClick={() => { setEditPolicy(true); setPolicyText(dataProtectionPolicy.content); }}>Edit Policy</Button>}
          />
          <CardContent>
            {editPolicy ? (
              <>
                <TextField
                  value={policyText}
                  onChange={e => setPolicyText(e.target.value)}
                  multiline
                  fullWidth
                  minRows={6}
                />
                <Stack direction="row" spacing={2} sx={{ mt: 2 }}>
                  <Button variant="contained" color="success" onClick={() => { updatePolicyMutation.mutate(policyText); setEditPolicy(false); }}>Save</Button>
                  <Button variant="outlined" color="error" onClick={() => setEditPolicy(false)}>Cancel</Button>
                </Stack>
              </>
            ) : (
              <Typography sx={{ whiteSpace: 'pre-line' }}>{dataProtectionPolicy.content || 'No policy set.'}</Typography>
            )}
          </CardContent>
        </Card>
      )}
    </Box>
  );
};

export default ContentManagement;
