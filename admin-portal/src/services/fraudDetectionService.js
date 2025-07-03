import { collection, addDoc, getDocs, query, where, orderBy, limit, Timestamp } from 'firebase/firestore';
import { db } from '../config/firebase';
import toast from 'react-hot-toast';

// Collection name for activity logs
const ACTIVITY_LOG_COLLECTION = 'activityLogs';
const FRAUD_ALERTS_COLLECTION = 'fraudAlerts';

// Log user activity
export const logUserActivity = async (userId, action, details = {}) => {
  try {
    const activity = {
      userId,
      action,
      details: JSON.stringify(details),
      timestamp: Timestamp.fromDate(new Date()),
      ipAddress: details.ipAddress || 'unknown',
      userAgent: details.userAgent || 'unknown'
    };
    await addDoc(collection(db, ACTIVITY_LOG_COLLECTION), activity);
    console.log(`Logged activity: ${action} for user ${userId}`);
    // Check for anomalies after logging activity
    checkForAnomalies(userId, action, details);
  } catch (error) {
    console.error('Error logging user activity:', error);
  }
};

// Check for anomalies in user behavior
export const checkForAnomalies = async (userId, action, details) => {
  try {
    // Define rules for anomaly detection
    if (action === 'login_failed') {
      // Check for multiple failed login attempts
      const now = new Date();
      const tenMinutesAgo = new Date(now.getTime() - 10 * 60 * 1000);
      const failedLoginsQuery = query(
        collection(db, ACTIVITY_LOG_COLLECTION),
        where('userId', '==', userId),
        where('action', '==', 'login_failed'),
        where('timestamp', '>=', Timestamp.fromDate(tenMinutesAgo)),
        orderBy('timestamp', 'desc')
      );
      const failedLoginsSnapshot = await getDocs(failedLoginsQuery);
      if (failedLoginsSnapshot.docs.length >= 5) {
        // Flag as potential brute force attack
        const alertDetails = {
          type: 'brute_force_attempt',
          message: `Multiple failed login attempts detected for user ${userId}. Count: ${failedLoginsSnapshot.docs.length}`,
          severity: 'high',
          timestamp: Timestamp.fromDate(new Date()),
          userId
        };
        await raiseFraudAlert(alertDetails);
        return alertDetails;
      }
    } else if (action === 'order_modification' && details.orderValue) {
      // Check for unusually high order value modifications
      if (details.orderValue > 1000000) { // Threshold for suspicious order value (1M TZS)
        const alertDetails = {
          type: 'suspicious_order_value',
          message: `Unusually high order value modification detected for user ${userId}. Value: ${details.orderValue}`,
          severity: 'medium',
          timestamp: Timestamp.fromDate(new Date()),
          userId
        };
        await raiseFraudAlert(alertDetails);
        return alertDetails;
      }
    } else if (action === 'ip_change') {
      // Check for frequent IP changes
      const now = new Date();
      const oneHourAgo = new Date(now.getTime() - 60 * 60 * 1000);
      const ipChangesQuery = query(
        collection(db, ACTIVITY_LOG_COLLECTION),
        where('userId', '==', userId),
        where('action', '==', 'ip_change'),
        where('timestamp', '>=', Timestamp.fromDate(oneHourAgo)),
        orderBy('timestamp', 'desc')
      );
      const ipChangesSnapshot = await getDocs(ipChangesQuery);
      if (ipChangesSnapshot.docs.length >= 3) {
        const alertDetails = {
          type: 'frequent_ip_change',
          message: `Frequent IP changes detected for user ${userId}. Count: ${ipChangesSnapshot.docs.length} in last hour`,
          severity: 'medium',
          timestamp: Timestamp.fromDate(new Date()),
          userId
        };
        await raiseFraudAlert(alertDetails);
        return alertDetails;
      }
    }
    return null;
  } catch (error) {
    console.error('Error checking for anomalies:', error);
    return null;
  }
};

// Raise a fraud alert
export const raiseFraudAlert = async (alertDetails) => {
  try {
    await addDoc(collection(db, FRAUD_ALERTS_COLLECTION), alertDetails);
    console.log(`Fraud alert raised: ${alertDetails.type} for user ${alertDetails.userId}`);
    // TODO: Integrate with notification system to alert admins
    toast.error(`Fraud Alert: ${alertDetails.message}`);
  } catch (error) {
    console.error('Error raising fraud alert:', error);
  }
};

// Get recent fraud alerts
export const getRecentFraudAlerts = async (limitCount = 5) => {
  try {
    const alertsSnapshot = await getDocs(
      query(
        collection(db, FRAUD_ALERTS_COLLECTION),
        orderBy('timestamp', 'desc'),
        limit(limitCount)
      )
    );
    return alertsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        type: data.type,
        message: data.message,
        severity: data.severity,
        timestamp: data.timestamp?.toDate() || new Date(),
        userId: data.userId
      };
    });
  } catch (error) {
    console.error('Error fetching recent fraud alerts:', error);
    // Return mock data on error
    return [
      {
        id: '1',
        type: 'brute_force_attempt',
        message: 'Multiple failed login attempts detected for user XYZ123',
        severity: 'high',
        timestamp: new Date(),
        userId: 'XYZ123'
      },
      {
        id: '2',
        type: 'suspicious_order_value',
        message: 'Unusually high order value modification detected. Value: 2500000',
        severity: 'medium',
        timestamp: new Date(Date.now() - 86400000),
        userId: 'ABC456'
      }
    ];
  }
};

// Get activity logs for a specific user
export const getUserActivityLogs = async (userId, limitCount = 10) => {
  try {
    const logsSnapshot = await getDocs(
      query(
        collection(db, ACTIVITY_LOG_COLLECTION),
        where('userId', '==', userId),
        orderBy('timestamp', 'desc'),
        limit(limitCount)
      )
    );
    return logsSnapshot.docs.map(doc => {
      const data = doc.data();
      return {
        id: doc.id,
        action: data.action,
        details: data.details ? JSON.parse(data.details) : {},
        timestamp: data.timestamp?.toDate() || new Date(),
        ipAddress: data.ipAddress,
        userAgent: data.userAgent
      };
    });
  } catch (error) {
    console.error(`Error fetching activity logs for user ${userId}:`, error);
    return [];
  }
};
