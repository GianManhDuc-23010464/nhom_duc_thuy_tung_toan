// widgets/gradient_learn_button.dart - NÚT HỌC CHÍNH Ở ĐÁY MÀN HÌNH
// Giữ API cũ (onPressed, onTestPressed, cardCount...). Dạng phẳng một hàng cao 52px
// thay cho khối gradient 140px nhấp nháy, để không che nội dung trên điện thoại nhỏ.
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientLearnButton extends StatelessWidget {
  final VoidCallback onPressed;
  final int cardCount;
  final bool isEnabled;
  final String? buttonText;
  final bool showTestButton;
  final VoidCallback? onTestPressed;

  const GradientLearnButton({
    super.key,
    required this.onPressed,
    required this.cardCount,
    this.isEnabled = true,
    this.buttonText,
    this.showTestButton = false,
    this.onTestPressed,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    const style = ButtonStyle(minimumSize: WidgetStatePropertyAll(Size(0, 52)));
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton(
            onPressed: isEnabled ? onPressed : null,
            style: style,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.school, size: 22),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    buttonText ?? "Học ngay",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (cardCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("$cardCount", style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (showTestButton && onTestPressed != null) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: isEnabled ? onTestPressed : null,
              style: style.copyWith(
                side: WidgetStatePropertyAll(BorderSide(color: p.border, width: 1.5)),
              ),
              icon: const Icon(Icons.quiz, size: 20),
              label: const Text("Kiểm tra", maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      ],
    );
  }
}
