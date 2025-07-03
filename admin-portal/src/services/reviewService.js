import { collection, getDocs, query, where, doc, updateDoc } from 'firebase/firestore';
import { db } from '../config/firebase';

// Fetch all reviews
export const getReviews = async () => {
  try {
    const reviewsCollection = collection(db, 'reviews');
    const reviewsSnapshot = await getDocs(reviewsCollection);
    const reviewsList = reviewsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      productName: doc.data().productId || 'Unknown Product', // Placeholder, ideally map to product name
      userName: doc.data().userId || 'Unknown User', // Placeholder, ideally map to user name
    }));
    return reviewsList;
  } catch (error) {
    console.error('Error fetching reviews:', error);
    throw error;
  }
};

// Fetch flagged or pending reviews for moderation
export const getFlaggedReviews = async () => {
  try {
    const reviewsCollection = collection(db, 'reviews');
    const q = query(reviewsCollection, where('status', 'in', ['pending', 'flagged']));
    const reviewsSnapshot = await getDocs(q);
    const reviewsList = reviewsSnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      productName: doc.data().productId || 'Unknown Product',
      userName: doc.data().userId || 'Unknown User',
    }));
    return reviewsList;
  } catch (error) {
    console.error('Error fetching flagged reviews:', error);
    throw error;
  }
};

// Update review status (approve, reject, etc.)
export const updateReviewStatus = async (reviewId, status, reason = '') => {
  try {
    const reviewRef = doc(db, 'reviews', reviewId);
    const updateData = { status };
    if (reason) {
      updateData.moderationReason = reason;
    }
    await updateDoc(reviewRef, updateData);
    return true;
  } catch (error) {
    console.error('Error updating review status:', error);
    throw error;
  }
};
