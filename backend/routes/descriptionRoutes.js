import express from "express";
import { createDescription, getDatasetDescription, updateDescription, deleteDescription } from "../controllers/descriptionController.js";

const router = express.Router();

router.post("/", createDescription);
router.get("/:datasetId", getDatasetDescription);
router.put("/:datasetId", updateDescription);
router.delete("/:datasetId", deleteDescription);

export default router;