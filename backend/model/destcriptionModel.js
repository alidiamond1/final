import mongoose from "mongoose";


const descriptionSchema = new mongoose.Schema({
    datasetId:{
        type:String,
        required:true
    },
    format:String,
    size:String,
    language:String,
    
},{timestamps:true});

const Description = mongoose.model("Description", descriptionSchema);
export default Description;
