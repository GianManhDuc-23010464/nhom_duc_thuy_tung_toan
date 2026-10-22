// widgets/flip_card.dart - ĐÃ THÊM THAM SỐ isMastered
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';
import '../theme/app_theme.dart';
import 'common.dart';

// Cho phép lật thẻ từ nút bên ngoài (ví dụ "Hiện đáp án")
class FlipCardController extends ChangeNotifier {
  void flip() => notifyListeners();
}

class FlipCard extends StatefulWidget {
  final String frontText;
  final String backText;
  final String? imagePath;
  final bool isMastered; // THÊM THAM SỐ MỚI
  final String? hintText; // Gợi ý hiện ở mặt trước
  final String? explain; // Giải thích hiện ở mặt sau
  final double height;
  final ValueChanged<bool>? onFlip; // true: đang hiện mặt sau
  final FlipCardController? controller;
  final bool showSideLabel; // Nhãn "Mặt trước / Mặt sau" ở góc dưới
  final double? fontSize;

  const FlipCard({
    super.key,
    required this.frontText,
    required this.backText,
    this.imagePath,
    this.isMastered = false, // GIÁ TRỊ MẶC ĐỊNH
    this.hintText,
    this.explain,
    this.height = 300,
    this.onFlip,
    this.controller,
    this.showSideLabel = true,
    this.fontSize,
  });

  @override
  State<FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<FlipCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool isFront = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    widget.controller?.addListener(_toggle);
  }

  void _toggle() {
    if (isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => isFront = !isFront);
    widget.onFlip?.call(!isFront);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = cardImageExists(widget.imagePath);
    final p = context.palette;

    return GestureDetector(
      onTap: _toggle,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final angle = _controller.value * pi;
          final isUnder = angle > (pi / 2);

          return Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY(angle),
            alignment: Alignment.center,
            child: Container(
              width: double.infinity,
              height: widget.height,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isUnder ? p.cardAlt : p.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: p.border),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF282E3E).withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 6)),
                ],
              ),
              child: Stack(
                children: [
                  // NỘI DUNG THẺ
                  Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.rotationY(isUnder ? pi : 0),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: _buildCardContent(isUnder, hasImage, p),
                    ),
                  ),

                  // ICON THÀNH THẠO - HIỂN THỊ TRÊN CẢ 2 MẶT
                  if (widget.isMastered)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: p.successBg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check,
                          color: p.success,
                          size: 18,
                        ),
                      ),
                    ),

                  // NHÃN MẶT THẺ
                  if (widget.showSideLabel)
                  Positioned(
                    bottom: 12,
                    left: isUnder ? 12 : null,
                    right: isUnder ? null : 12,
                    // Xoay ngược ở mặt sau để chữ không bị lật gương
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(isUnder ? pi : 0),
                      child: Text(
                        isUnder ? "Mặt sau" : "Mặt trước",
                        style: TextStyle(
                          color: p.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCardContent(bool isUnder, bool hasImage, AppPalette p) {
    if (!isUnder && hasImage) {
      // Mặt trước có ảnh
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.imagePath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildTextContent(isUnder, p),
        ),
      );
    } else if (!isUnder && widget.imagePath != null) {
      // Thẻ có ảnh nhưng file không có trên máy này: hiện ảnh thay thế kèm nội dung chữ
      return Column(
        children: [
          const MissingImagePlaceholder(compact: true),
          Expanded(child: _buildTextContent(isUnder, p)),
        ],
      );
    } else {
      // Mặt sau hoặc mặt trước không có ảnh
      return _buildTextContent(isUnder, p);
    }
  }

  Widget _buildTextContent(bool isUnder, AppPalette p) {
    final text = isUnder ? widget.backText : widget.frontText;
    // Nội dung dài hoặc nhiều dòng (câu hỏi kèm đáp án A/B/C/D) căn trái cho dễ đọc
    final alignStart = text.length > 60 || text.contains('\n');
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: alignStart ? CrossAxisAlignment.start : CrossAxisAlignment.center,
          children: [
            Text(
              text,
              textAlign: alignStart ? TextAlign.start : TextAlign.center,
              style: TextStyle(
                fontSize: widget.fontSize ?? (widget.height < 250 ? 20 : 26),
                color: p.text,
                fontWeight: FontWeight.w700,
                height: 1.3,
              ),
            ),
            if (!isUnder && widget.hintText != null) ...[
              const SizedBox(height: 12),
              Text(
                "Gợi ý: ${widget.hintText}",
                style: TextStyle(color: p.textMuted, fontSize: 16, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ],
            if (isUnder && (widget.explain ?? '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.explain!,
                style: TextStyle(color: p.textMuted, fontSize: 14, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_toggle);
    _controller.dispose();
    super.dispose();
  }
}