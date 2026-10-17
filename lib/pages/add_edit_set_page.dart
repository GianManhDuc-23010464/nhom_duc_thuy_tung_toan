// lib/pages/add_edit_set_page.dart
import 'package:flutter/material.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import 'generic_screen.dart';

/// Trang tạo/sửa bộ Flashcard kế thừa GenericStatefulScreen<FlashcardSet>
/// Kế thừa bố cục chung (AppBar, Scaffold, cơ chế quản lý trạng thái loading)
class AddEditSetPage extends GenericStatefulScreen<FlashcardSet> {
  const AddEditSetPage({super.key, super.initialData})
      : super(title: "Tạo bộ mới");

  @override
  State<AddEditSetPage> createState() => _AddEditSetPageState();
}

class _AddEditSetPageState
    extends GenericScreenState<AddEditSetPage, FlashcardSet> {
  final TextEditingController _controller = TextEditingController();
  final FlashcardService _service = FlashcardService();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _controller.text = widget.initialData!.title;
    }
  }

  /// Cài đặt phương thức trừu tượng buildContent kế thừa từ GenericScreenState
  @override
  Widget buildContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              labelText: "Tên bộ flashcard",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final title = _controller.text.trim();
              if (title.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vui lòng nhập tên bộ!")),
                );
                return;
              }
              setLoading(true);
              try {
                await _service.addSet(title);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                setError("Lỗi tạo bộ thẻ: $e");
              } finally {
                setLoading(false);
              }
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text("Tạo bộ", style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}