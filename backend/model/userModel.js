import mongoose from "mongoose";

const userSchema =new mongoose.Schema({
    name:String,
    email:String,
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