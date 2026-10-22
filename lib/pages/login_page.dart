import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../utils/validators.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onNavigateToRegister;

  const LoginPage({
    super.key,
    required this.onLoginSuccess,
    required this.onNavigateToRegister,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error; // Lỗi từ máy chủ / mạng, hiển thị dưới biểu mẫu

  void _login() async {
    if (_isLoading) return;
    setState(() => _error = null);
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      if (!await context.read<ConnectivityService>().check()) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Không có kết nối mạng. Kiểm tra Wi-Fi hoặc dữ liệu di động rồi thử lại.';
        });
        return;
      }

      if (!mounted) return;
      final failure = await context.read<AuthService>().login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (failure == null) {
        widget.onLoginSuccess();
      } else {
        setState(() => _error = failure.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng nhập'),
      ),
      body: ResponsiveBody(child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 40),
              // Logo
              Icon(
                Icons.library_books,
                size: 80,
                color: context.palette.brandText,
              ),
              const SizedBox(height: 20),
              const Text(
                'Đăng nhập',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                textInputAction: TextInputAction.next,
                validator: validateEmail,
              ),
              const SizedBox(height: 16),

              // Mật khẩu
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Mật khẩu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
                onFieldSubmitted: (_) => _login(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  return null;
                },
              ),

              // Quên mật khẩu
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ForgotPasswordPage(initialEmail: _emailController.text.trim()),
                    ),
                  ),
                  child: const Text('Quên mật khẩu?'),
                ),
              ),

              if (_error != null) ...[
                AuthErrorBox(message: _error!),
                const SizedBox(height: 12),
              ],
              const SizedBox(height: 8),

              // Nút đăng nhập
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text(
                  'ĐĂNG NHẬP',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Chuyển đến đăng ký
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Chưa có tài khoản?'),
                  TextButton(
                    onPressed: widget.onNavigateToRegister,
                    child: const Text(
                      'Đăng ký ngay',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      )),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Hộp thông báo lỗi dưới biểu mẫu xác thực
class AuthErrorBox extends StatelessWidget {
  final String message;
  const AuthErrorBox({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.palette.errorBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.palette.errorBg),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: context.palette.error),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: TextStyle(color: context.palette.error))),
        ],
      ),
    );
  }
}
