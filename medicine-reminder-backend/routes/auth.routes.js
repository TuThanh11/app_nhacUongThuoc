// routes/auth.routes.js
const express = require('express');
const router = express.Router();
const { auth, db } = require('../server');
const axios = require('axios');
const { generateRandomPassword, sendNewPasswordEmail } = require('../services/email.service');

// Firebase Web API Key
const FIREBASE_API_KEY = "AIzaSyDsNyUZZujExEI5r3HosP61VB9QVlCaA5o";

// Helper to generate numeric user_id
function generateNumericUserId(uid) {
  let hash = 0;
  for (let i = 0; i < uid.length; i++) {
    const char = uid.charCodeAt(i);
    hash = ((hash << 5) - hash) + char;
    hash = hash & hash;
  }
  return Math.abs(hash);
}

// POST /api/auth/signup - Đăng ký
router.post('/signup', async (req, res) => {
  try {
    const { username, email, password } = req.body;

    console.log('Signup request:', { username, email });

    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ thông tin'
      });
    }

    if (password.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu phải có ít nhất 6 ký tự'
      });
    }

    const userRecord = await auth.createUser({
      email: email,
      password: password,
      displayName: username
    });

    console.log('User created in Firebase Auth:', userRecord.uid);

    const numericUserId = generateNumericUserId(userRecord.uid);

    await db.collection('users').doc(userRecord.uid).set({
      username: username,
      email: email,
      created_at: new Date().toISOString(),
      numeric_user_id: numericUserId,
      avatar_url: 'preset_0'
    });

    console.log('User document created in Firestore');

    res.status(201).json({
      success: true,
      message: 'Đăng ký thành công!',
      user: {
        uid: userRecord.uid,
        email: userRecord.email,
        username: username,
        numeric_user_id: numericUserId,
        avatar_url: 'preset_0'
      }
    });
  } catch (error) {
    console.error('Signup error:', error);
    
    let message = 'Đăng ký thất bại!';
    if (error.code === 'auth/email-already-exists') {
      message = 'Email này đã được sử dụng.';
    } else if (error.code === 'auth/invalid-email') {
      message = 'Email không hợp lệ.';
    }

    res.status(400).json({
      success: false,
      message: message,
      error: error.message
    });
  }
});

// POST /api/auth/login - Đăng nhập
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;

    console.log('Login request:', { email });

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập email và mật khẩu'
      });
    }

    const firebaseAuthUrl = `https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=${FIREBASE_API_KEY}`;
    
    let firebaseResponse;
    try {
      firebaseResponse = await axios.post(firebaseAuthUrl, {
        email: email,
        password: password,
        returnSecureToken: true
      });
    } catch (authError) {
      console.error('Firebase Auth error:', authError.response?.data);
      
      let message = 'Email hoặc mật khẩu không đúng';
      if (authError.response?.data?.error?.message) {
        const errorMessage = authError.response.data.error.message;
        if (errorMessage === 'EMAIL_NOT_FOUND') {
          message = 'Không tìm thấy tài khoản với email này';
        } else if (errorMessage === 'INVALID_PASSWORD') {
          message = 'Mật khẩu không đúng';
        } else if (errorMessage === 'USER_DISABLED') {
          message = 'Tài khoản đã bị vô hiệu hóa';
        }
      }

      return res.status(401).json({
        success: false,
        message: message
      });
    }

    const uid = firebaseResponse.data.localId;
    console.log('Login successful for uid:', uid);

    const userDoc = await db.collection('users').doc(uid).get();
    
    if (!userDoc.exists) {
      console.log('User document not found, creating...');
      const numericUserId = generateNumericUserId(uid);
      const userData = {
        username: firebaseResponse.data.displayName || email.split('@')[0],
        email: email,
        created_at: new Date().toISOString(),
        numeric_user_id: numericUserId,
        avatar_url: 'preset_0'
      };

      await db.collection('users').doc(uid).set(userData);

      return res.json({
        success: true,
        message: 'Đăng nhập thành công!',
        user: {
          uid: uid,
          ...userData
        }
      });
    }

    const userData = userDoc.data();
    console.log('User data from Firestore:', userData);

    res.json({
      success: true,
      message: 'Đăng nhập thành công!',
      user: {
        uid: uid,
        email: email,
        ...userData
      }
    });
  } catch (error) {
    console.error('Login error:', error);
    
    res.status(500).json({
      success: false,
      message: 'Đã xảy ra lỗi khi đăng nhập',
      error: error.message
    });
  }
});

// POST /api/auth/forgot-password - Quên mật khẩu
router.post('/forgot-password', async (req, res) => {
  try {
    const { email } = req.body;

    console.log('Forgot password request:', { email });

    if (!email) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập email'
      });
    }

    // Kiểm tra email có tồn tại không
    let userRecord;
    try {
      userRecord = await auth.getUserByEmail(email);
    } catch (error) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy tài khoản với email này'
      });
    }

    // Lấy thông tin user từ Firestore
    const userDoc = await db.collection('users').doc(userRecord.uid).get();
    const userData = userDoc.exists ? userDoc.data() : {};

    // Generate mật khẩu mới
    const newPassword = generateRandomPassword(8);

    // Cập nhật mật khẩu trong Firebase Auth
    await auth.updateUser(userRecord.uid, {
      password: newPassword
    });

    // Gửi email
    const emailResult = await sendNewPasswordEmail(
      email, 
      newPassword, 
      userData.username || email.split('@')[0]
    );

    if (!emailResult.success) {
      return res.status(500).json({
        success: false,
        message: 'Đã tạo mật khẩu mới nhưng không thể gửi email. Vui lòng liên hệ quản trị viên.'
      });
    }

    res.json({
      success: true,
      message: 'Mật khẩu mới đã được gửi đến email của bạn. Vui lòng kiểm tra hộp thư!'
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({
      success: false,
      message: 'Đã xảy ra lỗi khi khôi phục mật khẩu',
      error: error.message
    });
  }
});

// GET /api/auth/user/:userId - Lấy thông tin user
router.get('/user/:userId', async (req, res) => {
  try {
    const { userId } = req.params;

    console.log('Get user info for:', userId);

    const userDoc = await db.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thông tin người dùng'
      });
    }

    const userData = userDoc.data();
    console.log('User data:', userData);

    res.json({
      success: true,
      user: {
        uid: userId,
        ...userData
      }
    });
  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thông tin người dùng',
      error: error.message
    });
  }
});

// PUT /api/auth/avatar/:userId - Cập nhật avatar
router.put('/avatar/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { avatarUrl } = req.body;

    console.log('Update avatar for:', userId, 'to:', avatarUrl);

    await db.collection('users').doc(userId).update({
      avatar_url: avatarUrl,
      updated_at: new Date().toISOString()
    });

    res.json({
      success: true,
      message: 'Cập nhật avatar thành công!'
    });
  } catch (error) {
    console.error('Update avatar error:', error);
    res.status(500).json({
      success: false,
      message: 'Không thể cập nhật avatar',
      error: error.message
    });
  }
});

// PUT /api/auth/password/:userId - Đổi mật khẩu
router.put('/password/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { newPassword } = req.body;

    console.log('Change password for:', userId);

    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'Mật khẩu mới phải có ít nhất 6 ký tự'
      });
    }

    await auth.updateUser(userId, {
      password: newPassword
    });

    res.json({
      success: true,
      message: 'Đổi mật khẩu thành công!'
    });
  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({
      success: false,
      message: 'Đổi mật khẩu thất bại!',
      error: error.message
    });
  }
});

module.exports = router;