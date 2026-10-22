import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../widgets/common.dart';
import 'deck_cards_page.dart';

// Tạo bộ thẻ (bước 1/2) hoặc sửa thông tin bộ thẻ khi có deckId
class AddSetPage extends StatefulWidget {
  final String? deckId;
  const AddSetPage({super.key, this.deckId});

  @override
  State<AddSetPage> createState() => _AddSetPageState();
}

class _AddSetPageState extends State<AddSetPage> {
  late final FlashcardService _flashcardService = context.read<FlashcardService>();
  late final FlashcardSet? _editing = _flashcardService.deckById(widget.deckId);
  late final TextEditingController _titleController = TextEditingController(text: _editing?.title ?? '');
  late final TextEditingController _descriptionController = TextEditingController(text: _editing?.description ?? '');
  late String? _subject = _editing == null ? null : normalizeSubject(_editing.subject);
  late String _visibility = _editing?.visibility ?? 'private';
  bool _isLoading = false;
  bool _dirty = false;
  String? _titleError;

  bool get _isEdit => _editing != null;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_markDirty);
    _descriptionController.addListener(_markDirty);
  }

  void _markDirty() {
    if (!_dirty) setState(() => _dirty = true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isLoading) return; // Tránh bấm hai lần
    final title = _titleController.text.trim();
    setState(() {
      _titleError = title.isEmpty
          ? "Vui lòng nhập tên bộ thẻ"
          : _flashcardService.hasDuplicateTitle(title, exceptId: widget.deckId)
          ? "Bạn đã có bộ thẻ cùng tên. Hãy đặt tên khác."
          : null;
    });
    if (_titleError != null) return;

    setState(() {
      _isLoading = true;
    });

    if (_isEdit) {
      final ok = await _flashcardService.updateDeckInfo(
        _editing!.id,
        title: title,
        description: _descriptionController.text,
        subject: _subject ?? 'Khác',
        visibility: _visibility,
      );
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (ok) {
        _dirty = false;
        showSnack(context, "Đã lưu thay đổi");
        Navigator.pop(context);
      } else {
        showSaveError(context, _save);
      }
      return;
    }

    final deck = await _flashcardService.createDeck(
      title: title,
      description: _descriptionController.text,
      subject: _subject ?? 'Khác',
      visibility: _visibility,
    );
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (deck == null) {
      showSaveError(context, _save);
      return;
    }
    _dirty = false;
    showSnack(context, "Đã tạo bản nháp \"$title\"");
    // Bước 2: thêm thẻ
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => DeckCardsPage(deckId: deck.id)),
    );
  }

  Future<void> _close() async {
    if (!_dirty || await confirmDiscardChanges(context)) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? "Sửa bộ thẻ" : "Tạo bộ Flashcard mới"),
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
          actions: [
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
                          "• Bộ thẻ công khai hiện trong Thư viện › Khám phá, người khác xem, lưu và sao chép được nhưng không sửa được",
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
        body: ResponsiveBody(child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              color: context.palette.brandSoft,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  children: [
                    Icon(Icons.person, color: context.palette.brandText),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _flashcardService.user?.username ?? "Người dùng",
                            style: TextStyle(fontWeight: FontWeight.bold, color: context.palette.text),
                          ),
                          Text(
                            _isEdit ? "Đang sửa thông tin bộ thẻ" : "Bước 1/2 · Thông tin bộ thẻ",
                            style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tiêu đề bộ thẻ
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: "Tên bộ thẻ *",
                hintText: "Ví dụ: Từ vựng TOEIC, Ngữ pháp N3...",
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.title),
                errorText: _titleError,
              ),
              maxLength: 60,
              onSubmitted: (_) => _save(),
            ),

            const SizedBox(height: 16),

            // Mô tả (tùy chọn)
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: "Mô tả (tùy chọn)",
                hintText: "Bộ thẻ này dùng để ôn gì?",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 2,
              maxLength: 200,
            ),

            const SizedBox(height: 16),

            // Môn học
            DropdownButtonFormField<String>(
              initialValue: _subject,
              decoration: const InputDecoration(
                labelText: "Môn học (tùy chọn)",
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.school),
              ),
              items: kSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setState(() {
                _subject = v;
                _dirty = true;
              }),
            ),

            const SizedBox(height: 16),

            // Quyền hiển thị
            const Text("Quyền hiển thị", style: TextStyle(fontWeight: FontWeight.bold)),
            RadioGroup<String>(
              groupValue: _visibility,
              onChanged: (v) => setState(() {
                _visibility = v!;
                _dirty = true;
              }),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    value: 'private',
                    title: Text("Riêng tư"),
                    subtitle: Text("Chỉ bạn xem và học được."),
                    secondary: Icon(Icons.lock),
                  ),
                  RadioListTile<String>(
                    value: 'public',
                    title: Text("Công khai"),
                    subtitle: Text("Hiện trong Thư viện › Khám phá. Người khác xem, lưu và sao chép được nhưng không sửa được."),
                    secondary: Icon(Icons.public),
                  ),
                ],
              ),
            ),

            if (!_isEdit)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: context.palette.brandText, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Bộ thẻ được lưu dạng bản nháp, bước tiếp theo bạn sẽ thêm thẻ.",
                          style: TextStyle(
                            fontSize: 12,
                            color: context.palette.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 24),
            // Nút nằm trong nội dung cuộn: luôn ở trên bàn phím, không bị che
            BusyButton(
              busy: _isLoading,
              onPressed: _save,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_isEdit ? Icons.save : Icons.arrow_forward, size: 20),
                  const SizedBox(width: 8),
                  Text(_isEdit ? "Lưu thay đổi" : "Tiếp tục: thêm thẻ"),
                ],
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _isLoading ? null : _close,
              style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text("Hủy"),
            ),
          ],
        )),
      ),
    );
  }
}
