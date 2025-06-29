import { useState, useEffect } from 'react';
import { Box, useMediaQuery, Drawer, useTheme } from '@mui/material';
import { ProSidebarProvider } from 'react-pro-sidebar';
import SidebarNav from './Sidebar';
import TopBar from './TopBar';

const AdminLayout = ({ children, toggleColorMode, currentMode }) => {
  // Media queries for different breakpoints
  const isMobile = useMediaQuery('(max-width: 768px)');
  const isTablet = useMediaQuery('(min-width: 769px) and (max-width: 1024px)');
  const isDesktop = useMediaQuery('(min-width: 1025px)');
  const theme = useTheme();
  
  // State for sidebar on mobile
  const [mobileOpen, setMobileOpen] = useState(false);
  const [defaultCollapsed, setDefaultCollapsed] = useState(false);
  
  // Update collapsed state based on screen size
  useEffect(() => {
    if (isMobile) {
      setDefaultCollapsed(true);
    } else if (isTablet) {
      setDefaultCollapsed(true);
    } else {
      setDefaultCollapsed(false);
    }
  }, [isMobile, isTablet, isDesktop]);
  
  // Toggle drawer for mobile view
  const handleDrawerToggle = () => {
    setMobileOpen(!mobileOpen);
  };

  return (
    <Box sx={{ 
      display: 'flex', 
      flexDirection: 'column', 
      height: '100vh', 
      overflow: 'hidden',
      bgcolor: theme.palette.background.default,
      color: theme.palette.text.primary
    }}>
      {/* Top bar is always visible */}
      <TopBar 
        onMenuToggle={handleDrawerToggle} 
        showMenuIcon={isMobile}
        toggleColorMode={toggleColorMode}
      />

      <Box sx={{ display: 'flex', flexGrow: 1, overflow: 'hidden' }}>
        {/* Sidebar - desktop & tablet view */}
        {!isMobile && (
          <ProSidebarProvider defaultCollapsed={defaultCollapsed}>
            <Box
              sx={{
                height: '100%',
                position: 'sticky',
                top: 0,
                '& .ps-sidebar-container': {
                  backgroundColor: `${theme.palette.background.paper} !important`,
                  borderRight: `1px solid ${theme.palette.divider}`,
                  boxShadow: 'none',
                },
                '& .ps-sidebar-container, .ps-sidebar-root': {
                  height: 'calc(100vh - 64px) !important',
                },
                flexShrink: 0,
              }}
            >
              <SidebarNav currentMode={currentMode} />
            </Box>
          </ProSidebarProvider>
        )}

        {/* Sidebar - mobile view (drawer) */}
        {isMobile && (
          <Drawer
            variant="temporary"
            open={mobileOpen}
            onClose={handleDrawerToggle}
            ModalProps={{
              keepMounted: true, // Better mobile performance
            }}
            sx={{
              '& .MuiDrawer-paper': {
                boxSizing: 'border-box',
                width: 280,
                backgroundColor: theme.palette.background.paper,
              },
              display: { xs: 'block', md: 'none' },
            }}
          >
            <ProSidebarProvider defaultCollapsed={false}>
              <SidebarNav onClose={handleDrawerToggle} currentMode={currentMode} />
            </ProSidebarProvider>
          </Drawer>
        )}

        {/* Main content area */}
        <Box
          component="main"
          sx={{
            flexGrow: 1,
            p: { xs: 2, sm: 3 },
            width: { xs: '100%', md: `calc(100% - ${defaultCollapsed ? '80px' : '280px'})` },
            backgroundColor: theme.palette.background.default,
            overflow: 'auto',
            height: 'calc(100vh - 64px)',
            transition: 'width 0.3s ease',
          }}
        >
          {children}
        </Box>
      </Box>
    </Box>
  );
};

export default AdminLayout; 