import { createContext, useContext, useState, useEffect } from 'react';
import { 
  checkAdminAuth, 
  loginAdmin, 
  logoutAdmin, 
  updateCurrentUser, 
  updateUserPassword,
  uploadProfileImage 
} from '../api/auth';

const AuthContext = createContext();

export const useAuth = () => useContext(AuthContext);

export const AuthProvider = ({ children }) => {
  const [auth, setAuth] = useState({
    isAuthenticated: false,
    user: null,
    loading: true,
    error: null
  });

  useEffect(() => {
    const checkAuth = () => {
      try {
        const { isAuthenticated, user } = checkAdminAuth();
        setAuth({
          isAuthenticated,
          user,
          loading: false,
          error: null
        });
      } catch (error) {
        setAuth({
          isAuthenticated: false,
          user: null,
          loading: false,
          error: 'Authentication check failed'
        });
      }
    };

    checkAuth();
  }, []);

  const login = async (credentials) => {
    try {
      setAuth(prev => ({ ...prev, loading: true, error: null }));
      const result = await loginAdmin(credentials);
      setAuth({
        isAuthenticated: true,
        user: result.user,
        loading: false,
        error: null
      });
      return result;
    } catch (error) {
      setAuth(prev => ({
        ...prev,
        isAuthenticated: false,
        loading: false,
        error: error.message || 'Login failed'
      }));
      throw error;
    }
  };

  const logout = () => {
    logoutAdmin();
    setAuth({
      isAuthenticated: false,
      user: null,
      loading: false,
      error: null
    });
  };
  
  const updateUserProfile = async (profileData) => {
    try {
      setAuth(prev => ({ ...prev, loading: true, error: null }));
      
      // Call the updateCurrentUser function from the auth API
      const { user: updatedUser } = await updateCurrentUser({
        name: profileData.name,
        email: profileData.email,
        bio: profileData.bio,
      });
      
      setAuth(prev => ({
        ...prev,
        user: updatedUser,
        loading: false
      }));
      
      return updatedUser;
    } catch (error) {
      setAuth(prev => ({
        ...prev,
        loading: false,
        error: error.message || 'Failed to update profile'
      }));
      throw error;
    }
  };

  const changePassword = async (passwordData) => {
    try {
      setAuth(prev => ({ ...prev, loading: true, error: null }));
      
      // Call the updateUserPassword function from the auth API
      await updateUserPassword({
        currentPassword: passwordData.currentPassword,
        newPassword: passwordData.newPassword,
      });
      
      setAuth(prev => ({
        ...prev,
        loading: false
      }));
      
      return true;
    } catch (error) {
      setAuth(prev => ({
        ...prev,
        loading: false,
        error: error.message || 'Failed to update password'
      }));
      throw error;
    }
  };

  const updateProfileImage = async (imageFile) => {
    try {
      setAuth(prev => ({ ...prev, loading: true, error: null }));
      
      // Call the uploadProfileImage function from the auth API
      const result = await uploadProfileImage(imageFile);
      
      // Update the user in the state with the new profile image
      setAuth(prev => ({
        ...prev,
        user: { ...prev.user, profileImage: result.profileImage },
        loading: false
      }));
      
      return result;
    } catch (error) {
      setAuth(prev => ({
        ...prev,
        loading: false,
        error: error.message || 'Failed to upload profile image'
      }));
      throw error;
    }
  };

  const clearError = () => {
    setAuth(prev => ({ ...prev, error: null }));
  };

  const value = {
    ...auth,
    login,
    logout,
    updateUserProfile,
    changePassword,
    updateProfileImage,
    clearError
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export default AuthContext; 