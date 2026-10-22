// widgets/common.dart - THÀNH PHẦN DÙNG CHUNG: trạng thái trống/lỗi, banner mất mạng, thông báo, hộp thoại, bố cục responsive
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../theme/app_theme.dart';

// Mốc màn hình: ≤360 gọn, ≥600 máy tính bảng (nội dung đọc giới hạn bề rộng)
class Breakpoints {
  static const double compact = 360;
  static const double tablet = 600;
  static const double readableWidth = 640;

  static bool isCompact(BuildContext context) => MediaQuery.sizeOf(context).width <= compact;
}

// Căn giữa và giới hạn bề rộng nội dung trên màn hình rộng; điện thoại giữ nguyên
class ResponsiveBody extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  const ResponsiveBody({super.key, required this.child, this.maxWidth = Breakpoints.readableWidth});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, box) {
      final width = box.maxWidth.isFinite && box.maxWidth < maxWidth ? box.maxWidth : maxWidth;
      // heightFactor 1: chỉ cao bằng nội dung (dùng được cả trong thanh đáy)
      return Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: SizedBox(width: width, child: child),
      );
    });
  }
}

// Trạng thái trống: icon, tiêu đề, mô tả, nút hành động
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final List<Widget> actions;
  final Color? iconColor;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actions = const [],
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: p.brandSoft, shape: BoxShape.circle),
                child: Icon(icon, size: 40, color: iconColor ?? p.brandText),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: p.text, fontWeight: FontWeight.bold),
              ),
              if (message != null) ...[
                const SizedBox(height: 8),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: p.textMuted, height: 1.4),
                ),
              ],
              for (final a in actions) ...[const SizedBox(height: 12), SizedBox(width: double.infinity, child: a)],
            ],
          ),
        ),
      ),
    );
  }
}

// Trạng thái lỗi kèm nút Thử lại
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.title, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off,
      iconColor: context.palette.error,
      title: title,
      message: message,
      actions: [ElevatedButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text("Thử lại"))],
    );
  }
}

// Hiện khi mất kết nối mạng
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final online = context.watch<ConnectivityService>().isOnline;
    if (online) return const SizedBox.shrink();
    final p = context.palette;
    return Container(
      width: double.infinity,
      color: p.warningBg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(Icons.wifi_off, size: 16, color: p.warning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Mất kết nối. Dữ liệu được lưu trên máy và đồng bộ khi có mạng.",
              style: TextStyle(fontSize: 12, color: p.warning),
            ),
          ),
        ],
      ),
    );
  }
}

// Thông báo ngắn. color = Colors.red: thông báo lỗi; còn lại dùng màu mặc định của theme
void showSnack(BuildContext context, String message, {Color? color, String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  final isError = color == Colors.red;
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    backgroundColor: isError ? AppPalette.light.error : null,
    duration: Duration(seconds: onAction != null ? 5 : 2),
    action: onAction != null ? SnackBarAction(label: actionLabel ?? 'Thử lại', textColor: Colors.white, onPressed: onAction) : null,
  ));
}

// Báo lỗi ghi dữ liệu kèm nút Thử lại
void showSaveError(BuildContext context, VoidCallback retry) {
  showSnack(
    context,
    "Không lưu được dữ liệu. Nội dung bạn nhập vẫn còn nguyên.",
    color: Colors.red,
    actionLabel: "Thử lại",
    onAction: retry,
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String content,
  required String confirmLabel,
  String cancelLabel = "Hủy",
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(confirmLabel, style: TextStyle(color: danger ? ctx.palette.error : null)),
        ),
      ],
    ),
  );
  return result ?? false;
}

// Hộp thoại "Bỏ thay đổi chưa lưu?" dùng cho các biểu mẫu
Future<bool> confirmDiscardChanges(BuildContext context) => confirmDialog(
      context,
      title: "Bỏ thay đổi chưa lưu?",
      content: "Các thay đổi bạn vừa nhập sẽ không được lưu.",
      cancelLabel: "Tiếp tục chỉnh sửa",
      confirmLabel: "Bỏ thay đổi",
      danger: true,
    );

