import {
  collection,
  doc,
  getDocs,
  getDoc,
  addDoc,
  updateDoc,
  deleteDoc,
  query,
  where,
  orderBy,
  limit,
  writeBatch,
} from 'firebase/firestore';
import { db } from '../config/firebase';

// Get all products with filters
export const getProducts = async (filters = {}) => {
  try {
    let q = collection(db, 'products');
    
    // Apply filters
    if (filters.category) {
      q = query(q, where('category', '==', filters.category));
    }
    
    if (filters.status) {
      const isActive = filters.status === 'active';
      q = query(q, where('isActive', '==', isActive));
    }
    
    // Add ordering
    q = query(q, orderBy('createdAt', 'desc'));
    
    const snapshot = await getDocs(q);
    const products = snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      image: doc.data().images?.[0] || null,
      status: doc.data().isActive ? 'active' : 'inactive',
      createdAt: doc.data().createdAt?.toDate(),
      updatedAt: doc.data().updatedAt?.toDate(),
    }));
    
    // Apply search filter on client side (for simplicity)
    if (filters.search) {
      const searchTerm = filters.search.toLowerCase();
      return products.filter(product =>
        product.name.toLowerCase().includes(searchTerm) ||
        product.description?.toLowerCase().includes(searchTerm) ||
        product.category.toLowerCase().includes(searchTerm)
      );
    }
    
    return products;
  } catch (error) {
    console.error('Error fetching products:', error);
    throw new Error('Failed to fetch products');
  }
};

// Get single product
export const getProduct = async (id) => {
  try {
    const docRef = doc(db, 'products', id);
    const docSnap = await getDoc(docRef);
    
    if (!docSnap.exists()) {
      throw new Error('Product not found');
    }
    
    return {
      id: docSnap.id,
      ...docSnap.data(),
      createdAt: docSnap.data().createdAt?.toDate(),
      updatedAt: docSnap.data().updatedAt?.toDate(),
    };
  } catch (error) {
    console.error('Error fetching product:', error);
    throw new Error('Failed to fetch product');
  }
};

// Create new product
export const createProduct = async (productData) => {
  try {
    const docRef = await addDoc(collection(db, 'products'), {
      ...productData,
      createdAt: new Date(),
      updatedAt: new Date(),
      viewCount: 0,
      totalReviews: 0,
      averageRating: 0,
    });
    
    return docRef.id;
  } catch (error) {
    console.error('Error creating product:', error);
    throw new Error('Failed to create product');
  }
};

// Update product
export const updateProduct = async (id, productData) => {
  try {
    const docRef = doc(db, 'products', id);
    await updateDoc(docRef, {
      ...productData,
      updatedAt: new Date(),
    });
    
    return id;
  } catch (error) {
    console.error('Error updating product:', error);
    throw new Error('Failed to update product');
  }
};

// Delete product
export const deleteProduct = async (id) => {
  try {
    const docRef = doc(db, 'products', id);
    await deleteDoc(docRef);
    
    return id;
  } catch (error) {
    console.error('Error deleting product:', error);
    throw new Error('Failed to delete product');
  }
};

// Bulk update products
export const bulkUpdateProducts = async ({ productIds, updates }) => {
  try {
    const batch = writeBatch(db);
    
    productIds.forEach(id => {
      const docRef = doc(db, 'products', id);
      batch.update(docRef, {
        ...updates,
        updatedAt: new Date(),
      });
    });
    
    await batch.commit();
    return productIds;
  } catch (error) {
    console.error('Error bulk updating products:', error);
    throw new Error('Failed to update products');
  }
};

// Bulk delete products
export const bulkDeleteProducts = async (productIds) => {
  try {
    const batch = writeBatch(db);
    
    productIds.forEach(id => {
      const docRef = doc(db, 'products', id);
      batch.delete(docRef);
    });
    
    await batch.commit();
    return productIds;
  } catch (error) {
    console.error('Error bulk deleting products:', error);
    throw new Error('Failed to delete products');
  }
};

// Get product categories
export const getProductCategories = async () => {
  try {
    const snapshot = await getDocs(collection(db, 'products'));
    const categories = new Set();
    
    snapshot.docs.forEach(doc => {
      const category = doc.data().category;
      if (category) {
        categories.add(category);
      }
    });
    
    return Array.from(categories);
  } catch (error) {
    console.error('Error fetching categories:', error);
    throw new Error('Failed to fetch categories');
  }
};

// Get low stock products
export const getLowStockProducts = async (threshold = 10) => {
  try {
    const q = query(
      collection(db, 'products'),
      where('stock', '<=', threshold),
      where('isActive', '==', true),
      orderBy('stock', 'asc')
    );
    
    const snapshot = await getDocs(q);
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    console.error('Error fetching low stock products:', error);
    throw new Error('Failed to fetch low stock products');
  }
};
