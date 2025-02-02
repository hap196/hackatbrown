const express = require('express');
const router = express.Router();
const User = require('../models/user');

// Add a new pill for a user
router.post('/:uid/pills', async (req, res) => {
    const { uid } = req.params;
    const pillData = req.body;

    try {
        const user = await User.findOne({ uid });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        user.pills.push(pillData);
        await user.save();

        res.status(201).json({ message: 'Pill added successfully', user });
    } catch (err) {
        res.status(500).json({ error: 'Error adding pill', details: err.message });
    }
});

// Get all pills for a user
router.get('/:uid/pills', async (req, res) => {
    const { uid } = req.params;

    try {
        const user = await User.findOne({ uid });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        res.status(200).json(user.pills);
    } catch (err) {
        res.status(500).json({ error: 'Error fetching pills', details: err.message });
    }
});

// Update a specific pill
router.put('/:uid/pills/:pillId', async (req, res) => {
    const { uid, pillId } = req.params;
    const updatedData = req.body;

    try {
        const user = await User.findOne({ uid });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        const pill = user.pills.id(pillId);
        if (!pill) {
            return res.status(404).json({ message: 'Pill not found' });
        }

        Object.assign(pill, updatedData);  // Update pill with new data
        await user.save();

        res.status(200).json({ message: 'Pill updated successfully', pill });
    } catch (err) {
        res.status(500).json({ error: 'Error updating pill', details: err.message });
    }
});

// Delete a specific pill
router.delete('/:uid/pills/:pillId', async (req, res) => {
    const { uid, pillId } = req.params;

    try {
        const user = await User.findOne({ uid });

        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }

        user.pills.id(pillId).remove();
        await user.save();

        res.status(200).json({ message: 'Pill deleted successfully' });
    } catch (err) {
        res.status(500).json({ error: 'Error deleting pill', details: err.message });
    }
});

// Log intake for a specific pill
router.post('/:uid/pills/:pillId/intake', async (req, res) => {
    const { uid, pillId } = req.params;
    // Now also expect a date field from the client.
    const { amountTaken, comments, logDate } = req.body;
    
    try {
        const user = await User.findOne({ uid });
        if (!user) {
            return res.status(404).json({ message: 'User not found' });
        }
        
        const pill = user.pills.id(pillId);
        if (!pill) {
            return res.status(404).json({ message: 'Pill not found' });
        }
        
        // Use logDate if provided; otherwise, default to Date.now().
        const intakeDate = logDate ? new Date(logDate) : new Date();
        
        pill.intakeLogs.push({ amount: amountTaken, comments, date: intakeDate });
        await user.save();
        
        res.status(200).json({ message: 'Intake logged successfully', pill });
    } catch (err) {
        res.status(500).json({ error: 'Error logging intake', details: err.message });
    }
});


module.exports = router;

