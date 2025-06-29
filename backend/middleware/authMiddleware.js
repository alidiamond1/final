import jwt from "jsonwebtoken";
import User from "../model/userModel.js";

export const protect = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.split(" ")[1];
        if (!token) {
            return res.status(401).json({ error: "Not authorized to access this route" });
        }
        
        // Decode the token
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        
        // Log token details for debugging
        console.log('Token decoded:', decoded);
        
        // Check if user exists
        const user = await User.findById(decoded.id);
        if (!user) {
            console.log('User not found for ID:', decoded.id);
            return res.status(401).json({ error: "User not found" });
        }
        
        // Attach user to request
        req.user = {
            id: user._id,
            name: user.name,
            email: user.email,
            role: user.role
        };
        
        console.log('User authenticated:', req.user.email, 'Role:', req.user.role);
        next();
    } catch (error) {
        console.error('Authentication error:', error.message);
        res.status(401).json({ error: "Authentication failed: " + error.message });
    }
};

export const admin = async (req, res, next) => {
    try {
        // The protect middleware should have already attached the user to the request
        if (!req.user) {
            console.log('Admin check failed: No user in request');
            return res.status(401).json({ error: "Authentication required" });
        }
        
        console.log('Admin check for user:', req.user.email, 'Role:', req.user.role);
        
        if (req.user.role === "admin") {
            console.log('Admin access granted for user:', req.user.email);
            next();
        } else {
            console.log('Admin access denied for user:', req.user.email, 'Role:', req.user.role);
            res.status(403).json({ error: "Admin privileges required to access this route" });
        }
    } catch (error) {
        console.error('Admin middleware error:', error.message);
        res.status(403).json({ error: "Admin authorization failed: " + error.message });
    }
};
