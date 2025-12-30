// routes/medicine.routes.js
const express = require('express');
const router = express.Router();
const { db } = require('../server');

// Helper function để lấy hoặc tạo numeric_user_id
async function getOrCreateNumericUserId(userId) {
  const userDoc = await db.collection('users').doc(userId).get();
  
  if (!userDoc.exists) {
    throw new Error('Không tìm thấy người dùng');
  }

  let userData = userDoc.data();
  
  // Nếu chưa có numeric_user_id, tạo mới
  if (!userData.numeric_user_id) {
    const timestamp = Date.now();
    const numericUserId = parseInt(timestamp.toString().slice(-9));
    
    await db.collection('users').doc(userId).update({
      numeric_user_id: numericUserId
    });
    
    console.log(`Created numeric_user_id: ${numericUserId} for user: ${userId}`);
    return numericUserId;
  }
  
  return userData.numeric_user_id;
}

// GET /api/medicines/:userId - Lấy danh sách thuốc
router.get('/:userId', async (req, res) => {
  try {
    const { userId } = req.params;
    
    console.log('Get medicines for userId:', userId);
    
    const numericUserId = await getOrCreateNumericUserId(userId);
    console.log('Querying with numeric_user_id:', numericUserId);

    const snapshot = await db.collection('medicines')
      .where('user_id', '==', numericUserId)
      .get();

    const medicines = [];
    snapshot.forEach(doc => {
      medicines.push({
        id: doc.id,
        ...doc.data()
      });
    });

    medicines.sort((a, b) => a.name.localeCompare(b.name));

    console.log('Found medicines:', medicines.length);

    res.json({
      success: true,
      medicines: medicines
    });
  } catch (error) {
    console.error('Get medicines error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi lấy danh sách thuốc',
      error: error.message
    });
  }
});

// POST /api/medicines - Tạo thuốc mới
router.post('/', async (req, res) => {
  try {
    const { userId, name, description, usage, startDate, expiryDate } = req.body;

    if (!userId || !name || !startDate || !expiryDate) {
      return res.status(400).json({
        success: false,
        message: 'Vui lòng nhập đầy đủ thông tin'
      });
    }

    // ✅ Sử dụng helper function
    const numericUserId = await getOrCreateNumericUserId(userId);
    console.log('Using numeric_user_id:', numericUserId);

    const medicineData = {
      user_id: numericUserId,
      name: name,
      description: description || null,
      usage: usage || null,
      start_date: startDate,
      expiry_date: expiryDate,
      created_at: new Date().toISOString()
    };

    const docRef = await db.collection('medicines').add(medicineData);

    res.status(201).json({
      success: true,
      message: 'Thêm thuốc thành công!',
      medicine: {
        id: docRef.id,
        ...medicineData
      }
    });
  } catch (error) {
    console.error('Create medicine error:', error);
    res.status(500).json({
      success: false,
      message: 'Lỗi khi thêm thuốc',
      error: error.message
    });
  }
});

// PUT /api/medicines/:id - Cập nhật thuốc
router.put('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, name, description, usage, startDate, expiryDate } = req.body;

    const doc = await db.collection('medicines').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thuốc'
      });
    }

    // Verify ownership
    const numericUserId = await getOrCreateNumericUserId(userId);
    if (doc.data().user_id !== numericUserId) {
      return res.status(403).json({
        success: false,
        message: 'Không có quyền chỉnh sửa'
      });
    }

    const updateData = {
      name: name,
      description: description || null,
      usage: usage || null,
      start_date: startDate,
      expiry_date: expiryDate,
      updated_at: new Date().toISOString()
    };

    await db.collection('medicines').doc(id).update(updateData);

    res.json({
      success: true,
      message: 'Cập nhật thuốc thành công!'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi cập nhật thuốc',
      error: error.message
    });
  }
});

// DELETE /api/medicines/:id - Xóa thuốc
router.delete('/:id', async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.query;

    const doc = await db.collection('medicines').doc(id).get();
    if (!doc.exists) {
      return res.status(404).json({
        success: false,
        message: 'Không tìm thấy thuốc'
      });
    }

    // Verify ownership
    if (userId) {
      const numericUserId = await getOrCreateNumericUserId(userId);
      if (doc.data().user_id !== numericUserId) {
        return res.status(403).json({
          success: false,
          message: 'Không có quyền xóa'
        });
      }
    }

    await db.collection('medicines').doc(id).delete();

    res.json({
      success: true,
      message: 'Xóa thuốc thành công!'
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Lỗi khi xóa thuốc',
      error: error.message
    });
  }
});

module.exports = router;