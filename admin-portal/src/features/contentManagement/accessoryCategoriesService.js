import { getFirestore, collection, getDocs, addDoc, updateDoc, deleteDoc, doc } from 'firebase/firestore';
import { getStorage, ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { storage } from '../../config/firebase';
import { db } from '../../config/firebase';

//const storage = getStorage(db);

// Helper for uploading image file to Firebase Storage
const uploadImage = async (file, folder = 'images') => {
  if (!file) return '';
  const storageRef = ref(storage, `${folder}/${Date.now()}_${file.name}`);
  await uploadBytes(storageRef, file);
  return await getDownloadURL(storageRef);
};

// Accessory Categories CRUD
export const getAccessoryCategories = async () => {
  const snap = await getDocs(collection(db, 'accessoryCategories'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
export const addAccessoryCategory = async (data) => {
  let imageUrl = data.imageUrl;
  if (data.imageFile) imageUrl = await uploadImage(data.imageFile, 'accessoryCategories');
  await addDoc(collection(db, 'accessoryCategories'), { name: data.name, imageUrl });
  return { success: true };
};
export const updateAccessoryCategory = async (id, data) => {
  let imageUrl = data.imageUrl;
  if (data.imageFile) imageUrl = await uploadImage(data.imageFile, 'accessoryCategories');
  await updateDoc(doc(db, 'accessoryCategories', id), { name: data.name, imageUrl });
  return { success: true };
};
export const deleteAccessoryCategory = async (id) => {
  await deleteDoc(doc(db, 'accessoryCategories', id));
  return { success: true };
};
