// Feedback & Reviews Service
// Implement API calls for feedback moderation here
import { getFirestore, collection, getDocs, updateDoc, doc } from 'firebase/firestore';
import { db } from '../../config/firebase';

const dbFirestore = db;

export const getProductReviews = async () => {
  const snap = await getDocs(collection(dbFirestore, 'reviews'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const moderateReview = async (reviewId, action) => {
  // action: 'approve' | 'remove' | 'flag'
  await updateDoc(doc(dbFirestore, 'reviews', reviewId), { status: action });
  return { success: true };
};
