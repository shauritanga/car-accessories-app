import { initializeApp } from 'firebase/app';
import { getAuth } from 'firebase/auth';
import { getFirestore } from 'firebase/firestore';
import { getStorage } from 'firebase/storage';

const firebaseConfig = {
  apiKey: "AIzaSyCxXTS1V8B3ryj3DNVWkgjhU6vckAoDy78",
  authDomain: "car-accessories-thy.firebaseapp.com",
  projectId: "car-accessories-thy",
  storageBucket: "car-accessories-thy.firebasestorage.app",
  messagingSenderId: "518343099919",
  appId: "1:518343099919:web:c8996c42081efef533c57a"
};


// Initialize Firebase
const app = initializeApp(firebaseConfig);

// Initialize Firebase services
export const auth = getAuth(app);
export const db = getFirestore(app);
export const storage = getStorage(app);

export default app;
