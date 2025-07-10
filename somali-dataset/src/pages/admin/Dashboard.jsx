import { useState, useEffect } from "react";
import {
  Box,
  Typography,
  Grid,
  Card,
  CardContent,
  IconButton,
  CircularProgress,
  Avatar,
  Button,
  Divider,
  useMediaQuery,
  useTheme,
  Paper,
} from "@mui/material";
import { Link } from "react-router-dom";
import {
  MoreVert as MoreVertIcon,
  Dataset as DatasetIcon,
  Group as UsersIcon,
  CloudDownload as DownloadIcon,
  Storage as DatabaseIcon,
  Edit as EditIcon,
} from "@mui/icons-material";
import { ResponsiveBar } from "@nivo/bar";
import { ResponsivePie } from "@nivo/pie";
import { ResponsiveLine } from "@nivo/line";
import { getAllDatasets, getStats } from "../../api/datasets";
import { getAllUsers } from "../../api/auth";
import { themeColors } from "../../theme";
import defaultProfileImage from "../../assets/profile.jpg";
import { useAuth } from "../../context/AuthContext";
import { Line, Pie } from "react-chartjs-2";
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  ArcElement,
} from "chart.js";

// Register ChartJS components
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  ArcElement
);

const API_URL = "http://localhost:3000";

// Helper function to format bytes into a readable string (KB, MB, GB)
const formatBytes = (bytes, decimals = 2) => {
  if (bytes === 0) return '0 Bytes';
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return `${parseFloat((bytes / Math.pow(k, i)).toFixed(dm))} ${sizes[i]}`;
};