// Ô thống kê nhỏ: icon tròn, giá trị, nhãn
class MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final bool selected;
  final VoidCallback? onTap;

  const MiniStat({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final c = color ?? p.brandText;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? p.brandSoft : null,
          border: Border.all(color: selected ? p.brand : Colors.transparent, width: 2),
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: p.text),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(fontSize: 12, color: p.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Khung thẻ phẳng chung (nền thẻ, viền mảnh, bo 16)
BoxDecoration cardDecoration(BuildContext context, {Color? color, Color? borderColor}) {
  final p = context.palette;
  return BoxDecoration(
    color: color ?? p.card,
    borderRadius: BorderRadius.circular(AppRadius.large),
    border: Border.all(color: borderColor ?? p.border),
  );
}

// Nút có vòng xoay khi đang xử lý
class BusyButton extends StatelessWidget {
  final bool busy;
  final VoidCallback? onPressed;
  final Widget child;
  final bool outlined;
  const BusyButton({super.key, required this.busy, required this.onPressed, required this.child, this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final content = busy
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : child;
    final style = ButtonStyle(minimumSize: WidgetStateProperty.all(const Size(double.infinity, 52)));
    return outlined
        ? OutlinedButton(onPressed: busy ? null : onPressed, style: style, child: content)
        : ElevatedButton(onPressed: busy ? null : onPressed, style: style, child: content);
  }
}

// Ô số liệu ở các màn kết quả / tổng kết (dùng trong Row)
class ResultTile extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  const ResultTile(this.label, this.value, this.color, {super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: cardDecoration(context),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color ?? p.text)),
            const SizedBox(height: 2),
            Text(label, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: p.textMuted)),
          ],
        ),
      ),
    );
  }
}

// === CHUYỂN ĐỘNG ===
// Thời lượng hiệu ứng; bằng 0 khi người dùng bật "Giảm chuyển động" trong cài đặt máy
Duration motion(BuildContext context, int ms) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false ? Duration.zero : Duration(milliseconds: ms);

// Thanh tiến độ chạy mượt tới giá trị mới
class AnimatedProgressBar extends StatelessWidget {
  final double value;
  final double minHeight;
  final Color? color;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;
  const AnimatedProgressBar({
    super.key,
    required this.value,
    this.minHeight = 4,
    this.color,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: motion(context, 300),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => LinearProgressIndicator(
        value: v,
        minHeight: minHeight,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        valueColor: color == null ? null : AlwaysStoppedAnimation(color!),
      ),
    );
  }
}

// Số đổi giá trị thì nảy nhẹ
class AnimatedCount extends StatelessWidget {
  final int value;
  final TextStyle style;
  const AnimatedCount(this.value, {super.key, required this.style});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: motion(context, 220),
      transitionBuilder: (child, anim) => ScaleTransition(
        scale: Tween(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      child: Text("$value", key: ValueKey(value), style: style),
    );
  }
}

// Phóng to dần khi xuất hiện (icon hoàn thành, cúp...)
class PopIn extends StatelessWidget {
  final Widget child;
  const PopIn({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion(context, 550),
      curve: Curves.elasticOut,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: child,
    );
  }
}

// Rung ngang một lần khi [active] chuyển sang true (trả lời sai)
class Shake extends StatelessWidget {
  final bool active;
  final Widget child;
  const Shake({super.key, required this.active, required this.child});

  @override
  Widget build(BuildContext context) {
    if (!active) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: motion(context, 380),
      builder: (context, v, child) => Transform.translate(
        offset: Offset(sin(v * pi * 4) * 8 * (1 - v), 0),
        child: child,
      ),
      child: child,
    );
  }
}

// === ẢNH THẺ ===
// Ảnh thẻ lưu cục bộ theo đường dẫn trên máy đã thêm ảnh; mở ở máy khác thì file không tồn tại
bool cardImageExists(String? path) => path != null && File(path).existsSync();

// Ảnh thay thế khi không tìm thấy file ảnh
class MissingImagePlaceholder extends StatelessWidget {
  final bool compact;
  const MissingImagePlaceholder({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 8 : 16),
      decoration: BoxDecoration(color: p.background, borderRadius: BorderRadius.circular(AppRadius.medium)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.image_not_supported_outlined, size: compact ? 24 : 40, color: p.textMuted),
          const SizedBox(height: 4),
          Text("Ảnh không có trên thiết bị này",
              textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: p.textMuted)),
        ],
      ),
    );
  }
}
