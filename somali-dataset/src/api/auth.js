import axios from 'axios';

// Make sure this URL matches your backend server
// For local development typically http://localhost:3000/api
// For Android emulator use http://10.0.2.2:3000/api
const API_URL = 'http://localhost:3000/api';

console.log('API client initialized with URL:', API_URL);

// Create axios instance with base config
const api = axios.create({
  baseURL: API_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add interceptor to include auth token in requests
api.interceptors.request.use(
  (config) => {
    const token = localStorage.getItem('admin_token');
    if (token) {
      config.headers['Authorization'] = `Bearer ${token}`;
    }
    return config;
  },
  (error) => Promise.reject(error)
);

// Auth APIs
export const loginAdmin = async (credentials) => {
  try {
    console.log('Attempting admin login with:', credentials.email);
    
    const response = await api.post('/users/login', credentials);
    console.log('Login response:', response.data);
    
    // Check if response contains token and user data
    if (!response.data.token || !response.data.user) {
      throw new Error('Invalid server response: missing token or user data');
    }
    
    // Verify if user is an admin
    if (response.data.user.role !== 'admin') {
      console.error('Non-admin user attempted to log in:', response.data.user);
      throw new Error('Unauthorized: Admin access only');
    }
    
    console.log('Admin login successful for user:', response.data.user.email);
    
    // Store token and user info in localStorage
    localStorage.setItem('admin_token', response.data.token);
    localStorage.setItem('admin_user', JSON.stringify({
      _id: response.data.user._id,
      name: response.data.user.name,
      email: response.data.user.email,
      role: response.data.user.role,
      profileImage: response.data.user.profileImage,
    }));
    
    return response.data;
  } catch (error) {
    console.error('Login error:', error);
    if (error.response) {
      console.error('Server response:', error.response.data);
      throw error.response.data?.error || error.response.data || 'Server error during login';
    }
    throw error.message || 'Login failed';
  }
};

export const logoutAdmin = () => {
  localStorage.removeItem('admin_token');
  localStorage.removeItem('admin_user');
};

export const checkAdminAuth = () => {
  const token = localStorage.getItem('admin_token');
  const user = JSON.parse(localStorage.getItem('admin_user') || '{}');
  return { isAuthenticated: !!token && user.role === 'admin', user };
};

// User Management APIs
export const getAllUsers = async () => {
  try {
    const response = await api.get('/users/all');
    return response.data.users || [];
  } catch (error) {
    console.error('Failed to fetch users:', error);
    // Return empty array instead of throwing error to prevent dashboard from breaking
    return [];
  }
};

export const getUserById = async (userId) => {
  try {
    const response = await api.get(`/users/${userId}`);
    return response.data.user;
  } catch (error) {
    throw error.response?.data || error.message || 'Failed to fetch user';
  }
};

export const updateUser = async (userId, userData) => {
  try {
    console.log(`Updating user with ID: ${userId}`, userData);
    const response = await api.put(`/users/${userId}`, userData);
    return response.data.user;
  } catch (error) {
    console.error('Error updating user:', error);
    console.error('Error details:', error.response?.data);
    throw error.response?.data?.error || error.message || 'Failed to update user';
  }
};

export const updateCurrentUser = async (userData) => {
  try {
    // Get the current user from localStorage
    const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
    
    if (!currentUser || !currentUser._id) {
      throw new Error('User not found');
    }
    
    // Call the API to update the user
    const response = await api.put(`/users/${currentUser._id}`, userData);
    
    // Update localStorage with the updated user data
    localStorage.setItem('admin_user', JSON.stringify(response.data.user));
    
    return response.data;
  } catch (error) {
    throw error.response?.data || error.message || 'Failed to update profile';
  }
};

export const updateUserPassword = async (passwordData) => {
  try {
    // Get the current user from localStorage
    const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
    
    if (!currentUser || !currentUser._id) {
      throw new Error('User not found');
    }
    
    // Call the API to update the password
    const response = await api.put(`/users/${currentUser._id}/password`, passwordData);
    return response.data;
  } catch (error) {
    throw error.response?.data?.error || error.message || 'Failed to update password';
  }
};

export const uploadProfileImage = async (imageFile) => {
  try {
    // Get the current user from localStorage
    const currentUser = JSON.parse(localStorage.getItem('admin_user') || '{}');
    
    if (!currentUser || !currentUser._id) {
      throw new Error('User not found');
    }
    
    // Create form data to send the image
    const formData = new FormData();
    formData.append('profileImage', imageFile);
    
    // Create a custom config for the multipart/form-data
    const config = {
      headers: {
        'Content-Type': 'multipart/form-data',
        'Authorization': `Bearer ${localStorage.getItem('admin_token')}`
      }
    };
    
    // Call the API to upload the image
    const response = await axios.post(
      `${API_URL}/users/${currentUser._id}/profile-image`, 
      formData,
      config
    );
    
    // Update localStorage with the updated user data including the new image path
    const updatedUser = { ...currentUser, profileImage: response.data.profileImage };
    localStorage.setItem('admin_user', JSON.stringify(updatedUser));
    
    return response.data;
  } catch (error) {
    console.error('Error uploading profile image:', error);
    if (error.response) {
      console.error('Server response:', error.response.data);
      throw error.response.data?.error || error.response.data || 'Server error during upload';
    }
    throw error.message || 'Failed to upload profile image';
  }
};

export const deleteUser = async (userId) => {
  try {
    console.log(`Deleting user with ID: ${userId}`);
    const response = await api.delete(`/users/${userId}`);
    return response.data;
  } catch (error) {
    console.error('Error deleting user:', error);
    console.error('Error details:', error.response?.data);
    throw error.response?.data?.error || error.message || 'Failed to delete user';
  }
};

export default api; 