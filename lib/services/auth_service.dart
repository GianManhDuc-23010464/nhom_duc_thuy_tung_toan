// services/auth_service.dart - ĐĂNG KÝ / ĐĂNG NHẬP BẰNG FIREBASE AUTH
// Mật khẩu do Firebase Auth quản lý; hồ sơ (tên hiển thị, email) lưu ở users/{uid}.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/user.dart';

// Lỗi xác thực: mã gốc của Firebase và thông báo tiếng Việt để hiện trên form
class AuthFailure {
  final String code;
  final String message;
  const AuthFailure(this.code, this.message);

  bool get isEmailTaken => code == 'email-already-in-use';
}

class AuthService {
  final fb.FirebaseAuth _auth;
  final FirebaseFirestore _db;

  AuthService({fb.FirebaseAuth? auth, FirebaseFirestore? db})
      : _auth = auth ?? fb.FirebaseAuth.instance,
        _db = db ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) => _db.collection('users').doc(uid);

  // Phiên đăng nhập do Firebase lưu; theo dõi khi đăng nhập / đăng xuất / phiên hết hạn
  Stream<fb.User?> authStateChanges() => _auth.authStateChanges();

  // Mở app: chờ Firebase khôi phục phiên (sự kiện đầu tiên của authStateChanges) rồi đọc hồ sơ
  Future<User?> restoreSession() async {
    final u = await _auth
        .authStateChanges()
        .first
        .timeout(const Duration(seconds: 5), onTimeout: () => _auth.currentUser);
    return u == null ? null : _profileOf(u);
  }

  Future<User?> getCurrentUser() async {
    final u = _auth.currentUser;
    return u == null ? null : _profileOf(u);
  }

  // Hồ sơ trên Firestore; chưa có (hoặc đang offline chưa có cache) thì dựng từ tài khoản Firebase
  Future<User> _profileOf(fb.User u) async {
    final fallback = User(
      id: u.uid,
      username: u.displayName ?? (u.email ?? '').split('@').first,
      email: u.email ?? '',
      createdAt: u.metadata.creationTime,
    );
    try {
      final doc = await _profileDoc(u.uid).get();
      if (doc.exists) return User.fromFirestore(doc.data()!, u.uid);
      await _profileDoc(u.uid).set(fallback.toFirestore(), SetOptions(merge: true));
    } catch (_) {}
    return fallback;
  }

  // Trả về null nếu thành công
  Future<AuthFailure?> register(String username, String email, String password) => _guard(() async {
        final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
        final u = cred.user!;
        await u.updateDisplayName(username.trim());
        final profile = User(id: u.uid, username: username.trim(), email: email.trim());
        await _profileDoc(u.uid).set(profile.toFirestore(), SetOptions(merge: true));
      });

  Future<AuthFailure?> login(String email, String password) =>
      _guard(() => _auth.signInWithEmailAndPassword(email: email.trim(), password: password));

  Future<AuthFailure?> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email.trim()));

  // Đổi tên hiển thị trên Firebase Auth và users/{uid}. Tên tác giả trên bộ thẻ do FlashcardService cập nhật.
  Future<({User? user, AuthFailure? failure})> updateUsername(String username) async {
    final u = _auth.currentUser;
    if (u == null) return (user: null, failure: const AuthFailure('no-current-user', 'Phiên đăng nhập đã hết hạn.'));
    User? updated;
    final failure = await _guard(() async {
      await u.updateDisplayName(username.trim());
      await _profileDoc(u.uid).set({'username': username.trim()}, SetOptions(merge: true));
      updated = (await _profileOf(u)).copyWith(username: username.trim());
    });
    return (user: updated, failure: failure);
  }

  Future<void> logout() => _auth.signOut();

  Future<AuthFailure?> _guard(Future<void> Function() op) async {
    try {
      await op();
      return null;
    } on fb.FirebaseAuthException catch (e) {
      return AuthFailure(e.code, messageFor(e.code));
    } on FirebaseException catch (e) {
      return AuthFailure(e.code, messageFor(e.code));
    } catch (e) {
      return AuthFailure('unknown', messageFor('unknown'));
    }
  }

  // Mã lỗi Firebase -> thông báo tiếng Việt
  static String messageFor(String code) => switch (code) {
        'email-already-in-use' => 'Email này đã có tài khoản. Hãy đăng nhập hoặc dùng email khác.',
        'invalid-email' => 'Email chưa đúng định dạng, ví dụ ban@email.com',
        'weak-password' => 'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.',
        'wrong-password' || 'invalid-credential' || 'user-not-found' || 'INVALID_LOGIN_CREDENTIALS' =>
          'Email hoặc mật khẩu không đúng. Kiểm tra lại hoặc chọn Quên mật khẩu.',
        'user-disabled' => 'Tài khoản này đã bị khóa. Vui lòng liên hệ hỗ trợ.',
        'too-many-requests' => 'Bạn thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.',
        'network-request-failed' || 'unavailable' =>
          'Không kết nối được máy chủ. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.',
        'operation-not-allowed' => 'Đăng nhập bằng email chưa được bật cho ứng dụng.',
        'requires-recent-login' => 'Vui lòng đăng nhập lại rồi thử lại.',
        'missing-email' => 'Vui lòng nhập email.',
        'permission-denied' => 'Bạn không có quyền thực hiện thao tác này.',
        _ => 'Đã có lỗi xảy ra. Vui lòng thử lại.',
      };
}
