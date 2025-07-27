import { useState, useEffect } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { Sidebar, Menu, MenuItem, SubMenu, useProSidebar } from 'react-pro-sidebar';
import {
  Box,
  IconButton,
  Typography,
  Avatar,
  Divider,
  Badge,
  Tooltip,
  useMediaQuery,
  useTheme,
} from '@mui/material';
import {
  Dashboard as DashboardIcon,
  Storage as DatasetIcon,
  Group as UsersIcon,
  CloudUpload as UploadIcon,
  Menu as MenuIcon,
  Logout as LogoutIcon,
  Settings as SettingsIcon,
  AccountCircle as ProfileIcon,
  MenuOpen as MenuOpenIcon,
  Language as LanguageIcon,
  Notifications as NotificationsIcon,
  Folder as FolderIcon,
  Close as CloseIcon,
  Person as PersonIcon,
} from '@mui/icons-material';
import { useAuth } from '../../context/AuthContext';
import defaultProfileImage from '../../assets/profile.jpg';

const API_URL = 'http://localhost:3000';

const SidebarNav = ({ onClose, currentMode }) => {
  const { user, logout } = useAuth();
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const { collapsed, collapseSidebar } = useProSidebar();
  const [active, setActive] = useState('');
  const theme = useTheme();
  
  const isMobile = useMediaQuery('(max-width: 768px)');

  // Get user profile image URL
  const getProfileImageUrl = () => {
    if (user && user.profileImage) {
      // Check if the image is a Base64 string or a relative path
      if (user.profileImage.startsWith('data:image')) {
        return user.profileImage; // It's a Base64 URI, use it directly
      }
      return `${API_URL}/${user.profileImage}`; // It's a relative path
    }
    return defaultProfileImage; // Fallback to default image
  };

  useEffect(() => {
    // Extract the current route from pathname to highlight active menu item
    const route = pathname.split('/')[2] || 'dashboard'; // default to dashboard
    setActive(route);
  }, [pathname]);

  // Handle menu item click on mobile to close the drawer
  const handleMenuItemClick = (path) => {
    if (isMobile && onClose) {
      navigate(path);
      onClose();
    }
  };

  // Menu sections for better organization
  const menuSections = [
    {
      title: 'Main',
      items: [
        {
          name: 'Dashboard',
          path: '/admin/dashboard',
          icon: <DashboardIcon />,
          key: 'dashboard'
        },
      ]
    },
    {
      title: 'Content',
      items: [
        {
          name: 'Datasets',
          path: '/admin/datasets',
          icon: <DatasetIcon />,
          key: 'datasets',
          badge: 4
        },
        {
          name: 'Upload Dataset',
          path: '/admin/upload',
          icon: <UploadIcon />,
          key: 'upload'
        },
        {
          name: 'Uploads By User',
          path: '/admin/uploads-by-user',
          icon: <PersonIcon />,
          key: 'uploads-by-user'
        },
      ]
    },
    {
      title: 'Admin',
      items: [
        {
          name: 'Users',
          path: '/admin/users',
          icon: <UsersIcon />,
          key: 'users',
          badge: 2
        },
        {
          name: 'Settings',
          path: '/admin/settings',
          icon: <SettingsIcon />,
          key: 'settings'
        },
      ]
    },
  ];

  // Handle logout with mobile support
  const handleLogout = () => {
    logout();
    if (isMobile && onClose) {
      onClose();
    }
  };

  // Get colors based on theme mode
  const getColors = () => {
    const isDark = theme.palette.mode === 'dark';
    
    return {
      sidebarBg: theme.palette.background.paper,
      menuItemBg: theme.palette.background.paper,
      menuItemColor: theme.palette.text.primary,
      menuItemColorActive: theme.palette.primary.main,
      menuItemBgActive: `${theme.palette.primary.main}15`,
      menuItemBgHover: `${theme.palette.primary.main}15`,
      dividerColor: theme.palette.divider,
      iconColor: isDark ? theme.palette.grey[400] : theme.palette.grey[700],
      textColor: theme.palette.text.primary,
      textColorSecondary: theme.palette.text.secondary,
    };
  };

  const colors = getColors();

  return (
    <Box
      sx={{
        display: 'flex',
        height: '100%',
        '& .ps-sidebar-root': {
          border: 'none !important',
          boxShadow: 'none',
          height: '100%',
        },
        '& .ps-menu-button': {
          padding: '12px 16px',
          borderRadius: '8px',
          margin: '4px 14px',
          transition: 'all 0.3s ease',
        },
        '& .ps-menu-button:hover': {
          backgroundColor: `${colors.menuItemBgHover} !important`,
          color: `${colors.menuItemColorActive} !important`,
        },
        '& .ps-menu-button.ps-active': {
          backgroundColor: `${colors.menuItemBgActive} !important`,
          color: `${colors.menuItemColorActive} !important`,
          fontWeight: 'bold',
          '& svg': {
            color: `${colors.menuItemColorActive} !important`,
          }
        },
        '& .ps-submenu-content': {
          backgroundColor: `${colors.menuItemBg} !important`,
        },
        '& .ps-menu-icon': {
          marginRight: '10px',
        },
      }}
    >
      <Sidebar
        backgroundColor={colors.sidebarBg}
        rootStyles={{
          border: 'none',
          height: '100%',
        }}
      >
        {/* HEADER */}
        <Box
          sx={{
            pt: 3,
            pb: 2,
            px: collapsed ? 2 : 3,
            display: 'flex',
            alignItems: 'center',
            justifyContent: collapsed ? 'center' : 'space-between',
          }}
        >
          {!collapsed && (
            <Box display="flex" alignItems="center" gap={1}>
              <LanguageIcon
                sx={{
                  color: colors.menuItemColorActive,
                  fontSize: 28,
                }}
              />
              <Typography
                variant="h5"
                color={colors.textColor}
                fontWeight="bold"
                sx={{ letterSpacing: '0.5px' }}
              >
                Somali Dataset
              </Typography>
            </Box>
          )}
          
          {/* For mobile, show close button instead of collapse */}
          {isMobile && onClose ? (
            <IconButton onClick={onClose}>
              <CloseIcon sx={{ color: colors.menuItemColorActive }} />
            </IconButton>
          ) : (
            <Tooltip title={collapsed ? "Expand" : "Collapse"} placement="right">
              <IconButton 
                onClick={() => collapseSidebar()}
                sx={{
                  backgroundColor: collapsed ? `${colors.menuItemBgActive}` : 'transparent',
                  borderRadius: '8px',
                  '&:hover': {
                    backgroundColor: `${colors.menuItemBgHover}`,
                  }
                }}
              >
                {collapsed ? (
                  <MenuIcon sx={{ color: colors.menuItemColorActive }} />
                ) : (
                  <MenuOpenIcon sx={{ color: colors.menuItemColorActive }} />
                )}
              </IconButton>
            </Tooltip>
          )}
        </Box>

        {/* USER INFO */}
        <Box
          sx={{
            pb: 3,
            px: collapsed ? 2 : 3,
            display: 'flex',
            flexDirection: collapsed ? 'column' : 'row',
            alignItems: 'center',
            gap: 2,
            mb: 1,
          }}
        >
          <Avatar
            src={getProfileImageUrl()}
            sx={{
              width: 46,
              height: 46,
              border: `2px solid ${colors.menuItemColorActive}`,
              boxShadow: '0 3px 5px rgba(0,0,0,0.1)',
            }}
          />
          {!collapsed && (
            <Box>
              <Typography variant="subtitle1" fontWeight="bold" noWrap color={colors.textColor}>
                {user?.name || 'Admin User'}
              </Typography>
              <Typography
                variant="caption"
                color={colors.textColorSecondary}
                noWrap
              >
                {user?.email || 'admin@example.com'}
              </Typography>
            </Box>
          )}
        </Box>

        <Divider
          sx={{
            mx: collapsed ? 2 : 3,
            backgroundColor: colors.dividerColor,
            mb: 2,
          }}
        />

        {/* MENU SECTIONS */}
        <Box sx={{ px: 0, pb: 5, overflowY: 'auto', flexGrow: 1 }}>
          {menuSections.map((section) => (
            <Box key={section.title} sx={{ mb: 2 }}>
              {!collapsed && (
                <Typography
                  variant="caption"
                  color={colors.textColorSecondary}
                  sx={{
                    px: 4,
                    py: 1,
                    display: 'block',
                    textTransform: 'uppercase',
                    fontWeight: 'bold',
                    letterSpacing: '1px',
                  }}
                >
                  {section.title}
                </Typography>
              )}
              
              <Menu
                menuItemStyles={{
                  button: ({ active }) => ({
                    color: active ? colors.menuItemColorActive : colors.menuItemColor,
                    '& .menu-icon': {
                      color: active ? colors.menuItemColorActive : colors.iconColor,
                    },
                  }),
                }}
              >
                {section.items.map((item) => (
                  <MenuItem
                    key={item.key}
                    component={isMobile ? undefined : <Link to={item.path} />}
                    active={active === item.key}
                    icon={
                      <span className="menu-icon">
                        {item.icon}
                      </span>
                    }
                    onClick={isMobile ? () => handleMenuItemClick(item.path) : undefined}
                    suffix={
                      item.badge && !collapsed ? (
                        <Badge
                          badgeContent={item.badge}
                          color="primary"
                          sx={{
                            '& .MuiBadge-badge': {
                              fontSize: '10px',
                              height: '18px',
                              minWidth: '18px',
                            }
                          }}
                        />
                      ) : null
                    }
                  >
                    <Typography variant="body2">{item.name}</Typography>
                  </MenuItem>
                ))}
              </Menu>
            </Box>
          ))}
        </Box>

        {/* BOTTOM ACTIONS */}
        <Box
          sx={{
            position: 'sticky',
            bottom: 0,
            width: '100%',
            pb: 2,
            pt: 2,
            borderTop: `1px solid ${colors.dividerColor}`,
            backgroundColor: colors.sidebarBg,
          }}
        >
          <Menu
            menuItemStyles={{
              button: {
                margin: '4px 14px',
                borderRadius: '8px',
                color: colors.menuItemColor,
                '&:hover': {
                  backgroundColor: '#fee2e2',
                  color: '#dc2626',
                },
              },
            }}
          >
            <MenuItem
              icon={<LogoutIcon />}
              onClick={handleLogout}
            >
              {!collapsed && <Typography variant="body2">Logout</Typography>}
            </MenuItem>
          </Menu>
        </Box>
      </Sidebar>
    </Box>
  );
};

export default SidebarNav;