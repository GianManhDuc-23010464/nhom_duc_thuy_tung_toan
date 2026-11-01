// main.dart - FLASHCARD APP WITH AUTH FLOW
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/stats_page.dart';
import 'pages/profile_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'services/flashcard_service.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/data_store.dart';
import 'services/reminder_service.dart';
import 'theme/app_theme.dart';
import 'widgets/common.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Cache offline: dùng được khi mất mạng, tự đồng bộ khi có mạng lại
  FirebaseFirestore.instance.settings =
      const Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED);
  final connectivity = ConnectivityService();
  runApp(FlashcardApp(
    authService: AuthService(),
    dataStore: FirestoreDataStore(FirebaseFirestore.instance, isOnline: () => connectivity.isOnline),
    connectivity: connectivity,
  ));
}

// Trạng thái xác thực
enum AuthStatus {
  loading,
  unauthenticated,
  authenticated,
  error, // Không tải được dữ liệu của phiên đăng nhập
}

final GlobalKey<ScaffoldMessengerState> rootMessengerKey = GlobalKey<ScaffoldMessengerState>();

class FlashcardApp extends StatefulWidget {
  // Truyền vào để test dùng Firebase giả (firebase_auth_mocks, fake_cloud_firestore)
  final AuthService authService;
  final DataStore dataStore;
  final ConnectivityService connectivity;
  final ReminderService? reminders;

  const FlashcardApp({
    super.key,
    required this.authService,
    required this.dataStore,
    required this.connectivity,
    this.reminders,
  });

  @override
  State<FlashcardApp> createState() => _FlashcardAppState();
}

class _FlashcardAppState extends State<FlashcardApp> {
  late final AuthService _authService = widget.authService;
  late final FlashcardService _flashcardService = FlashcardService()..useStore(widget.dataStore);
  late final ConnectivityService _connectivity = widget.connectivity;
  late final ReminderService _reminders = widget.reminders ?? ReminderService();
  late final ThemeProvider _themeProvider = ThemeProvider(_onLogout);
  StreamSubscription? _authSub;
  final TabNavigator _tabs = TabNavigator();
  AuthStatus _authStatus = AuthStatus.loading;
  bool _showLogin = true; // true: hiển thị login, false: hiển thị register

