import { collection, getDocs, updateDoc, doc } from 'firebase/firestore';
import { db } from '../../config/firebase';


// Product Management Service
// Implement API calls for product management here

// Fetch products pending approval
export const getPendingProducts = async () => {
  const snap = await getDocs(collection(db, 'products'));
  // Only return products with status 'pending'
  return snap.docs
    .map(doc => ({ id: doc.id, ...doc.data() }))
    .filter(product => product.status === 'pending');
};

// Approve, reject, or remove product
export const updateProductStatus = async (productId, status) => {
  await updateDoc(doc(db, 'products', productId), { status });
  return { success: true };
};

// Fetch product categories and descriptions
export const getProductCategories = async () => {
  const snap = await getDocs(collection(db, 'productCategories'));
  return snap.docs.map(doc => ({ id: doc.id, ...doc.data() }));
};
