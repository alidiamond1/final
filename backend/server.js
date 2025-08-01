import express from "express";
import dotenv from "dotenv";
import cors from "cors";
import mongoose from "mongoose";
import path from "path";
import { fileURLToPath } from "url";
import userRoute from "./routes/userRoute.js";
import datasetRoute from "./routes/datasetRoutes.js";
import descriptionRoute from "./routes/descriptionRoutes.js";
import connectDB from "./config/db.js";

// Import models to ensure they're registered with mongoose
import "./model/userModel.js";
import "./model/datasetModel.js";
import "./model/destcriptionModel.js";

dotenv.config();

// Get current directory path
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Define temp uploads directory (only used temporarily during upload)
const tempUploadsDir = path.join(__dirname, 'temp-uploads');

// Connect to MongoDB with retry logic
let retries = 0;
const maxRetries = 5;

function connectWithRetry() {
  console.log('MongoDB connection attempt #', retries + 1);
  
  connectDB().then(() => {
    // Check if we're actually connected
    if (mongoose.connection.readyState === 1) {
      console.log('MongoDB connected successfully');
    } else {
      if (retries < maxRetries) {
        retries++;
        // Wait 5 seconds before retrying
        setTimeout(connectWithRetry, 5000);
      } else {
        console.log('MongoDB connection failed after', maxRetries, 'attempts');
      }
    }
  }).catch(err => {
    if (retries < maxRetries) {
      retries++;
      // Wait 5 seconds before retrying
      setTimeout(connectWithRetry, 5000);
    } else {
      console.log('MongoDB connection failed after', maxRetries, 'attempts');
    }
  });
}

connectWithRetry();
const app = express();

// A more robust CORS configuration
const corsOptions = {
    origin: '*', // You can restrict this to specific origins in production
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE',
    credentials: true,
    exposedHeaders: ['Content-Length', 'Content-Disposition'], // Expose necessary headers
};

app.use(cors(corsOptions));
// Handle pre-flight requests across all routes
app.options('*', cors(corsOptions));

app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from the uploads directory
app.use('/uploads', (req, res, next) => {
  res.header('Access-Control-Allow-Origin', '*');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
  next();
}, express.static(path.join(__dirname, 'uploads')));

// API routes
app.use("/api/users", userRoute);
app.use("/api/datasets", datasetRoute);
app.use("/api/descriptions", descriptionRoute);

// Add health check endpoint for testing connection
app.get('/api/health', (req, res) => {
  res.status(200).json({ 
    status: 'ok', 
    mongo: mongoose.connection.readyState === 1 ? 'connected' : 'disconnected',
    environment: process.env.NODE_ENV || 'development'
  });
});

// Serve test page for connection testing
app.get('/test', (req, res) => {
  res.sendFile(path.join(__dirname, 'test.html'));
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Server running on port ${PORT}`));