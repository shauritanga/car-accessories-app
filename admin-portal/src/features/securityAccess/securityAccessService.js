// Security & Access Control Service
// Implement API calls for security and access control here
import { getFirestore, collection, getDocs } from 'firebase/firestore';
import { db } from '../../config/firebase';

const dbFirestore = db;

export const detectFraud = async () => {
  const snap = await getDocs(collection(dbFirestore, 'fraudCases'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};

export const getSecurityLogs = async () => {
  const snap = await getDocs(collection(dbFirestore, 'securityLogs'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
