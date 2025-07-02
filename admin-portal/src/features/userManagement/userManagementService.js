// User Management Service
// Implement API calls for user management here
// Example: Replace with real API endpoints
const API_BASE = '/api/admin';

export const getPendingSellers = async () => {
  // Fetch pending seller registrations
  const res = await fetch(`${API_BASE}/sellers/pending`);
  if (!res.ok) throw new Error('Failed to fetch pending sellers');
  return res.json();
};

export const updateUserStatus = async (userId, status) => {
  // Activate, deactivate, or suspend user
  const res = await fetch(`${API_BASE}/users/${userId}/status`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ status }),
  });
  if (!res.ok) throw new Error('Failed to update user status');
  return res.json();
};

export const getUserProfiles = async () => {
  // Fetch user profiles and activities
  const res = await fetch(`${API_BASE}/users/profiles`);
  if (!res.ok) throw new Error('Failed to fetch user profiles');
  return res.json();
};
