import { collection, getDocs, doc, getDoc, updateDoc } from 'firebase/firestore';
import { db } from '../config/firebase';

/**
 * Fetch all payments from the database
 * @returns {Promise<Array>} Array of payment objects
 */
export const getPayments = async () => {
  try {
    const querySnapshot = await getDocs(collection(db, 'payments'));
    return querySnapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      date: doc.data().date?.toDate ? doc.data().date.toDate() : new Date(),
    }));
  } catch (error) {
    console.error('Error fetching payments:', error);
    throw error;
  }
};

/**
 * Get a single payment by ID
 * @param {string} paymentId - The ID of the payment to fetch
 * @returns {Promise<Object|null>} Payment object or null if not found
 */
export const getPayment = async (paymentId) => {
  try {
    const paymentRef = doc(db, 'payments', paymentId);
    const paymentSnap = await getDoc(paymentRef);
    if (paymentSnap.exists()) {
      return {
        id: paymentSnap.id,
        ...paymentSnap.data(),
        date: paymentSnap.data().date?.toDate ? paymentSnap.data().date.toDate() : new Date(),
      };
    }
    return null;
  } catch (error) {
    console.error(`Error fetching payment ${paymentId}:`, error);
    throw error;
  }
};

/**
 * Process a refund for a payment
 * @param {string} paymentId - The ID of the payment to refund
 * @param {Object} refundData - Data related to the refund (e.g., amount, reason)
 * @returns {Promise<Object>} Updated payment object
 */
export const processRefund = async (paymentId, refundData) => {
  try {
    const paymentRef = doc(db, 'payments', paymentId);
    const updatedData = {
      status: 'refunded',
      refundAmount: refundData.amount || 0,
      refundReason: refundData.reason || 'Customer request',
      refundDate: new Date(),
    };
    await updateDoc(paymentRef, updatedData);
    return { id: paymentId, ...updatedData };
  } catch (error) {
    console.error(`Error processing refund for payment ${paymentId}:`, error);
    throw error;
  }
};
