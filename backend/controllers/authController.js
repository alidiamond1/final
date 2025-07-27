import User from "../model/userModel.js";
import jwt from "jsonwebtoken";
import bcrypt from "bcrypt";

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
        const { name, username, email, password, role } = req.body;

        // Check if user with this email or username already exists
        const existingUser = await User.findOne({ $or: [{ email }, { username }] });
        if (existingUser) {
            if (existingUser.email === email) {
                return res.status(400).json({ error: "A user with this email already exists" });
            }
            return res.status(400).json({ error: "A user with this username already exists" });
        }

        // Hash password
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(password, salt);

        // Create new user
        const userData = {
            name,
            username,
            email,
            password: hashedPassword,
            role: role || 'user'
        };

        const user = await User.create(userData);

        // Generate token
        const token = generateToken(user);

        res.status(201).json({
            message: "User registered successfully",
            user: {
                _id: user._id,
                name: user.name,
                username: user.username,
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
        const { username, password } = req.body;

        // Find user by username
        const user = await User.findOne({ username });

        // If no user found or password doesn't match, send a generic error
        if (!user || !(await bcrypt.compare(password, user.password))) {
            return res.status(401).json({ error: "Invalid username or password" });
        }

        // Generate token
        const token = generateToken(user);

        console.log(`User logged in: ${user.username} (${user.role})`);

        // Return user data and token
        res.status(200).json({
            user: {
                _id: user._id,
                name: user.name,
                username: user.username,
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
        // Explicitly select all fields, including profileImage, but exclude password
        const users = await User.find().select('-password');
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
            username: user.username,
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

// Configure multer to use memory storage
const storage = multer.memoryStorage();

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

// Controller to save profile image to database as Base64
export const saveProfileImage = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "No image file provided" });
        }

        const { id } = req.params;

        // Create a data URI for the image
        const mimeType = req.file.mimetype;
        const base64Data = req.file.buffer.toString('base64');
        const dataUri = `data:${mimeType};base64,${base64Data}`;

        // Update user with the Base64 data URI
        const user = await User.findByIdAndUpdate(
            id,
            { profileImage: dataUri },
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
            profileImage: user.profileImage, // This will now be the data URI
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