// Security & Access Control Service
// Implement API calls for security and access control here
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { app } from '../../firebase';

const db = getFirestore(app);

export const detectFraud = async () => {
  const snap = await getDocs(collection(db, 'fraudCases'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const getSecurityLogs = async () => {
  const snap = await getDocs(collection(db, 'securityLogs'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
