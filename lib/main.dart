// main.dart - FLASHCARD APP WITH AUTH FLOW
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'pages/home_page.dart';
import 'pages/stats_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'services/flashcard_service.dart';
import 'services/auth_service.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const FlashcardApp());
}

// Trạng thái xác thực
enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
}

class FlashcardApp extends StatefulWidget {
  const FlashcardApp({super.key});

  @override
  State<FlashcardApp> createState() => _FlashcardAppState();
}

class _FlashcardAppState extends State<FlashcardApp> {
  int _currentIndex = 0;
  ThemeMode _themeMode = ThemeMode.light;
  AuthStatus _authStatus = AuthStatus.loading;
  bool _showLogin = false; // true: hiển thị login, false: hiển thị register

  final List<Widget> _pages = [
    const HomePage(),
    const StatsPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Khởi tạo app - kiểm tra trạng thái đăng nhập và theme
  Future<void> _initializeApp() async {
    try {
      final authService = AuthService();
      final flashcardService = FlashcardService();

      // Kiểm tra theme và đăng nhập song song
      final results = await Future.wait([
        flashcardService.isDarkMode(),
        authService.isLoggedIn(),
      ]);

      final isDark = results[0] as bool;
      final isLoggedIn = results[1] as bool;

      if (mounted) {
        setState(() {
          _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
          _authStatus = isLoggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
          _showLogin = false; // Mặc định hiển thị trang đăng ký đầu tiên
        });
      }
    } catch (e) {
      // Nếu có lỗi, mặc định là chưa đăng nhập
      if (mounted) {
        setState(() {
          _authStatus = AuthStatus.unauthenticated;
          _showLogin = false;
        });
      }
    }
  }

  // Cập nhật theme
  void _updateTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
    FlashcardService().setDarkMode(isDark);
  }

  // Đăng nhập thành công
  void _onLoginSuccess() {
    setState(() {
      _authStatus = AuthStatus.authenticated;
      _currentIndex = 0; // Về trang chủ
    });
  }

  // Đăng xuất
  void _onLogout() {
    setState(() {
      _authStatus = AuthStatus.unauthenticated;
      _showLogin = false; // Hiển thị trang đăng ký sau khi logout
      _currentIndex = 0;
    });
  }

  // Đăng ký thành công - chuyển sang trang đăng nhập
  void _onRegisterSuccess() {
    setState(() {
      _showLogin = true;
    });

    // Hiển thị thông báo thành công
    ScaffoldMessenger.of(GlobalKey<NavigatorState>().currentContext!).showSnackBar(
      const SnackBar(
        content: Text('Đăng ký thành công! Vui lòng đăng nhập.'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );
  }

  // Chuyển đến trang đăng nhập
  void _navigateToLogin() {
    setState(() {
      _showLogin = true;
    });
  }

  // Chuyển đến trang đăng ký
  void _navigateToRegister() {
    setState(() {
      _showLogin = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(_updateTheme, _onLogout),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flashcard Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _themeMode,
            home: _buildCurrentPage(),
          );
        },
      ),
    );
  }

  // Xây dựng trang hiện tại dựa trên trạng thái auth
  Widget _buildCurrentPage() {
    switch (_authStatus) {
      case AuthStatus.loading:
        return _buildLoadingScreen();

      case AuthStatus.unauthenticated:
        return _showLogin
            ? LoginPage(
          onLoginSuccess: _onLoginSuccess,
          onNavigateToRegister: _navigateToRegister,
        )
            : RegisterPage(
          onRegisterSuccess: _onRegisterSuccess,
          onNavigateToLogin: _navigateToLogin,
        );

      case AuthStatus.authenticated:
        return _buildMainApp();
    }
  }

  // Màn hình loading
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: _themeMode == ThemeMode.dark
          ? const Color(0xFF121212)
          : const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo app
            Icon(
              Icons.library_books,
              size: 80,
              color: _themeMode == ThemeMode.dark
                  ? Colors.purple.shade300
                  : Colors.blue.shade700,
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Flashcard Pro',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _themeMode == ThemeMode.dark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Đang tải...',
              style: TextStyle(
                color: _themeMode == ThemeMode.dark ? Colors.grey.shade400 : Colors.grey.shade600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // App chính sau khi đăng nhập
  Widget _buildMainApp() {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        backgroundColor: _themeMode == ThemeMode.dark
            ? const Color(0xFF1E1E1E)
            : Colors.white,
        selectedItemColor: _themeMode == ThemeMode.dark
            ? const Color(0xFF9C27B0) // Màu tím trong dark mode
            : const Color(0xFF3F51B5), // Màu xanh trong light mode
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Thống kê',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Cá nhân',
          ),
        ],
      ),
    );
  }
}

// Provider quản lý theme và logout
class ThemeProvider extends ChangeNotifier {
  final Function(bool) onThemeChanged;
  final VoidCallback onLogout;

  ThemeProvider(this.onThemeChanged, this.onLogout);

  void toggleTheme(bool isDark) {
    onThemeChanged(isDark);
    notifyListeners();
  }

  void logout() {
    onLogout();
    notifyListeners();
  }
}