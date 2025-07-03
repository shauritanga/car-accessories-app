import { getFirestore, collection, getDocs, addDoc, updateDoc, deleteDoc, doc, getDoc, setDoc } from 'firebase/firestore';
import { getStorage, ref, uploadBytes, getDownloadURL } from 'firebase/storage';
import { app } from '../../firebase';

const db = getFirestore(app);
const storage = getStorage(app);

// Helper for uploading image file to Firebase Storage
const uploadImage = async (file, folder = 'images') => {
  if (!file) return '';
  const storageRef = ref(storage, `${folder}/${Date.now()}_${file.name}`);
  await uploadBytes(storageRef, file);
  return await getDownloadURL(storageRef);
};

// Banners CRUD
export const getBanners = async () => {
  const snap = await getDocs(collection(db, 'banners'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
export const addBanner = async (data) => {
  let imageUrl = data.imageUrl;
  if (data.imageFile) imageUrl = await uploadImage(data.imageFile, 'banners');
  await addDoc(collection(db, 'banners'), { title: data.title, imageUrl });
  return { success: true };
};
export const updateBanner = async (bannerId, data) => {
  let imageUrl = data.imageUrl;
  if (data.imageFile) imageUrl = await uploadImage(data.imageFile, 'banners');
  await updateDoc(doc(db, 'banners', bannerId), { title: data.title, imageUrl });
  return { success: true };
};
export const deleteBanner = async (bannerId) => {
  await deleteDoc(doc(db, 'banners', bannerId));
  return { success: true };
};

// FAQs CRUD
export const getFAQs = async () => {
  const snap = await getDocs(collection(db, 'faqs'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
export const addFAQ = async (data) => {
  await addDoc(collection(db, 'faqs'), data);
  return { success: true };
};
export const updateFAQ = async (faqId, data) => {
  await updateDoc(doc(db, 'faqs', faqId), data);
  return { success: true };
};
export const deleteFAQ = async (faqId) => {
  await deleteDoc(doc(db, 'faqs', faqId));
  return { success: true };
};

export const getDataProtectionPolicy = async () => {
  const policyRef = doc(db, 'policies', 'dataProtection');
  const snap = await getDoc(policyRef);
  if (snap.exists()) {
    return snap.data();
  } else {
    return { title: 'Data Protection Policy', content: '' };
  }
};

export const updateDataProtectionPolicy = async (content) => {
  const policyRef = doc(db, 'policies', 'dataProtection');
  await setDoc(policyRef, { title: 'Data Protection Policy', content });
  return { success: true };
};
