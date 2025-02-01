const mongoose = require('mongoose');

const pillSchema = new mongoose.Schema({
    pillName: { type: String, required: true },
    amount: { type: Number, required: true },
    duration: { type: Number, required: true },
    howOften: { type: String, required: true },
    specificTime: { type: String },
    foodInstruction: { type: String },
    notificationBefore: { type: String },
    additionalDetails: { type: String }
}, { timestamps: true });

const userSchema = new mongoose.Schema({
    uid: { type: String, required: true, unique: true },
    email: { type: String, required: true },
    name: { type: String },
    pills: [pillSchema]
}, { timestamps: true });

// Ensure the model is only compiled once
module.exports = mongoose.models.User || mongoose.model('User', userSchema);
