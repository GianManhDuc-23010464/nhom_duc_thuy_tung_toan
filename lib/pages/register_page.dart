import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../services/auth_service.dart';
import '../services/connectivity_service.dart';
import '../utils/validators.dart';
import 'login_page.dart' show AuthErrorBox;

class RegisterPage extends StatefulWidget {
  final VoidCallback onRegisterSuccess;
  final VoidCallback onNavigateToLogin;

  const RegisterPage({
    super.key,
    required this.onRegisterSuccess,
    required this.onNavigateToLogin,
  });

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreed = false;
  bool _showAgreeError = false;
  String? _emailTakenFor; // Email đã có tài khoản
  String? _error;

  void _register() async {
    if (_isLoading) return;
    setState(() {
      _error = null;
      _showAgreeError = !_agreed;
    });
    final valid = _formKey.currentState!.validate();
    if (valid && _agreed) {
      setState(() {
        _isLoading = true;
      });

      if (!await context.read<ConnectivityService>().check()) {
        if (!mounted) return;
        setState(() {
          _isLoading = false;
          _error = 'Không có kết nối mạng. Tạo tài khoản cần kết nối Internet.';
        });
        return;
      }

      if (!mounted) return;
      final failure = await context.read<AuthService>().register(
        _usernameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      if (failure == null) {
        // Đăng ký xong được đăng nhập luôn
        widget.onRegisterSuccess();
      } else if (failure.isEmailTaken) {
        _emailTakenFor = _emailController.text.trim();
        _formKey.currentState!.validate();
      } else {
        setState(() => _error = failure.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đăng ký tài khoản'),
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
                'Tạo tài khoản mới',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),

              // Tên người dùng
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Tên người dùng',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên người dùng';
                  }
                  if (value.length < 3) {
                    return 'Tên người dùng phải có ít nhất 3 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  final error = validateEmail(value);
                  if (error != null) return error;
                  if (_emailTakenFor != null && value!.trim().toLowerCase() == _emailTakenFor!.toLowerCase()) {
                    return 'Email này đã có tài khoản. Hãy đăng nhập hoặc dùng email khác.';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập mật khẩu';
                  }
                  if (value.length < 6) {
                    return 'Mật khẩu phải có ít nhất 6 ký tự';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Xác nhận mật khẩu
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Xác nhận mật khẩu',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng xác nhận mật khẩu';
                  }
                  if (value != _passwordController.text) {
                    return 'Mật khẩu không khớp';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),

              // Đồng ý điều khoản
              CheckboxListTile(
                value: _agreed,
                onChanged: (v) => setState(() {
                  _agreed = v ?? false;
                  if (_agreed) _showAgreeError = false;
                }),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Tôi đồng ý với điều khoản sử dụng và chính sách quyền riêng tư',
                  style: TextStyle(fontSize: 14),
                ),
              ),
              if (_showAgreeError)
                Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 8),
                  child: Text(
                    'Bạn cần đồng ý điều khoản để tạo tài khoản',
                    style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                AuthErrorBox(message: _error!),
              ],
              const SizedBox(height: 22),

              // Nút đăng ký
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _register,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                ),
                child: const Text(
                  'ĐĂNG KÝ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Chuyển đến đăng nhập
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Đã có tài khoản?'),
                  TextButton(
                    onPressed: widget.onNavigateToLogin,
                    child: const Text(
                      'Đăng nhập ngay',
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
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}