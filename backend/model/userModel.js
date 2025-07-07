import mongoose from "mongoose";

const userSchema =new mongoose.Schema({
    name: { type: String, required: true },
    username: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    email: {
        type: String,
        required: true,
        unique: true,
        lowercase: true,
        trim: true
    },
    role:{
        type:String,
        enum:["user","admin"],
        default:"user"
    },
    password:String,
    profileImage:String,
    bio:String
})

const User = mongoose.model("User",userSchema);
export default User;