// models/User.js
const mongoose = require('mongoose');

const intakeLogSchema = new mongoose.Schema({
    date: { type: Date, default: Date.now },
    amount: { type: Number, required: true },
    comments: { type: String }
});

const pillSchema = new mongoose.Schema({
    pillName: { type: String, required: true },
    amount: { type: Number, required: true },
    duration: { type: Number, required: true },
    howOften: { type: String, required: true },
    specificTime: { type: String },
    foodInstruction: { type: String },
    notificationBefore: { type: String },
    additionalDetails: { type: String },
    intakeLogs: [intakeLogSchema]
}, { timestamps: true });

const userSchema = new mongoose.Schema({
    uid: { type: String, required: true, unique: true },
    email: { type: String, required: true },
    name: { type: String },
    pills: [pillSchema],
    allergies: [{ type: String }]
}, { timestamps: true });

module.exports = mongoose.models.User || mongoose.model('User', userSchema);
