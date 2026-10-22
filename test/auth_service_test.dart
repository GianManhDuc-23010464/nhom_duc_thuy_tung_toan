// AuthService với Firebase Auth giả (firebase_auth_mocks) và Firestore giả
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mock_exceptions/mock_exceptions.dart';
import 'package:flashcard_app/services/auth_service.dart';

void main() {
  late MockFirebaseAuth auth;
  late FakeFirebaseFirestore db;
  late AuthService service;

  setUp(() {
    auth = MockFirebaseAuth();
    db = FakeFirebaseFirestore();
    service = AuthService(auth: auth, db: db);
  });

  void throwOn(Symbol method, String code) =>
      whenCalling(Invocation.method(method, null)).on(auth).thenThrow(FirebaseAuthException(code: code));

  test('đăng ký thành công: đăng nhập luôn, lưu hồ sơ users/{uid}, đặt tên hiển thị', () async {
    expect(await service.register('An', 'an@x.vn', '123456'), isNull);
    final uid = auth.currentUser!.uid;
    expect(auth.currentUser!.displayName, 'An');
    final profile = (await db.doc('users/$uid').get()).data()!;
    expect(profile['username'], 'An');
    expect(profile['email'], 'an@x.vn');
    final user = await service.getCurrentUser();
    expect(user!.username, 'An');
  });

  test('đăng ký trùng email: báo lỗi tiếng Việt, đánh dấu email đã có tài khoản', () async {
    throwOn(#createUserWithEmailAndPassword, 'email-already-in-use');
    final f = await service.register('An', 'an@x.vn', '123456');
    expect(f!.isEmailTaken, isTrue);
    expect(f.message, 'Email này đã có tài khoản. Hãy đăng nhập hoặc dùng email khác.');
    expect(auth.currentUser, isNull);
  });

  test('đăng nhập sai mật khẩu', () async {
    throwOn(#signInWithEmailAndPassword, 'wrong-password');
    final f = await service.login('an@x.vn', 'sai');
    expect(f!.code, 'wrong-password');
    expect(f.message, 'Email hoặc mật khẩu không đúng. Kiểm tra lại hoặc chọn Quên mật khẩu.');
  });

  test('đăng nhập đúng rồi đăng xuất', () async {
    expect(await service.login('an@x.vn', '123456'), isNull);
    expect(await service.getCurrentUser(), isNotNull);
    await service.logout();
    expect(await service.getCurrentUser(), isNull);
  });

  test('quên mật khẩu: gửi thành công / email sai định dạng', () async {
    expect(await service.sendPasswordReset('an@x.vn'), isNull);
    throwOn(#sendPasswordResetEmail, 'invalid-email');
    final f = await service.sendPasswordReset('an@');
    expect(f!.message, 'Email chưa đúng định dạng, ví dụ ban@email.com');
  });

  test('đổi tên hiển thị: Firebase Auth và users/{uid}', () async {
    await service.register('An', 'an@x.vn', '123456');
    final r = await service.updateUsername('  Bình  ');
    expect(r.failure, isNull);
    expect(r.user!.username, 'Bình');
    expect(auth.currentUser!.displayName, 'Bình');
    expect((await db.doc('users/${auth.currentUser!.uid}').get()).data()!['username'], 'Bình');
  });

  test('đổi tên khi chưa đăng nhập', () async {
    final r = await service.updateUsername('Bình');
    expect(r.user, isNull);
    expect(r.failure, isNotNull);
  });

  test('thông báo lỗi tiếng Việt cho các mã lỗi Firebase', () {
    const codes = {
      'invalid-email': 'Email chưa đúng định dạng, ví dụ ban@email.com',
      'weak-password': 'Mật khẩu quá yếu. Hãy dùng ít nhất 6 ký tự.',
      'invalid-credential': 'Email hoặc mật khẩu không đúng. Kiểm tra lại hoặc chọn Quên mật khẩu.',
      'user-not-found': 'Email hoặc mật khẩu không đúng. Kiểm tra lại hoặc chọn Quên mật khẩu.',
      'too-many-requests': 'Bạn thử quá nhiều lần. Vui lòng đợi vài phút rồi thử lại.',
      'network-request-failed': 'Không kết nối được máy chủ. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.',
      'ma-la': 'Đã có lỗi xảy ra. Vui lòng thử lại.',
    };
    codes.forEach((code, msg) => expect(AuthService.messageFor(code), msg, reason: code));
  });
}
