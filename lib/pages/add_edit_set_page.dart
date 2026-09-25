// lib/pages/add_edit_set_page.dart
import 'package:flutter/material.dart';
import '../services/flashcard_service.dart';

class AddEditSetPage extends StatefulWidget {
  const AddEditSetPage({super.key});

  @override
  State<AddEditSetPage> createState() => _AddEditSetPageState();
}

class _AddEditSetPageState extends State<AddEditSetPage> {
  final TextEditingController _controller = TextEditingController();
  final FlashcardService _service = FlashcardService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tạo bộ mới"),
      ),
      body: Padding(
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
                await _service.addSet(title);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Tạo bộ", style: TextStyle(fontSize: 18)),
            ),
          ],
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