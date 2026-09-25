import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';
import '../services/auth_service.dart'; // NEW
import '../models/flashcard_set.dart';
import 'set_detail_page.dart';
import 'add_set_page.dart'; // NEW: Đổi thành AddSetPage mới

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FlashcardService _service = FlashcardService();
  final AuthService _authService = AuthService(); // NEW
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<FlashcardSet> _sets = []; // NEW: Lưu trữ sets riêng
  bool _isLoading = true; // NEW: Loading state

  @override
  void initState() {
    super.initState();
    _loadData(); // NEW: Tải dữ liệu khi init
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  // NEW: Tải dữ liệu từ service
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    await _service.loadData();

    if (mounted) {
      setState(() {
        _sets = _service.sets;
        _isLoading = false;
      });
    }
  }

  void _refresh() async {
    await _loadData(); // NEW: Tải lại dữ liệu
  }

  @override
  Widget build(BuildContext context) {
    // LỌC THEO TÊN BỘ
    final filteredSets = _sets.where((set) {
      return set.title.toLowerCase().contains(_searchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bộ Flashcard"),
        actions: [
          // NEW: User avatar và refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: "Làm mới",
          ),
          FutureBuilder(
            future: _authService.getCurrentUser(),
            builder: (context, snapshot) {
              final user = snapshot.data;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  backgroundColor: user != null ? Colors.blue : Colors.grey,
                  child: user != null
                      ? Text(user.username[0].toUpperCase())
                      : const Icon(Icons.person, color: Colors.white),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm bộ flashcard...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                  },
                )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator()) // NEW: Loading indicator
          : _buildBody(filteredSets),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSetPage()), // NEW: Dùng AddSetPage mới
          );
          _refresh();
        },
        child: const Icon(Icons.add),
        tooltip: "Tạo bộ thẻ mới",
      ),
    );
  }

  Widget _buildBody(List<FlashcardSet> filteredSets) {
    if (filteredSets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _searchQuery.isEmpty ? Icons.folder_open : Icons.search_off,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? "Chưa có bộ nào" : "Không tìm thấy bộ nào",
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty) // NEW: Hướng dẫn khi chưa có bộ
              const Text(
                "Nhấn nút + để tạo bộ thẻ đầu tiên",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // NEW: Thống kê nhanh
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.grey[50],
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem("Tổng bộ", filteredSets.length.toString()),
              _buildStatItem("Tổng thẻ", _calculateTotalCards(filteredSets).toString()),

            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: filteredSets.length,
            itemBuilder: (context, index) {
              final set = filteredSets[index];
              return _buildSetCard(set, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  int _calculateTotalCards(List<FlashcardSet> sets) {
    return sets.fold(0, (sum, set) => sum + set.cards.length);
  }

  Widget _buildSetCard(FlashcardSet set, int index) {
    final colors = [
      [Colors.blue.shade400, Colors.purple.shade500],
      [Colors.green.shade400, Colors.blue.shade500],
      [Colors.orange.shade400, Colors.red.shade500],
      [Colors.purple.shade400, Colors.pink.shade500],
    ];

    final colorPair = colors[index % colors.length];

    return Hero(
      tag: set.id,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => SetDetailPage(set: set)),
          ).then((_) => _refresh());
        },
        onLongPress: () {
          // NEW: Long press để xem tùy chọn
          _showSetOptions(set);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colorPair,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: colorPair[0].withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // NEW: Background pattern
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.library_books,
                  size: 80,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      set.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.card_membership, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          "${set.cards.length} thẻ",
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    // NEW: Hiển thị ngày tạo
                    if (set.createdAt != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        "Tạo: ${_formatDate(set.createdAt!)}",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // NEW: Badge cho set mới
              if (_isNewSet(set))
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      "MỚI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // NEW: Kiểm tra set mới (tạo trong 7 ngày)
  bool _isNewSet(FlashcardSet set) {
    if (set.createdAt == null) return false;
    final now = DateTime.now();
    final difference = now.difference(set.createdAt!);
    return difference.inDays < 7;
  }

  // NEW: Định dạng ngày
  String _formatDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }

  // NEW: Hiển thị tùy chọn cho set
  void _showSetOptions(FlashcardSet set) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Mở bộ thẻ'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => SetDetailPage(set: set)),
                  ).then((_) => _refresh());
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Đổi tên'),
                onTap: () {
                  Navigator.pop(context);
                  _showRenameDialog(set);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Xóa bộ thẻ', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(set);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // NEW: Dialog đổi tên
  void _showRenameDialog(FlashcardSet set) {
    final controller = TextEditingController(text: set.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Đổi tên bộ thẻ"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Tên mới",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _service.updateSet(set.id, controller.text.trim());
                _refresh();
                Navigator.pop(context);
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }

  // NEW: Dialog xóa
  void _showDeleteDialog(FlashcardSet set) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa bộ thẻ?"),
        content: Text("Bạn có chắc muốn xóa bộ \"${set.title}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await _service.deleteSet(set.id);
              _refresh();
              Navigator.pop(context);
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}