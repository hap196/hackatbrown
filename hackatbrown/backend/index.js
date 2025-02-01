require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');

// App configuration
const app = express();
app.use(express.json());
app.use(cors());

// MongoDB connection
mongoose.connect(process.env.MONGO_URI, {
    useNewUrlParser: true,
    useUnifiedTopology: true,
}).then(() => {
    console.log('Connected to MongoDB');
}).catch(err => {
    console.error('MongoDB connection error:', err);
});

// Routes
const userRoutes = require('./routes/userRoutes');
app.use('/users', userRoutes);

const pillRoutes = require('./routes/pillRoutes');
app.use('/users', pillRoutes);


// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});

