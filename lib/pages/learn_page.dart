// pages/learn_page.dart - SỬ DỤNG TRỰC TIẾP THUỘC TÍNH MASTERED
import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../widgets/flip_card.dart';
import '../services/flashcard_service.dart';

class LearnPage extends StatefulWidget {
  final List<Flashcard> cards;
  final String? setName;
  const LearnPage({super.key, required this.cards, this.setName});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  int currentIndex = 0;
  final FlashcardService _service = FlashcardService();
  bool _hasRecordedStudy = false;
  Set<int> _newlyMastered = {}; // Theo dõi thẻ mới thành thạo trong phiên học

  @override
  void initState() {
    super.initState();

    // GHI NHẬN KHI VÀO HỌC - chỉ ghi nhận 1 lần
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasRecordedStudy && widget.cards.isNotEmpty) {
        _service.recordStudySession(widget.cards.length);
        _hasRecordedStudy = true;
        debugPrint('📚 Đã ghi nhận học ${widget.cards.length} thẻ từ bộ ${widget.setName}');
      }
    });
  }

  // Đánh dấu thẻ thành thạo
  Future<void> _markAsMastered(int index) async {
    if (index >= widget.cards.length) return;

    final card = widget.cards[index];
    if (!card.mastered) {
      setState(() {
        card.mastered = true;
        _newlyMastered.add(index);
      });

      // Cập nhật lên database/service
      try {
        // Tìm setId từ card (giả sử có cách lấy setId)
        // Trong thực tế, bạn cần có setId để cập nhật
        // Tạm thời để đây, bạn có thể điều chỉnh sau
        debugPrint('⭐ Đã đánh dấu thẻ thành thạo: ${card.term}');

        // Thông báo cập nhật UI
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã đánh dấu "${card.term}" thành thạo! ★'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint('❌ Lỗi khi đánh dấu thành thạo: $e');
      }
    }
  }

  // Bỏ đánh dấu thành thạo
  Future<void> _unmarkAsMastered(int index) async {
    if (index >= widget.cards.length) return;

    final card = widget.cards[index];
    if (card.mastered) {
      setState(() {
        card.mastered = false;
        _newlyMastered.remove(index);
      });

      try {
        debugPrint('🔁 Đã bỏ đánh dấu thành thạo: ${card.term}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã bỏ đánh dấu thành thạo "${card.term}"'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      } catch (e) {
        debugPrint('❌ Lỗi khi bỏ đánh dấu thành thạo: $e');
      }
    }
  }

  // Tính số thẻ đã thành thạo
  int get _masteredCount {
    return widget.cards.where((card) => card.mastered).length;
  }

  // Tính số thẻ mới thành thạo trong phiên học này
  int get _newMasteredCount {
    return _newlyMastered.length;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.cards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Học Flashcard")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                "Không có thẻ nào để học",
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final card = widget.cards[currentIndex];
    final isLastCard = currentIndex == widget.cards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setName ?? "Học Flashcard"),
        actions: [
          // Nút shuffle
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: () {
              setState(() {
                widget.cards.shuffle();
                currentIndex = 0;
                _newlyMastered.clear();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã xáo trộn thẻ")),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // THỐNG KÊ REAL-TIME
          _buildStatsHeader(),

          // THANH TIẾN ĐỘ
          LinearProgressIndicator(
            value: (currentIndex + 1) / widget.cards.length,
            backgroundColor: Colors.grey[300],
            color: Colors.blue,
          ),

          const SizedBox(height: 20),

          // PHẦN CHÍNH - SỬ DỤNG EXPANDED ĐỂ CHIẾM KHÔNG GIAN CÒN LẠI
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  // THẺ FLASHCARD
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    child: FlipCard(
                      frontText: card.term,
                      backText: card.meaning,
                      isMastered: card.mastered,
                    ),
                  ),

                  // NÚT THÀNH THẠO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!card.mastered)
                          ElevatedButton.icon(
                            onPressed: () => _markAsMastered(currentIndex),
                            icon: const Icon(Icons.star_border),
                            label: const Text("Đánh dấu thành thạo"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.amber,
                              foregroundColor: Colors.white,
                            ),
                          )
                        else
                          OutlinedButton.icon(
                            onPressed: () => _unmarkAsMastered(currentIndex),
                            icon: const Icon(Icons.star),
                            label: const Text("Đã thành thạo"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber,
                              side: const BorderSide(color: Colors.amber),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // GHI CHÚ
                  if (card.note != null && card.note!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        "💡 Ghi chú: ${card.note}",
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ĐIỀU HƯỚNG - CỐ ĐỊNH Ở DƯỚI
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // GIẢM PADDING NGANG
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly, // GIỮ NGUYÊN
              children: [
                // Nút quay lại - GIẢM KÍCH THƯỚC
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, size: 32), // GIẢM TỪ 32 XUỐNG 28
                  onPressed: currentIndex > 0 ? () => setState(() => currentIndex--) : null,
                  color: currentIndex > 0 ? Colors.blue : Colors.grey,
                  padding: const EdgeInsets.all(8), // GIẢM PADDING
                ),

                // Thông tin số thẻ - ĐƯA LẠI GẦN HƠN
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8), // GIẢM MARGIN
                  child: Column(
                    children: [
                      Text(
                        "${currentIndex + 1} / ${widget.cards.length}",
                        style: const TextStyle(
                          fontSize: 18, // GIẢM TỪ 18 XUỐNG 16
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        "Thẻ ${currentIndex + 1}",
                        style: const TextStyle(
                          fontSize: 12, // GIẢM TỪ 12 XUỐNG 11
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Nút tiếp theo - GIẢM KÍCH THƯỚC
                IconButton(
                  icon: Icon(
                    isLastCard ? Icons.check_circle : Icons.arrow_forward_ios,
                    size: 32, // GIẢM TỪ 32 XUỐNG 28
                  ),
                  onPressed: currentIndex < widget.cards.length - 1
                      ? () => setState(() => currentIndex++)
                      : () {
                    // Khi hoàn thành
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('🎉 Hoàn thành! Đã học ${widget.cards.length} thẻ'),
                        duration: const Duration(seconds: 3),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  color: currentIndex < widget.cards.length - 1 ? Colors.blue : Colors.green,
                  padding: const EdgeInsets.all(8), // GIẢM PADDING
                ),
              ],
            ),
          ),
        ],
      ),

      // NÚT FLOATING ACTION - Đánh dấu nhanh
      floatingActionButton: card.mastered
          ? FloatingActionButton(
        onPressed: () => _unmarkAsMastered(currentIndex),
        backgroundColor: Colors.orange,
        child: const Icon(Icons.star, color: Colors.white),
        tooltip: "Bỏ đánh dấu thành thạo",
      )
          : FloatingActionButton(
        onPressed: () => _markAsMastered(currentIndex),
        backgroundColor: Colors.amber,
        child: const Icon(Icons.star_border, color: Colors.white),
        tooltip: "Đánh dấu thành thạo",
      ),
    );
  }

  // WIDGET HIỂN THỊ THỐNG KÊ
  Widget _buildStatsHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
              "Tổng thẻ",
              "${widget.cards.length}",
              Icons.credit_card,
              Colors.blue
          ),
          _buildStatItem(
              "Đã thành thạo",
              "$_masteredCount",
              Icons.star,
              Colors.amber
          ),
          _buildStatItem(
              "Mới thành thạo",
              "$_newMasteredCount",
              Icons.new_releases,
              Colors.green
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}