const Dashboard = () => {
  const { user } = useAuth();
  const theme = useTheme();
  const isMobile = useMediaQuery(theme.breakpoints.down("sm"));
  const isTablet = useMediaQuery(theme.breakpoints.between("sm", "md"));
  const isDark = theme.palette.mode === "dark";

  const [stats, setStats] = useState({
    datasets: 0,
    users: 0,
    downloads: 0,
    storage: 0,
  });
  const [datasets, setDatasets] = useState([]);
  const [users, setUsers] = useState([]);
  const [downloadData, setDownloadData] = useState([]);
  const [categoryData, setCategoryData] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  // Configure chart colors based on theme
  const chartColors = {
    primary: theme.palette.primary.main,
    secondary: theme.palette.secondary.main,
    background: theme.palette.background.paper,
    text: theme.palette.text.primary,
    grid: isDark ? "rgba(255, 255, 255, 0.1)" : "rgba(0, 0, 0, 0.1)",
    pieColors: [
      theme.palette.primary.main,
      theme.palette.secondary.main,
      theme.palette.info.main,
      theme.palette.success.main,
      theme.palette.warning.main,
      theme.palette.error.main,
      theme.palette.primary.dark,
      theme.palette.secondary.dark,
      theme.palette.info.dark,
      theme.palette.success.dark,
    ],
  };

  // Line chart options
  const lineChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: "top",
        labels: {
          color: chartColors.text,
        },
      },
      title: {
        display: false,
      },
      tooltip: {
        backgroundColor: chartColors.background,
        titleColor: chartColors.text,
        bodyColor: chartColors.text,
        borderColor: theme.palette.divider,
        borderWidth: 1,
      },
    },
    scales: {
      x: {
        grid: {
          color: chartColors.grid,
        },
        ticks: {
          color: chartColors.text,
        },
      },
      y: {
        grid: {
          color: chartColors.grid,
        },
        ticks: {
          color: chartColors.text,
        },
      },
    },
  };

  // Pie chart options
  const pieChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: "right",
        labels: {
          color: chartColors.text,
        },
      },
      tooltip: {
        backgroundColor: chartColors.background,
        titleColor: chartColors.text,
        bodyColor: chartColors.text,
        borderColor: theme.palette.divider,
        borderWidth: 1,
      },
    },
  };

  // Generate a consistent color from a string
  const generateColorFromString = (str) => {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    let color = "#";
    for (let i = 0; i < 3; i++) {
      const value = (hash >> (i * 8)) & 0xff;
      color += ("00" + value.toString(16)).substr(-2);
    }
    return color;
  };

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
    const fetchData = async () => {
      try {
        setLoading(true);
        // Fetch all data in parallel, including the new stats endpoint
        const [datasetsData, usersData, statsData] = await Promise.all([
          getAllDatasets(),
          getAllUsers(),
          getStats(),
        ]);

        setDatasets(datasetsData || []);
        setUsers(usersData || []);

        // Process data for charts
        const categoryDistribution = processCategories(datasetsData || []);
        const downloadHistory = generateDownloadData(datasetsData || []);

        // Set stats directly from the API response
        setStats({
          datasets: (datasetsData || []).length,
          users: (usersData || []).length,
          downloads: statsData.downloads || 0,
          storage: formatBytes(statsData.storage || 0),
        });

        setCategoryData(categoryDistribution);
        setDownloadData(downloadHistory);
      } catch (err) {
        console.error("Failed to fetch dashboard data:", err);
        setError("Could not load dashboard data. Please try again later.");
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  // Process datasets to get category distribution
  const processCategories = (datasets) => {
    const categoryCounts = {};

    // Count datasets by type/category
    datasets.forEach((dataset) => {
      const type = dataset.type.toLowerCase();
      if (categoryCounts[type]) {
        categoryCounts[type]++;
      } else {
        categoryCounts[type] = 1;
      }
    });

    // Convert to format needed for pie chart
    return Object.keys(categoryCounts).map((category) => ({
      id: category,
      label: category.charAt(0).toUpperCase() + category.slice(1),
      value: categoryCounts[category],
    }));
  };

  // Generate download data based on dataset creation dates
  const generateDownloadData = (datasets) => {
    // Create a map of months
    const months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    const downloadsByMonth = {};

    // Initialize all months with 0
    months.forEach((month) => {
      downloadsByMonth[month] = 0;
    });

    // Count datasets created in each month (simulating downloads)
    datasets.forEach((dataset) => {
      if (dataset.createdAt) {
        const date = new Date(dataset.createdAt);
        const month = months[date.getMonth()];

        // Assume each dataset has random downloads between 10-100
        const randomDownloads = Math.floor(Math.random() * 90) + 10;
        downloadsByMonth[month] += randomDownloads;
      }
    });

    // Convert to format needed for line chart
    return months.map((month) => ({
      month,
      downloads: downloadsByMonth[month],
    }));
  };



  if (loading) {
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="80vh"
      >
        <CircularProgress />
      </Box>
    );
  }

  if (error) {
    return (
      <Box
        display="flex"
        justifyContent="center"
        alignItems="center"
        minHeight="80vh"
      >
        <Typography variant="h4" color="error">
          {error}
        </Typography>
      </Box>
    );
  }

  return (
    <Box>
      {/* Profile Card */}
      <Card
        sx={{
          borderRadius: 3,
          mb: 4,
          overflow: "hidden",
          backgroundColor: theme.palette.background.paper,
        }}
      >
        <Box
          sx={{
            height: 120,
            backgroundColor: theme.palette.primary.main,
            position: "relative",
          }}
        />
        <CardContent sx={{ position: "relative", mt: -8, pb: 3 }}>
          <Box
            display="flex"
            flexDirection={isMobile ? "column" : "row"}
            alignItems={isMobile ? "center" : "flex-end"}
            justifyContent="space-between"
          >
            <Box
              display="flex"
              flexDirection={isMobile ? "column" : "row"}
              alignItems={isMobile ? "center" : "flex-end"}
              mb={isMobile ? 2 : 0}
            >
              <Avatar
                src={getProfileImageUrl()}
                sx={{
                  width: isMobile ? 100 : 120,
                  height: isMobile ? 100 : 120,
                  border: "4px solid white",
                  boxShadow: "0px 4px 10px rgba(0,0,0,0.1)",
                }}
              />
              <Box
                ml={isMobile ? 0 : 3}
                mt={isMobile ? 2 : 0}
                mb={1}
                textAlign={isMobile ? "center" : "left"}
              >
                <Typography
                  variant={isMobile ? "h5" : "h4"}
                  fontWeight="bold"
                  color="text.primary"
                >
                  {user?.name || "Admin User"}
                </Typography>
                <Typography variant="body1" color="text.secondary">
                  {user?.email || "admin@example.com"}
                </Typography>
              </Box>
            </Box>
            <Button
              component={Link}
              to="/admin/profile/edit"
              variant="outlined"
              startIcon={<EditIcon />}
              sx={{
                borderRadius: 2,
                textTransform: "none",
                borderColor: theme.palette.divider,
                color: theme.palette.text.secondary,
                "&:hover": {
                  borderColor: theme.palette.text.primary,
                  backgroundColor: `${theme.palette.action.hover}`,
                },
              }}
            >
              Edit Profile
            </Button>
          </Box>
        </CardContent>
      </Card>

      <Box
        display="flex"
        flexDirection={isMobile ? "column" : "row"}
        justifyContent="space-between"
        alignItems={isMobile ? "flex-start" : "center"}
        mb={3}
      >
        <Typography
          variant={isMobile ? "h3" : "h2"}
          fontWeight="bold"
          color="text.primary"
          mb={isMobile ? 1 : 0}
        >
          Dashboard
        </Typography>
        <Typography variant="body1" color="text.secondary">
          Welcome to the Somali Dataset Admin Dashboard
        </Typography>
      </Box>

      {/* STATS CARDS */}
      <Grid container spacing={2} mb={4}>
        {/* DATASET COUNT */}
        <Grid item xs={12} sm={6} md={3}>
          <Paper
            elevation={0}
            sx={{
              p: 3,
              borderRadius: 2,
              backgroundColor: theme.palette.background.paper,
              border: `1px solid ${theme.palette.divider}`,
            }}
          >
            <Box
              display="flex"
              justifyContent="space-between"
              alignItems="center"
            >
              <Box>
                <Typography variant="body2" color="text.secondary" mb={1}>
                  Total Datasets
                </Typography>
                <Typography variant="h4" fontWeight="bold" color="text.primary">
                  {stats.datasets}
                </Typography>
              </Box>
              <Box
                sx={{
                  backgroundColor: theme.palette.primary.main,
                  color: "white",
                  p: 1.5,
                  borderRadius: 2,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <DatasetIcon sx={{ fontSize: 40 }} />
              </Box>
            </Box>
          </Paper>
        </Grid>

        {/* USERS COUNT */}
        <Grid item xs={12} sm={6} md={3}>
          <Paper
            elevation={0}
            sx={{
              p: 3,
              borderRadius: 2,
              backgroundColor: theme.palette.background.paper,
              border: `1px solid ${theme.palette.divider}`,
            }}
          >
            <Box
              display="flex"
              justifyContent="space-between"
              alignItems="center"
            >
              <Box>
                <Typography variant="body2" color="text.secondary" mb={1}>
                  Registered Users
                </Typography>
                <Typography variant="h4" fontWeight="bold" color="text.primary">
                  {stats.users}
                </Typography>
              </Box>
              <Box
                sx={{
                  backgroundColor: theme.palette.info.main,
                  color: "white",
                  p: 1.5,
                  borderRadius: 2,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <UsersIcon sx={{ fontSize: 40 }} />
              </Box>
            </Box>
          </Paper>
        </Grid>

        {/* DOWNLOADS COUNT */}
        <Grid item xs={12} sm={6} md={3}>
          <Paper
            elevation={0}
            sx={{
              p: 3,
              borderRadius: 2,
              backgroundColor: theme.palette.background.paper,
              border: `1px solid ${theme.palette.divider}`,
            }}
          >
            <Box
              display="flex"
              justifyContent="space-between"
              alignItems="center"
            >
              <Box>
                <Typography variant="body2" color="text.secondary" mb={1}>
                  Total Downloads
                </Typography>
                <Typography variant="h4" fontWeight="bold" color="text.primary">
                  {stats.downloads}
                </Typography>
              </Box>
              <Box
                sx={{
                  backgroundColor: theme.palette.success.main,
                  color: "white",
                  p: 1.5,
                  borderRadius: 2,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <DownloadIcon sx={{ fontSize: 40 }} />
              </Box>
            </Box>
          </Paper>
        </Grid>

        {/* STORAGE USED */}
        <Grid item xs={12} sm={6} md={3}>
          <Paper
            elevation={0}
            sx={{
              p: 3,
              borderRadius: 2,
              backgroundColor: theme.palette.background.paper,
              border: `1px solid ${theme.palette.divider}`,
            }}
          >
            <Box
              display="flex"
              justifyContent="space-between"
              alignItems="center"
            >
              <Box>
                <Typography variant="body2" color="text.secondary" mb={1}>
                  Storage Used
                </Typography>
                <Typography variant="h4" fontWeight="bold" color="text.primary">
                  {`${stats.storage} MB`}
                </Typography>
              </Box>
              <Box
                sx={{
                  backgroundColor: theme.palette.warning.main,
                  color: "white",
                  p: 1.5,
                  borderRadius: 2,
                  display: "flex",
                  alignItems: "center",
                  justifyContent: "center",
                }}
              >
                <DatabaseIcon sx={{ fontSize: 40 }} />
              </Box>
            </Box>
          </Paper>
        </Grid>
      </Grid>

      {/* CHARTS */}
      <Grid container spacing={3}>
        {/* DOWNLOADS CHART */}
        <Grid item xs={12} lg={8}>
          <Card
            elevation={0}
            sx={{
              borderRadius: 2,
              height: "100%",
              backgroundColor: theme.palette.background.paper,
              border: `1px solid ${theme.palette.divider}`,
            }}
          >
            <CardContent>
              <Box
                display="flex"
                justifyContent="space-between"
                alignItems="center"
                mb={2}
              >
                <Typography variant="h6" fontWeight="bold" color="text.primary">
                  Downloads Over Time
                </Typography>
                <IconButton size="small">
                  <MoreVertIcon />
                </IconButton>
              </Box>
              <Box sx={{ height: 300 }}>
                {downloadData.length > 0 ? (
                  <Line
                    data={{
                      labels: downloadData.map((item) => item.month),
                      datasets: [
                        {
                          label: "Downloads",
                          data: downloadData.map((item) => item.downloads),
                          borderColor: chartColors.primary,
                          backgroundColor: `${chartColors.primary}20`,
                          tension: 0.4,
                          fill: true,
                        },
                      ],
                    }}
                    options={lineChartOptions}
                  />
                ) : (
                  <Box
                    display="flex"
                    alignItems="center"
                    justifyContent="center"
                    height="100%"
                  >
                    <Typography variant="body1" color="text.secondary">
                      No download data available
                    </Typography>
                  </Box>
                )}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* CATEGORY DISTRIBUTION */}
        <Grid item xs={12} lg={4}>
          <Card
            elevation={0}
            sx={{
              borderRadius: 2,
              height: "100%",
              backgroundColor: theme.palette.background.paper,
              border: `1px solid ${theme.palette.divider}`,
            }}
          >
            <CardContent>
              <Box
                display="flex"
                justifyContent="space-between"
                alignItems="center"
                mb={2}
              >
                <Typography variant="h6" fontWeight="bold" color="text.primary">
                  Dataset Categories
                </Typography>
                <IconButton size="small">
                  <MoreVertIcon />
                </IconButton>
              </Box>
              <Box sx={{ height: 300, position: "relative" }}>
                {categoryData.length > 0 ? (
                  <Pie
                    data={{
                      labels: categoryData.map((item) => item.label),
                      datasets: [
                        {
                          data: categoryData.map((item) => item.value),
                          backgroundColor: categoryData.map((item) =>
                            generateColorFromString(item.id)
                          ),
                          borderColor: isDark
                            ? theme.palette.background.paper
                            : "#fff",
                          borderWidth: 2,
                        },
                      ],
                    }}
                    options={pieChartOptions}
                  />
                ) : (
                  <Box
                    display="flex"
                    alignItems="center"
                    justifyContent="center"
                    height="100%"
                  >
                    <Typography variant="body1" color="text.secondary">
                      No category data available
                    </Typography>
                  </Box>
                )}
              </Box>
            </CardContent>
          </Card>
        </Grid>

        {/* RECENT ACTIVITY */}
        <Grid item xs={12}>
          <Card
            elevation={0}
            sx={{
              borderRadius: 2,
              backgroundColor: theme.palette.background.paper,
              border: `1px solid ${theme.palette.divider}`,
            }}
          >
            <CardContent>
              <Box
                display="flex"
                justifyContent="space-between"
                alignItems="center"
                mb={2}
              >
                <Typography variant="h6" fontWeight="bold" color="text.primary">
                  Recent Datasets
                </Typography>
                <Button
                  component={Link}
                  to="/admin/datasets"
                  variant="text"
                  size="small"
                  sx={{
                    color: theme.palette.primary.main,
                    "&:hover": {
                      backgroundColor: "transparent",
                      color: theme.palette.primary.dark,
                    },
                  }}
                >
                  View All
                </Button>
              </Box>

              <Box py={1}>
                {datasets.length > 0 ? (
                  datasets.slice(0, 5).map((dataset, index) => (
                    <Box key={dataset._id || index}>
                      <Box
                        display="flex"
                        flexDirection={isMobile ? "column" : "row"}
                        justifyContent={
                          isMobile ? "flex-start" : "space-between"
                        }
                        alignItems={isMobile ? "flex-start" : "center"}
                        py={1.5}
                      >
                        <Box>
                          <Typography
                            variant="body1"
                            fontWeight="medium"
                            color="text.primary"
                          >
                            {dataset.title}
                          </Typography>
                          <Typography variant="body2" color="text.secondary">
                            {dataset.type} • {dataset.size}
                          </Typography>
                        </Box>
                        <Typography
                          variant="body2"
                          color="text.secondary"
                          mt={isMobile ? 1 : 0}
                        >
                          {dataset.createdAt
                            ? new Date(dataset.createdAt).toLocaleDateString()
                            : "Unknown date"}
                        </Typography>
                      </Box>
                      {index < datasets.slice(0, 5).length - 1 && <Divider />}
                    </Box>
                  ))
                ) : (
                  <Typography
                    variant="body2"
                    color="text.secondary"
                    textAlign="center"
                    py={4}
                  >
                    No datasets available
                  </Typography>
                )}
              </Box>
            </CardContent>
          </Card>
        </Grid>
      </Grid>
    </Box>
  );
};

export default Dashboard;
