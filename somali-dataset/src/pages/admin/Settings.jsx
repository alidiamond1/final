import { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  Grid,
  Switch,
  FormControlLabel,
  Divider,
  Alert,
  CircularProgress
} from '@mui/material';
import {
  Save as SaveIcon,
  Storage as StorageIcon,
  Language as LanguageIcon
} from '@mui/icons-material';
import { themeColors } from '../../theme';

const Settings = () => {
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  
  const [generalSettings, setGeneralSettings] = useState({
    siteName: 'Somali Dataset Repository',
    siteDescription: 'A comprehensive collection of Somali language datasets for research and development',
    adminEmail: 'admin@somali-dataset.com'
  });
  
  const [datasetSettings, setDatasetSettings] = useState({
    allowPublicDownloads: true,
    maxFileSize: 100,
    supportedFormats: 'CSV, Excel, JSON, Text'
  });
  
  const handleGeneralChange = (e) => {
    const { name, value } = e.target;
    setGeneralSettings(prev => ({ ...prev, [name]: value }));
  };
  
  const handleDatasetChange = (e) => {
    const { name, value, checked, type } = e.target;
    setDatasetSettings(prev => ({ 
      ...prev, 
      [name]: type === 'checkbox' ? checked : value 
    }));
  };
  
  const handleSubmit = async (e) => {
    e.preventDefault();
    
    setLoading(true);
    
    try {
      // Mock API call to save settings
      await new Promise(resolve => setTimeout(resolve, 1500));
      
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (error) {
      console.error('Failed to save settings:', error);
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <Box>
      <Typography variant="h2" fontWeight="bold" color={themeColors.grey[900]} mb={3}>
        Settings
      </Typography>
      
      {success && (
        <Alert 
          severity="success" 
          sx={{ mb: 3 }}
          onClose={() => setSuccess(false)}
        >
          Settings saved successfully!
        </Alert>
      )}
      
      <form onSubmit={handleSubmit}>
        <Grid container spacing={3}>
          {/* General Settings */}
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
              <Box display="flex" alignItems="center" mb={3}>
                <StorageIcon sx={{ color: themeColors.primary[500], mr: 1.5 }} />
                <Typography variant="h4" fontWeight="medium">
                  General Settings
                </Typography>
              </Box>
              
              <Divider sx={{ mb: 3 }} />
              
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Site Name"
                    name="siteName"
                    value={generalSettings.siteName}
                    onChange={handleGeneralChange}
                  />
                </Grid>
                
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Site Description"
                    name="siteDescription"
                    value={generalSettings.siteDescription}
                    onChange={handleGeneralChange}
                    multiline
                    rows={2}
                  />
                </Grid>
                
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Admin Email"
                    name="adminEmail"
                    type="email"
                    value={generalSettings.adminEmail}
                    onChange={handleGeneralChange}
                  />
                </Grid>
              </Grid>
            </Paper>
          </Grid>
          
          {/* Dataset Settings */}
          <Grid item xs={12} md={6}>
            <Paper sx={{ p: 3, borderRadius: 3, height: '100%' }}>
              <Box display="flex" alignItems="center" mb={3}>
                <LanguageIcon sx={{ color: themeColors.primary[500], mr: 1.5 }} />
                <Typography variant="h4" fontWeight="medium">
                  Dataset Settings
                </Typography>
              </Box>
              
              <Divider sx={{ mb: 3 }} />
              
              <Grid container spacing={2}>
                <Grid item xs={12}>
                  <FormControlLabel
                    control={
                      <Switch
                        checked={datasetSettings.allowPublicDownloads}
                        onChange={handleDatasetChange}
                        name="allowPublicDownloads"
                        color="primary"
                      />
                    }
                    label="Allow Public Downloads"
                  />
                </Grid>
                
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Maximum File Size (MB)"
                    name="maxFileSize"
                    type="number"
                    value={datasetSettings.maxFileSize}
                    onChange={handleDatasetChange}
                    InputProps={{ inputProps: { min: 1 } }}
                  />
                </Grid>
                
                <Grid item xs={12}>
                  <TextField
                    fullWidth
                    label="Supported File Formats"
                    name="supportedFormats"
                    value={datasetSettings.supportedFormats}
                    onChange={handleDatasetChange}
                    helperText="Comma separated list of file formats"
                  />
                </Grid>
              </Grid>
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
                {loading ? 'Saving...' : 'Save Settings'}
              </Button>
            </Box>
          </Grid>
        </Grid>
      </form>
    </Box>
  );
};

export default Settings; 