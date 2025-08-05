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
  Button,
  Chip,
  Dialog,
  DialogTitle,
  DialogContent,
  DialogContentText,
  DialogActions,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  CircularProgress,
  Tooltip,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  Search as SearchIcon,
  Download as DownloadIcon,
} from '@mui/icons-material';
import { getAllDatasets, updateDataset, deleteDataset } from '../../api/datasets';
import { themeColors } from '../../theme';

const Datasets = () => {
  const [datasets, setDatasets] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredDatasets, setFilteredDatasets] = useState([]);
  
  // Dialog states
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [openEditDialog, setOpenEditDialog] = useState(false);
  const [selectedDataset, setSelectedDataset] = useState(null);
  const [editFormData, setEditFormData] = useState({
    title: '',
    description: '',
    type: '',
    size: '',
    file: null,
  });
  
  useEffect(() => {
    fetchDatasets();
  }, []);
  
  useEffect(() => {
    if (datasets.length > 0) {
      filterDatasets();
    }
  }, [searchQuery, datasets]);
  
  const fetchDatasets = async () => {
    try {
      setLoading(true);
      const data = await getAllDatasets();
      setDatasets(data);
      setFilteredDatasets(data);
    } catch (err) {
      console.error('Error fetching datasets:', err);
      setError('Failed to load datasets');
    } finally {
      setLoading(false);
    }
  };
  
  const filterDatasets = () => {
    if (!searchQuery) {
      setFilteredDatasets(datasets);
      return;
    }
    
    const filtered = datasets.filter(
      dataset => 
        dataset.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
        dataset.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
        dataset.type.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (dataset.user && dataset.user.name.toLowerCase().includes(searchQuery.toLowerCase())) ||
        (dataset.user && dataset.user.email.toLowerCase().includes(searchQuery.toLowerCase()))
    );
    
    setFilteredDatasets(filtered);
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
  
  const handleDeleteClick = (dataset) => {
    setSelectedDataset(dataset);
    setOpenDeleteDialog(true);
  };
  
  const handleEditClick = (dataset) => {
    setSelectedDataset(dataset);
    setEditFormData({
      title: dataset.title,
      description: dataset.description,
      type: dataset.type,
      size: dataset.size,
    });
    setOpenEditDialog(true);
  };
  
  const handleDeleteConfirm = async () => {
    if (!selectedDataset) return;
    
    try {
      setLoading(true);
      await deleteDataset(selectedDataset._id);
      setDatasets(prevDatasets => prevDatasets.filter(dataset => dataset._id !== selectedDataset._id));
      setFilteredDatasets(prevDatasets => prevDatasets.filter(dataset => dataset._id !== selectedDataset._id));
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
  
  const handleEditFormChange = (e) => {
    const { name, value, files } = e.target;
    if (name === 'file') {
      setEditFormData(prev => ({ ...prev, file: files[0] }));
    } else {
      setEditFormData(prev => ({ ...prev, [name]: value }));
    }
  };
  
  const handleEditSubmit = async () => {
    if (!selectedDataset) return;
    
    try {
      setLoading(true);
      const result = await updateDataset(selectedDataset._id, editFormData);
      const updatedDataset = result.dataset;
      
      setDatasets(prevDatasets => 
        prevDatasets.map(dataset => 
          dataset._id === selectedDataset._id ? updatedDataset : dataset
        )
      );
      
      setFilteredDatasets(prevFilteredDatasets => 
        prevFilteredDatasets.map(dataset => 
          dataset._id === selectedDataset._id ? updatedDataset : dataset
        )
      );
      
      setOpenEditDialog(false);
      setSelectedDataset(null);
      alert('Dataset updated successfully');
    } catch (err) {
      console.error('Error updating dataset:', err);
      alert(`Failed to update dataset: ${err.toString()}`);
      setError('Failed to update dataset: ' + (err.toString() || 'Unknown error'));
    } finally {
      setLoading(false);
    }
  };
  
  if (loading && datasets.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  if (error && datasets.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <Typography variant="h4" color="error">
          {error}
        </Typography>
      </Box>
    );
  }

  return (
    <Box>
      <Box display="flex" justifyContent="space-between" alignItems="center" mb={3}>
        <Typography variant="h2" fontWeight="bold" color={themeColors.grey[900]}>
          Dataset Management
        </Typography>
      </Box>

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
          placeholder="Search datasets..."
          fullWidth
          value={searchQuery}
          onChange={handleSearchChange}
          InputProps={{
            disableUnderline: true,
          }}
        />
      </Paper>

      <Paper sx={{ borderRadius: 3, overflow: 'hidden' }}>
        <TableContainer>
          <Table>
            <TableHead sx={{ backgroundColor: themeColors.background.dark }}>
              <TableRow>
                <TableCell sx={{ fontWeight: 'bold' }}>Title</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }}>Description</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }}>Type</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }}>Size</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }} align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading && datasets.length > 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 5 }}>
                    <CircularProgress size={30} />
                  </TableCell>
                </TableRow>
              ) : filteredDatasets.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={6} align="center" sx={{ py: 5 }}>
                    <Typography variant="body1" color={themeColors.grey[600]}>
                      No datasets found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                filteredDatasets
                  .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                  .map((dataset) => (
                    <TableRow key={dataset._id} hover>
                      <TableCell>
                        <Typography variant="body1" fontWeight="500">
                          {dataset.title}
                        </Typography>
                        {dataset.fileName && (
                          <Typography variant="caption" color="text.secondary" display="block">
                            File: {dataset.fileName}
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
                      <TableCell>
                        {dataset.size}
                        {dataset.fileId && (
                          <Typography variant="caption" color="success.main" display="block">
                            ✓ File uploaded
                          </Typography>
                        )}
                      </TableCell>
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
                        <Tooltip title="Edit Dataset">
                          <IconButton
                            color="primary"
                            onClick={() => handleEditClick(dataset)}
                            sx={{ mr: 1 }}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
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
        <TablePagination
          rowsPerPageOptions={[5, 10, 25]}
          component="div"
          count={filteredDatasets.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Paper>

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

      <Dialog
        open={openEditDialog}
        onClose={() => setOpenEditDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Edit Dataset</DialogTitle>
        <DialogContent>
          <Box component="form" sx={{ mt: 2 }} noValidate>
            <TextField
              margin="normal"
              required
              fullWidth
              id="title"
              label="Title"
              name="title"
              value={editFormData.title}
              onChange={handleEditFormChange}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="description"
              label="Description"
              name="description"
              multiline
              rows={4}
              value={editFormData.description}
              onChange={handleEditFormChange}
            />
            <FormControl fullWidth margin="normal">
              <InputLabel>Type</InputLabel>
              <Select
                name="type"
                value={editFormData.type}
                label="Type"
                onChange={handleEditFormChange}
              >
                <MenuItem value="text">Text</MenuItem>
                <MenuItem value="excel">Excel</MenuItem>
                <MenuItem value="csv">CSV</MenuItem>
                <MenuItem value="json">JSON</MenuItem>
              </Select>
            </FormControl>
            <TextField
              margin="normal"
              required
              fullWidth
              id="size"
              label="Size"
              name="size"
              value={editFormData.size}
              onChange={handleEditFormChange}
            />
            <Box mt={2}>
              <Button variant="contained" component="label">
                Upload New File
                <input
                  type="file"
                  hidden
                  name="file"
                  onChange={handleEditFormChange}
                />
              </Button>
              {editFormData.file && (
                <Typography variant="body2" sx={{ mt: 1 }}>
                  Selected file: {editFormData.file.name}
                </Typography>
              )}
            </Box>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenEditDialog(false)}>Cancel</Button>
          <Button onClick={handleEditSubmit} variant="contained">
            Save Changes
          </Button>
        </DialogActions>
      </Dialog>
    </Box>
  );
};

export default Datasets;