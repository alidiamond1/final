import Dataset from "../model/datasetModel.js";
import User from "../model/userModel.js";
import Download from "../model/downloadModel.js";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";
import multer from "multer";
import mongoose from "mongoose";
import crypto from "crypto";
import dotenv from "dotenv";

dotenv.config();

// Get the current directory path
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Set up a temporary disk storage for multer
const tempDir = path.join(__dirname, '../temp-uploads');
// Create the directory if it doesn't exist
if (!fs.existsSync(tempDir)) {
  fs.mkdirSync(tempDir, { recursive: true });
}

// Configure multer for temporary file storage
const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, tempDir);
  },
  filename: function (req, file, cb) {
    // Create unique filename with original extension
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, file.fieldname + '-' + uniqueSuffix + ext);
  }
});

// File filter to validate file types
const fileFilter = (req, file, cb) => {
  // Allowed file types
  const allowedTypes = [
    'text/csv',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/json',
    'text/plain',
    'application/pdf',
    'image/jpeg',
    'image/png',
    'audio/mpeg',
    'audio/wav',
    'video/mp4',
    'application/zip',
    'application/x-zip-compressed',
    'application/octet-stream'
  ];
  
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new Error(`File type not allowed. Supported types: CSV, Excel, JSON, Text, PDF, Images, Audio, Video`), false);
  }
};

// Configure multer middleware
export const upload = multer({ 
  storage: storage,
  fileFilter: fileFilter,
  limits: {
    fileSize: 100 * 1024 * 1024 // 100 MB limit
  }
});

export const createDataset = async (req, res) => {
    try {
        // Add debug logging to see what's coming in the request
        console.log('📥 Received dataset upload request');
        console.log('📋 Request body:', req.body);
        console.log('📎 Request file:', req.file ? {
            filename: req.file.originalname,
            mimetype: req.file.mimetype,
            size: req.file.size,
            path: req.file.path
        } : '❌ No file uploaded');

        const { title, description, type } = req.body;
        
        if (!title || !description || !type) {
            console.error('❌ Missing required fields');
            return res.status(400).json({ error: "Title, description, and type are required" });
        }
        
        // Check if a file was uploaded
        let fileId = null;
        let fileName = null;
        let size = "0 bytes";
        let fileContent = null;
        let fileContentType = null;
        
        if (req.file) {
            console.log(`📁 Processing file upload: ${req.file.originalname} (${req.file.size} bytes)`);
            
            try {
                // Verify the file exists on disk before attempting to process
                if (!fs.existsSync(req.file.path)) {
                    console.error(`❌ File not found at path: ${req.file.path}`);
                    return res.status(500).json({ error: "Uploaded file not found on server" });
                }
                
                console.log(`✅ File exists at ${req.file.path}, proceeding with storage`);
                
                // Generate a unique fileId
                fileId = crypto.randomBytes(16).toString('hex');
                fileName = req.file.originalname;
                size = req.file.size; // Store size in bytes
                fileContentType = req.file.mimetype;
                
                // Read file content into buffer
                fileContent = fs.readFileSync(req.file.path);
                console.log(`✅ File content read into buffer: ${formatFileSize(fileContent.length)}`);
                
                // Clean up the temporary file
                fs.unlink(req.file.path, (err) => {
                    if (err) {
                        console.error(`❌ Error deleting temp file: ${err.message}`);
                    } else {
                        console.log(`✅ Temp file deleted: ${req.file.path}`);
                    }
                });
            } catch (err) {
                console.error("❌ Failed to process file:", err);
                return res.status(500).json({ error: "Failed to process file: " + err.message });
            }
        } else {
            console.log('ℹ️ No file was included in the request');
        }
        
        // Create dataset with file information if available
        const dataset = await Dataset.create({ 
            title, 
            description, 
            type, 
            size,
            fileName,
            fileId,
            fileContent,
            fileContentType,
            user: req.user._id // Save the user ID from authentication
        });
        
        console.log('✅ Dataset created successfully:', dataset._id);
        
        // Don't include the fileContent in the response
        const responseDataset = {
            _id: dataset._id,
            title: dataset.title,
            description: dataset.description,
            type: dataset.type,
            size: dataset.size,
            fileName: dataset.fileName,
            fileId: dataset.fileId,
            createdAt: dataset.createdAt
        };
        
        res.status(201).json({ dataset: responseDataset });
    } catch (error) {
        console.error("❌ Error creating dataset:", error);
        
        // If there was an error and a temp file exists, delete it
        if (req.file && req.file.path) {
            fs.unlink(req.file.path, (err) => {
                if (err) console.error("❌ Error deleting temp file:", err);
                else console.log("✅ Temp file deleted:", req.file.path);
            });
        }
        
        res.status(500).json({ error: error.message });
    }
};

// Helper function to format file size
function formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes';
    
    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    
    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}



