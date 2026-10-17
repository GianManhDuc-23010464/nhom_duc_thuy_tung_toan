import 'package:flutter/material.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../services/auth_service.dart';
import 'generic_screen.dart';

/// Trang tạo bộ Flashcard kế thừa GenericStatefulScreen<FlashcardSet>
/// Kế thừa bố cục chung (AppBar, Actions, Scaffold, Loading state)
class AddSetPage extends GenericStatefulScreen<FlashcardSet> {
  const AddSetPage({super.key, super.initialData})
      : super(title: "Tạo bộ Flashcard mới");

  @override
  State<AddSetPage> createState() => _AddSetPageState();
}

class _AddSetPageState extends GenericScreenState<AddSetPage, FlashcardSet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FlashcardService _flashcardService = FlashcardService();
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _createSet() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty) {
      _showError("Vui lòng nhập tên bộ thẻ!");
      return;
    }

    setLoading(true);

    try {
      await _flashcardService.addSet(title);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã tạo bộ thẻ "$title"'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        _showError("Lỗi khi tạo bộ thẻ: $e");
      }
    } finally {
      setLoading(false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// Kế thừa và định nghĩa các nút hành động (Actions) trên AppBar chung
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.help_outline),
        tooltip: "Mẹo tạo thẻ",
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
    ];
  }

  /// Kế thừa và định nghĩa phần nội dung chính (Content) của trang
  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thông tin người dùng hiện tại
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
            maxLength: 50,
            onSubmitted: (_) => _createSet(),
          ),

          const SizedBox(height: 16),

          // Mô tả (tùy chọn)
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

          // Card thông tin thêm
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
              onPressed: isLoading ? null : _createSet,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              child: const Row(
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

          // Nút hủy
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text("HỦY"),
            ),
          ),
        ],
      ),
    );
  }
}