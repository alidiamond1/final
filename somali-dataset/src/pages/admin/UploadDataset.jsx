import { useState } from 'react';
import {
  Box,
  Typography,
  Paper,
  TextField,
  Button,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  Grid,
  Card,
  CardContent,
  CircularProgress,
  Alert,
  IconButton,
  Divider,
  LinearProgress
} from '@mui/material';
import {
  CloudUpload as CloudUploadIcon,
  Delete as DeleteIcon,
  Description as DescriptionIcon,
  AttachFile as AttachFileIcon,
  InsertDriveFile as FileIcon,
  Article as TextIcon
} from '@mui/icons-material';
import { themeColors } from '../../theme';

const UploadDataset = () => {
  const [loading, setLoading] = useState(false);
  const [uploadProgress, setUploadProgress] = useState(0);
  const [success, setSuccess] = useState(false);
  const [error, setError] = useState(null);
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    type: '',
    file: null
  });
  const [filePreview, setFilePreview] = useState(null);

  const handleChange = (e) => {
    const { name, value } = e.target;
    setFormData(prev => ({ ...prev, [name]: value }));
  };

  const handleFileChange = (e) => {
    if (e.target.files && e.target.files[0]) {
      const file = e.target.files[0];
      setFormData(prev => ({ ...prev, file }));
      setFilePreview({
        name: file.name,
        type: file.type,
        size: formatFileSize(file.size)
      });
      console.log("File selected:", file.name, file.type, file.size);
    }
  };

  const formatFileSize = (bytes) => {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  };

  const getFileIcon = (fileType) => {
    if (!fileType) return <FileIcon />;
    
    if (fileType.includes('csv')) return <DescriptionIcon />;
    if (fileType.includes('excel') || fileType.includes('xls')) return <DescriptionIcon />;
    if (fileType.includes('json')) return <DescriptionIcon />;
    if (fileType.includes('text') || fileType.includes('txt')) return <TextIcon />;
    
    return <FileIcon />;
  };

  const handleClearFile = () => {
    setFormData(prev => ({ ...prev, file: null }));
    setFilePreview(null);
  };

  const simulateProgress = () => {
    const timer = setInterval(() => {
      setUploadProgress((oldProgress) => {
        const newProgress = Math.min(oldProgress + Math.random() * 10, 95);
        if (newProgress === 95) {
          clearInterval(timer);
        }
        return newProgress;
      });
    }, 500);
    
    return timer;
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!formData.title || !formData.description || !formData.type) {
      setError('Title, description, and type are required');
      return;
    }

    setLoading(true);
    setError(null);
    setSuccess(false);
    setUploadProgress(0);
    
    // Start progress simulation
    const progressTimer = simulateProgress();
    
    try {
      // Import the createDataset function from the API
      const { createDataset } = await import('../../api/datasets');
      
      // Create a new FormData object properly
      const formDataToSend = new FormData();
      formDataToSend.append('title', formData.title);
      formDataToSend.append('description', formData.description);
      formDataToSend.append('type', formData.type);
      
      // Check if file exists before appending
      if (formData.file) {
        formDataToSend.append('file', formData.file);
        console.log('File being uploaded:', formData.file.name, formData.file.size, 'bytes');
      }
      
      // Call the API to create the dataset with the new FormData
      const result = await createDataset(formDataToSend);
      
      console.log('Upload result:', result);
      clearInterval(progressTimer);
      setUploadProgress(100);
      setError(null);
      setSuccess(true);
      
      // Clear form after successful upload
      setFormData({
        title: '',
        description: '',
        type: '',
        file: null
      });
      setFilePreview(null);
      
      // Reset success message after 5 seconds
      setTimeout(() => {
        setSuccess(false);
        setUploadProgress(0);
      }, 5000);
      
    } catch (err) {
      clearInterval(progressTimer);
      setUploadProgress(0);
      console.error('Upload failed:', err);
      setError(err.message || 'Failed to upload dataset. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <Box>
      <Typography variant="h2" fontWeight="bold" color={themeColors.grey[900]} mb={3}>
        Upload New Dataset
      </Typography>
      
      {success && (
        <Alert 
          severity="success" 
          sx={{ mb: 3 }}
          onClose={() => setSuccess(false)}
        >
          Dataset uploaded successfully! The file has been stored in the database.
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

      <Grid container spacing={4}>
        <Grid item xs={12} md={8}>
          <Paper 
            component="form" 
            onSubmit={handleSubmit}
            sx={{ borderRadius: 3, p: 4 }}
          >
            <Typography variant="h4" fontWeight="medium" mb={3}>
              Dataset Information
            </Typography>
            
            <Grid container spacing={3}>
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  required
                  label="Dataset Title"
                  name="title"
                  value={formData.title}
                  onChange={handleChange}
                  variant="outlined"
                />
              </Grid>
              
              <Grid item xs={12}>
                <TextField
                  fullWidth
                  required
                  label="Description"
                  name="description"
                  value={formData.description}
                  onChange={handleChange}
                  multiline
                  rows={4}
                  variant="outlined"
                />
              </Grid>
              
              <Grid item xs={12} sm={6}>
                <FormControl fullWidth required>
                  <InputLabel>Dataset Type</InputLabel>
                  <Select
                    name="type"
                    value={formData.type}
                    label="Dataset Type"
                    onChange={handleChange}
                  >
                    <MenuItem value="csv">CSV</MenuItem>
                    <MenuItem value="excel">Excel</MenuItem>
                    <MenuItem value="json">JSON</MenuItem>
                    <MenuItem value="text">Text</MenuItem>
                  </Select>
                </FormControl>
              </Grid>
              
              <Grid item xs={12}>
                <Divider sx={{ my: 2 }} />
                
                <Box mb={3}>
                  <Typography variant="h6" fontWeight="medium" mb={2}>
                    Dataset File
                  </Typography>
                  
                  <input
                    type="file"
                    id="dataset-file"
                    style={{ display: 'none' }}
                    onChange={handleFileChange}
                    accept=".csv,.txt,.json,.xlsx,.xls"
                  />
                  
                  {!filePreview ? (
                    <Button
                      component="label"
                      htmlFor="dataset-file"
                      variant="outlined"
                      startIcon={<CloudUploadIcon />}
                      sx={{ borderRadius: 2, py: 1.5 }}
                    >
                      Choose File
                    </Button>
                  ) : (
                    <Box 
                      display="flex" 
                      alignItems="center" 
                      p={2} 
                      sx={{ 
                        backgroundColor: themeColors.grey[100], 
                        borderRadius: 2 
                      }}
                    >
                      <Box sx={{ mr: 2, color: themeColors.grey[600] }}>
                        {getFileIcon(filePreview.type)}
                      </Box>
                      <Box flex={1}>
                        <Typography variant="body1" fontWeight="medium">
                          {filePreview.name}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {filePreview.size}
                        </Typography>
                      </Box>
                      <IconButton 
                        color="error" 
                        onClick={handleClearFile}
                        size="small"
                      >
                        <DeleteIcon />
                      </IconButton>
                    </Box>
                  )}
                </Box>
              </Grid>
              
              <Grid item xs={12}>
                {loading && (
                  <Box sx={{ width: '100%', mb: 2 }}>
                    <LinearProgress 
                      variant="determinate" 
                      value={uploadProgress} 
                      sx={{ 
                        height: 8, 
                        borderRadius: 5,
                        backgroundColor: themeColors.grey[200],
                        '& .MuiLinearProgress-bar': {
                          backgroundColor: themeColors.primary[500]
                        }
                      }}
                    />
                    <Typography variant="caption" color="text.secondary" align="right" display="block" mt={0.5}>
                      {uploadProgress === 100 ? 'Complete!' : `Uploading... ${Math.round(uploadProgress)}%`}
                    </Typography>
                  </Box>
                )}
              
                <Button
                  type="submit"
                  variant="contained"
                  disabled={loading}
                  size="large"
                  startIcon={loading ? <CircularProgress size={20} color="inherit" /> : <CloudUploadIcon />}
                  sx={{
                    mt: 2,
                    py: 1.5,
                    borderRadius: 2,
                    backgroundColor: themeColors.primary[500],
                    '&:hover': {
                      backgroundColor: themeColors.primary[600],
                    },
                  }}
                >
                  {loading ? 'Uploading...' : 'Upload Dataset'}
                </Button>
              </Grid>
            </Grid>
          </Paper>
        </Grid>
        
        <Grid item xs={12} md={4}>
          <Card sx={{ borderRadius: 3, mb: 3, height: '100%' }}>
            <CardContent sx={{ p: 3 }}>
              <Box mb={2} display="flex" alignItems="center">
                <AttachFileIcon sx={{ mr: 1, color: themeColors.primary[500] }} />
                <Typography variant="h4" fontWeight="medium">
                  Upload Guidelines
                </Typography>
              </Box>
              
              <Typography variant="body1" paragraph>
                Please follow these guidelines when uploading datasets:
              </Typography>
              
              <Box component="ul" sx={{ pl: 2 }}>
                <Typography component="li" variant="body1" mb={1}>
                  Ensure your dataset is organized and properly documented
                </Typography>
                <Typography component="li" variant="body1" mb={1}>
                  Provide a clear and detailed description
                </Typography>
                <Typography component="li" variant="body1" mb={1}>
                  Supported file types: CSV, Excel, JSON, Text
                </Typography>
                <Typography component="li" variant="body1" mb={1}>
                  Maximum file size is 100MB
                </Typography>
                <Typography component="li" variant="body1">
                  Include license information if applicable
                </Typography>
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default UploadDataset; 