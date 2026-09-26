import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/flashcard.dart';

class AddEditFlashcardPage extends StatefulWidget {
  final Flashcard? card;
  final Future<void> Function(Flashcard card, String? imageFilePath) onSave;

  const AddEditFlashcardPage({super.key, this.card, required this.onSave});

  @override
  State<AddEditFlashcardPage> createState() => _AddEditFlashcardPageState();
}

class _AddEditFlashcardPageState extends State<AddEditFlashcardPage> {
  late final TextEditingController termCtrl;
  late final TextEditingController meaningCtrl;
  late final TextEditingController noteCtrl;
  final ImagePicker _picker = ImagePicker();

  XFile? _pickedImage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    termCtrl = TextEditingController(text: widget.card?.term ?? '');
    meaningCtrl = TextEditingController(text: widget.card?.meaning ?? '');
    noteCtrl = TextEditingController(text: widget.card?.note ?? '');
  }

  Future<void> _pickImage() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (image != null && mounted) {
      setState(() => _pickedImage = image);
    }
  }

  ImageProvider<Object>? _previewImage() {
    if (_pickedImage != null) return FileImage(File(_pickedImage!.path));
    final imageUrl = widget.card?.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty) return NetworkImage(imageUrl);
    return null;
  }

  Future<void> _save() async {
    final term = termCtrl.text.trim();
    final meaning = meaningCtrl.text.trim();
    if (term.isEmpty || meaning.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập từ vựng và nghĩa.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final oldCard = widget.card;
      final card = Flashcard(
        id: oldCard?.id,
        term: term,
        meaning: meaning,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        imageUrl: oldCard?.imageUrl,
        mastered: oldCard?.mastered ?? false,
        correctCount: oldCard?.correctCount ?? 0,
        createdAt: oldCard?.createdAt,
        updatedAt: DateTime.now(),
      );
      await widget.onSave(card, _pickedImage?.path);
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể lưu flashcard: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;
    final preview = _previewImage();
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Sửa thẻ' : 'Thêm thẻ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: termCtrl,
              decoration: const InputDecoration(labelText: 'Từ vựng'),
            ),
            TextField(
              controller: meaningCtrl,
              decoration: const InputDecoration(labelText: 'Nghĩa'),
            ),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Ghi chú (tùy chọn)',
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _isSaving ? null : _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  image: preview == null
                      ? null
                      : DecorationImage(image: preview, fit: BoxFit.cover),
                ),
                child: preview == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                          SizedBox(height: 8),
                          Text(
                            'Thêm ảnh',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Cập nhật' : 'Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    termCtrl.dispose();
    meaningCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }
}
