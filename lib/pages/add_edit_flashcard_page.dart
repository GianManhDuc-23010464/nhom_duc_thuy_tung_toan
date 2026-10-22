// pages/add_edit_flashcard_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../widgets/common.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class AddEditFlashcardPage extends StatefulWidget {
  final String deckId;
  final Flashcard? card;
  const AddEditFlashcardPage({super.key, required this.deckId, this.card});

  @override
  State<AddEditFlashcardPage> createState() => _AddEditFlashcardPageState();
}

class _AddEditFlashcardPageState extends State<AddEditFlashcardPage> {
  late final FlashcardService _service = context.read<FlashcardService>();
  late TextEditingController termCtrl;
  late TextEditingController meaningCtrl;
  late TextEditingController noteCtrl;
  late List<TextEditingController> wrongCtrls;
  File? _image;
  String? _savedImagePath;
  bool _dirty = false;
  bool _isSaving = false;
  Map<String, String> _errors = {};

  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final c = widget.card;
    termCtrl = TextEditingController(text: c?.term ?? '');
    meaningCtrl = TextEditingController(text: c?.meaning ?? '');
    noteCtrl = TextEditingController(text: c?.note ?? '');
    wrongCtrls = List.generate(
      3,
      (i) => TextEditingController(text: (c != null && i < c.wrongOptions.length) ? c.wrongOptions[i] : ''),
    );
    _savedImagePath = c?.imagePath;
    // File ảnh có thể không tồn tại khi mở trên máy khác: giữ đường dẫn, hiện ảnh thay thế
    if (cardImageExists(_savedImagePath)) {
      _image = File(_savedImagePath!);
    }
    for (final ctrl in [termCtrl, meaningCtrl, noteCtrl, ...wrongCtrls]) {
      ctrl.addListener(() => _dirty = true);
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = path.basename(pickedFile.path);
        final savedImage = await File(pickedFile.path).copy('${appDir.path}/$fileName');
        setState(() {
          _image = savedImage;
          _savedImagePath = savedImage.path;
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) showSnack(context, "Không mở được thư viện ảnh", color: Colors.red);
    }
  }

  // Kiểm tra dữ liệu; trả về thẻ hợp lệ hoặc null
  Flashcard? _validate() {
    final errors = <String, String>{};
    final back = meaningCtrl.text.trim();
    if (termCtrl.text.trim().isEmpty) errors['term'] = 'Nhập mặt trước của thẻ';
    if (back.isEmpty) errors['meaning'] = 'Nhập mặt sau của thẻ';
    final seen = <String>[];
    for (var i = 0; i < 3; i++) {
      final v = wrongCtrls[i].text.trim();
      if (v.isEmpty) continue;
      if (v.toLowerCase() == back.toLowerCase()) {
        errors['w$i'] = 'Phương án sai không được trùng đáp án đúng';
      } else if (seen.contains(v.toLowerCase())) {
        errors['w$i'] = 'Phương án này bị lặp lại';
      }
      seen.add(v.toLowerCase());
    }
    setState(() => _errors = errors);
    if (errors.isNotEmpty) return null;
    return Flashcard(
      id: widget.card?.id, // Giữ ID khi sửa để không mất tiến độ
      term: termCtrl.text.trim(),
      meaning: back,
      note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      imagePath: _savedImagePath,
      wrongOptions: wrongCtrls.map((c) => c.text.trim()).where((x) => x.isNotEmpty).toList(),
    );
  }

  Future<void> _save({bool addMore = false}) async {
    if (_isSaving) return;
    final card = _validate();
    if (card == null) return;
    setState(() => _isSaving = true);
    final ok = widget.card != null
        ? await _service.updateCard(widget.deckId, card)
        : await _service.addCard(widget.deckId, card);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      showSaveError(context, () => _save(addMore: addMore));
      return;
    }
    _dirty = false;
    if (addMore) {
      final count = _service.deckById(widget.deckId)?.cards.length ?? 0;
      for (final ctrl in [termCtrl, meaningCtrl, noteCtrl, ...wrongCtrls]) {
        ctrl.clear();
      }
      setState(() {
        _image = null;
        _savedImagePath = null;
        _dirty = false;
      });
      showSnack(context, "Đã thêm thẻ $count");
    } else {
      showSnack(context, widget.card != null ? "Đã cập nhật thẻ!" : "Đã thêm thẻ mới!");
      Navigator.pop(context);
    }
  }

  Future<void> _close() async {
    if (!_dirty || await confirmDiscardChanges(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.card != null;
    final deck = _service.deckById(widget.deckId);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(isEdit ? "Sửa thẻ" : "Thêm thẻ"),
              if (deck != null) Text(deck.title, style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
            ],
          ),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
        ),
        body: ResponsiveBody(child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: termCtrl,
                maxLines: null,
                decoration: InputDecoration(labelText: 'Từ vựng / câu hỏi (mặt trước)', errorText: _errors['term']),
              ),
              TextField(
                controller: meaningCtrl,
                maxLines: null,
                decoration: InputDecoration(labelText: 'Nghĩa / đáp án (mặt sau)', errorText: _errors['meaning']),
              ),
              TextField(
                controller: noteCtrl,
                maxLines: null,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú / giải thích (tùy chọn)',
                  helperText: 'Hiện sau khi lật thẻ và khi xem lại đáp án quiz',
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: context.palette.textMuted),
                    borderRadius: BorderRadius.circular(12),
                    image: _image != null
                        ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                        : null,
                  ),
                  child: _image == null && _savedImagePath != null
                      ? const Center(child: MissingImagePlaceholder())
                      : _image == null
                      ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, size: 48, color: context.palette.textMuted),
                      SizedBox(height: 8),
                      Text("Thêm ảnh", style: TextStyle(color: context.palette.textMuted)),
                    ],
                  )
                      : null,
                ),
              ),
              if (_image != null || _savedImagePath != null)
                TextButton.icon(
                  onPressed: () => setState(() {
                    _image = null;
                    _savedImagePath = null;
                    _dirty = true;
                  }),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text("Bỏ ảnh"),
                ),
              const SizedBox(height: 16),
              const Text("Phương án sai cho quiz (tùy chọn)", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                "Nếu bỏ trống, ứng dụng lấy đáp án của các thẻ khác trong bộ làm phương án sai.",
                style: TextStyle(fontSize: 12, color: context.palette.textMuted),
              ),
              for (var i = 0; i < 3; i++)
                TextField(
                  controller: wrongCtrls[i],
                  decoration: InputDecoration(labelText: 'Phương án sai ${i + 1}', errorText: _errors['w$i']),
                ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (!isEdit) ...[
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving ? null : () => _save(addMore: true),
                        child: const Text("Lưu & thêm thẻ"),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      child: Text(isEdit ? "Cập nhật" : "Lưu"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )),
      ),
    );
  }

  @override
  void dispose() {
    termCtrl.dispose();
    meaningCtrl.dispose();
    noteCtrl.dispose();
    for (final c in wrongCtrls) {
      c.dispose();
    }
    super.dispose();
  }
}
