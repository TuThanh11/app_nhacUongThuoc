// routes/reminder.routes.js
const express = require('express');
const router = express.Router();
const { db } = require('../server');

// GET /api/reminders/:userId - Lấy danh sách nhắc nhở
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log('Get reminders for userId:', userId);
    
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }

    const userData = userDoc.data();
    const numericUserId = userData.numeric_user_id || userData.user_id;
    
    if (!numericUserId) {
      console.error('No numeric_user_id found for user:', userId);
      return res.json({
        success: true,
        reminders: []
      });
    }

    console.log('Querying with numeric_user_id:', numericUserId);

    const snapshot = await db.collection('reminders')
      .where('user_id', '==', numericUserId)
      .get();

    const reminders = [];
    snapshot.forEach(doc => {
      reminders.push({
        id: doc.id,
        ...doc.data()
      });
    });

    reminders.sort((a, b) => new Date(b.created_at) - new Date(a.created_at));

    console.log('Found reminders:', reminders.length);

    res.json({
      success: true,
      reminders: reminders
    });
  } catch (error) {
    console.error('Get reminders error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách nhắc nhở',
      error: error.message
    });
  }
});

// GET /api/reminders/:userId/today - Lấy nhắc nhở hôm nay
router.get('/:userId/today', async (req, res) => {
  try {
    const { userId } = req.params;
    const today = new Date();
    const dayOfWeek = today.getDay();
    const dayIndex = dayOfWeek === 0 ? 6 : dayOfWeek - 1;

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }

    const numericUserId = userDoc.data().numeric_user_id;

    const snapshot = await db.collection('reminders')
      .where('user_id', '==', numericUserId)
      .where('is_enabled', '==', 1)
      .get();

    const todayReminders = [];
    snapshot.forEach(doc => {
      const data = { id: doc.id, ...doc.data() };
      
      if (data.repeat_mode === 'Hằng ngày') {
        todayReminders.push(data);
      } else if (data.repeat_mode === 'Từ thứ 2 đến thứ 6' && dayIndex >= 0 && dayIndex <= 4) {
        todayReminders.push(data);
      } else if (data.repeat_mode === 'Tùy chỉnh') {
        const customDays = data.custom_days.split(',').map(d => parseInt(d.trim()));
        if (customDays.includes(dayIndex)) {
          todayReminders.push(data);
        }
      } else if (data.repeat_mode === 'Một lần') {
        todayReminders.push(data);
      }
    });

    res.json({
      success: true,
      reminders: todayReminders
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy nhắc nhở hôm nay',
      error: error.message
    });
  }
});

// POST /api/reminders - Tạo nhắc nhở mới
router.post('/', async (req, res) => {
  try {
    const {
      userId,
      medicineName,
      description,
      isRepeatEnabled,
      repeatMode,
      customDays,
      times,
      isEnabled,
      selectedDate
    } = req.body;
    
    console.log('=== CREATE REMINDER DEBUG ===');
    console.log('Received userId (UID):', userId);
    
    if (!userId || !medicineName || !times || times.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ thông tin'
      });
    }

    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.error('User document not found for UID:', userId);
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy người dùng'
      });
    }

    const userData = userDoc.data();
    const numericUserId = userData.numeric_user_id || userData.user_id;
    
    if (!numericUserId) {
      console.error('No numeric_user_id found in user document');
      return res.status(400).json({
        success: false,
        message: 'Không tìm thấy numeric_user_id'
      });
    }

    console.log('Using numeric_user_id:', numericUserId);

    const reminderData = {
      user_id: numericUserId,
      medicine_id: null,
      medicine_name: medicineName,
      description: description || null,
      is_repeat_enabled: isRepeatEnabled ? 1 : 0,
      repeat_mode: repeatMode,
      custom_days: customDays.join(','),
      times: times.join(','),
      is_enabled: isEnabled ? 1 : 0,
      selected_date: selectedDate || null,
      created_at: new Date().toISOString()
    };

    const docRef = await db.collection('reminders').add(reminderData);

    res.status(201).json({
      success: true,
      message: 'Tạo nhắc nhở thành công!',
      reminder: {
        id: docRef.id,
        ...reminderData
      }
    });
  } catch (error) {
    console.error('Create reminder error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi tạo nhắc nhở',
      error: error.message
    });
  }
});

