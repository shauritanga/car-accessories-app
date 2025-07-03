import { db, storage } from '../config/firebase';
import {
  collection,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  doc,
  query,
  orderBy,
} from 'firebase/firestore';
import { ref, uploadBytes, getDownloadURL } from 'firebase/storage';

// Banners
const bannersCollectionRef = collection(db, 'banners');

export const getBanners = async () => {
  try {
    const q = query(bannersCollectionRef, orderBy('order', 'asc'));
    const data = await getDocs(q);
    return data.docs.map((doc) => ({ ...doc.data(), id: doc.id }));
  } catch (error) {
    console.error('Error fetching banners:', error);
    throw error;
  }
};

export const getBannerById = async (id) => {
  try {
    const bannerDoc = doc(db, 'banners', id);
    const data = await getDoc(bannerDoc);
    if (data.exists()) {
      return { ...data.data(), id: data.id };
    } else {
      throw new Error('Banner not found');
    }
  } catch (error) {
    console.error('Error fetching banner:', error);
    throw error;
  }
};

export const addBanner = async (banner) => {
  try {
    await addDoc(bannersCollectionRef, {
      ...banner,
      createdAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error adding banner:', error);
    throw error;
  }
};

export const updateBanner = async (id, banner) => {
  try {
    const bannerDoc = doc(db, 'banners', id);
    await updateDoc(bannerDoc, {
      ...banner,
      updatedAt: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error updating banner:', error);
    throw error;
  }
};

export const updateBannerOrder = async (orderUpdates) => {
  try {
    for (const update of orderUpdates) {
      const bannerDoc = doc(db, 'banners', update.id);
      await updateDoc(bannerDoc, { order: update.order });
    }
  } catch (error) {
    console.error('Error updating banner order:', error);
    throw error;
  }
};

export const deleteBanner = async (id) => {
  try {
    const bannerDoc = doc(db, 'banners', id);
    await deleteDoc(bannerDoc);
  } catch (error) {
    console.error('Error deleting banner:', error);
    throw error;
  }
};

export const uploadBannerImage = async (file) => {
  try {
    const storageRef = ref(storage, `banners/${Date.now()}_${file.name}`);
    await uploadBytes(storageRef, file);
    const downloadURL = await getDownloadURL(storageRef);
    return downloadURL;
  } catch (error) {
    console.error('Error uploading banner image:', error);
    throw error;
  }
};

// FAQs
const faqsCollectionRef = collection(db, 'faqs');

export const getFAQs = async () => {
  try {
    const data = await getDocs(faqsCollectionRef);
    return data.docs.map((doc) => ({ ...doc.data(), id: doc.id }));
  } catch (error) {
    console.error('Error fetching FAQs:', error);
    throw error;
  }
};

export const getFAQById = async (id) => {
  try {
    const faqDoc = doc(db, 'faqs', id);
    const data = await getDoc(faqDoc);
    if (data.exists()) {
      return { ...data.data(), id: data.id };
    } else {
      throw new Error('FAQ not found');
    }
  } catch (error) {
    console.error('Error fetching FAQ:', error);
    throw error;
  }
};

export const addFAQ = async (faq) => {
  try {
    await addDoc(faqsCollectionRef, {
      ...faq,
      createdAt: new Date().toISOString(),
      lastUpdated: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error adding FAQ:', error);
    throw error;
  }
};

export const updateFAQ = async (id, faq) => {
  try {
    const faqDoc = doc(db, 'faqs', id);
    await updateDoc(faqDoc, {
      ...faq,
      lastUpdated: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error updating FAQ:', error);
    throw error;
  }
};

export const deleteFAQ = async (id) => {
  try {
    const faqDoc = doc(db, 'faqs', id);
    await deleteDoc(faqDoc);
  } catch (error) {
    console.error('Error deleting FAQ:', error);
    throw error;
  }
};

// Legal Content
const legalContentsCollectionRef = collection(db, 'legalContents');

export const getLegalContents = async () => {
  try {
    const data = await getDocs(legalContentsCollectionRef);
    return data.docs.map((doc) => ({ ...doc.data(), id: doc.id }));
  } catch (error) {
    console.error('Error fetching legal contents:', error);
    throw error;
  }
};

export const getLegalContentById = async (id) => {
  try {
    const legalContentDoc = doc(db, 'legalContents', id);
    const data = await getDoc(legalContentDoc);
    if (data.exists()) {
      return { ...data.data(), id: data.id };
    } else {
      throw new Error('Legal content not found');
    }
  } catch (error) {
    console.error('Error fetching legal content:', error);
    throw error;
  }
};

export const addLegalContent = async (legalContent) => {
  try {
    await addDoc(legalContentsCollectionRef, {
      ...legalContent,
      createdAt: new Date().toISOString(),
      lastUpdated: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error adding legal content:', error);
    throw error;
  }
};

export const updateLegalContent = async (id, legalContent) => {
  try {
    const legalContentDoc = doc(db, 'legalContents', id);
    await updateDoc(legalContentDoc, {
      ...legalContent,
      lastUpdated: new Date().toISOString(),
    });
  } catch (error) {
    console.error('Error updating legal content:', error);
    throw error;
  }
};

export const deleteLegalContent = async (id) => {
  try {
    const legalContentDoc = doc(db, 'legalContents', id);
    await deleteDoc(legalContentDoc);
  } catch (error) {
    console.error('Error deleting legal content:', error);
    throw error;
  }
};
