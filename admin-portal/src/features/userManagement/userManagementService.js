// User Management Service
// Implement API calls for user management here
// Example: Replace with real API endpoints
import { getFirestore, collection, getDocs, updateDoc, doc, query, where } from 'firebase/firestore';
import { app } from '../../firebase';

const db = getFirestore(app);

export const getPendingSellers = async () => {
  const q = query(collection(db, 'users'), where('role', '==', 'seller'), where('status', '==', 'pending'));
  const snap = await getDocs(q);
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const updateUserStatus = async (userId, status) => {
  await updateDoc(doc(db, 'users', userId), { status });
  return { success: true };
};

export const getUserProfiles = async () => {
  const snap = await getDocs(collection(db, 'users'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const getUserActivities = async (userId) => {
  const q = query(collection(db, 'userActivities'), where('userId', '==', userId));
  const snap = await getDocs(q);
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
