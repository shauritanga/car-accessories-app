import { getFirestore, collection, getDocs, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { app } from '../../firebase';

const db = getFirestore(app);

// Car Models Service
export const getCarModels = async () => {
  const snap = await getDocs(collection(db, 'carModels'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
export const addCarModel = async (data) => {
  await addDoc(collection(db, 'carModels'), data);
  return { success: true };
};
export const updateCarModel = async (id, data) => {
  await updateDoc(doc(db, 'carModels', id), data);
  return { success: true };
};
export const deleteCarModel = async (id) => {
  await deleteDoc(doc(db, 'carModels', id));
  return { success: true };
};
