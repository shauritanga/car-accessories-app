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
import ContentManagement from './pages/ContentManagement/ContentManagement';
import FeedbackReviews from './pages/FeedbackReviews/FeedbackReviews';
import PaymentOversight from './pages/PaymentOversight/PaymentOversight';
import LoadingScreen from './components/LoadingScreen/LoadingScreen';

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
                  <Route path="/feedback-reviews/*" element={<FeedbackReviews />} />
                  <Route path="/settings/*" element={<Settings />} />
                  <Route path="/content-management/*" element={<ContentManagement />} />
                  <Route path="/payment-oversight/*" element={<PaymentOversight />} />
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
