// widgets/gradient_learn_button.dart - ĐÃ SỬA ĐỂ THÊM NÚT KIỂM TRA
import 'package:flutter/material.dart';

class GradientLearnButton extends StatefulWidget {
  final VoidCallback onPressed;
  final int cardCount;
  final bool isEnabled;
  final String? buttonText;
  final bool showTestButton; // THÊM: Hiển thị nút kiểm tra
  final VoidCallback? onTestPressed; // THÊM: Callback cho nút kiểm tra

  const GradientLearnButton({
    super.key,
    required this.onPressed,
    required this.cardCount,
    this.isEnabled = true,
    this.buttonText,
    this.showTestButton = false, // Mặc định không hiển thị
    this.onTestPressed, // Callback cho nút kiểm tra
  });

  @override
  State<GradientLearnButton> createState() => _GradientLearnButtonState();
}

class _GradientLearnButtonState extends State<GradientLearnButton>
    with SingleTickerProviderStateMixin {

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;
  bool _isTapped = false;
  bool _isTestTapped = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _colorAnimation = ColorTween(
      begin: Colors.white.withOpacity(0.2),
      end: Colors.white.withOpacity(0.4),
    ).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled) {
      setState(() {
        _isTapped = true;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _isTapped = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _isTapped = false;
    });
  }

  void _onTestTapDown(TapDownDetails details) {
    if (widget.isEnabled && widget.onTestPressed != null) {
      setState(() {
        _isTestTapped = true;
      });
    }
  }

  void _onTestTapUp(TapUpDetails details) {
    setState(() {
      _isTestTapped = false;
    });
  }

  void _onTestTapCancel() {
    setState(() {
      _isTestTapped = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isEnabled
              ? (_isTapped ? 0.95 : _pulseAnimation.value)
              : 1.0,
          child: Container(
            width: double.infinity,
            height: widget.showTestButton ? 140 : 68, // THÊM: Tăng chiều cao khi có nút kiểm tra
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.isEnabled
                    ? [
                  Colors.blue.shade600,
                  Colors.blueAccent.shade400,
                  Colors.purple.shade500,
                ]
                    : [
                  Colors.grey.shade400,
                  Colors.grey.shade500,
                  Colors.grey.shade600,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(35),
              boxShadow: widget.isEnabled
                  ? [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(35),
              child: Column(
                children: [
                  // NÚT HỌC CHÍNH
                  Expanded(
                    child: InkWell(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(35),
                        topRight: Radius.circular(35),
                      ),
                      onTap: widget.isEnabled ? widget.onPressed : null,
                      onTapDown: widget.isEnabled ? _onTapDown : null,
                      onTapUp: widget.isEnabled ? _onTapUp : null,
                      onTapCancel: widget.isEnabled ? _onTapCancel : null,
                      splashColor: Colors.white.withOpacity(0.3),
                      highlightColor: Colors.white.withOpacity(0.2),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon với hiệu ứng
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _colorAnimation.value,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.school,
                                color: widget.isEnabled ? Colors.white : Colors.grey.shade200,
                                size: 26,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Text chính
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.buttonText ?? "Học ngay",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: widget.isEnabled ? Colors.white : Colors.grey.shade200,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  if (widget.cardCount > 0)
                                    Text(
                                      "${widget.cardCount} thẻ sẵn sàng",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: widget.isEnabled
                                            ? Colors.white.withOpacity(0.8)
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            // Badge số thẻ
                            if (widget.cardCount > 0)
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: widget.isEnabled
                                      ? Colors.white.withOpacity(0.2)
                                      : Colors.grey.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: widget.isEnabled
                                      ? Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  )
                                      : null,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      widget.cardCount.toString(),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isEnabled ? Colors.white : Colors.grey.shade200,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.credit_card,
                                      size: 16,
                                      color: widget.isEnabled ? Colors.white : Colors.grey.shade200,
                                    ),
                                  ],
                                ),
                              ),

                            // Mũi tên (chỉ hiện khi enabled)
                            if (widget.isEnabled) ...[
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white.withOpacity(0.8),
                                size: 20,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // NÚT KIỂM TRA (HIỆN KHI CÓ SHOWTESTBUTTON)
                  if (widget.showTestButton && widget.onTestPressed != null) ...[
                    Container(
                      height: 1,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      color: Colors.white.withOpacity(0.3),
                    ),
                    Expanded(
                      child: Transform.scale(
                        scale: _isTestTapped ? 0.95 : 1.0,
                        child: InkWell(
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(35),
                            bottomRight: Radius.circular(35),
                          ),
                          onTap: widget.isEnabled ? widget.onTestPressed : null,
                          onTapDown: widget.isEnabled ? _onTestTapDown : null,
                          onTapUp: widget.isEnabled ? _onTestTapUp : null,
                          onTapCancel: widget.isEnabled ? _onTestTapCancel : null,
                          splashColor: Colors.orange.withOpacity(0.3),
                          highlightColor: Colors.orange.withOpacity(0.2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.quiz,
                                    color: widget.isEnabled ? Colors.white : Colors.grey.shade200,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Kiểm tra",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: widget.isEnabled ? Colors.white : Colors.grey.shade200,
                                        ),
                                      ),
                                      if (widget.cardCount > 0)
                                        Text(
                                          "${widget.cardCount} câu hỏi",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: widget.isEnabled
                                                ? Colors.white.withOpacity(0.8)
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (widget.cardCount > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Text(
                                      widget.cardCount.toString(),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: widget.isEnabled ? Colors.white : Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}