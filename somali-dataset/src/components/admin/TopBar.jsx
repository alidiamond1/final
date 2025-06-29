import { useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../context/AuthContext';
import {
  AppBar,
  Box,
  Toolbar,
  IconButton,
  Typography,
  Avatar,
  Tooltip,
  Menu,
  MenuItem,
  ListItemIcon,
  useTheme,
} from '@mui/material';
import {
  Menu as MenuIcon,
  AccountCircle,
  Settings as SettingsIcon,
  Logout as LogoutIcon,
  Edit as EditIcon,
  LightMode as LightModeIcon,
  DarkMode as DarkModeIcon,
} from '@mui/icons-material';
import defaultProfileImage from '../../assets/profile.jpg';

const API_URL = 'http://localhost:3000';

const TopBar = ({ onMenuToggle, showMenuIcon = false, toggleColorMode }) => {
  const { user, logout } = useAuth();
  const theme = useTheme();
  const [anchorEl, setAnchorEl] = useState(null);
  const isDarkMode = theme.palette.mode === 'dark';

  // Get user profile image URL
  const getProfileImageUrl = () => {
    if (user && user.profileImage) {
      return `${API_URL}/${user.profileImage}`;
    }
    return defaultProfileImage;
  };

  const handleMenu = (event) => {
    setAnchorEl(event.currentTarget);
  };

  const handleClose = () => {
    setAnchorEl(null);
  };

  return (
    <AppBar 
      position="sticky"
      elevation={0}
      sx={{ 
        backgroundColor: theme.palette.background.paper,
        borderBottom: `1px solid ${theme.palette.divider}`,
        zIndex: (theme) => theme.zIndex.drawer + 1,
      }}
    >
      <Toolbar>
        {/* Menu Icon for Mobile */}
        {showMenuIcon && (
          <IconButton
            edge="start"
            color="inherit"
            aria-label="menu"
            onClick={onMenuToggle}
            sx={{ mr: 2 }}
          >
            <MenuIcon />
          </IconButton>
        )}

        {/* Logo and Title */}
        <Box sx={{ display: { xs: 'none', sm: 'flex' }, alignItems: 'center' }}>
          <Typography
            variant="h6"
            component={Link}
            to="/admin/dashboard"
            sx={{
              textDecoration: 'none',
              color: theme.palette.text.primary,
              fontWeight: 'bold',
            }}
          >
            Somali Dataset Admin
          </Typography>
        </Box>

        {/* Spacer */}
        <Box sx={{ flexGrow: 1 }} />

        {/* Theme Toggle */}
        <Tooltip title={isDarkMode ? "Switch to Light Mode" : "Switch to Dark Mode"}>
          <IconButton 
            onClick={toggleColorMode} 
            color="inherit"
            sx={{ mr: 1 }}
          >
            {isDarkMode ? <LightModeIcon /> : <DarkModeIcon />}
          </IconButton>
        </Tooltip>

        {/* User Profile */}
        <Box>
          <Tooltip title="Account settings">
            <IconButton
              onClick={handleMenu}
              size="small"
              sx={{ ml: 1 }}
              aria-controls="menu-appbar"
              aria-haspopup="true"
            >
              <Avatar 
                src={getProfileImageUrl()}
                sx={{ 
                  width: 40, 
                  height: 40,
                  border: `2px solid ${theme.palette.primary.main}` 
                }}
              >
                {!user && <AccountCircle />}
              </Avatar>
            </IconButton>
          </Tooltip>
          <Menu
            id="menu-appbar"
            anchorEl={anchorEl}
            anchorOrigin={{
              vertical: 'bottom',
              horizontal: 'right',
            }}
            keepMounted
            transformOrigin={{
              vertical: 'top',
              horizontal: 'right',
            }}
            open={Boolean(anchorEl)}
            onClose={handleClose}
            PaperProps={{
              sx: {
                mt: 1.5,
                width: 200,
                backgroundColor: theme.palette.background.paper,
                boxShadow: '0 8px 16px rgba(0,0,0,0.1)',
                '& .MuiMenuItem-root': {
                  px: 2,
                  py: 1.5,
                  borderRadius: 1,
                  m: 0.5,
                  '&:hover': {
                    backgroundColor: `${theme.palette.primary.main}15`,
                  },
                },
              },
            }}
          >
            <Box sx={{ px: 2, py: 1.5 }}>
              <Typography variant="subtitle1" fontWeight="bold" color="text.primary">
                {user?.name || 'Admin User'}
              </Typography>
              <Typography variant="body2" color="text.secondary">
                {user?.email || 'admin@example.com'}
              </Typography>
            </Box>
            
            <MenuItem component={Link} to="/admin/profile/edit" onClick={handleClose}>
              <ListItemIcon>
                <EditIcon fontSize="small" />
              </ListItemIcon>
              Edit Profile
            </MenuItem>
            
            <MenuItem component={Link} to="/admin/settings" onClick={handleClose}>
              <ListItemIcon>
                <SettingsIcon fontSize="small" />
              </ListItemIcon>
              Settings
            </MenuItem>
            
            <MenuItem onClick={() => { handleClose(); logout(); }}>
              <ListItemIcon>
                <LogoutIcon fontSize="small" />
              </ListItemIcon>
              Logout
            </MenuItem>
          </Menu>
        </Box>
      </Toolbar>
    </AppBar>
  );
};

export default TopBar;