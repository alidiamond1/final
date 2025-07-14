import mongoose from "mongoose";

const datasetSchema = new mongoose.Schema({
    title: {
        type: String,
        required: true
    },
    description: {
        type: String,
        required: true
    },
    type: {
        type: String,
        required: true
    },
    size: {
        type: Number, // Changed from String to Number
        required: true
    },
    downloads: { // Added downloads field
        type: Number,
        default: 0
    },
    user: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User',
        required: false
    },
    fileId: {
        type: String,
        default: null
    },
    fileName: {
        type: String,
        default: null
    },
    fileContent: {
        type: Buffer,
        default: null
    },
    fileContentType: {
        type: String,
        default: null
    },
    createdAt: {
        type: Date,
        default: Date.now
    }
});

const Dataset = mongoose.model("Dataset", datasetSchema);
export default Dataset;
