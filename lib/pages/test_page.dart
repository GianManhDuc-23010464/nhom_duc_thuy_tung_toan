// pages/test_page.dart - SỬA LỖI TEXT FIELD
import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';

class TestPage extends StatefulWidget {
  final List<Flashcard> cards;
  final String setName;

  const TestPage({
    super.key,
    required this.cards,
    required this.setName,
  });

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final FlashcardService _service = FlashcardService();
  final List<Flashcard> _testCards = [];
  final TextEditingController _textController = TextEditingController(); // THÊM CONTROLLER
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _showResult = false;
  bool _isCorrect = false;
  String? _userAnswer;
  final Map<int, String> _userAnswers = {};

  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  @override
  void dispose() {
    _textController.dispose(); // QUAN TRỌNG: dispose controller
    super.dispose();
  }

  void _initializeTest() {
    // Trộn ngẫu nhiên các thẻ
    _testCards.addAll(widget.cards);
    _testCards.shuffle();
  }

  void _checkAnswer(String answer) {
    final currentCard = _testCards[_currentIndex];
    final isCorrect = answer.trim().toLowerCase() == currentCard.meaning.toLowerCase();

    setState(() {
      _showResult = true;
      _isCorrect = isCorrect;
      _userAnswer = answer;
      _userAnswers[_currentIndex] = answer;

      if (isCorrect) {
        _correctCount++;
      } else {
        _wrongCount++;
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _testCards.length - 1) {
      setState(() {
        _currentIndex++;
        _showResult = false;
        _userAnswer = null;
        _textController.clear(); // QUAN TRỌNG: Clear controller
      });
    } else {
      _showTestResult();
    }
  }

  void _previousQuestion() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
        _showResult = false;
        _userAnswer = _userAnswers[_currentIndex];
        _textController.text = _userAnswers[_currentIndex] ?? ''; // CẬP NHẬT CONTROLLER
      });
    }
  }

  void _showTestResult() {
    // Ghi nhận kết quả kiểm tra
    _service.recordTestSession(
      _correctCount,
      _testCards.length,
      0, // Số thẻ thành thạo mới
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Kết quả kiểm tra"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Bộ thẻ: ${widget.setName}"),
            const SizedBox(height: 16),
            _buildResultItem("Tổng số câu", "${_testCards.length}"),
            _buildResultItem("Số câu đúng", "$_correctCount", Colors.green),
            _buildResultItem("Số câu sai", "$_wrongCount", Colors.red),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getResultColor(),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Tỷ lệ đúng: ${((_correctCount / _testCards.length) * 100).toStringAsFixed(1)}%",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Hoàn tất"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _restartTest();
            },
            child: const Text("Làm lại"),
          ),
        ],
      ),
    );
  }

  Color _getResultColor() {
    final percentage = (_correctCount / _testCards.length) * 100;
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildResultItem(String label, String value, [Color? color]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _restartTest() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _showResult = false;
      _isCorrect = false;
      _userAnswer = null;
      _userAnswers.clear();
      _textController.clear(); // QUAN TRỌNG: Clear controller
      _testCards.shuffle();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_testCards.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text("Kiểm tra - ${widget.setName}")),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 64, color: Colors.orange),
              SizedBox(height: 16),
              Text(
                "Không có thẻ để kiểm tra",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      );
    }

    final currentCard = _testCards[_currentIndex];
    final isLastQuestion = _currentIndex == _testCards.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text("Kiểm tra - ${widget.setName}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _restartTest,
            tooltip: "Làm lại bài kiểm tra",
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tiến độ
            _buildProgressIndicator(),
            const SizedBox(height: 20),

            // Câu hỏi
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      "Câu ${_currentIndex + 1}/${_testCards.length}",
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currentCard.term,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (currentCard.note != null && currentCard.note!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        currentCard.note!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Ô nhập đáp án - SỬA LẠI HOÀN TOÀN
            TextField(
              controller: _textController, // SỬ DỤNG CONTROLLER
              decoration: InputDecoration(
                labelText: "Nhập nghĩa tiếng Việt",
                border: const OutlineInputBorder(),
                hintText: "Nhập câu trả lời của bạn...",
                enabled: !_showResult,
                suffixIcon: _userAnswer != null && _userAnswer!.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _userAnswer = null;
                      _textController.clear();
                    });
                  },
                )
                    : null,
              ),
              onChanged: (value) {
                if (!_showResult) {
                  setState(() {
                    _userAnswer = value;
                  });
                }
              },
              onSubmitted: _showResult ? null : _checkAnswer,
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 20),

            // Kết quả
            if (_showResult) _buildResultCard(currentCard),

            const Spacer(),

            // Nút điều hướng
            _buildNavigationButtons(isLastQuestion),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        LinearProgressIndicator(
          value: (_currentIndex + 1) / _testCards.length,
          backgroundColor: Colors.grey[300],
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Tiến độ: ${_currentIndex + 1}/${_testCards.length}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              "Đúng: $_correctCount | Sai: $_wrongCount",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildResultCard(Flashcard card) {
    return Card(
      color: _isCorrect ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _isCorrect ? Icons.check_circle : Icons.error,
                  color: _isCorrect ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  _isCorrect ? "Chính xác! 🎉" : "Chưa chính xác",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isCorrect ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!_isCorrect) ...[
              const Text(
                "Đáp án đúng:",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                card.meaning,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
            if (_isCorrect) ...[
              const SizedBox(height: 8),
              Text(
                "Tuyệt vời! Bạn đã trả lời đúng.",
                style: TextStyle(
                  color: Colors.green[700],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationButtons(bool isLastQuestion) {
    return Row(
      children: [
        // Nút quay lại
        Expanded(
          child: OutlinedButton(
            onPressed: _currentIndex > 0 ? _previousQuestion : null,
            child: const Text("Quay lại"),
          ),
        ),
        const SizedBox(width: 12),

        // Nút tiếp theo/kiểm tra
        Expanded(
          child: _showResult
              ? ElevatedButton(
            onPressed: _nextQuestion,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text(isLastQuestion ? "Xem kết quả" : "Tiếp theo"),
          )
              : ElevatedButton(
            onPressed: _userAnswer != null && _userAnswer!.trim().isNotEmpty
                ? () => _checkAnswer(_userAnswer!)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _userAnswer != null && _userAnswer!.trim().isNotEmpty
                  ? Colors.green
                  : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: const Text("Kiểm tra"),
          ),
        ),
      ],
    );
  }
}