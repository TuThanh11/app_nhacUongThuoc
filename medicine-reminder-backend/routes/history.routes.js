const express = require('express');
const router = express.Router();
const { db } = require('../server');

// Helper function để lấy numeric_user_id
async function getNumericUserId(userId) {
  const userDoc = await db.collection('users').doc(userId).get();
  if (!userDoc.exists) {
    throw new Error('Không tìm thấy người dùng');
  }
  return userDoc.data().numeric_user_id || userDoc.data().user_id;
}

// GET /api/history/:userId - Lấy lịch sử uống thuốc
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate } = req.query;

    const numericUserId = await getNumericUserId(userId);

    // ✅ SIMPLE QUERY - Không cần index
    const snapshot = await db.collection('medicine_history')
      .where('user_id', '==', numericUserId)
      .get();

    let history = [];
    snapshot.forEach(doc => {
      history.push({
        id: doc.id,
        ...doc.data()
      });
    });

    // ✅ Filter và sort trong JavaScript
    if (startDate) {
      history = history.filter(item => item.timestamp >= startDate);
    }
    if (endDate) {
      history = history.filter(item => item.timestamp <= endDate);
    }

    // Sort theo timestamp giảm dần
    history.sort((a, b) => {
      const timeA = new Date(a.timestamp).getTime();
      const timeB = new Date(b.timestamp).getTime();
      return timeB - timeA; // Descending
    });

    res.json({
      success: true,
      history: history
    });
  } catch (error) {
    console.error('Get history error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy lịch sử',
      error: error.message
    });
  }
});

// POST /api/history - Ghi nhận lịch sử uống thuốc
router.post('/', async (req, res) => {
  try {
    const {
      userId,
      reminderId,
      medicineName,
      time,
      status, // 'taken' or 'rejected'
      timestamp
    } = req.body;

    if (!userId || !medicineName || !status) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ thông tin'
      });
    }

    const numericUserId = await getNumericUserId(userId);

    const historyData = {
      user_id: numericUserId,
      reminder_id: reminderId || null,
      medicine_name: medicineName,
      scheduled_time: time,
      status: status, // 'taken', 'rejected', 'missed'
      timestamp: timestamp || new Date().toISOString(),
      created_at: new Date().toISOString()
    };

    const docRef = await db.collection('medicine_history').add(historyData);

    res.status(201).json({
      success: true,
      message: 'Ghi nhận lịch sử thành công!',
      history: {
        id: docRef.id,
        ...historyData
      }
    });
  } catch (error) {
    console.error('Create history error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi ghi nhận lịch sử',
      error: error.message
    });
  }
});

// GET /api/history/:userId/stats - Thống kê uống thuốc
router.get('/:userId/stats', async (req, res) => {
  try {
    const { userId } = req.params;
    const { startDate, endDate } = req.query;

    console.log('=== STATS REQUEST ===');
    console.log('User ID:', userId);
    console.log('Start date:', startDate);
    console.log('End date:', endDate);

    const numericUserId = await getNumericUserId(userId);

    // ✅ SIMPLE QUERY - Không cần index phức tạp
    // Chỉ query theo user_id, filter date trong code
    const snapshot = await db.collection('medicine_history')
      .where('user_id', '==', numericUserId)
      .get();

    console.log('Total documents:', snapshot.size);

    let taken = 0;
    let rejected = 0;
    let missed = 0;

    snapshot.forEach(doc => {
      const data = doc.data();
      const itemTimestamp = data.timestamp;

      // ✅ Filter theo date trong JavaScript
      if (startDate && itemTimestamp < startDate) {
        return; // Skip document này
      }
      if (endDate && itemTimestamp > endDate) {
        return; // Skip document này
      }
      
      // Đếm theo status
      if (data.status === 'taken') taken++;
      else if (data.status === 'rejected') rejected++;
      else if (data.status === 'missed') missed++;
    });

    const total = taken + rejected + missed;
    const adherenceRate = total > 0 ? ((taken / total) * 100).toFixed(1) : 0;

    console.log('Stats result:', { total, taken, rejected, missed, adherenceRate });

    res.json({
      success: true,
      stats: {
        total: total,
        taken: taken,
        rejected: rejected,
        missed: missed,
        adherenceRate: parseFloat(adherenceRate)
      }
    });
  } catch (error) {
    console.error('Get stats error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy thống kê',
      error: error.message
    });
  }
});

// DELETE /api/history/:id - Xóa lịch sử
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;

    const doc = await db.collection('medicine_history').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy lịch sử'
      });
    }

    // Verify ownership
    if (userId) {
      const numericUserId = await getNumericUserId(userId);
      if (doc.data().user_id !== numericUserId) {
        return res.status(403).json({
          success: false,
          message: 'Không có quyền xóa'
        });
      }
    }

    await db.collection('medicine_history').doc(id).delete();

    res.json({
      success: true,
      message: 'Xóa lịch sử thành công!'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa lịch sử',
      error: error.message
    });
  }
});

module.exports = router;