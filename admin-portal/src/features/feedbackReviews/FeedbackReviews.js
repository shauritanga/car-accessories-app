// Feedback & Reviews main component
import React from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getProductReviews, moderateReview } from './feedbackReviewsService';
import { Box, Typography, Button, Table, TableHead, TableRow, TableCell, TableBody, Chip, CircularProgress, Stack } from '@mui/material';

// TODO: Implement feedback & reviews UI and logic for:
// - Moderate product reviews and ratings
// - Take action on negative or abusive feedback
// Use feedbackReviewsService.js for API calls

const FeedbackReviews = () => {
  const queryClient = useQueryClient();
  // Fetch product reviews
  const { data: reviews = [], isLoading } = useQuery({
    queryKey: ['productReviews'],
    queryFn: getProductReviews,
  });
  // Mutation for moderating reviews
  const mutation = useMutation({
    mutationFn: ({ reviewId, action }) => moderateReview(reviewId, action),
    onSuccess: () => {
      queryClient.invalidateQueries(['productReviews']);
    },
  });

  const handleModerate = (reviewId, action) => {
    mutation.mutate({ reviewId, action });
  };

  if (isLoading) return <CircularProgress />;

  return (
    <Box>
      <Typography variant="h5" fontWeight="bold" mb={2}>Product Reviews & Ratings</Typography>
      <Table size="small">
        <TableHead>
          <TableRow>
            <TableCell>Product</TableCell>
            <TableCell>User</TableCell>
            <TableCell>Rating</TableCell>
            <TableCell>Comment</TableCell>
            <TableCell>Status</TableCell>
            <TableCell>Actions</TableCell>
          </TableRow>
        </TableHead>
        <TableBody>
          {reviews.length === 0 && (
            <TableRow><TableCell colSpan={6}>No reviews found</TableCell></TableRow>
          )}
          {reviews.map((review) => (
            <TableRow key={review.id}>
              <TableCell>{review.productName}</TableCell>
              <TableCell>{review.userName}</TableCell>
              <TableCell>{review.rating}</TableCell>
              <TableCell>{review.comment}</TableCell>
              <TableCell><Chip label={review.status} color={review.status === 'flagged' ? 'error' : 'success'} /></TableCell>
              <TableCell>
                <Stack direction="row" spacing={1}>
                  <Button size="small" color="success" variant="contained" onClick={() => handleModerate(review.id, 'approve')}>Approve</Button>
                  <Button size="small" color="error" variant="outlined" onClick={() => handleModerate(review.id, 'remove')}>Remove</Button>
                  <Button size="small" color="warning" variant="outlined" onClick={() => handleModerate(review.id, 'flag')}>Flag</Button>
                </Stack>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </Box>
  );
};

export default FeedbackReviews;
