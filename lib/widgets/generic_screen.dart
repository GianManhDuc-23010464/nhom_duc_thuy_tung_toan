// lib/widgets/generic_screen.dart
import 'package:flutter/material.dart';

/// ============================================================================
/// CÂU 2: BỐ CỤC CHUNG (GENERICS) CHO CÁC TRANG MÀN HÌNH VÀ KẾ THỪA BỐ CỤC NÀY
/// ============================================================================

/// 1. LỚP BỐ CỤC CHUNG STATELESS (`GenericScreen<T>`)
/// `[T]`: Kiểu dữ liệu chính mà màn hình làm việc (vd: FlashcardSet, Flashcard, User, List<...>)
abstract class GenericScreen<T> extends StatelessWidget {
  final String title;
  final T? data;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const GenericScreen({
    super.key,
    required this.title,
    this.data,
    this.showBackButton = true,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  /// Phương thức trừu tượng: Màn hình con kế thừa bắt buộc cài đặt phần nội dung (Body)
  Widget buildBody(BuildContext context);

  /// Xây dựng AppBar chung cho màn hình
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(title),
      automaticallyImplyLeading: showBackButton,
      actions: buildActions(context),
    );
  }

  /// Danh sách nút hành động trên AppBar
  List<Widget>? buildActions(BuildContext context) => actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: buildAppBar(context),
      body: buildBody(context),
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// 2. LỚP BỐ CỤC CHUNG STATEFUL (`GenericStatefulScreen<T>`)
/// Dành cho các màn hình có trạng thái, tương tác form, gọi API hoặc dữ liệu thay đổi
abstract class GenericStatefulScreen<T> extends StatefulWidget {
  final String title;
  final T? initialData;
  final bool showBackButton;
  final List<Widget>? actions;

  const GenericStatefulScreen({
    super.key,
    required this.title,
    this.initialData,
    this.showBackButton = true,
    this.actions,
  });
}

/// State cơ sở kế thừa bố cục chung (`GenericScreenState<W, T>`)
/// Cung cấp sẵn cơ chế quản lý loading, lỗi, dữ liệu T, và cấu trúc Scaffold chuẩn
abstract class GenericScreenState<W extends GenericStatefulScreen<T>, T>
    extends State<W> {
  bool isLoading = false;
  String? errorMessage;
  T? screenData;

  @override
  void initState() {
    super.initState();
    screenData = widget.initialData;
  }

  /// Cập nhật trạng thái loading
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  /// Cập nhật thông báo lỗi
  void setError(String? error) {
    if (mounted) {
      setState(() {
        errorMessage = error;
      });
    }
  }

  /// Cập nhật dữ liệu màn hình
  void setScreenData(T data) {
    if (mounted) {
      setState(() {
        screenData = data;
      });
    }
  }

  /// PHƯƠNG THỨC TRỪU TƯỢNG BẮT BUỘC: Màn hình con kế thừa để định nghĩa giao diện chính
  Widget buildContent(BuildContext context);

  /// Xây dựng AppBar chung - màn hình con có thể dùng mặc định hoặc ghi đè (override)
  PreferredSizeWidget? buildAppBar(BuildContext context) {
    return AppBar(
      title: Text(widget.title),
      automaticallyImplyLeading: widget.showBackButton,
      actions: buildActions(context),
      bottom: buildAppBarBottom(context),
    );
  }

  /// Các action trên AppBar (màn hình con ghi đè nếu có)
  List<Widget>? buildActions(BuildContext context) => widget.actions;

  /// Phần bottom của AppBar (như thanh tìm kiếm, tabbar...)
  PreferredSizeWidget? buildAppBarBottom(BuildContext context) => null;

  /// Floating Action Button (màn hình con ghi đè nếu có)
  Widget? buildFloatingActionButton(BuildContext context) => null;

  /// Bottom Navigation Bar (màn hình con ghi đè nếu có)
  Widget? buildBottomNavigationBar(BuildContext context) => null;

  /// Widget hiển thị khi đang tải dữ liệu (loading)
  Widget buildLoadingIndicator(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text("Đang tải dữ liệu...", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  /// Widget hiển thị khi có lỗi
  Widget buildErrorWidget(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => setError(null),
              icon: const Icon(Icons.refresh),
              label: const Text("Thử lại"),
            ),
          ],
        ),
      ),
    );
  }

  /// Build bố cục tổng quát (Template Method Pattern)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context),
      body: isLoading
          ? buildLoadingIndicator(context)
          : errorMessage != null
              ? buildErrorWidget(context, errorMessage!)
              : buildContent(context),
      floatingActionButton: buildFloatingActionButton(context),
      bottomNavigationBar: buildBottomNavigationBar(context),
    );
  }
}

/// 3. LỚP BỐ CỤC CHUNG COMPONENT (`GenericLayout<T>`)
/// Sử dụng linh hoạt cho mọi widget hoặc nhúng trực tiếp
class GenericLayout<T> extends StatelessWidget {
  final String title;
  final T? data;
  final bool isLoading;
  final String? errorMessage;
  final Widget? body;
  final Widget Function(BuildContext context, T? data)? contentBuilder;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final PreferredSizeWidget? appBarBottom;

  const GenericLayout({
    super.key,
    required this.title,
    this.data,
    this.isLoading = false,
    this.errorMessage,
    this.body,
    this.contentBuilder,
    this.actions,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.appBarBottom,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (errorMessage != null) {
      content = Center(
        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
      );
    } else if (contentBuilder != null) {
      content = contentBuilder!(context, data);
    } else if (body != null) {
      content = body!;
    } else {
      content = const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        bottom: appBarBottom,
      ),
      body: content,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
