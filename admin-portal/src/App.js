import React from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './contexts/AuthContext';
import Layout from './components/Layout/Layout';
import Login from './pages/Login/Login';
import Dashboard from './pages/Dashboard/Dashboard';
import Products from './pages/Products/Products';
import Orders from './pages/Orders/Orders';
import Users from './pages/Users/Users';
import Analytics from './pages/Analytics/Analytics';
import Settings from './pages/Settings/Settings';
import LoadingScreen from './components/LoadingScreen/LoadingScreen';
import AdminUserManagementPage from './pages/admin/UserManagementPage';
import AdminProductManagementPage from './pages/admin/ProductManagementPage';
import AdminOrderManagementPage from './pages/admin/OrderManagementPage';
import AdminFeedbackReviewsPage from './pages/admin/FeedbackReviewsPage';
import AdminAnalyticsReportsPage from './pages/admin/AnalyticsReportsPage';
import AdminContentManagementPage from './pages/admin/ContentManagementPage';
import AdminSecurityAccessPage from './pages/admin/SecurityAccessPage';
import AdminPaymentOversightPage from './pages/admin/PaymentOversightPage';

// Protected Route Component
const ProtectedRoute = ({ children }) => {
  const { currentUser } = useAuth();
  return currentUser ? children : <Navigate to="/login" />;
};

// Public Route Component (redirect if authenticated)
const PublicRoute = ({ children }) => {
  const { currentUser } = useAuth();
  return !currentUser ? children : <Navigate to="/dashboard" />;
};

function App() {
  const { loading } = useAuth();

  if (loading) {
    return <LoadingScreen />;
  }

  return (
    <div className="App">
      <Routes>
        {/* Public Routes */}
        <Route 
          path="/login" 
          element={
            <PublicRoute>
              <Login />
            </PublicRoute>
          } 
        />

        {/* Protected Routes */}
        <Route 
          path="/*" 
          element={
            <ProtectedRoute>
              <Layout>
                <Routes>
                  <Route path="/dashboard" element={<Dashboard />} />
                  <Route path="/products/*" element={<Products />} />
                  <Route path="/orders/*" element={<Orders />} />
                  <Route path="/users/*" element={<Users />} />
                  <Route path="/analytics" element={<Analytics />} />
                  <Route path="/settings/*" element={<Settings />} />
                  {/* Admin Portal Features */}
                  <Route path="/admin/user-management" element={<AdminUserManagementPage />} />
                  <Route path="/admin/product-management" element={<AdminProductManagementPage />} />
                  <Route path="/admin/order-management" element={<AdminOrderManagementPage />} />
                  <Route path="/admin/feedback-reviews" element={<AdminFeedbackReviewsPage />} />
                  <Route path="/admin/analytics-reports" element={<AdminAnalyticsReportsPage />} />
                  <Route path="/admin/content-management" element={<AdminContentManagementPage />} />
                  <Route path="/admin/security-access" element={<AdminSecurityAccessPage />} />
                  <Route path="/admin/payment-oversight" element={<AdminPaymentOversightPage />} />
                  <Route path="/" element={<Navigate to="/dashboard" />} />
                </Routes>
              </Layout>
            </ProtectedRoute>
          } 
        />
      </Routes>
    </div>
  );
}

export default App;
