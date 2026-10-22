// widgets/base_scaffold.dart - KHUNG MÀN HÌNH CHUNG
// Thống nhất AppBar, màu nền và chữ tiêu đề (lấy từ AppTheme / AppPalette) cho các màn hình chính.
// Không truyền title / titleWidget thì không có AppBar (ví dụ Trang chủ có đầu trang riêng).
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BaseScaffold extends StatelessWidget {
  final String? title;
  final Widget? titleWidget; // Tiêu đề tùy biến (nhiều dòng, cắt chữ...)
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom; // Ô tìm kiếm, TabBar dưới AppBar
  final Widget body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  const BaseScaffold({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.bottom,
    required this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasAppBar = title != null || titleWidget != null;
    return Scaffold(
      backgroundColor: backgroundColor ?? context.palette.background,
      appBar: hasAppBar
          ? AppBar(
              title: titleWidget ?? Text(title!),
              actions: actions,
              bottom: bottom,
            )
          : null,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}
