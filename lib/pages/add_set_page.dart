import 'package:flutter/material.dart';
import '../services/flashcard_service.dart'; // NEW
import '../services/auth_service.dart'; // NEW

class AddSetPage extends StatefulWidget {
  const AddSetPage({super.key});

  @override
  State<AddSetPage> createState() => _AddSetPageState();
}

class _AddSetPageState extends State<AddSetPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController(); // NEW
  final FlashcardService _flashcardService = FlashcardService(); // NEW
  final AuthService _authService = AuthService(); // NEW
  bool _isLoading = false; // NEW

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose(); // NEW
    super.dispose();
  }

  Future<void> _createSet() async { // NEW: Đổi thành async
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim(); // NEW

    if (title.isEmpty) {
      _showError("Vui lòng nhập tên bộ thẻ!");
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // NEW: Sử dụng service để tạo set
      await _flashcardService.addSet(title);

      // NEW: Thông báo thành công
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Đã tạo bộ thẻ \"$title\""),
            backgroundColor: Colors.green,
          ),
        );

        // Quay lại trang trước
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError("Lỗi khi tạo bộ thẻ: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showError(String message) { // NEW: Hiển thị lỗi
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo bộ Flashcard mới"),
        actions: [
          // NEW: Nút hỗ trợ
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text("Mẹo tạo bộ thẻ"),
                  content: const Text(
                    "• Đặt tên rõ ràng, dễ nhớ\n"
                        "• Mỗi bộ nên có 10-50 thẻ\n"
                        "• Có thể thêm mô tả để dễ quản lý\n"
                        "• Bộ thẻ sẽ được lưu riêng cho tài khoản của bạn",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Đã hiểu"),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // NEW: Loading indicator
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // NEW: User info
            FutureBuilder(
              future: _authService.getCurrentUser(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }

                final user = snapshot.data;
                return Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.blue),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user?.username ?? "Người dùng",
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "Bộ thẻ sẽ được lưu cho tài khoản này",
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Tiêu đề bộ thẻ
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Tên bộ thẻ *",
                hintText: "Ví dụ: Từ vựng TOEIC, Ngữ pháp N3...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 50, // NEW: Giới hạn ký tự
              onSubmitted: (_) => _createSet(), // NEW: Enter để tạo
            ),

            const SizedBox(height: 16),

            // NEW: Mô tả (tùy chọn)
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Mô tả (tùy chọn)",
                hintText: "Mô tả ngắn về bộ thẻ này...",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              maxLength: 100,
            ),

            const SizedBox(height: 8),

            // NEW: Thông tin thêm
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Bạn có thể thêm thẻ sau khi tạo bộ",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Spacer(),

            // Nút tạo
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createSet,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, size: 20),
                    SizedBox(width: 8),
                    Text(
                      "TẠO BỘ THẺ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // NEW: Nút hủy
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                child: const Text("HỦY"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}