// ✅ FIX: PUT /api/reminders/:id - Cập nhật nhắc nhở
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const {
      userId,
      medicineName,
      description,
      isRepeatEnabled,
      repeatMode,
      customDays,
      times,
      isEnabled
    } = req.body;

    console.log('=== UPDATE REMINDER DEBUG ===');
    console.log('Reminder ID:', id);
    console.log('User ID (UID):', userId);

    // Lấy reminder hiện tại
    const doc = await db.collection('reminders').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy nhắc nhở'
      });
    }

    const reminderData = doc.data();
    console.log('Current reminder user_id:', reminderData.user_id);

    // ✅ Verify ownership - SO SÁNH ĐÚNG
    if (userId) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy người dùng'
        });
      }

      const userData = userDoc.data();
      const numericUserId = userData.numeric_user_id || userData.user_id;
      
      console.log('User numeric_user_id:', numericUserId);
      console.log('Reminder user_id:', reminderData.user_id);

      // ✅ So sánh numeric với numeric
      if (reminderData.user_id !== numericUserId) {
        console.error('Ownership check failed!');
        console.error(`Expected: ${numericUserId}, Got: ${reminderData.user_id}`);
        return res.status(403).json({
          success: false,
          message: 'Không có quyền chỉnh sửa'
        });
      }

      console.log('✅ Ownership verified successfully');
    }

    // Update data
    const updateData = {
      medicine_name: medicineName,
      description: description || null,
      is_repeat_enabled: isRepeatEnabled ? 1 : 0,
      repeat_mode: repeatMode,
      custom_days: customDays.join(','),
      times: times.join(','),
      is_enabled: isEnabled !== undefined ? (isEnabled ? 1 : 0) : reminderData.is_enabled,
      updated_at: new Date().toISOString()
    };

    await db.collection('reminders').doc(id).update(updateData);

    console.log('✅ Reminder updated successfully');

    res.json({
      success: true,
      message: 'Cập nhật nhắc nhở thành công!'
    });
  } catch (error) {
    console.error('Update reminder error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật nhắc nhở',
      error: error.message
    });
  }
});

// ✅ FIX: DELETE /api/reminders/:id - Xóa nhắc nhở
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;

    console.log('=== DELETE REMINDER DEBUG ===');
    console.log('Reminder ID:', id);
    console.log('User ID (UID):', userId);

    const doc = await db.collection('reminders').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy nhắc nhở'
      });
    }

    const reminderData = doc.data();
    console.log('Current reminder user_id:', reminderData.user_id);

    // ✅ Verify ownership
    if (userId) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy người dùng'
        });
      }

      const userData = userDoc.data();
      const numericUserId = userData.numeric_user_id || userData.user_id;
      
      console.log('User numeric_user_id:', numericUserId);

      // ✅ So sánh numeric với numeric
      if (reminderData.user_id !== numericUserId) {
        console.error('Ownership check failed!');
        return res.status(403).json({
          success: false,
          message: 'Không có quyền xóa'
        });
      }

      console.log('✅ Ownership verified successfully');
    }

    await db.collection('reminders').doc(id).delete();

    console.log('✅ Reminder deleted successfully');

    res.json({
      success: true,
      message: 'Xóa nhắc nhở thành công!'
    });
  } catch (error) {
    console.error('Delete reminder error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa nhắc nhở',
      error: error.message
    });
  }
});

// ✅ FIX: PUT /api/reminders/:id/toggle - Bật/tắt nhắc nhở
router.put('/:id/toggle', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    console.log('=== TOGGLE REMINDER DEBUG ===');
    console.log('Reminder ID:', id);
    console.log('User ID (UID):', userId);

    const doc = await db.collection('reminders').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy nhắc nhở'
      });
    }

    const reminderData = doc.data();
    console.log('Current reminder user_id:', reminderData.user_id);

    // ✅ Verify ownership
    if (userId) {
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        return res.status(404).json({
          success: false,
          message: 'Không tìm thấy người dùng'
        });
      }

      const userData = userDoc.data();
      const numericUserId = userData.numeric_user_id || userData.user_id;
      
      console.log('User numeric_user_id:', numericUserId);

      // ✅ So sánh numeric với numeric
      if (reminderData.user_id !== numericUserId) {
        console.error('Ownership check failed!');
        return res.status(403).json({
          success: false,
          message: 'Không có quyền thay đổi'
        });
      }

      console.log('✅ Ownership verified successfully');
    }

    const currentStatus = reminderData.is_enabled;
    const newStatus = currentStatus === 1 ? 0 : 1;

    await db.collection('reminders').doc(id).update({
      is_enabled: newStatus,
      updated_at: new Date().toISOString()
    });

    console.log('✅ Reminder toggled successfully');

    res.json({
      success: true,
      message: 'Cập nhật trạng thái thành công!',
      isEnabled: newStatus === 1
    });
  } catch (error) {
    console.error('Toggle reminder error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật trạng thái',
      error: error.message
    });
  }
});

module.exports = router;