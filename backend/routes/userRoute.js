import express from "express";
import { 
    registerUser, 
    loginUser, 
    logoutUser, 
    getAllUsers, 
    deleteUser, 
    updateUser, 
    updatePassword,
    uploadProfileImage,
    saveProfileImage
} from "../controllers/authController.js";
import { protect, admin } from "../middleware/authMiddleware.js";

const router = express.Router();

// Public routes
router.post("/register", registerUser);
router.post("/login", loginUser);
router.post("/logout", logoutUser);

// Protected routes (require authentication)
router.get("/all", protect, admin, getAllUsers);
router.delete("/:id", protect, admin, deleteUser);
router.put("/:id", protect, updateUser);
router.put("/:id/password", protect, updatePassword);
router.post("/:id/profile-image", protect, uploadProfileImage, saveProfileImage);


export default router;