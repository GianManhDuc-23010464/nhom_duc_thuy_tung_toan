// pages/add_edit_flashcard_page.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/flashcard.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddEditFlashcardPage extends StatefulWidget {
  final Flashcard? card;
  final Function(Flashcard) onSave;
  const AddEditFlashcardPage({super.key, this.card, required this.onSave});

  @override
  State<AddEditFlashcardPage> createState() => _AddEditFlashcardPageState();
}

class _AddEditFlashcardPageState extends State<AddEditFlashcardPage> {
  late TextEditingController termCtrl;
  late TextEditingController meaningCtrl;
  late TextEditingController noteCtrl;
  File? _image;
  String? _savedImagePath;

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    termCtrl = TextEditingController(text: widget.card?.term ?? '');
    meaningCtrl = TextEditingController(text: widget.card?.meaning ?? '');
    noteCtrl = TextEditingController(text: widget.card?.note ?? '');
    _savedImagePath = widget.card?.imagePath;
    if (_savedImagePath != null) {
      _image = File(_savedImagePath!);
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final fileName = path.basename(pickedFile.path);
      final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
      setState(() {
        _image = savedImage;
        _savedImagePath = savedImage.path;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Sửa thẻ" : "Thêm thẻ")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(controller: termCtrl, decoration: const InputDecoration(labelText: 'Từ vựng')),
            TextField(controller: meaningCtrl, decoration: const InputDecoration(labelText: 'Nghĩa')),
            TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: 'Ghi chú (tùy chọn)')),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  image: _image != null
                      ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                      : null,
                ),
                child: _image == null
                    ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text("Thêm ảnh", style: TextStyle(color: Colors.grey)),
                  ],
                )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final card = Flashcard(
                  term: termCtrl.text,
                  meaning: meaningCtrl.text,
                  note: noteCtrl.text.isEmpty ? null : noteCtrl.text,
                  imagePath: _savedImagePath,
                );
                widget.onSave(card);
                Navigator.pop(context);
              },
              child: Text(isEdit ? "Cập nhật" : "Lưu"),
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