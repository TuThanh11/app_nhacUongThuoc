// services/email.service.js
const nodemailer = require('nodemailer');

// Cấu hình Gmail transporter
const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: process.env.EMAIL_USER, // Email của bạn
    pass: process.env.EMAIL_PASSWORD // App Password từ Gmail
  }
});

// Generate random password
function generateRandomPassword(length = 8) {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#$%^&*';
  let password = '';
  for (let i = 0; i < length; i++) {
    password += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return password;
}

// Gửi email mật khẩu mới
async function sendNewPasswordEmail(email, newPassword, username) {
  const mailOptions = {
    from: process.env.EMAIL_USER,
    to: email,
    subject: 'Khôi phục mật khẩu - HOT Reminder',
    html: `
      <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
        <div style="background-color: #5F9F7A; padding: 20px; text-align: center;">
          <h1 style="color: white; margin: 0;">HOT Reminder</h1>
          <p style="color: white; margin: 5px 0;">Healthy On Time</p>
        </div>
        
        <div style="padding: 30px; background-color: #f9f9f9;">
          <h2 style="color: #2D5F3F;">Xin chào ${username || 'bạn'}!</h2>
          
          <p style="font-size: 16px; line-height: 1.6;">
            Chúng tôi đã nhận được yêu cầu khôi phục mật khẩu cho tài khoản của bạn.
          </p>
          
          <div style="background-color: white; padding: 20px; border-radius: 10px; margin: 20px 0;">
            <p style="margin: 0; color: #666;">Mật khẩu mới của bạn là:</p>
            <h2 style="color: #5F9F7A; margin: 10px 0; font-size: 24px; letter-spacing: 2px;">
              ${newPassword}
            </h2>
          </div>
          
          <p style="font-size: 14px; color: #666; line-height: 1.6;">
            <strong>Lưu ý:</strong> Vì lý do bảo mật, chúng tôi khuyên bạn nên đổi mật khẩu này ngay sau khi đăng nhập.
          </p>
          
          <p style="font-size: 14px; color: #999; margin-top: 30px;">
            Nếu bạn không yêu cầu khôi phục mật khẩu, vui lòng bỏ qua email này.
          </p>
        </div>
        
        <div style="background-color: #2D5F3F; padding: 20px; text-align: center;">
          <p style="color: white; margin: 0; font-size: 12px;">
            © 2025 HOT Reminder. All rights reserved.
          </p>
        </div>
      </div>
    `
  };

  try {
    await transporter.sendMail(mailOptions);
    return { success: true };
  } catch (error) {
    console.error('Send email error:', error);
    return { success: false, error: error.message };
  }
}

module.exports = {
  generateRandomPassword,
  sendNewPasswordEmail
};