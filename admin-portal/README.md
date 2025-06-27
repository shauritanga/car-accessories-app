# Car Accessories Admin Portal

A comprehensive, professional admin web portal built with React.js and React Query for managing your car accessories e-commerce platform.

## 🚀 Features

### ✅ **Authentication System**
- Secure admin-only login (no registration)
- Firebase Authentication integration
- Protected routes with role-based access
- Password reset functionality

### ✅ **Dashboard Overview**
- Real-time analytics and key metrics
- Revenue and order charts
- Top-selling products
- Recent orders overview
- Interactive data visualization

### ✅ **Product Management**
- Complete CRUD operations
- Bulk actions (update, delete, activate/deactivate)
- Image upload with Firebase Storage
- Advanced filtering and search
- Inventory tracking
- Product categories and specifications

### ✅ **Order Management**
- Order tracking and status updates
- Customer information management
- Payment status monitoring
- Order analytics and reporting
- Bulk status updates

### ✅ **User Management**
- Customer and seller management
- User role administration
- Activity tracking
- Account status management

### ✅ **Analytics & Reports**
- Sales analytics
- Revenue tracking
- Customer insights
- Product performance metrics
- Exportable reports

### ✅ **Settings & Configuration**
- System settings
- App configuration
- Admin preferences
- Notification settings

## 🛠️ Technology Stack

- **Frontend**: React 18, Material-UI 5
- **State Management**: React Query (TanStack Query)
- **Routing**: React Router v6
- **Forms**: React Hook Form + Yup validation
- **Charts**: Recharts
- **Animations**: Framer Motion
- **Backend**: Firebase (Firestore, Auth, Storage)
- **Styling**: Material-UI with custom theming

## 📦 Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd admin-portal
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Authentication, Firestore, and Storage
   - Copy your Firebase config to `src/config/firebase.js`

4. **Set up Firestore Security Rules**
   ```javascript
   // Firestore Rules
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Admin users only
       match /{document=**} {
         allow read, write: if request.auth != null && 
           get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
       }
     }
   }
   ```

5. **Create an admin user**
   - Go to Firebase Console > Authentication
   - Add a user with admin email
   - In Firestore, create a document in `users` collection:
   ```javascript
   {
     email: "admin@example.com",
     role: "admin",
     name: "Admin User",
     createdAt: new Date()
   }
   ```

6. **Start the development server**
   ```bash
   npm start
   ```

## 🔧 Configuration

### Firebase Setup

Update `src/config/firebase.js` with your Firebase configuration:

```javascript
const firebaseConfig = {
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};
```

### Environment Variables

Create a `.env` file in the root directory:

```env
REACT_APP_FIREBASE_API_KEY=your-api-key
REACT_APP_FIREBASE_AUTH_DOMAIN=your-project.firebaseapp.com
REACT_APP_FIREBASE_PROJECT_ID=your-project-id
REACT_APP_FIREBASE_STORAGE_BUCKET=your-project.appspot.com
REACT_APP_FIREBASE_MESSAGING_SENDER_ID=123456789
REACT_APP_FIREBASE_APP_ID=your-app-id
```

## 📱 Usage

### Login
- Navigate to `/login`
- Enter admin credentials
- Only users with `role: "admin"` can access the portal

### Dashboard
- View key metrics and analytics
- Monitor recent orders and top products
- Track revenue and performance

### Product Management
- Add, edit, and delete products
- Upload multiple product images
- Manage inventory and categories
- Bulk operations for efficiency

### Order Management
- Track order status and updates
- Manage customer information
- Process payments and shipments
- Generate reports

## 🎨 Customization

### Theming
Customize the Material-UI theme in `src/index.js`:

```javascript
const theme = createTheme({
  palette: {
    primary: {
      main: '#1976d2', // Your brand color
    },
    secondary: {
      main: '#dc004e',
    },
  },
});
```

### Adding New Features
1. Create new components in `src/components/`
2. Add new pages in `src/pages/`
3. Create services in `src/services/`
4. Update routing in `src/App.js`

## 📊 Data Structure

### Products Collection
```javascript
{
  name: string,
  description: string,
  price: number,
  category: string,
  stock: number,
  images: string[],
  isActive: boolean,
  createdAt: timestamp,
  updatedAt: timestamp
}
```

### Orders Collection
```javascript
{
  customerName: string,
  customerEmail: string,
  items: array,
  total: number,
  status: string,
  paymentStatus: string,
  shippingAddress: object,
  createdAt: timestamp,
  statusHistory: array
}
```

### Users Collection
```javascript
{
  email: string,
  name: string,
  role: string, // 'admin', 'customer', 'seller'
  createdAt: timestamp,
  isActive: boolean
}
```

## 🚀 Deployment

### Build for Production
```bash
npm run build
```

### Deploy to Firebase Hosting
```bash
npm install -g firebase-tools
firebase login
firebase init hosting
firebase deploy
```

### Deploy to Netlify
1. Build the project: `npm run build`
2. Drag and drop the `build` folder to Netlify
3. Configure redirects for React Router

## 🔒 Security

- Admin-only access with Firebase Auth
- Role-based permissions
- Secure API endpoints
- Input validation and sanitization
- Protected routes and components

## 📈 Performance

- Code splitting with React.lazy()
- Image optimization
- Efficient data fetching with React Query
- Memoized components
- Lazy loading for large datasets

## 🐛 Troubleshooting

### Common Issues

1. **Firebase connection errors**
   - Check your Firebase config
   - Ensure Firestore rules allow admin access

2. **Authentication issues**
   - Verify admin user exists in Firestore
   - Check user role is set to 'admin'

3. **Build errors**
   - Clear node_modules and reinstall
   - Check for missing dependencies

## 📞 Support

For support and questions:
- Check the documentation
- Review Firebase console for errors
- Ensure all dependencies are up to date

## 📄 License

This project is licensed under the MIT License.

---

**Built with ❤️ for Car Accessories E-commerce Platform**
