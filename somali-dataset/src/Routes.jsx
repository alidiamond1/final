import { useState, useMemo } from 'react';
import { Routes, Route, Navigate } from 'react-router-dom';
import { useAuth } from './context/AuthContext';
import { createTheme, ThemeProvider, CssBaseline } from '@mui/material';
import { themeSettings } from './theme';

// Admin components
import AdminLogin from './pages/admin/Login';
import Dashboard from './pages/admin/Dashboard';
import Users from './pages/admin/Users';
import Datasets from './pages/admin/Datasets';
import UploadDataset from './pages/admin/UploadDataset';
import Settings from './pages/admin/Settings';
import EditProfile from './pages/admin/EditProfile';
import AdminLayout from './components/admin/Layout';

const AppRoutes = () => {
  const { isAuthenticated, loading } = useAuth();
  const [mode, setMode] = useState('light');

  // Theme toggle handler
  const toggleColorMode = () => {
    setMode((prevMode) => (prevMode === 'light' ? 'dark' : 'light'));
  };

  // Create theme with current mode
  const theme = useMemo(() => {
    const baseTheme = themeSettings;
    
    // Deep merge for dark mode
    if (mode === 'dark') {
      return createTheme({
        ...baseTheme,
        palette: {
          ...baseTheme.palette,
          mode: 'dark',
          primary: {
            ...baseTheme.palette.primary,
            main: baseTheme.palette.primary[400], // Lighter shade for dark mode
          },
          background: {
            default: '#121212',
            paper: '#1e1e1e',
            light: '#1e1e1e',
            main: '#121212',
            dark: '#0a0a0a',
          },
          text: {
            primary: '#ffffff',
            secondary: 'rgba(255, 255, 255, 0.7)',
          },
          divider: 'rgba(255, 255, 255, 0.12)',
          grey: {
            ...baseTheme.palette.grey,
            100: '#2c2c2c',
            200: '#333333',
            300: '#4d4d4d',
            400: '#666666',
            500: '#808080',
            600: '#999999',
            700: '#b3b3b3',
            800: '#cccccc',
            900: '#e6e6e6',
          },
        },
        components: {
          ...baseTheme.components,
          MuiPaper: {
            styleOverrides: {
              root: {
                backgroundColor: '#1e1e1e',
              },
            },
          },
          MuiAppBar: {
            styleOverrides: {
              root: {
                backgroundColor: '#1e1e1e',
                borderBottom: '1px solid rgba(255, 255, 255, 0.12)',
              },
            },
          },
          MuiDrawer: {
            styleOverrides: {
              paper: {
                backgroundColor: '#1e1e1e',
              },
            },
          },
        },
      });
    }
    
    // Light mode theme
    return createTheme(baseTheme);
  }, [mode]);

  // Protected route wrapper
  const AdminRoute = ({ children }) => {
    if (loading) return null;
    return isAuthenticated ? children : <Navigate to="/admin/login" />;
  };

  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Routes>
        {/* Admin Routes */}
        <Route path="/admin/login" element={<AdminLogin />} />
        <Route
          path="/admin/dashboard"
          element={
            <AdminRoute>
              <AdminLayout toggleColorMode={toggleColorMode} currentMode={mode}>
                <Dashboard />
              </AdminLayout>
            </AdminRoute>
          }
        />
        <Route
          path="/admin/users"
          element={
            <AdminRoute>
              <AdminLayout toggleColorMode={toggleColorMode} currentMode={mode}>
                <Users />
              </AdminLayout>
            </AdminRoute>
          }
        />
        <Route
          path="/admin/datasets"
          element={
            <AdminRoute>
              <AdminLayout toggleColorMode={toggleColorMode} currentMode={mode}>
                <Datasets />
              </AdminLayout>
            </AdminRoute>
          }
        />
        <Route
          path="/admin/upload"
          element={
            <AdminRoute>
              <AdminLayout toggleColorMode={toggleColorMode} currentMode={mode}>
                <UploadDataset />
              </AdminLayout>
            </AdminRoute>
          }
        />
        <Route
          path="/admin/settings"
          element={
            <AdminRoute>
              <AdminLayout toggleColorMode={toggleColorMode} currentMode={mode}>
                <Settings />
              </AdminLayout>
            </AdminRoute>
          }
        />
        <Route
          path="/admin/profile/edit"
          element={
            <AdminRoute>
              <AdminLayout toggleColorMode={toggleColorMode} currentMode={mode}>
                <EditProfile />
              </AdminLayout>
            </AdminRoute>
          }
        />
        <Route
          path="/admin/*"
          element={<Navigate to="/admin/dashboard" replace />}
        />

        {/* Default route */}
        <Route path="*" element={<Navigate to="/admin/login" replace />} />
      </Routes>
    </ThemeProvider>
  );
};

export default AppRoutes; 