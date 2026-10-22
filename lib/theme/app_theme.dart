// theme/app_theme.dart - HỆ MÀU VÀ THEME (phong cách Quizlet: trắng + xanh chàm, ít màu)
//
// Quy tắc: ~65% trung tính (nền, thẻ), ~30% xanh chàm (hành động), ≤5% màu trạng thái.
// Xanh lá / đỏ / cam chỉ dùng khi báo đúng / sai / đang học; vàng chỉ cho sao và chuỗi ngày.
import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color brand; // Nền nút chính, thanh tiến độ, tab đang chọn
  final Color brandPressed;
  final Color brandText; // Chữ / icon nhấn trên nền thẻ
  final Color brandSoft; // Nền nút phụ, chip đang chọn, khối thống kê
  final Color background;
  final Color card;
  final Color cardAlt; // Mặt sau thẻ ghi nhớ
  final Color border;
  final Color text;
  final Color textMuted;
  final Color yellow; // Sao, chuỗi ngày học
  final Color success;
  final Color successBg;
  final Color error;
  final Color errorBg;
  final Color warning;
  final Color warningBg;

  const AppPalette({
    required this.brand,
    required this.brandPressed,
    required this.brandText,
    required this.brandSoft,
    required this.background,
    required this.card,
    required this.cardAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.yellow,
    required this.success,
    required this.successBg,
    required this.error,
    required this.errorBg,
    required this.warning,
    required this.warningBg,
  });

  static const light = AppPalette(
    brand: Color(0xFF4255FF),
    brandPressed: Color(0xFF3046E8),
    brandText: Color(0xFF4255FF),
    brandSoft: Color(0xFFEDEFFF),
    background: Color(0xFFF6F7FB),
    card: Color(0xFFFFFFFF),
    cardAlt: Color(0xFFEDEFFF),
    border: Color(0xFFD9DDE8),
    text: Color(0xFF282E3E),
    textMuted: Color(0xFF586380),
    yellow: Color(0xFFFFCD1F),
    success: Color(0xFF167448),
    successBg: Color(0xFFE6F6EE),
    error: Color(0xFFC2243A),
    errorBg: Color(0xFFFDECEE),
    warning: Color(0xFFB45309),
    warningBg: Color(0xFFFFF4D6),
  );

  static const dark = AppPalette(
    brand: Color(0xFF4255FF),
    brandPressed: Color(0xFF3046E8),
    brandText: Color(0xFFA8B1FF),
    brandSoft: Color(0xFF2B3168),
    background: Color(0xFF0A092D),
    card: Color(0xFF2E3856),
    cardAlt: Color(0xFF2B3168),
    border: Color(0xFF4A5578),
    text: Color(0xFFFFFFFF),
    textMuted: Color(0xFFD9DDE8),
    yellow: Color(0xFFFFCD1F),
    success: Color(0xFF6FD49A),
    successBg: Color(0xFF173B2C),
    error: Color(0xFFFF8A9A),
    errorBg: Color(0xFF4A1C26),
    warning: Color(0xFFFFCF70),
    warningBg: Color(0xFF4A3A12),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) => t < 0.5 || other is! AppPalette ? this : other;
}

extension PaletteContext on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

// Bo góc và khoảng cách dùng chung
class AppRadius {
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
}

class AppTheme {
  static ThemeData _build(AppPalette p, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: p.brand, brightness: brightness).copyWith(
      primary: p.brand,
      onPrimary: Colors.white,
      primaryContainer: p.brandSoft,
      onPrimaryContainer: p.brandText,
      secondary: p.brandText,
      surface: p.card,
      onSurface: p.text,
      onSurfaceVariant: p.textMuted,
      outline: p.border,
      outlineVariant: p.border,
      error: p.error,
      surfaceContainerHighest: p.background,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium));
    final textTheme = (brightness == Brightness.dark ? Typography.whiteMountainView : Typography.blackMountainView)
        .apply(bodyColor: p.text, displayColor: p.text);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [p],
      scaffoldBackgroundColor: p.background,
      canvasColor: p.background,
      dividerColor: p.border,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: p.card,
        foregroundColor: p.text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: p.text),
        shape: Border(bottom: BorderSide(color: p.border)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: p.border),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: p.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: p.border,
          disabledForegroundColor: p.textMuted,
          elevation: 0,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          shape: buttonShape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: p.brandText,
          backgroundColor: p.card,
          minimumSize: const Size(48, 48),
          side: BorderSide(color: p.border, width: 1.5),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          shape: buttonShape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: p.brandText,
          minimumSize: const Size(48, 48),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.brand,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const CircleBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.card,
        labelStyle: TextStyle(color: p.textMuted),
        hintStyle: TextStyle(color: p.textMuted),
        prefixIconColor: p.textMuted,
        suffixIconColor: p.textMuted,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: p.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: p.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.medium), borderSide: BorderSide(color: p.brand, width: 2)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.card,
        selectedColor: p.brandSoft,
        labelStyle: TextStyle(color: p.text, fontSize: 14),
        side: BorderSide(color: p.border),
        checkmarkColor: p.brandText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: p.card,
        selectedItemColor: p.brandText,
        unselectedItemColor: p.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
        unselectedLabelStyle: const TextStyle(fontSize: 12),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: p.brandText,
        unselectedLabelColor: p.textMuted,
        indicatorColor: p.brand,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: p.brand,
        linearTrackColor: p.border,
        circularTrackColor: p.border,
      ),
      listTileTheme: ListTileThemeData(iconColor: p.textMuted, textColor: p.text),
      dialogTheme: DialogThemeData(
        backgroundColor: p.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: p.card, surfaceTintColor: Colors.transparent),
      popupMenuTheme: PopupMenuThemeData(color: p.card, surfaceTintColor: Colors.transparent),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: brightness == Brightness.dark ? p.card : const Color(0xFF282E3E),
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        actionTextColor: const Color(0xFFA8B1FF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.medium)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : p.textMuted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.brand : p.border),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.brand : null),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.brand : p.textMuted),
      ),
    );
  }

  static final ThemeData lightTheme = _build(AppPalette.light, Brightness.light);
  static final ThemeData darkTheme = _build(AppPalette.dark, Brightness.dark);
}
