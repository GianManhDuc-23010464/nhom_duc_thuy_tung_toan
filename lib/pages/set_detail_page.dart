// pages/set_detail_page.dart - CHỈ KIỂM TRA BỘ THẺ ĐƯỢC CHỌN
import 'package:flutter/material.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import 'add_edit_flashcard_page.dart';
import 'learn_page.dart';
import 'test_page.dart'; // Import TestPage
import '../widgets/gradient_learn_button.dart';

class SetDetailPage extends StatefulWidget {
  final FlashcardSet set;
  const SetDetailPage({super.key, required this.set});

  @override
  State<SetDetailPage> createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<SetDetailPage> {
  late FlashcardSet _currentSet;
  final FlashcardService _service = FlashcardService();
  List<FlashcardSet> _allSets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentSet = widget.set;
    _loadCurrentSet();
  }

  Future<void> _loadCurrentSet() async {
    setState(() {
      _isLoading = true;
    });

    await _service.loadData();
    _allSets = _service.sets;

    final updatedSet = _allSets.firstWhere(
          (set) => set.id == _currentSet.id,
      orElse: () => _currentSet,
    );

    if (mounted) {
      setState(() {
        _currentSet = updatedSet;
        _isLoading = false;
      });
    }
  }

  void _refresh() async {
    await _loadCurrentSet();
  }

  // Tính số thẻ đã thành thạo
  int _getMasteredCount() {
    return _currentSet.cards.where((card) => card.mastered).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_currentSet.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
            tooltip: "Làm mới",
          ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditSetDialog,
            tooltip: "Sửa tên bộ thẻ",
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteSetDialog();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Xóa bộ thẻ'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading ? _buildLoading() : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCard,
        child: const Icon(Icons.add),
        tooltip: "Thêm thẻ mới",
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Đang tải dữ liệu...'),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_currentSet.cards.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      children: [
        _buildStatsHeader(),
        const SizedBox(height: 8),
        _buildCardList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            const Text(
              "Bộ thẻ trống",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            const Text(
              "Hãy thêm thẻ đầu tiên để bắt đầu học!",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _addCard,
              icon: const Icon(Icons.add),
              label: const Text("Thêm thẻ đầu tiên"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsHeader() {
    final masteredCount = _getMasteredCount();
    final masteredPercent = _currentSet.cards.isNotEmpty
        ? (masteredCount / _currentSet.cards.length * 100).round()
        : 0;

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
          _buildStatItem("Tổng thẻ", _currentSet.cards.length.toString(), Icons.credit_card),


        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: Colors.blue[800]),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildCardList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _currentSet.cards.length,
        itemBuilder: (context, index) {
          final card = _currentSet.cards[index];
          return _buildCardItem(card, index);
        },
      ),
    );
  }

  Widget _buildCardItem(Flashcard card, int index) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: Dismissible(
        key: Key('${card.term}_$index'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await _showDeleteCardDialog(card);
        },
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: card.mastered ? Colors.green[100] : Colors.blue[100],
            child: Icon(
              card.mastered ? Icons.star : Icons.credit_card,
              color: card.mastered ? Colors.green : Colors.blue,
              size: 20,
            ),
          ),
          title: Text(
            card.term,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: card.mastered ? Colors.green[800] : Colors.black,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(card.meaning),
              if (card.note != null && card.note!.isNotEmpty)
                Text(
                  card.note!,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (card.mastered)
                Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
          onTap: () => _editCard(card),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: GradientLearnButton(
          onPressed: _currentSet.cards.isEmpty
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Hãy thêm thẻ để bắt đầu học!"),
                duration: Duration(seconds: 2),
              ),
            );
          }
              : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => LearnPage(
                cards: _currentSet.cards,
                setName: _currentSet.title,
              ),
            ),
          ),
          onTestPressed: _currentSet.cards.isEmpty
              ? () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Hãy thêm thẻ để bắt đầu kiểm tra!"),
                duration: Duration(seconds: 2),
              ),
            );
          }
              : () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TestPage(
                cards: _currentSet.cards,
                setName: _currentSet.title,
              ),
            ),
          ),
          cardCount: _currentSet.cards.length,
          isEnabled: _currentSet.cards.isNotEmpty,
          showTestButton: true,
          buttonText: "Học ngay",
        ),
      ),
    );
  }

  void _addCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFlashcardPage(
          onSave: (card) async {
            await _service.addCard(_currentSet.id, card);
            _refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã thêm thẻ mới!")),
            );
          },
        ),
      ),
    );
  }

  void _editCard(Flashcard card) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditFlashcardPage(
          card: card,
          onSave: (newCard) async {
            await _service.updateCard(_currentSet.id, card.term, newCard);
            _refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã cập nhật thẻ!")),
            );
          },
        ),
      ),
    );
  }

  Future<bool> _showDeleteCardDialog(Flashcard card) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa thẻ?"),
        content: Text("Bạn có chắc muốn xóa thẻ \"${card.term}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _service.deleteCard(_currentSet.id, card.term);
      _refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đã xóa thẻ \"${card.term}\"")),
      );
    }

    return result ?? false;
  }

  void _showDeleteSetDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Xóa bộ thẻ?"),
        content: Text("Bạn có chắc muốn xóa bộ thẻ \"${_currentSet.title}\" và tất cả ${_currentSet.cards.length} thẻ bên trong?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy"),
          ),
          TextButton(
            onPressed: () async {
              await _service.deleteSet(_currentSet.id);
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Đã xóa bộ thẻ \"${_currentSet.title}\"")),
                );
              }
            },
            child: const Text("Xóa", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditSetDialog() {
    final controller = TextEditingController(text: _currentSet.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Sửa tên bộ thẻ"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: "Tên bộ thẻ",
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy")
          ),
          TextButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await _service.updateSet(_currentSet.id, controller.text.trim());
                setState(() {
                  _currentSet = FlashcardSet(
                      id: _currentSet.id,
                      userId: _currentSet.userId,
                      title: controller.text.trim(),
                      cards: _currentSet.cards
                  );
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Đã cập nhật tên bộ thẻ!")),
                );
              }
            },
            child: const Text("Lưu"),
          ),
        ],
      ),
    );
  }
}