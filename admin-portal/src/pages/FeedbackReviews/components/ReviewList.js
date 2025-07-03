import React, { useState, useEffect } from 'react';
import { Box, Button, MenuItem, Select, TextField, Typography, Table, TableBody, TableCell, TableContainer, TableHead, TableRow, Paper } from '@mui/material';
import { getReviews } from '../../../services/reviewService';

function ReviewList() {
  const [reviews, setReviews] = useState([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState('all');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    const fetchReviews = async () => {
      try {
        const data = await getReviews();
        setReviews(data);
        setLoading(false);
      } catch (error) {
        console.error('Error fetching reviews:', error);
        setLoading(false);
      }
    };

    fetchReviews();
  }, []);

  const handleFilterChange = (event) => {
    setFilter(event.target.value);
  };

  const handleSearchChange = (event) => {
    setSearchTerm(event.target.value);
  };

  const filteredReviews = reviews.filter(review => {
    const matchesFilter = filter === 'all' || review.status === filter;
    const matchesSearch = review.productName.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          review.userName.toLowerCase().includes(searchTerm.toLowerCase()) || 
                          review.comment.toLowerCase().includes(searchTerm.toLowerCase());
    return matchesFilter && matchesSearch;
  });

  if (loading) {
    return <Typography>Loading reviews...</Typography>;
  }

  return (
    <Box>
      <Box sx={{ display: 'flex', justifyContent: 'space-between', mb: 2 }}>
        <TextField 
          placeholder="Search reviews..."
          variant="outlined"
          size="small"
          sx={{ flexGrow: 1, mr: 2 }}
          value={searchTerm}
          onChange={handleSearchChange}
        />
        <Select
          value={filter}
          onChange={handleFilterChange}
          size="small"
          sx={{ minWidth: 120 }}
        >
          <MenuItem value="all">All Statuses</MenuItem>
          <MenuItem value="approved">Approved</MenuItem>
          <MenuItem value="pending">Pending</MenuItem>
          <MenuItem value="rejected">Rejected</MenuItem>
          <MenuItem value="flagged">Flagged</MenuItem>
        </Select>
      </Box>
      {filteredReviews.length === 0 ? (
        <Typography>No reviews found.</Typography>
      ) : (
        <TableContainer component={Paper}>
          <Table>
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
              {filteredReviews.map((review) => (
                <TableRow key={review.id}>
                  <TableCell>{review.productName}</TableCell>
                  <TableCell>{review.userName}</TableCell>
                  <TableCell>{review.rating}/5</TableCell>
                  <TableCell>{review.comment.length > 100 ? `${review.comment.substring(0, 100)}...` : review.comment}</TableCell>
                  <TableCell>{review.status}</TableCell>
                  <TableCell>
                    <Button size="small" sx={{ mr: 1 }}>View</Button>
                    {review.status !== 'approved' && <Button size="small" color="primary" sx={{ mr: 1 }}>Approve</Button>}
                    {review.status !== 'rejected' && <Button size="small" color="error">Reject</Button>}
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      )}
    </Box>
  );
}

export default ReviewList;