export const getDataset = async (req, res) => {
    try {
        const { id } = req.params;
        
        // Exclude fileContent from the response to save bandwidth
        // Populate user information
        const dataset = await Dataset.findById(id)
            .select('-fileContent')
            .populate('user', 'name email profileImage');
        
        if (!dataset) {
            return res.status(404).json({ error: "Dataset not found" });
        }
        
        res.status(200).json({ dataset });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const getAllDatasets = async (req, res) => {
    try {
        // Exclude fileContent from the response to save bandwidth
        // Populate user information
        const datasets = await Dataset.find()
            .select('-fileContent')
            .populate('user', 'name email profileImage'); // Populate user data
        
        res.status(200).json({ datasets });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const downloadDataset = async (req, res) => {
    try {
        const { id } = req.params;
        console.log(`📥 Downloading dataset: ${id}`);

        // Get user information if available
        const userId = req.query.userId || null;
        let user = null;
        
        if (userId) {
            try {
                user = await User.findById(userId);
            } catch (err) {
                console.error(`❌ Error finding user: ${err.message}`);
                // Continue even if user lookup fails
            }
        }

        // Atomically increment the download count before sending the file
        await Dataset.findByIdAndUpdate(id, { $inc: { downloads: 1 } });

        const dataset = await Dataset.findById(id);
        
        if (!dataset) {
            console.error(`❌ Dataset not found: ${id}`);
            return res.status(404).json({ error: "Dataset not found" });
        }
        
        // Record download in the Download collection
        try {
            await Download.create({
                dataset: dataset._id,
                user: userId || undefined,
                ipAddress: req.ip || req.connection.remoteAddress,
                userAgent: req.headers['user-agent']
            });
            console.log(`✅ Download recorded for dataset: ${dataset.title}`);
        } catch (err) {
            console.error(`❌ Error recording download: ${err.message}`);
            // Continue even if recording fails
        }
        
        // If the dataset has file content, serve it
        if (dataset.fileContent && dataset.fileName) {
            try {
                console.log(`📂 Serving file from database: ${dataset.fileName} (${dataset.size})`);
                
                // Determine content type
                let contentType = dataset.fileContentType || 'application/octet-stream'; // Use stored content type or default
                
                // Set appropriate headers for download
                res.set('Content-Type', contentType);
                res.set('Content-Disposition', `attachment; filename="${dataset.fileName}"`);
                // Use the length of the buffer for an accurate Content-Length
                res.set('Content-Length', dataset.fileContent.length);
                
                // Send the file content directly from the database
                console.log(`🚀 Sending file content to client...`);
                res.send(dataset.fileContent);
                
            } catch (err) {
                console.error(`❌ Error downloading file: ${err.message}`);
                res.status(500).json({ error: `Error downloading file: ${err.message}` });
            }
        } else {
            console.error(`❌ No file associated with dataset: ${id}`);
            res.status(404).json({ error: "No file associated with this dataset" });
        }
    } catch (error) {
        console.error(`❌ Error downloading dataset: ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

// Get download history
export const getDownloadHistory = async (req, res) => {
    try {
        const history = await Download.aggregate([
            {
                $group: {
                    _id: { $dateToString: { format: "%Y-%m-%d", date: "$downloadedAt" } },
                    downloads: { $sum: 1 }
                }
            },
            {
                $sort: { _id: 1 }
            }
        ]);
        
        res.status(200).json(history);
    } catch (error) {
        console.error('❌ Error fetching download history:', error);
        res.status(500).json({ error: 'Server error while fetching download history' });
    }
};
// Get dataset statistics (total downloads and storage)
export const getDatasetStats = async (req, res) => {
    try {
        // Fetch all datasets to compute totals
        const datasets = await Dataset.find({}, 'size downloads');

        let totalDownloads = 0;
        let totalStorage = 0; // in bytes

        datasets.forEach(ds => {
            // Safely add downloads
            totalDownloads += (ds.downloads && typeof ds.downloads === 'number') ? ds.downloads : 0;

            // Safely calculate and add storage
            let sizeBytes = 0;
            if (ds.size) { // Check if size is not null or undefined
                if (typeof ds.size === 'number') {
                    sizeBytes = ds.size;
                } else if (typeof ds.size === 'string') {
                    const match = ds.size.match(/(\d+\.?\d*)\s*(B|KB|MB|GB|TB)?/i);
                    if (match) {
                        const value = parseFloat(match[1]);
                        const unit = (match[2] || 'B').toUpperCase();
                        const multipliers = { B: 1, KB: 1024, MB: 1024 ** 2, GB: 1024 ** 3, TB: 1024 ** 4 };
                        sizeBytes = value * (multipliers[unit] || 1);
                    }
                }
            }
            totalStorage += sizeBytes;
        });

        // Return raw numbers for the frontend to format
        return res.json({
            downloads: totalDownloads,
            storage: totalStorage, // Send raw bytes
        });
    } catch (error) {
        console.error('❌ Error fetching dataset stats:', error);
        return res.status(500).json({ error: 'Server error while fetching stats' });
    }
};

// Get datasets by user ID
export const getUserDatasets = async (req, res) => {
    try {
        const { userId } = req.params;
        console.log(`📋 Fetching datasets for user: ${userId}`);
        
        // If the requesting user is not an admin, verify they are requesting their own datasets
        if (req.user.role !== 'admin' && req.user._id.toString() !== userId) {
            console.error(`❌ User ${req.user._id} attempted to access datasets of user ${userId}`);
            return res.status(403).json({ error: "You can only view your own datasets" });
        }
        
        // Exclude fileContent from the response to save bandwidth
        // Populate user information
        const datasets = await Dataset.find({ user: userId })
            .select('-fileContent')
            .populate('user', 'name email profileImage');
        
        console.log(`✅ Found ${datasets.length} datasets for user ${userId}`);
        res.status(200).json({ datasets });
    } catch (error) {
        console.error(`❌ Error fetching user datasets: ${error.message}`);
        res.status(500).json({ error: error.message });
    }
};

// Delete dataset
export const deleteDataset = async (req, res) => {
    try {
        const { id } = req.params;
        console.log(`🗑️ Received delete request for dataset: ${id}`);
        
        // Find the dataset to delete
        const dataset = await Dataset.findById(id);
        if (!dataset) {
            console.error(`❌ Dataset not found: ${id}`);
            return res.status(404).json({ error: "Dataset not found" });
        }
        
        // Delete the dataset from the database
        await Dataset.findByIdAndDelete(id);
        
        console.log(`✅ Dataset deleted successfully: ${id}`);
        res.status(200).json({ message: "Dataset deleted successfully" });
    } catch (error) {
        console.error("❌ Error deleting dataset:", error);
        res.status(500).json({ error: error.message });
    }
};

// Update dataset
export const updateDataset = async (req, res) => {
    try {
        const { id } = req.params;
        const { title, description, type } = req.body;

        const dataset = await Dataset.findById(id);

        if (!dataset) {
            return res.status(404).json({ message: 'Dataset not found' });
        }

        // Authorization: Check if the user is an admin or the owner of the dataset
        if (req.user.role !== 'admin' && dataset.user.toString() !== req.user._id.toString()) {
            return res.status(403).json({ message: 'User not authorized to update this dataset' });
        }

        // Update fields
        dataset.title = title || dataset.title;
        dataset.description = description || dataset.description;
        dataset.type = type || dataset.type;

        // If a new file is uploaded, replace the old one
        if (req.file) {
            dataset.fileContent = fs.readFileSync(req.file.path);
            dataset.fileName = req.file.originalname;
            dataset.fileContentType = req.file.mimetype;
            dataset.size = req.file.size;
            fs.unlinkSync(req.file.path); // Clean up temp file
        }

        const updatedDataset = await dataset.save();

        res.json({
            _id: updatedDataset._id,
            title: updatedDataset.title,
            description: updatedDataset.description,
            type: updatedDataset.type,
            fileName: updatedDataset.fileName,
            size: updatedDataset.size,
            user: updatedDataset.user,
            createdAt: updatedDataset.createdAt,
            updatedAt: updatedDataset.updatedAt,
        });

    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// Get download statistics for admin
export const getDownloadStats = async (req, res) => {
    try {
        // Basic statistics
        const totalDownloads = await Download.countDocuments();
        const uniqueUsers = await Download.distinct('user').countDocuments();
        const uniqueDatasets = await Download.distinct('dataset').countDocuments();
        
        // Recent downloads (last 30)
        const recentDownloads = await Download.find()
            .sort({ downloadedAt: -1 })
            .limit(30)
            .populate('dataset', 'title')
            .populate('user', 'name username')
            .select('-__v');
            
        // Most downloaded datasets (top 10)
        const mostDownloaded = await Dataset.find()
            .sort({ downloads: -1 })
            .limit(10)
            .select('title downloads');
            
        // Downloads by day (last 30 days)
        const thirtyDaysAgo = new Date();
        thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
        
        const downloadsByDay = await Download.aggregate([
            {
                $match: {
                    downloadedAt: { $gte: thirtyDaysAgo }
                }
            },
            {
                $group: {
                    _id: {
                        year: { $year: "$downloadedAt" },
                        month: { $month: "$downloadedAt" },
                        day: { $dayOfMonth: "$downloadedAt" }
                    },
                    count: { $sum: 1 }
                }
            },
            {
                $sort: { "_id.year": 1, "_id.month": 1, "_id.day": 1 }
            }
        ]);
        
        // Format the results
        const downloadsByDayFormatted = downloadsByDay.map(item => {
            const date = new Date(item._id.year, item._id.month - 1, item._id.day);
            return {
                date: date.toISOString().split('T')[0],
                count: item.count
            };
        });
        
        // Return all statistics
        res.status(200).json({
            totalDownloads,
            uniqueUsers,
            uniqueDatasets,
            recentDownloads,
            mostDownloaded,
            downloadsByDay: downloadsByDayFormatted
        });
    } catch (error) {
        console.error('❌ Error fetching download stats:', error);
        res.status(500).json({ error: error.message });
    }
};