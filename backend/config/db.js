import mongoose from "mongoose";
import dotenv from "dotenv";
dotenv.config();

// Always use local MongoDB for file uploads
// const MONGO_URL = "mongodb://localhost:27017/somali-dataset";
const MONGO_URL = process.env.MONGO_URL;

const connectDB = async () => {
    try {
        // Set mongoose options for better stability
        const options = {
            serverSelectionTimeoutMS: 5000, // Timeout after 5s instead of 30s
            socketTimeoutMS: 45000, // Close sockets after 45s of inactivity
        };
        
        await mongoose.connect(MONGO_URL, options);
        console.log("✅ Connected to MongoDB:", MONGO_URL);
    } catch (error) {
        console.log("❌ MongoDB Connection Error:", error.message);
        console.log("Make sure MongoDB is installed and running locally");
    }
};

export default connectDB;

