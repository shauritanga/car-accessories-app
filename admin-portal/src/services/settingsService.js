import { getFirestore, doc, getDoc, setDoc } from 'firebase/firestore';
import { app } from '../../firebase';

const db = getFirestore(app);
const CONFIG_DOC_PATH = 'appConfig/config';

export const getSettings = async () => {
    const configRef = doc(db, CONFIG_DOC_PATH);
    const snap = await getDoc(configRef);
    if (snap.exists()) {
        return snap.data();
    } else {
        // Return default settings if not set
        return {
            appName: 'Car Accessories Store',
            appVersion: '1.0.0',
            defaultLanguage: 'en',
            timezone: 'Africa/Dar_es_Salaam',
            taxRate: 18,
            shippingCost: 5000,
            freeShippingThreshold: 100000,
            orderProcessingTime: '1-2',
            featureToggles: {
                reviews: true,
                wishlist: true,
                liveChat: false,
                pushNotifications: true,
                orderTracking: true,
                loyalty: false
            },
            apiKeys: {
                paymentGateway: '',
                smsService: ''
            }
        };
    }
};

export const saveSettings = async (settings) => {
    const configRef = doc(db, CONFIG_DOC_PATH);
    await setDoc(configRef, settings, { merge: true });
    return { success: true };
}; 