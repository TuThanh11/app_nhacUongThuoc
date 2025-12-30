// server.js - Main entry point
require('dotenv').config();
const express = require('express');
const cors = require('cors');
const admin = require('firebase-admin');

// Initialize Express
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());

// Initialize Firebase Admin
const serviceAccount = require('./serviceAccountKey.json');
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

const db = admin.firestore();
const auth = admin.auth();

// EXPORT TRƯỚC KHI IMPORT ROUTES
module.exports = { db, auth, admin };

// Import routes SAU KHI export
const authRoutes = require('./routes/auth.routes');
const medicineRoutes = require('./routes/medicine.routes');
const reminderRoutes = require('./routes/reminder.routes');
const historyRoutes = require('./routes/history.routes');

// Use routes
app.use('/api/auth', authRoutes);
app.use('/api/medicines', medicineRoutes);
app.use('/api/reminders', reminderRoutes);
app.use('/api/history', historyRoutes);

// Health check
app.get('/health', (req, res) => {
  res.json({ status: 'OK', message: 'Medicine Reminder API is running' });
});

// Test Firebase endpoint
app.get('/test-firebase', async (req, res) => {
  try {
    const testUser = await auth.createUser({
      email: 'test' + Date.now() + '@example.com',
      password: '123456',
      displayName: 'Test User'
    });
    
    // Delete test user immediately
    await auth.deleteUser(testUser.uid);
    
    res.json({
      success: true,
      message: 'Firebase Admin SDK hoạt động OK!',
      uid: testUser.uid
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Firebase Admin SDK lỗi!',
      error: error.message
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ 
    success: false, 
    message: 'Đã xảy ra lỗi!',
    error: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
  console.log(`📡 Health check: http://localhost:${PORT}/health`);
  console.log(`🧪 Test Firebase: http://localhost:${PORT}/test-firebase`);
});