// widgets/flip_card.dart - ĐÃ THÊM THAM SỐ isMastered
import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:math';

class FlipCard extends StatefulWidget {
  final String frontText;
  final String backText;
  final String? imagePath;
  final bool isMastered; // THÊM THAM SỐ MỚI

  const FlipCard({
    super.key,
    required this.frontText,
    required this.backText,
    this.imagePath,
    this.isMastered = false, // GIÁ TRỊ MẶC ĐỊNH
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
  }

  void _toggle() {
    if (isFront) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() => isFront = !isFront);
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.imagePath != null && File(widget.imagePath!).existsSync();

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
              height: 300,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: isUnder ? Colors.green[600] : Colors.blueAccent,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
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
                      child: _buildCardContent(isUnder, hasImage),
                    ),
                  ),

                  // ICON THÀNH THẠO - HIỂN THỊ TRÊN CẢ 2 MẶT
                  if (widget.isMastered)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.amber,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.star,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),

                  // NHÃN MẶT THẺ
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Text(
                      isUnder ? "Mặt sau" : "Mặt trước",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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

  Widget _buildCardContent(bool isUnder, bool hasImage) {
    if (!isUnder && hasImage) {
      // Mặt trước có ảnh
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(widget.imagePath!),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildTextContent(isUnder),
        ),
      );
    } else {
      // Mặt sau hoặc mặt trước không có ảnh
      return _buildTextContent(isUnder);
    }
  }

  Widget _buildTextContent(bool isUnder) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          isUnder ? widget.backText : widget.frontText,
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}