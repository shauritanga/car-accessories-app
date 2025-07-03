import { collection, getDocs, doc, getDoc, setDoc, updateDoc, deleteDoc, query, where } from 'firebase/firestore';
import { db } from '../config/firebase';

/**
 * Fetch all products from the database with optional filters
 * @param {Object} filters - Optional filters for search, category, and status
 * @returns {Promise<Array>} Array of product objects
 */
export const getProducts = async (filters = {}) => {
  try {
    let q = collection(db, 'products');
    const conditions = [];
    
    if (filters.search) {
      conditions.push(where('name', '>=', filters.search));
      conditions.push(where('name', '<=', filters.search + '\uf8ff'));
    }
    
    if (filters.category) {
      conditions.push(where('category', '==', filters.category));
    }
    
    if (filters.status) {
      conditions.push(where('status', '==', filters.status));
    }
    
    if (conditions.length > 0) {
      q = query(q, ...conditions);
    }
    
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate ? doc.data().createdAt.toDate() : new Date(),
    }));
  } catch (error) {
    console.error('Error fetching products:', error);
    throw error;
  }
};

/**
 * Fetch products with low stock
 * @param {number} threshold - Stock threshold for low stock products
 * @returns {Promise<Array>} Array of low stock product objects
 */
export const getLowStockProducts = async (threshold = 10) => {
  try {
    const q = query(collection(db, 'products'), where('stock', '<=', threshold));
    const querySnapshot = await getDocs(q);
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate ? doc.data().createdAt.toDate() : new Date(),
    }));
  } catch (error) {
    console.error('Error fetching low stock products:', error);
    throw error;
  }
};

/**
 * Fetch product categories
 * @returns {Promise<Array>} Array of category strings
 */
export const getProductCategories = async () => {
  try {
    // This could be a separate collection or fetched from a config
    // For now, return hardcoded categories or fetch distinct values if possible
    return [
      'interior',
      'exterior',
      'electronics',
      'performance',
      'maintenance'
    ];
  } catch (error) {
    console.error('Error fetching product categories:', error);
    throw error;
  }
};

/**
 * Get a single product by ID
 * @param {string} productId - The ID of the product to fetch
 * @returns {Promise<Object|null>} Product object or null if not found
 */
export const getProduct = async (productId) => {
  try {
    const productRef = doc(db, 'products', productId);
    const productSnap = await getDoc(productRef);
    if (productSnap.exists()) {
      return {
        id: productSnap.id,
        ...productSnap.data(),
        createdAt: productSnap.data().createdAt?.toDate ? productSnap.data().createdAt.toDate() : new Date(),
      };
    }
    return null;
  } catch (error) {
    console.error(`Error fetching product ${productId}:`, error);
    throw error;
  }
};

/**
 * Create a new product
 * @param {Object} productData - Data for the new product
 * @returns {Promise<Object>} Created product object with ID
 */
export const createProduct = async (productData) => {
  try {
    const newProductRef = doc(collection(db, 'products'));
    const productWithMeta = {
      ...productData,
      createdAt: new Date(),
      updatedAt: new Date(),
      isActive: productData.isActive || false,
      status: productData.status || 'pending'
    };
    await setDoc(newProductRef, productWithMeta);
    return { id: newProductRef.id, ...productWithMeta };
  } catch (error) {
    console.error('Error creating product:', error);
    throw error;
  }
};

/**
 * Update an existing product
 * @param {string} productId - The ID of the product to update
 * @param {Object} productData - Updated data for the product
 * @returns {Promise<Object>} Updated product object
 */
export const updateProduct = async (productId, productData) => {
  try {
    const productRef = doc(db, 'products', productId);
    const updatedData = {
      ...productData,
      updatedAt: new Date(),
    };
    await updateDoc(productRef, updatedData);
    return { id: productId, ...updatedData };
  } catch (error) {
    console.error(`Error updating product ${productId}:`, error);
    throw error;
  }
};

/**
 * Delete a product
 * @param {string} productId - The ID of the product to delete
 * @returns {Promise<void>}
 */
export const deleteProduct = async (productId) => {
  try {
    const productRef = doc(db, 'products', productId);
    await deleteDoc(productRef);
  } catch (error) {
    console.error(`Error deleting product ${productId}:`, error);
    throw error;
  }
};

/**
 * Bulk update multiple products
 * @param {Object} updateData - Object with product IDs and updates
 * @returns {Promise<Array>} Array of updated product objects
 */
export const bulkUpdateProducts = async ({ productIds, updates }) => {
  try {
    const updatedData = {
      ...updates,
      updatedAt: new Date(),
    };
    
    const updatePromises = productIds.map(productId => {
      const productRef = doc(db, 'products', productId);
      return updateDoc(productRef, updatedData).then(() => ({ id: productId, ...updatedData }));
    });
    
    return Promise.all(updatePromises);
  } catch (error) {
    console.error('Error bulk updating products:', error);
    throw error;
  }
};

/**
 * Bulk delete multiple products
 * @param {Array} productIds - Array of product IDs to delete
 * @returns {Promise<void>}
 */
export const bulkDeleteProducts = async (productIds) => {
  try {
    const deletePromises = productIds.map(productId => {
      const productRef = doc(db, 'products', productId);
      return deleteDoc(productRef);
    });
    
    await Promise.all(deletePromises);
  } catch (error) {
    console.error('Error bulk deleting products:', error);
    throw error;
  }
};

/**
 * Update product status (e.g., approve or reject)
 * @param {string} productId - The ID of the product to update
 * @param {string} status - The new status for the product
 * @returns {Promise<Object>} Updated product object
 */
export const updateProductStatus = async (productId, status) => {
  try {
    const productRef = doc(db, 'products', productId);
    const updatedData = {
      status,
      updatedAt: new Date(),
      isActive: status === 'approved'
    };
    await updateDoc(productRef, updatedData);
    return { id: productId, ...updatedData };
  } catch (error) {
    console.error(`Error updating product status for ${productId}:`, error);
    throw error;
  }
};
