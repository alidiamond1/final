import User from "../model/userModel.js";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";
import path from "path";
import fs from "fs";
import multer from "multer";

const generateToken = (user) => {
    return jwt.sign(
        { 
            id: user._id,
            role: user.role
        }, 
        process.env.JWT_SECRET, 
        {
            expiresIn: "1d",
        }
    );
};

export const registerUser = async (req, res) => {
    try {
        const { name, email, password, role } = req.body;
        
        // Check if user with this email already exists
        const existingUser = await User.findOne({ email });
        if (existingUser) {
            return res.status(400).json({ error: "A user with this email already exists" });
        }
        
        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);
        
        // Create new user with role (default to 'user' if not specified)
        const userData = { 
            name, 
            email, 
            password: hashedPassword,
            role: role || 'user' 
        };
        
        console.log('Creating new user:', {...userData, password: '[HIDDEN]'});
        const user = await User.create(userData);
        
        // Generate a token for the new user
        const token = generateToken(user);
        
        console.log('User created successfully:', user._id);
        res.status(201).json({ 
            message: "User registered successfully",
            user: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role
            },
            token 
        });
    } catch (error) {
        console.error('Error registering user:', error);
        res.status(500).json({ error: error.message });
    }
};

export const loginUser = async (req, res) => {
    try {
        const { email, password } = req.body;
        
        // Try to find user by email (which could actually be a username)
        let user = await User.findOne({ email });
        
        // If user not found by email, check if email input was actually a username (stored in name field)
        if (!user) {
            user = await User.findOne({ name: email });
        }
        
        // If still no user found
        if (!user) {
            return res.status(404).json({ error: "User not found. Please check your username/email." });
        }
        
        // Verify password using bcrypt
        const isPasswordValid = await bcrypt.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ error: "Invalid password" });
        }
        
        // Generate token for authentication
        const token = generateToken(user);
        
        console.log(`User logged in: ${user.name} (${user.role})`);
        
        // Return user data and token
        res.status(200).json({ 
            user: {
                _id: user._id,
                name: user.name,
                email: user.email,
                role: user.role,
                profileImage: user.profileImage,
                bio: user.bio
            }, 
            token 
        });
    } catch (error) {
        console.error('Login error:', error);
        res.status(500).json({ error: error.message });
    }
};

export const logoutUser = async (req, res) => {
    try {
        res.status(200).json({ message: "User logged out" });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const deleteUser = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await User.findByIdAndDelete(id);
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        res.status(200).json({ user });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};


export const getAllUsers = async (req, res) => {
    try {
        const users = await User.find();
        res.status(200).json({ users });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const updateUser = async (req, res) => {
    try {
        const { id } = req.params;
        const user = await User.findByIdAndUpdate(id, req.body, { new: true });
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        
        // Don't return the password in the response
        const userResponse = {
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            profileImage: user.profileImage,
            bio: user.bio
        };
        
        res.status(200).json({ user: userResponse });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const updatePassword = async (req, res) => {
    try {
        const { id } = req.params;
        const { currentPassword, newPassword } = req.body;
        
        // Find the user
        const user = await User.findById(id);
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        
        // Verify current password
        const isPasswordValid = await bcrypt.compare(currentPassword, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({ error: "Current password is incorrect" });
        }
        
        // Hash new password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(newPassword, salt);
        
        // Update password
        user.password = hashedPassword;
        await user.save();
        
        res.status(200).json({ message: "Password updated successfully" });
    } catch (error) {
        console.error('Error updating password:', error);
        res.status(500).json({ error: error.message });
    }
};

// Configure multer storage for profile images
const storage = multer.diskStorage({
    destination: (req, file, cb) => {
        const uploadDir = 'uploads/profiles';
        
        // Create directory if it doesn't exist
        if (!fs.existsSync(uploadDir)) {
            fs.mkdirSync(uploadDir, { recursive: true });
        }
        
        cb(null, uploadDir);
    },
    filename: (req, file, cb) => {
        // Use user ID and timestamp for unique filename
        const userId = req.params.id;
        const fileExt = path.extname(file.originalname);
        const fileName = `profile_${userId}_${Date.now()}${fileExt}`;
        cb(null, fileName);
    }
});

// Create multer upload instance
const upload = multer({ 
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5MB limit
    fileFilter: (req, file, cb) => {
        // Accept only image files
        if (!file.mimetype.startsWith('image/')) {
            return cb(new Error('Only image files are allowed'));
        }
        cb(null, true);
    }
});

// Middleware to handle profile image upload
export const uploadProfileImage = (req, res, next) => {
    const uploadSingle = upload.single('profileImage');
    
    uploadSingle(req, res, (err) => {
        if (err) {
            return res.status(400).json({ error: err.message });
        }
        next();
    });
};

// Controller to save profile image path to user
export const saveProfileImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }
        
        const { id } = req.params;
        const profileImagePath = req.file.path.replace(/\\/g, '/'); // Normalize path for all OS
        
        // Update user with profile image path
        const user = await User.findByIdAndUpdate(
            id, 
            { profileImage: profileImagePath },
            { new: true }
        );
        
        if (!user) {
            return res.status(404).json({ error: "User not found" });
        }
        
        const userResponse = {
            _id: user._id,
            name: user.name,
            email: user.email,
            role: user.role,
            profileImage: user.profileImage,
            bio: user.bio
        };

        res.status(200).json({ 
            message: "Profile image updated successfully",
            user: userResponse
        });
    } catch (error) {
        console.error('Error saving profile image:', error);
        res.status(500).json({ error: error.message });
    }
};