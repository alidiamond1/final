import mongoose from "mongoose";

const downloadSchema = new mongoose.Schema({
    dataset: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'Dataset',
        required: true
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User' // Not required for anonymous downloads
    },
    downloadedAt: {
        type: Date,
        default: Date.now
    },
    ipAddress: String,
    userAgent: String
});

const Download = mongoose.model("Download", downloadSchema);
export default Download; 