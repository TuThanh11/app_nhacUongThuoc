import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  AuthService._init();

  // Lấy user hiện tại
  User? get currentUser => _auth.currentUser;

  // Stream để theo dõi trạng thái đăng nhập
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Đăng ký với email và password
  Future<Map<String, dynamic>> signUp({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      // Tạo user trong Firebase Auth
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Cập nhật display name
      await userCredential.user?.updateDisplayName(username);

      // Lưu thông tin user vào Firestore
      await _db.collection('users').doc(userCredential.user!.uid).set({
        'username': username,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
        'user_id': userCredential.user!.uid.hashCode,
        'avatar_url': 'preset_0', // Default avatar
      });

      return {
        'success': true,
        'message': 'Đăng ký thành công!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng ký thất bại!';
      
      switch (e.code) {
        case 'weak-password':
          message = 'Mật khẩu quá yếu. Vui lòng chọn mật khẩu mạnh hơn.';
          break;
        case 'email-already-in-use':
          message = 'Email này đã được sử dụng.';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ.';
          break;
        case 'operation-not-allowed':
          message = 'Đăng ký bị vô hiệu hóa.';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Đăng nhập với email và password
  Future<Map<String, dynamic>> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return {
        'success': true,
        'message': 'Đăng nhập thành công!',
        'user': userCredential.user,
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Đăng nhập thất bại!';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản với email này.';
          break;
        case 'wrong-password':
          message = 'Mật khẩu không đúng.';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ.';
          break;
        case 'user-disabled':
          message = 'Tài khoản này đã bị vô hiệu hóa.';
          break;
        case 'invalid-credential':
          message = 'Email hoặc mật khẩu không đúng.';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Đăng xuất
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Lấy thông tin user từ Firestore
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Lấy user_id (hashCode) để dùng trong app
  Future<int?> getUserId() async {
    try {
      final user = currentUser;
      if (user == null) return null;

      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data()?['user_id'] as int?;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Đổi mật khẩu
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = currentUser;
      if (user == null || user.email == null) {
        return {
          'success': false,
          'message': 'Không tìm thấy thông tin người dùng.',
        };
      }

      // Xác thực lại với mật khẩu hiện tại
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);

      // Đổi mật khẩu mới
      await user.updatePassword(newPassword);

      return {
        'success': true,
        'message': 'Đổi mật khẩu thành công!',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Đổi mật khẩu thất bại!';
      
      switch (e.code) {
        case 'wrong-password':
          message = 'Mật khẩu hiện tại không đúng.';
          break;
        case 'weak-password':
          message = 'Mật khẩu mới quá yếu.';
          break;
        case 'invalid-credential':
          message = 'Mật khẩu hiện tại không đúng.';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Reset mật khẩu qua email
  Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return {
        'success': true,
        'message': 'Email đặt lại mật khẩu đã được gửi!',
      };
    } on FirebaseAuthException catch (e) {
      String message = 'Gửi email thất bại!';
      
      switch (e.code) {
        case 'user-not-found':
          message = 'Không tìm thấy tài khoản với email này.';
          break;
        case 'invalid-email':
          message = 'Email không hợp lệ.';
          break;
        default:
          message = 'Lỗi: ${e.message}';
      }
      
      return {
        'success': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Đã xảy ra lỗi: $e',
      };
    }
  }

  // Cập nhật avatar URL
  Future<void> updateUserAvatar(String avatarUrl) async {
    try {
      final user = currentUser;
      if (user == null) return;

      await _db.collection('users').doc(user.uid).update({
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Không thể cập nhật avatar: $e');
    }
  }

  // Lấy avatar URL
  Future<String?> getUserAvatar() async {
    try {
      final userInfo = await getUserInfo();
      return userInfo?['avatar_url'] as String?;
    } catch (e) {
      return null;
    }
  }
}