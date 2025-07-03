import React, { useState, useEffect } from 'react';
import { Box, Button, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper, Dialog, DialogActions, DialogContent, DialogTitle, TextField } from '@mui/material';
import { getFlaggedReviews, updateReviewStatus } from '../../../services/reviewService';

function ModerationQueue() {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [selectedReview, setSelectedReview] = useState(null);
  const [openDialog, setOpenDialog] = useState(false);
  const [action, setAction] = useState('');
  const [reason, setReason] = useState('');

  useEffect(() => {
    const fetchFlaggedReviews = async () => {
      try {
        const data = await getFlaggedReviews();
        setReviews(data);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching flagged reviews:', error);
        setLoading(false);
      }
    };

    fetchFlaggedReviews();
  }, []);

  const handleOpenDialog = (review, actionType) => {
    setSelectedReview(review);
    setAction(actionType);
    setOpenDialog(true);
  };

  const handleCloseDialog = () => {
    setOpenDialog(false);
    setSelectedReview(null);
    setAction('');
    setReason('');
  };

  const handleConfirmAction = async () => {
    if (selectedReview) {
      try {
        await updateReviewStatus(selectedReview.id, action, reason);
        setReviews(reviews.filter(r => r.id !== selectedReview.id));
        handleCloseDialog();
      } catch (error) {
        console.error('Error updating review status:', error);
      }
    }
  };

  if (loading) {
    return <Typography>Loading moderation queue...</Typography>;
  }

  return (
    <Box>
      <Typography variant="h6" gutterBottom>
        Reviews Requiring Moderation
      </Typography>
      {reviews.length === 0 ? (
        <Typography>No reviews in moderation queue.</Typography>
      ) : (
        <TableContainer component={Paper}>
          <Table>
            <TableHead>
              <TableRow>
                <TableCell>Product</TableCell>
                <TableCell>User</TableCell>
                <TableCell>Rating</TableCell>
                <TableCell>Comment</TableCell>
                <TableCell>Reason Flagged</TableCell>
                <TableCell>Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {reviews.map((review) => (
                <TableRow key={review.id}>
                  <TableCell>{review.productName}</TableCell>
                  <TableCell>{review.userName}</TableCell>
                  <TableCell>{review.rating}/5</TableCell>
                  <TableCell>{review.comment.length > 100 ? `${review.comment.substring(0, 100)}...` : review.comment}</TableCell>
                  <TableCell>{review.flagReason || 'N/A'}</TableCell>
                  <TableCell>
                    <Button size="small" sx={{ mr: 1 }} onClick={() => handleOpenDialog(review, 'view')}>View</Button>
                    <Button size="small" color="primary" sx={{ mr: 1 }} onClick={() => handleOpenDialog(review, 'approve')}>Approve</Button>
                    <Button size="small" color="error" onClick={() => handleOpenDialog(review, 'reject')}>Reject</Button>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}

      {/* Dialog for View/Approve/Reject Actions */}
      <Dialog open={openDialog} onClose={handleCloseDialog} maxWidth="md" fullWidth>
        <DialogTitle>
          {action === 'view' ? 'Review Details' : action === 'approve' ? 'Approve Review' : 'Reject Review'}
        </DialogTitle>
        <DialogContent>
          {selectedReview && (
            <>
              <Typography variant="h6">{selectedReview.productName}</Typography>
              <Typography variant="subtitle1">By: {selectedReview.userName}</Typography>
              <Typography variant="subtitle2">Rating: {selectedReview.rating}/5</Typography>
              <Typography variant="body1" sx={{ mt: 2 }}>{selectedReview.comment}</Typography>
              <Typography variant="body2" color="text.secondary">Flagged Reason: {selectedReview.flagReason || 'N/A'}</Typography>
              {action !== 'view' && (
                <TextField
                  fullWidth
                  margin="normal"
                  label={action === 'approve' ? 'Approval Note (optional)' : 'Reason for Rejection'}
                  multiline
                  rows={3}
                  value={reason}
                  onChange={(e) => setReason(e.target.value)}
                />
              )}
            </>
          )}
        </DialogContent>
        <DialogActions>
          <Button onClick={handleCloseDialog}>Cancel</Button>
          {action !== 'view' && (
            <Button onClick={handleConfirmAction} color={action === 'approve' ? 'primary' : 'error'}>
              {action === 'approve' ? 'Confirm Approval' : 'Confirm Rejection'}
            </Button>
          )}
        </DialogActions>
      </Dialog>
    </Box>
  );
}

export default ModerationQueue;
