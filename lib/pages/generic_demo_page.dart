import 'package:flutter/material.dart';
import '../entities/Genericclass.dart';
import '../entities/people.dart';
import '../entities/book.dart';
import '../entities/student.dart';
import '../models/flashcard_set.dart';
import '../models/flashcard.dart';
import '../models/user.dart';
import 'generic_screen.dart';

/// ============================================================================
/// TRANG DEMO MINH HOẠ BÀI TẬP GENERICS
/// Câu 1: Entities kế thừa Genericclass<T> (FlashcardSet, Flashcard, User, People, Book, Student)
/// Câu 2: Screens kế thừa GenericStatefulScreen<T> & GenericScreen<T>
/// ============================================================================
class GenericDemoPage extends GenericStatefulScreen<Genericclass<dynamic>> {
  const GenericDemoPage({super.key})
      : super(
          title: "Minh Họa Generics (Câu 1 & Câu 2)",
          showBackButton: true,
        );

  @override
  State<GenericDemoPage> createState() => _GenericDemoPageState();
}

class _GenericDemoPageState
    extends GenericScreenState<GenericDemoPage, Genericclass<dynamic>> {
  String _statusMessage = 'Nhấn các nút bên dưới để kiểm tra tính đúng đắn của Generics.';
  final List<String> _logs = [];

  void _log(String message) {
    setState(() {
      _logs.insert(0, message);
      _statusMessage = message;
    });
  }

  void _testCau1Entities() {
    _logs.clear();

    // 1. Kiểm tra People (Ví dụ trong bài giảng)
    final people = People(
      id: 101,
      name: "Nguyen Lan Anh",
      description: "Sinh viên năm 3 ngành CNTT",
    );
    _log("✅ [People]: id=${people.getId()}, name=${people.getName()}, desc=${people.getDescription()}");
    people.setName("Nguyen Lan Anh (Đã cập nhật)");
    _log("   -> setName thành công: ${people.getName()}");

    // 2. Kiểm tra Book (Ví dụ trong bài giảng có thêm biến soluong)
    final book = Book(
      id: "BK-001",
      name: "Lập trình Flutter cơ bản",
      description: "Sách giáo trình chuyên ngành",
      soluong: 50,
    );
    _log("✅ [Book]: id=${book.getId()}, name=${book.getName()}, số lượng=${book.getSoluong()}");
    book.setSoluong(88);
    _log("   -> setSoluong thành công: ${book.getSoluong()}");

    // 3. Kiểm tra FlashcardSet (Entity bài tập cuối kỳ kế thừa Genericclass<String>)
    final set = FlashcardSet(
      id: "SET-1",
      name: "3000 Từ vựng Oxford",
      description: "Bộ thẻ từ vựng thiết yếu",
      userId: "USER-99",
      cards: [],
    );
    _log("✅ [FlashcardSet]: id=${set.getId()}, title/name=${set.getName()}, desc=${set.getDescription()}");
    set.setName("Oxford 3000 - Phiên bản nâng cao");
    _log("   -> setName/setTitle thành công: ${set.title}");

    // 4. Kiểm tra Flashcard (Entity thẻ flashcard kế thừa Genericclass<String>)
    final card = Flashcard(
      id: "CARD-1",
      term: "Generic Programming",
      meaning: "Lập trình tổng quát cho phép một lớp hoạt động với nhiều kiểu dữ liệu",
      note: "Học phần Flutter",
    );
    _log("✅ [Flashcard]: id=${card.getId()}, term/name=${card.getName()}, meaning/desc=${card.getDescription()}");
    card.setDescription("Khái niệm nâng cao về OOP và Generics");
    _log("   -> setDescription thành công: ${card.meaning}");

    // 5. Kiểm tra User (Entity người dùng kế thừa Genericclass<String>)
    final user = User(
      id: "USR-001",
      username: "manhduc",
      description: "Thành viên nhóm dự án",
      email: "duc@phenikaa-uni.edu.vn",
      passwordHash: "hash123",
      createdAt: DateTime.now(),
    );
    _log("✅ [User]: id=${user.getId()}, username/name=${user.getName()}, desc=${user.getDescription()}");

    // 6. Kiểm tra Student
    final student = Student(
      id: "23010464",
      name: "Sinh viên Phenikaa",
      description: "Nhóm Đức Thúy Tùng Toàn",
      email: "sv@phenikaa.edu.vn",
      studentCode: "SV23010464",
    );
    _log("✅ [Student]: MSSV=${student.getId()}, Họ tên=${student.getName()}, Lớp=${student.getDescription()}");

    _log("🎉 Tất cả các Entities đã kế thừa thành công các đặc điểm và phương thức chung từ Genericclass<T>!");
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.playlist_add_check),
        tooltip: "Chạy test Câu 1",
        onPressed: _testCau1Entities,
      ),
      IconButton(
        icon: const Icon(Icons.info_outline),
        tooltip: "Thông tin",
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Về bài tập Generics"),
              content: const Text(
                "• Câu 1: Tất cả entities (FlashcardSet, Flashcard, User, People, Book, Student) kế thừa Genericclass<T> chứa id, name, description và getters/setters.\n\n"
                "• Câu 2: Tất cả screens (HomePage, SetDetailPage, AddSetPage, AddEditSetPage, AddEditFlashcardPage, GenericDemoPage) kế thừa bố cục GenericStatefulScreen<T> và GenericScreenState<W, T>.",
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Đóng"),
                ),
              ],
            ),
          );
        },
      ),
    ];
  }

  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner mô tả
          Card(
            color: Colors.blue[50],
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.school, color: Colors.blue, size: 28),
                      SizedBox(width: 8),
                      Text(
                        "Kiểm tra chuyển đổi Generics",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Nút bấm kiểm tra
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _testCau1Entities,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text("Chạy Test Câu 1"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _logs.clear();
                      _statusMessage = "Đã xóa nhật ký.";
                    });
                  },
                  icon: const Icon(Icons.clear_all),
                  label: const Text("Xóa nhật ký"),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            "Nhật ký kiểm tra (Execution Logs):",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // Danh sách log
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: _logs.isEmpty
                  ? const Center(
                      child: Text(
                        "Chưa có nhật ký. Bấm 'Chạy Test Câu 1' để bắt đầu.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final isSuccess = log.startsWith("✅") || log.startsWith("🎉");
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            log,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: isSuccess ? Colors.green[800] : Colors.black87,
                              fontWeight: isSuccess ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
