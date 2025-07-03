// Order Management Service
// Implement API calls for order management here
import { getFirestore, collection, getDocs, updateDoc, doc } from 'firebase/firestore';
import { app } from '../../firebase';

const db = getFirestore(app);

export const getOrders = async () => {
  const snap = await getDocs(collection(db, 'orders'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const handleComplaint = async (orderId, action) => {
  // action: 'resolve' or 'details'
  if (action === 'resolve') {
    await updateDoc(doc(db, 'orders', orderId), { complaint: null });
    return { success: true };
  }
  // For 'details', just return success (UI can show details from order data)
  return { success: true };
};

export const getSystemPerformance = async () => {
  const snap = await getDocs(collection(db, 'systemPerformance'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
