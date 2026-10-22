// pages/forgot_password_page.dart - QUÊN MẬT KHẨU
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';
import '../utils/validators.dart';
import '../widgets/common.dart';
import 'login_page.dart' show AuthErrorBox;

class ForgotPasswordPage extends StatefulWidget {
  final String initialEmail;
  final bool signedIn; // Mở từ Cài đặt khi đang đăng nhập
  const ForgotPasswordPage({super.key, this.initialEmail = '', this.signedIn = false});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.initialEmail);
  bool _isLoading = false;
  bool _sent = false;
  String? _error;

  // Gửi email đặt lại mật khẩu qua Firebase Auth.
  // Email chưa đăng ký vẫn báo "đã gửi" để không tiết lộ email nào có tài khoản.
  Future<AuthFailure?> _request() async {
    final failure = await context.read<AuthService>().sendPasswordReset(_emailController.text.trim());
    return failure?.code == 'user-not-found' ? null : failure;
  }

  Future<void> _send() async {
    if (_isLoading) return;
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final online = await context.read<ConnectivityService>().check();
    if (!mounted) return;
    if (!online) {
      setState(() {
        _isLoading = false;
        _error = 'Không có kết nối mạng. Kiểm tra kết nối rồi gửi lại.';
      });
      return;
    }
    final failure = await _request();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _error = failure?.message;
      _sent = failure == null;
    });
  }

  Future<void> _resend() async {
    if (!await context.read<ConnectivityService>().check()) {
      if (mounted) showSnack(context, 'Không có kết nối mạng.', color: Colors.red);
      return;
    }
    if (!mounted) return;
    final failure = await _request();
    if (mounted) showSnack(context, failure?.message ?? 'Đã gửi lại email đặt lại mật khẩu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_sent ? 'Đặt lại mật khẩu' : 'Quên mật khẩu')),
      body: ResponsiveBody(child: _sent ? _buildSent() : _buildForm()),
    );
  }

  Widget _buildSent() {
    return EmptyState(
      icon: Icons.mark_email_read,
      title: 'Kiểm tra hộp thư của bạn',
      message:
          'Nếu ${_emailController.text.trim()} đã đăng ký, bạn sẽ nhận được liên kết đặt lại mật khẩu trong vài phút. Hãy xem cả thư mục Spam.',
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.signedIn ? 'Quay lại' : 'Về đăng nhập'),
        ),
        TextButton(onPressed: _resend, child: const Text('Gửi lại email')),
      ],
    );
  }

  Widget _buildForm() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            const SizedBox(height: 40),
            Icon(Icons.lock_reset, size: 80, color: context.palette.brandText),
            const SizedBox(height: 20),
            Text(
              'Nhập email đã đăng ký. Chúng tôi sẽ gửi liên kết để bạn đặt mật khẩu mới.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: context.palette.textMuted),
            ),
            const SizedBox(height: 30),
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: validateEmail,
              onFieldSubmitted: (_) => _send(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              AuthErrorBox(message: _error!),
            ],
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _send,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 52),
                    ),
                    child: const Text(
                      'GỬI LIÊN KẾT ĐẶT LẠI',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
