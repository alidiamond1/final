import { useState, useEffect } from 'react';
import {
  Box,
  Typography,
  Paper,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  TablePagination,
  IconButton,
  Chip,
  TextField,
  CircularProgress,
  Tooltip,
  Avatar,
  Accordion,
  AccordionSummary,
  AccordionDetails,
  Divider,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  Button,
} from '@mui/material';
import {
  Search as SearchIcon,
  ExpandMore as ExpandMoreIcon,
  Download as DownloadIcon,
  Delete as DeleteIcon,
} from '@mui/icons-material';
import { getAllDatasets, getDatasetsByUser, deleteDataset } from '../../api/datasets';
import { themeColors } from '../../theme';
import { useAuth } from '../../context/AuthContext';

const UploadsByUser = () => {
  const { user } = useAuth();
  const [datasets, setDatasets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(5);
  const [searchQuery, setSearchQuery] = useState('');
  const [userDatasets, setUserDatasets] = useState([]);
  const [expandedUser, setExpandedUser] = useState('');
  const [currentUserData, setCurrentUserData] = useState(null);
  const isAdmin = user && user.role === 'admin';
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [selectedDataset, setSelectedDataset] = useState(null);
  
  useEffect(() => {
    if (isAdmin) {
      fetchAllDatasets();
    } else if (user && user._id) {
      fetchCurrentUserDatasets();
    }
  }, [user]);
  
  useEffect(() => {
    if (datasets.length > 0 && isAdmin) {
      processUserDatasets();
    }
  }, [searchQuery, datasets]);
  
  // For admin: fetch all datasets
  const fetchAllDatasets = async () => {
    try {
      setLoading(true);
      const data = await getAllDatasets();
      setDatasets(data);
      processUserDatasets(data);
    } catch (err) {
      console.error('Error fetching datasets:', err);
      setError('Failed to load datasets');
    } finally {
      setLoading(false);
    }
  };
  
  // For regular users: fetch only their own datasets
  const fetchCurrentUserDatasets = async () => {
    try {
      setLoading(true);
      const data = await getDatasetsByUser(user._id);
      
      // Create a single user entry for the current user
      const userData = {
        user: {
          _id: user._id,
          name: user.name,
          email: user.email,
          profileImage: user.profileImage
        },
        datasets: data
      };
      
      setCurrentUserData(userData);
      setExpandedUser(user._id); // Auto-expand for regular users
    } catch (err) {
      console.error('Error fetching user datasets:', err);
      setError('Failed to load your datasets');
    } finally {
      setLoading(false);
    }
  };

  const handleDeleteClick = (dataset) => {
    setSelectedDataset(dataset);
    setOpenDeleteDialog(true);
  };
  
  const handleDeleteConfirm = async () => {
    if (!selectedDataset) return;
    
    try {
      setLoading(true);
      await deleteDataset(selectedDataset._id);
      
      // Update the UI after successful deletion
      if (isAdmin) {
        // For admin view, update the datasets list
        setDatasets(prevDatasets => prevDatasets.filter(dataset => dataset._id !== selectedDataset._id));
        
        // Update the userDatasets state
        setUserDatasets(prevUserDatasets => {
          return prevUserDatasets.map(userData => ({
            ...userData,
            datasets: userData.datasets.filter(dataset => dataset._id !== selectedDataset._id)
          }));
        });
      } else {
        // For regular user view
        if (currentUserData) {
          setCurrentUserData({
            ...currentUserData,
            datasets: currentUserData.datasets.filter(dataset => dataset._id !== selectedDataset._id)
          });
        }
      }
      
      setOpenDeleteDialog(false);
      setSelectedDataset(null);
      alert('Dataset deleted successfully');
    } catch (err) {
      console.error('Error deleting dataset:', err);
      alert(`Failed to delete dataset: ${err.toString()}`);
      setError('Failed to delete dataset: ' + (err.toString() || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };
  
  const processUserDatasets = (data = datasets) => {
    // Group datasets by user
    const userMap = new Map();
    
    data.forEach(dataset => {
      if (dataset.user) {
        const userId = dataset.user._id;
        if (!userMap.has(userId)) {
          userMap.set(userId, {
            user: dataset.user,
            datasets: []
          });
        }
        userMap.get(userId).datasets.push(dataset);
      }
    });
    
    // Convert map to array and filter by search query if needed
    let userDatasetsArray = Array.from(userMap.values());
    
    if (searchQuery) {
      userDatasetsArray = userDatasetsArray.filter(item => 
        item.user.name?.toLowerCase().includes(searchQuery.toLowerCase()) || 
        item.user.email?.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }
    
    setUserDatasets(userDatasetsArray);
  };
  
  const handleSearchChange = (e) => {
    setSearchQuery(e.target.value);
  };
  
  const handleChangePage = (event, newPage) => {
    setPage(newPage);
  };
  
  const handleChangeRowsPerPage = (event) => {
    setRowsPerPage(parseInt(event.target.value, 10));
    setPage(0);
  };
  
  const handleAccordionChange = (userId) => (event, isExpanded) => {
    setExpandedUser(isExpanded ? userId : '');
  };
  
  if (loading && !currentUserData && userDatasets.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  if (error && !currentUserData && userDatasets.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <Typography variant="h4" color="error">
          {error}
        </Typography>
      </Box>
    );
  }

  // Determine which data to display based on user role
  const displayData = isAdmin ? userDatasets : (currentUserData ? [currentUserData] : []);
  const showSearch = isAdmin; // Only show search for admins

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h2" fontWeight="bold" color={themeColors.grey[900]}>
          {isAdmin ? 'Uploads By User' : 'My Uploads'}
        </Typography>
      </Box>

      {showSearch && (
        <Paper
          sx={{
            p: 2,
            mb: 3,
            borderRadius: 3,
            display: 'flex',
            alignItems: 'center',
          }}
        >
          <SearchIcon sx={{ color: themeColors.grey[500], mr: 2 }} />
          <TextField
            variant="standard"
            placeholder="Search users..."
            fullWidth
            value={searchQuery}
            onChange={handleSearchChange}
            InputProps={{
              disableUnderline: true,
            }}
          />
        </Paper>
      )}

      {loading && displayData.length === 0 ? (
        <Box display="flex" justifyContent="center" py={5}>
          <CircularProgress />
        </Box>
      ) : displayData.length === 0 ? (
        <Paper sx={{ p: 5, borderRadius: 3, textAlign: 'center' }}>
          <Typography variant="h6" color={themeColors.grey[600]}>
            {isAdmin ? 'No users with uploads found' : 'You have not uploaded any datasets yet'}
          </Typography>
        </Paper>
      ) : (
        <>
          {displayData
            .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
            .map((userData) => (
              <Paper 
                key={userData.user._id} 
                sx={{ 
                  mb: 2, 
                  borderRadius: 3, 
                  overflow: 'hidden'
                }}
              >
                <Accordion
                  expanded={expandedUser === userData.user._id}
                  onChange={handleAccordionChange(userData.user._id)}
                  disableGutters
                  elevation={0}
                  sx={{
                    '&:before': {
                      display: 'none',
                    },
                  }}
                >
                  <AccordionSummary
                    expandIcon={<ExpandMoreIcon />}
                    sx={{
                      p: 2,
                      backgroundColor: expandedUser === userData.user._id 
                        ? `${themeColors.primary.light}15` 
                        : 'transparent',
                      '&:hover': {
                        backgroundColor: `${themeColors.primary.light}10`,
                      }
                    }}
                  >
                    <Box sx={{ display: 'flex', alignItems: 'center', width: '100%' }}>
                      <Avatar 
                        src={userData.user.profileImage}
                        sx={{ 
                          width: 50, 
                          height: 50,
                          mr: 2,
                          border: `2px solid ${themeColors.primary.main}`
                        }}
                      />
                      <Box sx={{ flexGrow: 1 }}>
                        <Typography variant="h6" fontWeight="bold">
                          {userData.user.name || 'Unknown User'}
                          {!isAdmin && userData.user._id === user._id && ' (You)'}
                        </Typography>
                        <Typography variant="body2" color="text.secondary">
                          {userData.user.email || 'No email available'}
                        </Typography>
                      </Box>
                      <Chip 
                        label={`${userData.datasets.length} Uploads`} 
                        color="primary"
                        sx={{ fontWeight: 'bold' }}
                      />
                    </Box>
                  </AccordionSummary>
                  <AccordionDetails sx={{ p: 0 }}>
                    <Divider />
                    <TableContainer>
                      <Table>
                        <TableHead sx={{ backgroundColor: themeColors.background.dark }}>
                          <TableRow>
                            <TableCell sx={{ fontWeight: 'bold' }}>Dataset Name</TableCell>
                            <TableCell sx={{ fontWeight: 'bold' }}>Description</TableCell>
                            <TableCell sx={{ fontWeight: 'bold' }}>Type</TableCell>
                            <TableCell sx={{ fontWeight: 'bold' }}>Size</TableCell>
                            <TableCell sx={{ fontWeight: 'bold' }} align="right">Actions</TableCell>
                          </TableRow>
                        </TableHead>
                        <TableBody>
                          {userData.datasets.length === 0 ? (
                            <TableRow>
                              <TableCell colSpan={5} align="center">
                                <Typography variant="body2" color="text.secondary" py={2}>
                                  No datasets uploaded yet
                                </Typography>
                              </TableCell>
                            </TableRow>
                          ) : (
                            userData.datasets.map((dataset) => (
                              <TableRow key={dataset._id} hover>
                                <TableCell>
                                  <Typography variant="body1" fontWeight="500">
                                    {dataset.title}
                                  </Typography>
                                  {dataset.fileName && (
                                    <Typography variant="caption" color="text.secondary" display="block">
                                      {dataset.fileName}
                                    </Typography>
                                  )}
                                </TableCell>
                                <TableCell>
                                  <Typography variant="body2" noWrap sx={{ maxWidth: 300 }}>
                                    {dataset.description}
                                  </Typography>
                                </TableCell>
                                <TableCell>
                                  <Chip
                                    label={dataset.type}
                                    size="small"
                                    sx={{
                                      backgroundColor: 
                                        dataset.type === 'text' ? '#e3f2fd' :
                                        dataset.type === 'excel' ? '#e8f5e9' :
                                        dataset.type === 'csv' ? '#fff3e0' : '#f5f5f5',
                                      color: 
                                        dataset.type === 'text' ? '#1565c0' :
                                        dataset.type === 'excel' ? '#2e7d32' :
                                        dataset.type === 'csv' ? '#e65100' : '#616161',
                                      fontWeight: 500,
                                    }}
                                  />
                                </TableCell>
                                <TableCell>{dataset.size}</TableCell>
                                <TableCell align="right">
                                  <Tooltip title={dataset.fileId ? "Download Dataset" : "No file available"}>
                                    <span>
                                      <IconButton
                                        color="primary"
                                        sx={{ mr: 1 }}
                                        onClick={() => window.open(`http://localhost:3000/api/datasets/${dataset._id}/download`, '_blank')}
                                        disabled={!dataset.fileId}
                                      >
                                        <DownloadIcon fontSize="small" />
                                      </IconButton>
                                    </span>
                                  </Tooltip>
                                  <Tooltip title="Delete Dataset">
                                    <IconButton
                                      color="error"
                                      onClick={() => handleDeleteClick(dataset)}
                                    >
                                      <DeleteIcon fontSize="small" />
                                    </IconButton>
                                  </Tooltip>
                                </TableCell>
                              </TableRow>
                            ))
                          )}
                        </TableBody>
                      </Table>
                    </TableContainer>
                  </AccordionDetails>
                </Accordion>
              </Paper>
            ))}
          <TablePagination
            rowsPerPageOptions={[5, 10, 25]}
            component="div"
            count={displayData.length}
            rowsPerPage={rowsPerPage}
            page={page}
            onPageChange={handleChangePage}
            onRowsPerPageChange={handleChangeRowsPerPage}
          />
        </>
      )}

      {/* Delete Confirmation Dialog */}
      <Dialog
        open={openDeleteDialog}
        onClose={() => setOpenDeleteDialog(false)}
      >
        <DialogTitle>Delete Dataset</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete the dataset "{selectedDataset?.title}"? This action cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDeleteDialog(false)}>Cancel</Button>
          <Button onClick={handleDeleteConfirm} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default UploadsByUser; 