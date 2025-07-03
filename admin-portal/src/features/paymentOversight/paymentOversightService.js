// Payment Oversight Service
// Implement API calls for payment oversight here
import { getFirestore, collection, getDocs, updateDoc, doc } from 'firebase/firestore';
import { db } from '../../config/firebase';

const dbFirestore = db;

export const getTransactions = async () => {
  const snap = await getDocs(collection(dbFirestore, 'transactions'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const handleRefund = async (transactionId, action) => {
  // action: 'approve' | 'reject'
  await updateDoc(doc(dbFirestore, 'transactions', transactionId), { refundStatus: action });
  return { success: true };
};
