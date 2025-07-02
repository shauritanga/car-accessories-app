// Admin Portal Sidebar Navigation
import React from 'react';
import { Link } from 'react-router-dom';

const Sidebar = () => (
  <nav className="sidebar">
    <ul>
      <li><Link to="/user-management">User Management</Link></li>
      <li><Link to="/product-management">Product Management</Link></li>
      <li><Link to="/order-management">Order Management</Link></li>
      <li><Link to="/feedback-reviews">Feedback & Reviews</Link></li>
      <li><Link to="/analytics-reports">Analytics & Reports</Link></li>
      <li><Link to="/content-management">Content Management</Link></li>
      <li><Link to="/security-access">Security & Access Control</Link></li>
      <li><Link to="/payment-oversight">Payment Oversight</Link></li>
    </ul>
  </nav>
);

export default Sidebar;
