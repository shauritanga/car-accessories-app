import { getFirestore, collection, getDocs, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { db } from '../../config/firebase';

const dbFirestore = db;

// Car Models Service
export const getCarModels = async () => {
  const snap = await getDocs(collection(dbFirestore, 'carModels'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
export const addCarModel = async (data) => {
  await addDoc(collection(dbFirestore, 'carModels'), data);
  return { success: true };
};
export const updateCarModel = async (id, data) => {
  await updateDoc(doc(dbFirestore, 'carModels', id), data);
  return { success: true };
};
export const deleteCarModel = async (id) => {
  await deleteDoc(doc(dbFirestore, 'carModels', id));
  return { success: true };
};
