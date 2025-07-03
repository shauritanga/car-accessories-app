// Feedback & Reviews Service
// Implement API calls for feedback moderation here
import { getFirestore, collection, getDocs, updateDoc, doc } from 'firebase/firestore';
import { app } from '../../firebase';

const db = getFirestore(app);

export const getProductReviews = async () => {
  const snap = await getDocs(collection(db, 'reviews'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const moderateReview = async (reviewId, action) => {
  // action: 'approve' | 'remove' | 'flag'
  await updateDoc(doc(db, 'reviews', reviewId), { status: action });
  return { success: true };
};