  final List<Widget> _pages = const [
    HomePage(),
    LibraryPage(),
    StatsPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _flashcardService.onSynced = _onSynced;
    // Phiên bị đăng xuất từ nơi khác (hết hạn, đổi mật khẩu...): quay về màn Đăng nhập
    _authSub = _authService.authStateChanges().listen((u) {
      if (u == null && _authStatus == AuthStatus.authenticated && mounted) {
        _flashcardService.clear();
        _cancelReminder();
        setState(() {
          _authStatus = AuthStatus.unauthenticated;
          _showLogin = true;
        });
      }
    });
    _initializeApp();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  // Khởi tạo app - kiểm tra phiên đăng nhập và giao diện
  Future<void> _initializeApp() async {
    if (_authStatus != AuthStatus.loading) setState(() => _authStatus = AuthStatus.loading);
    _connectivity.start();
    try {
      final splash = Future.delayed(const Duration(milliseconds: 800)); // Splash tối thiểu
      await _themeProvider.load();
      final user = await _authService.restoreSession();
      if (user != null) {
        await _flashcardService.loadForUser(user);
        _syncReminder();
      }
      await splash;
      if (mounted) {
        setState(() {
          _authStatus = user != null ? AuthStatus.authenticated : AuthStatus.unauthenticated;
        });
      }
    } catch (e) {
      // Có phiên nhưng không đọc được dữ liệu: báo lỗi và cho thử lại, không đẩy về Đăng nhập
      debugPrint('❌ Lỗi khởi tạo: $e');
      if (mounted) {
        setState(() => _authStatus = AuthStatus.error);
      }
    }
  }

  // Nhắc học lưu theo tài khoản: đăng nhập trên máy này thì đặt lại lịch theo cài đặt của tài khoản
  Future<void> _syncReminder() async {
    try {
      if (_flashcardService.remindEnabled) {
        await _reminders.scheduleDaily(_flashcardService.remindTime);
      } else {
        await _reminders.cancel();
      }
    } catch (e) {
      debugPrint('❌ Không đặt được lịch nhắc học: $e');
    }
  }

  Future<void> _cancelReminder() async {
    try {
      await _reminders.cancel();
    } catch (_) {}
  }

  // Firestore đã đẩy xong các kết quả làm khi mất mạng
  void _onSynced(int n) {
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text("Đã có mạng. Đã đồng bộ $n kết quả kiểm tra.")),
    );
  }

  // Đăng nhập / đăng ký thành công: tải dữ liệu của tài khoản rồi vào Trang chủ
  Future<void> _onAuthenticated(String message) async {
    final user = await _authService.getCurrentUser();
    if (user == null) return;
    try {
      await _flashcardService.loadForUser(user);
      _syncReminder();
    } catch (e) {
      rootMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text("Không tải được dữ liệu học tập. Vui lòng thử lại.")),
      );
      return;
    }
    if (!mounted) return;
    _tabs.go(0);
    setState(() => _authStatus = AuthStatus.authenticated);
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  // Đăng xuất
  Future<void> _onLogout() async {
    await _cancelReminder();
    await _authService.logout();
    _flashcardService.clear();
    if (!mounted) return;
    setState(() {
      _authStatus = AuthStatus.unauthenticated;
      _showLogin = true;
    });
    rootMessengerKey.currentState?.showSnackBar(const SnackBar(content: Text("Đã đăng xuất")));
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _themeProvider),
        ChangeNotifierProvider.value(value: _flashcardService),
        ChangeNotifierProvider.value(value: _connectivity),
        ChangeNotifierProvider.value(value: _tabs),
        Provider.value(value: _authService),
        Provider.value(value: _reminders),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Flashcard And Quizz',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootMessengerKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            // Chạm ra ngoài ô nhập để ẩn bàn phím
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            ),
            home: _buildCurrentPage(themeProvider.isDark(context)),
          );
        },
      ),
    );
  }

  // Xây dựng trang hiện tại dựa trên trạng thái auth
  Widget _buildCurrentPage(bool isDark) {
    switch (_authStatus) {
      case AuthStatus.loading:
        return _buildLoadingScreen(isDark);

      case AuthStatus.unauthenticated:
        return _showLogin
            ? LoginPage(
          onLoginSuccess: () => _onAuthenticated('Đăng nhập thành công'),
          onNavigateToRegister: () => setState(() => _showLogin = false),
        )
            : RegisterPage(
          onRegisterSuccess: () => _onAuthenticated('Đã tạo tài khoản. Chào mừng bạn!'),
          onNavigateToLogin: () => setState(() => _showLogin = true),
        );

      case AuthStatus.authenticated:
        return _buildMainApp(isDark);

      case AuthStatus.error:
        return Scaffold(
          body: SafeArea(
            child: ErrorState(
              title: "Không tải được dữ liệu",
              message: "Chưa đọc được dữ liệu học tập. Kiểm tra kết nối rồi thử lại, dữ liệu của bạn không bị xóa.",
              onRetry: _initializeApp,
            ),
          ),
        );
    }
  }

  // Màn hình khởi động (Splash): kiểm tra phiên đăng nhập
  Widget _buildLoadingScreen(bool isDark) {
    final p = isDark ? AppPalette.dark : AppPalette.light;
    return Scaffold(
      backgroundColor: p.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo app
            Icon(
              Icons.library_books,
              size: 80,
              color: p.brandText,
            ),
            const SizedBox(height: 20),
            CircularProgressIndicator(color: p.brand),
            const SizedBox(height: 20),
            Text(
              'Flashcard And Quizz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: p.text,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Đang kiểm tra phiên đăng nhập...',
              style: TextStyle(
                color: p.textMuted,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // App chính sau khi đăng nhập
  Widget _buildMainApp(bool isDark) {
    return Consumer<TabNavigator>(
      builder: (context, tabs, _) => Scaffold(
        body: IndexedStack(
          index: tabs.index,
          children: _pages,
        ),
        // Màu lấy từ bottomNavigationBarTheme; viền mảnh phía trên tách khỏi nội dung
        bottomNavigationBar: DecoratedBox(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: context.palette.border))),
          child: BottomNavigationBar(
          currentIndex: tabs.index,
          onTap: tabs.go,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.collections_bookmark),
              label: 'Thư viện',
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
        ),
      ),
    );
  }
}

// Điều hướng giữa các tab chính; Thư viện có thể mở sẵn một tab con
class TabNavigator extends ChangeNotifier {
  static const int home = 0, library = 1, stats = 2, profile = 3;

  int _index = 0;
  int get index => _index;
  String? _libraryTab; // 'mine' | 'saved' | 'explore'
  bool _focusSearch = false;

  void go(int index) {
    _index = index;
    notifyListeners();
  }

  void openLibrary({String? tab, bool focusSearch = false}) {
    _libraryTab = tab;
    _focusSearch = focusSearch;
    go(library);
  }

  // Thư viện đọc yêu cầu một lần rồi xóa
  ({String? tab, bool focusSearch}) takeLibraryRequest() {
    final r = (tab: _libraryTab, focusSearch: _focusSearch);
    _libraryTab = null;
    _focusSearch = false;
    return r;
  }
}

// Provider quản lý giao diện sáng/tối và đăng xuất
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'sm_appearance';
  final Future<void> Function() onLogout;
  ThemeMode _themeMode = ThemeMode.system;

  ThemeProvider(this.onLogout);

  ThemeMode get themeMode => _themeMode;

  bool isDark(BuildContext context) =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system && MediaQuery.platformBrightnessOf(context) == Brightness.dark);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _themeMode = ThemeMode.values.firstWhere((m) => m.name == saved, orElse: () => ThemeMode.system);
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  Future<void> logout() => onLogout();
}
