import Description from "../model/destcriptionModel.js";

export const createDescription = async (req, res) => {
    try {
        const { datasetId, format, size, language } = req.body;
        const description = await Description.create({ datasetId, format, size, language });
        res.status(201).json({ description });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const getDatasetDescription = async (req, res) => {
    try {
        const { datasetId } = req.params;
        const description = await Description.findOne({ datasetId });
        res.status(200).json({ description });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const updateDescription = async (req, res) => {
    try {
        const { datasetId } = req.params;
        const { text } = req.body;
        const description = await Description.findOneAndUpdate(
            { datasetId },
            { text },
            { new: true }
        );
        if (!description) {
            return res.status(404).json({ error: "Description not found" });
        }
        res.status(200).json({ description });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

export const deleteDescription = async (req, res) => {
    try {
        const { datasetId } = req.params;
        const description = await Description.findOneAndDelete({ datasetId });
        if (!description) {
            return res.status(404).json({ error: "Description not found" });
        }
        res.status(200).json({ description });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};
