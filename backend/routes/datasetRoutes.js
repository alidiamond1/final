import express from "express";
import { 
    createDataset, 
    getDataset, 
    getAllDatasets, 
    downloadDataset, 
    upload, 
    updateDataset, 
    deleteDataset, 
    getDatasetStats, 
    getUserDatasets,
    getDownloadHistory, // Import the new controller function
} from "../controllers/datasetController.js";
import { protect, admin } from "../middleware/authMiddleware.js";

const router = express.Router();

// Create dataset - requires authentication and file upload
router.post("/", protect, upload.single('file'), createDataset);

// Get dataset statistics - requires admin privileges
router.get("/stats", protect, admin, getDatasetStats);

// Get download history - requires admin privileges
router.get("/downloads/history", protect, admin, getDownloadHistory);

// Get all datasets - requires authentication
router.get("/", protect, getAllDatasets);

// Get datasets by user - requires authentication
router.get("/user/:userId", protect, getUserDatasets);

// Get a single dataset - requires authentication
router.get("/:id", protect, getDataset);

// Download dataset - no authentication required to allow direct downloads from mobile
router.get("/:id/download", downloadDataset);


// Update dataset - requires authentication and admin privileges
router.put("/:id", protect, admin, upload.single('file'), updateDataset);

// Delete dataset - requires authentication and admin privileges
router.delete("/:id", protect, admin, deleteDataset);

export default router;
