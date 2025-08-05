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
  Avatar,
  CircularProgress,
  Tooltip,
  useMediaQuery,
  useTheme,
  Snackbar,
  Alert,
} from '@mui/material';
import {
  Edit as EditIcon,
  Delete as DeleteIcon,
  Add as AddIcon,
  Search as SearchIcon,
  PersonAdd as PersonAddIcon,
} from '@mui/icons-material';
import { getAllUsers, updateUser, deleteUser } from '../../api/auth';
import { themeColors } from '../../theme';
import axios from 'axios';
import defaultProfileImage from '../../assets/profile.jpg';

const API_URL = 'http://localhost:3000';

const Users = () => {
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down('sm'));
  
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [page, setPage] = useState(0);
  const [rowsPerPage, setRowsPerPage] = useState(10);
  const [searchQuery, setSearchQuery] = useState('');
  const [filteredUsers, setFilteredUsers] = useState([]);
  
  // Dialog states
  const [openDeleteDialog, setOpenDeleteDialog] = useState(false);
  const [openEditDialog, setOpenEditDialog] = useState(false);
  const [openAddDialog, setOpenAddDialog] = useState(false);
  const [selectedUser, setSelectedUser] = useState(null);
  const [editFormData, setEditFormData] = useState({
    name: '',
    username: '',
    email: '',
    role: 'user',
  });
  const [addFormData, setAddFormData] = useState({
    name: '',
    username: '',
    email: '',
    password: '',
    role: 'user',
  });
  
  // Snackbar state
  const [snackbar, setSnackbar] = useState({
    open: false,
    message: '',
    severity: 'success',
  });
  
  useEffect(() => {
    fetchUsers();
  }, []);
  
  useEffect(() => {
    if (users.length > 0) {
      filterUsers();
    }
  }, [searchQuery, users]);
  
  const fetchUsers = async () => {
    try {
      setLoading(true);
      const data = await getAllUsers();
      setUsers(data);
      setFilteredUsers(data);
    } catch (err) {
      console.error('Error fetching users:', err);
      setError('Failed to load users');
    } finally {
      setLoading(false);
    }
  };
  
  const filterUsers = () => {
    if (!searchQuery) {
      setFilteredUsers(users);
      return;
    }
    
    const filtered = users.filter(
      user => 
        user.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.username.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.email.toLowerCase().includes(searchQuery.toLowerCase()) ||
        user.role.toLowerCase().includes(searchQuery.toLowerCase())
    );
    
    setFilteredUsers(filtered);
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
  
  const handleDeleteClick = (user) => {
    setSelectedUser(user);
    setOpenDeleteDialog(true);
  };
  
  const handleEditClick = (user) => {
    setSelectedUser(user);
    setEditFormData({
      name: user.name,
      username: user.username,
      email: user.email,
      role: user.role,
    });
    setOpenEditDialog(true);
  };
  
  const handleDeleteConfirm = async () => {
    if (!selectedUser) return;
    
    try {
      setLoading(true);
      await deleteUser(selectedUser._id);
      setUsers(prevUsers => prevUsers.filter(user => user._id !== selectedUser._id));
      setOpenDeleteDialog(false);
      setSelectedUser(null);
      
      // Show success message
      setSnackbar({
        open: true,
        message: 'User deleted successfully',
        severity: 'success',
      });
    } catch (err) {
      console.error('Error deleting user:', err);
      setError('Failed to delete user');
      
      // Show error message
      setSnackbar({
        open: true,
        message: 'Failed to delete user: ' + (err.message || 'Unknown error'),
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  };
  
  const handleEditFormChange = (e) => {
    const { name, value } = e.target;
    setEditFormData(prev => ({ ...prev, [name]: value }));
  };
  
  const handleAddFormChange = (e) => {
    const { name, value } = e.target;
    setAddFormData(prev => ({ ...prev, [name]: value }));
  };
  
  const handleEditSubmit = async () => {
    if (!selectedUser) return;
    
    try {
      setLoading(true);
      const updatedUser = await updateUser(selectedUser._id, editFormData);
      
      setUsers(prevUsers => 
        prevUsers.map(user => 
          user._id === selectedUser._id ? updatedUser : user
        )
      );
      
      setOpenEditDialog(false);
      setSelectedUser(null);
      
      // Show success message
      setSnackbar({
        open: true,
        message: 'User updated successfully',
        severity: 'success',
      });
    } catch (err) {
      console.error('Error updating user:', err);
      setError('Failed to update user');
      
      // Show error message
      setSnackbar({
        open: true,
        message: 'Failed to update user: ' + (err.message || 'Unknown error'),
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  };
  
  const handleAddSubmit = async () => {
    try {
      setLoading(true);
      
      // Validate form data
      if (!addFormData.name || !addFormData.email || !addFormData.password) {
        throw new Error('Please fill in all required fields');
      }
      
      // Create new user through API
      const response = await axios.post('http://localhost:3000/api/users/register', {
        name: addFormData.name,
        username: addFormData.username,
        email: addFormData.email,
        password: addFormData.password,
        role: addFormData.role,
      });
      
      const newUser = response.data.user;
      
      // Add new user to the list
      setUsers(prevUsers => [...prevUsers, newUser]);
      
      // Reset form and close dialog
      setAddFormData({
        name: '',
        username: '',
        email: '',
        password: '',
        role: 'user',
      });
      setOpenAddDialog(false);
      
      // Show success message
      setSnackbar({
        open: true,
        message: 'New user added successfully',
        severity: 'success',
      });
    } catch (err) {
      console.error('Error adding user:', err);
      
      // Show error message
      setSnackbar({
        open: true,
        message: 'Failed to add user: ' + (err.response?.data?.error || err.message || 'Unknown error'),
        severity: 'error',
      });
    } finally {
      setLoading(false);
    }
  };
  
  const handleAddClick = () => {
    setAddFormData({
      name: '',
      username: '',
      email: '',
      password: '',
      role: 'user',
    });
    setOpenAddDialog(true);
  };
  
  const handleCloseSnackbar = () => {
    setSnackbar(prev => ({ ...prev, open: false }));
  };
  
  if (loading && users.length === 0) {
    return (
      <Box display="flex" justifyContent="center" alignItems="center" minHeight="80vh">
        <CircularProgress />
      </Box>
    );
  }

  if (error && users.length === 0) {
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
      <Box 
        display="flex" 
        flexDirection={isMobile ? 'column' : 'row'}
        justifyContent="space-between" 
        alignItems={isMobile ? 'flex-start' : 'center'} 
        mb={3}
      >
        <Typography 
          variant={isMobile ? 'h3' : 'h2'} 
          fontWeight="bold" 
          color={themeColors.grey[900]}
          mb={isMobile ? 2 : 0}
        >
          User Management
        </Typography>
        <Button
          variant="contained"
          startIcon={<AddIcon />}
          onClick={handleAddClick}
          sx={{
            backgroundColor: themeColors.primary[500],
            '&:hover': {
              backgroundColor: themeColors.primary[600],
            },
            borderRadius: 2,
            px: 3,
            width: isMobile ? '100%' : 'auto',
          }}
        >
          Add New User
        </Button>
      </Box>

      {/* Search and Filter */}
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

      {/* Users Table */}
      <Paper sx={{ borderRadius: 3, overflow: 'hidden' }}>
        <TableContainer>
          <Table>
            <TableHead sx={{ backgroundColor: themeColors.background.dark }}>
              <TableRow>
                <TableCell sx={{ fontWeight: 'bold' }}>User</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }}>Username</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }}>Email</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }}>Role</TableCell>
                <TableCell sx={{ fontWeight: 'bold' }} align="right">Actions</TableCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {loading && users.length > 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center" sx={{ py: 5 }}>
                    <CircularProgress size={30} />
                  </TableCell>
                </TableRow>
              ) : filteredUsers.length === 0 ? (
                <TableRow>
                  <TableCell colSpan={4} align="center" sx={{ py: 5 }}>
                    <Typography variant="body1" color={themeColors.grey[600]}>
                      No users found
                    </Typography>
                  </TableCell>
                </TableRow>
              ) : (
                filteredUsers
                  .slice(page * rowsPerPage, page * rowsPerPage + rowsPerPage)
                  .map((user) => (
                    <TableRow key={user._id} hover>
                      <TableCell>
                        <Box display="flex" alignItems="center">
                          <Avatar
                            src={user.profileImage || defaultProfileImage}
                            sx={{
                              width: 40,
                              height: 40,
                              mr: 2,
                            }}
                          />
                          <Typography variant="body1">{user.name}</Typography>
                        </Box>
                      </TableCell>
                      <TableCell>{user.username}</TableCell>
                      <TableCell>{user.email}</TableCell>
                      <TableCell>
                        <Chip
                          label={user.role}
                          color={user.role === 'admin' ? 'primary' : 'default'}
                          size="small"
                          sx={{
                            backgroundColor: user.role === 'admin' 
                              ? `${themeColors.primary[500]}` 
                              : themeColors.grey[200],
                            color: user.role === 'admin' ? 'white' : themeColors.grey[700],
                            fontWeight: 500,
                          }}
                        />
                      </TableCell>
                      <TableCell align="right">
                        <Tooltip title="Edit User">
                          <IconButton
                            color="primary"
                            onClick={() => handleEditClick(user)}
                            sx={{ mr: 1 }}
                          >
                            <EditIcon fontSize="small" />
                          </IconButton>
                        </Tooltip>
                        <Tooltip title="Delete User">
                          <IconButton
                            color="error"
                            onClick={() => handleDeleteClick(user)}
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
          count={filteredUsers.length}
          rowsPerPage={rowsPerPage}
          page={page}
          onPageChange={handleChangePage}
          onRowsPerPageChange={handleChangeRowsPerPage}
        />
      </Paper>

      {/* Delete Dialog */}
      <Dialog
        open={openDeleteDialog}
        onClose={() => setOpenDeleteDialog(false)}
      >
        <DialogTitle>Delete User</DialogTitle>
        <DialogContent>
          <DialogContentText>
            Are you sure you want to delete the user "{selectedUser?.name}"? This action cannot be undone.
          </DialogContentText>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenDeleteDialog(false)}>Cancel</Button>
          <Button onClick={handleDeleteConfirm} color="error" variant="contained">
            Delete
          </Button>
        </DialogActions>
      </Dialog>

      {/* Edit Dialog */}
      <Dialog
        open={openEditDialog}
        onClose={() => setOpenEditDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>Edit User</DialogTitle>
        <DialogContent>
          <Box component="form" sx={{ mt: 2 }} noValidate>
            <TextField
              margin="normal"
              required
              fullWidth
              id="name"
              label="Name"
              name="name"
              value={editFormData.name}
              onChange={handleEditFormChange}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="edit-username"
              label="Username"
              name="username"
              value={editFormData.username}
              onChange={handleEditFormChange}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="email"
              label="Email Address"
              name="email"
              value={editFormData.email}
              onChange={handleEditFormChange}
            />
            <FormControl fullWidth margin="normal">
              <InputLabel>Role</InputLabel>
              <Select
                name="role"
                value={editFormData.role}
                label="Role"
                onChange={handleEditFormChange}
              >
                <MenuItem value="user">User</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenEditDialog(false)}>Cancel</Button>
          <Button onClick={handleEditSubmit} variant="contained">
            Save Changes
          </Button>
        </DialogActions>
      </Dialog>

      {/* Add User Dialog */}
      <Dialog
        open={openAddDialog}
        onClose={() => setOpenAddDialog(false)}
        maxWidth="sm"
        fullWidth
      >
        <DialogTitle>
          <Box display="flex" alignItems="center" gap={1}>
            <PersonAddIcon />
            <Typography variant="h6">Add New User</Typography>
          </Box>
        </DialogTitle>
        <DialogContent>
          <Box component="form" sx={{ mt: 2 }} noValidate>
            <TextField
              margin="normal"
              required
              fullWidth
              id="add-name"
              label="Full Name"
              name="name"
              value={addFormData.name}
              onChange={handleAddFormChange}
              autoFocus
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="add-username"
              label="Username"
              name="username"
              value={addFormData.username}
              onChange={handleAddFormChange}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="add-email"
              label="Email Address"
              name="email"
              type="email"
              value={addFormData.email}
              onChange={handleAddFormChange}
            />
            <TextField
              margin="normal"
              required
              fullWidth
              id="add-password"
              label="Password"
              name="password"
              type="password"
              value={addFormData.password}
              onChange={handleAddFormChange}
              helperText="Minimum 6 characters"
            />
            <FormControl fullWidth margin="normal">
              <InputLabel>Role</InputLabel>
              <Select
                name="role"
                value={addFormData.role}
                label="Role"
                onChange={handleAddFormChange}
              >
                <MenuItem value="user">User</MenuItem>
                <MenuItem value="admin">Admin</MenuItem>
              </Select>
            </FormControl>
          </Box>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setOpenAddDialog(false)}>Cancel</Button>
          <Button 
            onClick={handleAddSubmit} 
            variant="contained"
            disabled={!addFormData.name || !addFormData.email || !addFormData.password}
          >
            Add User
          </Button>
        </DialogActions>
      </Dialog>

      {/* Snackbar for notifications */}
      <Snackbar 
        open={snackbar.open} 
        autoHideDuration={6000} 
        onClose={handleCloseSnackbar}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'right' }}
      >
        <Alert 
          onClose={handleCloseSnackbar} 
          severity={snackbar.severity} 
          variant="filled"
          sx={{ width: '100%' }}
        >
          {snackbar.message}
        </Alert>
      </Snackbar>
    </Box>
  );
};

export default Users;