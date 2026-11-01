// main.dart - FLASHCARD APP
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'pages/home_page.dart';
import 'pages/library_page.dart';
import 'pages/stats_page.dart';
import 'services/flashcard_service.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/data_store.dart';
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

  const FlashcardApp({
    super.key,
    required this.authService,
    required this.dataStore,
    required this.connectivity,
  });

  @override
  State<FlashcardApp> createState() => _FlashcardAppState();
}

class _FlashcardAppState extends State<FlashcardApp> {
  late final AuthService _authService = widget.authService;
  late final FlashcardService _flashcardService = FlashcardService()..useStore(widget.dataStore);
  late final ConnectivityService _connectivity = widget.connectivity;
  StreamSubscription? _authSub;
  final TabNavigator _tabs = TabNavigator();
  AuthStatus _authStatus = AuthStatus.loading;

  final List<Widget> _pages = const [
    HomePage(),
    LibraryPage(),
    StatsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _flashcardService.onSynced = _onSynced;
    // Phiên bị đăng xuất từ nơi khác (hết hạn, đổi mật khẩu...): quay về màn Đăng nhập
    _authSub = _authService.authStateChanges().listen((u) {
      if (u == null && _authStatus == AuthStatus.authenticated && mounted) {
        _flashcardService.clear();
        setState(() {
          _authStatus = AuthStatus.unauthenticated;
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
      final user = await _authService.restoreSession();
      if (user != null) {
        await _flashcardService.loadForUser(user);
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

  // Firestore đã đẩy xong các kết quả làm khi mất mạng
  void _onSynced(int n) {
    rootMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text("Đã có mạng. Đã đồng bộ $n kết quả kiểm tra.")),
    );
  }


  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _flashcardService),
        ChangeNotifierProvider.value(value: _connectivity),
        ChangeNotifierProvider.value(value: _tabs),
        Provider.value(value: _authService),
      ],
      child: MaterialApp(
            title: 'Flashcard And Quizz',
            debugShowCheckedModeBanner: false,
            scaffoldMessengerKey: rootMessengerKey,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            // Chạm ra ngoài ô nhập để ẩn bàn phím
            builder: (context, child) => GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: child,
            ),
            home: Builder(
              builder: (context) => _buildCurrentPage(Theme.of(context).brightness == Brightness.dark),
            ),
          ),
    );
  }

  // Xây dựng trang hiện tại dựa trên trạng thái auth
  Widget _buildCurrentPage(bool isDark) {
    switch (_authStatus) {
      case AuthStatus.loading:
        return _buildLoadingScreen(isDark);

      case AuthStatus.unauthenticated:
        return Scaffold(
          body: Center(
            child: Text('Màn hình đăng nhập và đăng ký đang được tách riêng.'),
          ),
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
  static const int home = 0, library = 1, stats = 2;

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
