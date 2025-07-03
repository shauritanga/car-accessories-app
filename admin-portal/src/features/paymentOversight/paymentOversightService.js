// Payment Oversight Service
// Implement API calls for payment oversight here
import { getFirestore, collection, getDocs, updateDoc, doc } from 'firebase/firestore';
import { app } from '../../firebase';

const db = getFirestore(app);

export const getTransactions = async () => {
  const snap = await getDocs(collection(db, 'transactions'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const handleRefund = async (transactionId, action) => {
  // action: 'approve' | 'reject'
  await updateDoc(doc(db, 'transactions', transactionId), { refundStatus: action });
  return { success: true };
};
