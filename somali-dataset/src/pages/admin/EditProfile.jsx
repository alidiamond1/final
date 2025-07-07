import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Grid,
  Avatar,
  Divider,
  Alert,
  CircularProgress,
  IconButton,
  InputAdornment,
} from '@mui/material';
import {
  Save as SaveIcon,
  Person as PersonIcon,
  Email as EmailIcon,
  Lock as LockIcon,
  Visibility as VisibilityIcon,
  VisibilityOff as VisibilityOffIcon,
  PhotoCamera as PhotoCameraIcon,
} from '@mui/icons-material';
import { themeColors } from '../../theme';
import { useAuth } from '../../context/AuthContext';
import defaultProfileImage from '../../assets/profile.jpg';

const API_URL = 'http://localhost:3000';

const EditProfile = () => {
  const { user, updateUserProfile, changePassword, updateProfileImage } = useAuth();
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);
  
  const [profileData, setProfileData] = useState({
    name: '',
    email: '',
    bio: '',
    currentPassword: '',
    newPassword: '',
    confirmPassword: '',
  });
  
  const [showPassword, setShowPassword] = useState({
    current: false,
    new: false,
    confirm: false
  });
  
  const [selectedImage, setSelectedImage] = useState(null);
  const [previewImage, setPreviewImage] = useState(null);
  const [imageUploading, setImageUploading] = useState(false);
  
  useEffect(() => {
    if (user) {
      setProfileData(prev => ({
        ...prev,
        name: user.name || '',
        email: user.email || '',
        bio: user.bio || '',
      }));
      
      // If user has a profile image, use it
      if (user.profileImage) {
        setPreviewImage(`${API_URL}/${user.profileImage}`);
      }
    }
  }, [user]);
  
  const handleChange = (e) => {
    const { name, value } = e.target;
    setProfileData(prev => ({ ...prev, [name]: value }));
  };
  
  const handleImageChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setSelectedImage(file);
      
      // Create preview
      const reader = new FileReader();
      reader.onloadend = () => {
        setPreviewImage(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };
  
  const handleImageUpload = async () => {
    if (!selectedImage) return;
    
    try {
      setImageUploading(true);
      setError(null);
      
      const result = await updateProfileImage(selectedImage);
      
      // The backend now returns the full user object.
      // We need to access the profileImage from the user property.
      if (result && result.user && result.user.profileImage) {
        setPreviewImage(`${API_URL}/${result.user.profileImage}`);
      }
      
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
      
      // Clear selected image since it's now uploaded
      setSelectedImage(null);
    } catch (err) {
      console.error('Failed to upload image:', err);
      setError(err.message || 'Failed to upload profile image');
    } finally {
      setImageUploading(false);
    }
  };
  
  const togglePasswordVisibility = (field) => {
    setShowPassword(prev => ({
      ...prev,
      [field]: !prev[field]
    }));
  };
  
  const validateForm = () => {
    // Password validation
    if (profileData.newPassword && profileData.newPassword.length < 6) {
      setError('New password must be at least 6 characters long');
      return false;
    }
    
    if (profileData.newPassword && profileData.newPassword !== profileData.confirmPassword) {
      setError('New password and confirmation do not match');
      return false;
    }
    
    // If changing password, current password is required
    if (profileData.newPassword && !profileData.currentPassword) {
      setError('Current password is required to set a new password');
      return false;
    }
    
    return true;
  };
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    setError(null);
    
    if (!validateForm()) {
      return;
    }
    
    setLoading(true);
    
    try {
      // Update profile information
      await updateUserProfile({
        name: profileData.name,
        email: profileData.email,
        bio: profileData.bio,
      });
      
      // If password fields are filled, update password
      if (profileData.newPassword && profileData.currentPassword) {
        await changePassword({
          currentPassword: profileData.currentPassword,
          newPassword: profileData.newPassword,
        });
      }
      
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
      
      // Clear password fields after successful update
      setProfileData(prev => ({
        ...prev,
        currentPassword: '',
        newPassword: '',
        confirmPassword: '',
      }));
    } catch (err) {
      console.error('Failed to update profile:', err);
      setError(err.message || 'Failed to update profile');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <Box>
      <Typography variant="h2" fontWeight="bold" color={themeColors.grey[900]} mb={3}>
        Edit Profile
      </Typography>
      
      {success && (
        <Alert 
          severity="success" 
          sx={{ mb: 3 }}
          onClose={() => setSuccess(false)}
        >
          Profile updated successfully!
        </Alert>
      )}
      
      {error && (
        <Alert 
          severity="error" 
          sx={{ mb: 3 }}
          onClose={() => setError(null)}
        >
          {error}
        </Alert>
      )}
      
      <form onSubmit={handleSubmit}>
        <Grid container spacing={3}>
          {/* Profile Image */}
          <Grid item xs={12} md={4}>
            <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
              <Box display="flex" alignItems="center" mb={3}>
                <PersonIcon sx={{ color: themeColors.primary[500], mr: 1.5 }} />
                <Typography variant="h4" fontWeight="medium">
                  Profile Image
                </Typography>
              </Box>
              
              <Divider sx={{ mb: 3 }} />
              
              <Box display="flex" flexDirection="column" alignItems="center">
                <Avatar
                  src={previewImage || defaultProfileImage}
                  sx={{
                    width: 150,
                    height: 150,
                    mb: 2,
                    border: `4px solid ${themeColors.primary[500]}`,
                  }}
                />
                
                <input
                  accept="image/*"
                  style={{ display: 'none' }}
                  id="profile-image-upload"
                  type="file"
                  onChange={handleImageChange}
                />
                <label htmlFor="profile-image-upload">
                  <Button
                    variant="outlined"
                    component="span"
                    startIcon={<PhotoCameraIcon />}
                    sx={{
                      borderRadius: 2,
                      textTransform: 'none',
                      mb: 2
                    }}
                  >
                    Select Photo
                  </Button>
                </label>
                
                {selectedImage && (
                  <Button
                    variant="contained"
                    onClick={handleImageUpload}
                    disabled={imageUploading}
                    startIcon={imageUploading ? <CircularProgress size={24} color="inherit" /> : <SaveIcon />}
                    sx={{
                      borderRadius: 2,
                      textTransform: 'none',
                      mb: 2,
                      backgroundColor: themeColors.primary[500],
                      '&:hover': {
                        backgroundColor: themeColors.primary[600],
                      },
                    }}
                  >
                    {imageUploading ? 'Uploading...' : 'Upload Photo'}
                  </Button>
                )}
                
                <Typography variant="body2" color={themeColors.grey[600]} mt={1} textAlign="center">
                  Recommended: Square image, at least 300x300 pixels
                </Typography>
              </Box>
            </Paper>
          </Grid>
          
          {/* Personal Information */}
          <Grid item xs={12} md={8}>
            <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
              <Box display="flex" alignItems="center" mb={3}>
                <PersonIcon sx={{ color: themeColors.primary[500], mr: 1.5 }} />
                <Typography variant="h4" fontWeight="medium">
                  Personal Information
                </Typography>
              </Box>
              
              <Divider sx={{ mb: 3 }} />
              
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Full Name"
                    name="name"
                    value={profileData.name}
                    onChange={handleChange}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <PersonIcon sx={{ color: themeColors.grey[500] }} />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
                
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Email Address"
                    name="email"
                    type="email"
                    value={profileData.email}
                    onChange={handleChange}
                    InputProps={{
                      startAdornment: (
                        <InputAdornment position="start">
                          <EmailIcon sx={{ color: themeColors.grey[500] }} />
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
                
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Bio"
                    name="bio"
                    value={profileData.bio}
                    onChange={handleChange}
                    multiline
                    rows={3}
                    placeholder="Tell us about yourself"
                  />
                </Grid>
              </Grid>
            </Paper>
          </Grid>
          
          {/* Change Password */}
          <Grid item xs={12}>
            <Paper sx={{ p: 3, borderRadius: 3 }}>
              <Box display="flex" alignItems="center" mb={3}>
                <LockIcon sx={{ color: themeColors.primary[500], mr: 1.5 }} />
                <Typography variant="h4" fontWeight="medium">
                  Change Password
                </Typography>
              </Box>
              
              <Divider sx={{ mb: 3 }} />
              
              <Grid container spacing={2}>
                <Grid item xs={12} md={4}>
                  <TextField
                    fullWidth
                    label="Current Password"
                    name="currentPassword"
                    type={showPassword.current ? 'text' : 'password'}
                    value={profileData.currentPassword}
                    onChange={handleChange}
                    InputProps={{
                      endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                            onClick={() => togglePasswordVisibility('current')}
                            edge="end"
                          >
                            {showPassword.current ? <VisibilityOffIcon /> : <VisibilityIcon />}
                          </IconButton>
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
                
                <Grid item xs={12} md={4}>
                  <TextField
                    fullWidth
                    label="New Password"
                    name="newPassword"
                    type={showPassword.new ? 'text' : 'password'}
                    value={profileData.newPassword}
                    onChange={handleChange}
                    InputProps={{
                      endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                            onClick={() => togglePasswordVisibility('new')}
                            edge="end"
                          >
                            {showPassword.new ? <VisibilityOffIcon /> : <VisibilityIcon />}
                          </IconButton>
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
                
                <Grid item xs={12} md={4}>
                  <TextField
                    fullWidth
                    label="Confirm New Password"
                    name="confirmPassword"
                    type={showPassword.confirm ? 'text' : 'password'}
                    value={profileData.confirmPassword}
                    onChange={handleChange}
                    InputProps={{
                      endAdornment: (
                        <InputAdornment position="end">
                          <IconButton
                            onClick={() => togglePasswordVisibility('confirm')}
                            edge="end"
                          >
                            {showPassword.confirm ? <VisibilityOffIcon /> : <VisibilityIcon />}
                          </IconButton>
                        </InputAdornment>
                      ),
                    }}
                  />
                </Grid>
              </Grid>
              
              <Typography variant="body2" color={themeColors.grey[600]} mt={2}>
                Leave password fields empty if you don't want to change your password.
              </Typography>
            </Paper>
          </Grid>
          
          {/* Save Button */}
          <Grid item xs={12}>
            <Box display="flex" justifyContent="flex-end">
              <Button
                type="submit"
                variant="contained"
                disabled={loading}
                startIcon={loading ? <CircularProgress size={24} color="inherit" /> : <SaveIcon />}
                sx={{
                  py: 1.5,
                  px: 4,
                  borderRadius: 2,
                  backgroundColor: themeColors.primary[500],
                  '&:hover': {
                    backgroundColor: themeColors.primary[600],
                  },
                }}
              >
                {loading ? 'Saving...' : 'Save Changes'}
              </Button>
            </Box>
          </Grid>
        </Grid>
      </form>
    </Box>
  );
};

export default EditProfile; 