import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyDIqRL1JUfHzrjNKAC4vwPna4Rs0iEtgYg",
  authDomain: "car-accessory-dit.firebaseapp.com",
  projectId: "car-accessory-dit",
  storageBucket: "car-accessory-dit.firebasestorage.app",
  messagingSenderId: "910206601075",
  appId: "1:910206601075:web:f1e89fed2864dd9d6fa706"
};


// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export default app;
