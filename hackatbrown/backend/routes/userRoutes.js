const express = require('express');
const User = require('../models/user');

const router = express.Router();

// Create or update user
router.post('/', async (req, res) => {
    const { uid, email, name } = req.body;

    try {
        // Find the user by UID and update or create it
        const user = await User.findOneAndUpdate(
            { uid },
            { email, name },
            { upsert: true, new: true }
        );
        res.status(200).json({ message: 'User saved successfully', user });
    } catch (error) {
        res.status(500).json({ message: 'Error saving user', error });
    }
});

module.exports = router;

