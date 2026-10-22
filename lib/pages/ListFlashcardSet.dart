// ignore_for_file: file_names
// pages/ListFlashcardSet.dart - DANH SÁCH CRUD BỘ THẺ CỦA TÔI
// Thêm / sửa bằng bottom sheet, xóa có xác nhận; dữ liệu qua FlashcardService.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';
import '../utils/date_utils.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/common.dart';
import 'ListFlashcard.dart';
import 'home_page.dart' show confirmDeleteDeck;

class ListFlashcardSet extends StatelessWidget {
  const ListFlashcardSet({super.key});

  // Bottom sheet thêm mới (set == null) hoặc sửa thông tin bộ thẻ
  static Future<void> showForm(BuildContext context, {FlashcardSet? set}) async {
    final service = context.read<FlashcardService>();
    final title = TextEditingController(text: set?.title ?? '');
    final desc = TextEditingController(text: set?.description ?? '');
    var subject = set?.subject ?? 'Khác';
    var isPublic = set?.isPublic ?? false;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                set == null ? "Tạo bộ thẻ" : "Sửa bộ thẻ",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: title,
                autofocus: set == null,
                decoration: InputDecoration(labelText: "Tên bộ thẻ", errorText: error),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: "Mô tả"),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: subject,
                decoration: const InputDecoration(labelText: "Môn học"),
                items: [for (final s in kSubjects) DropdownMenuItem(value: s, child: Text(s))],
                onChanged: (v) => subject = v ?? subject,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Công khai"),
                subtitle: const Text("Mọi người thấy trong Thư viện › Khám phá"),
                value: isPublic,
                onChanged: (v) => setSheet(() => isPublic = v),
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () async {
                  final t = title.text.trim();
                  final err = t.isEmpty
                      ? "Nhập tên bộ thẻ"
                      : service.hasDuplicateTitle(t, exceptId: set?.id)
                      ? "Bạn đã có bộ thẻ cùng tên"
                      : null;
                  if (err != null) {
                    setSheet(() => error = err);
                    return;
                  }
                  final visibility = isPublic ? 'public' : 'private';
                  final ok = set == null
                      ? await service.createDeck(
                              title: t,
                              description: desc.text,
                              subject: subject,
                              visibility: visibility,
                            ) !=
                            null
                      : await service.updateDeckInfo(
                          set.id,
                          title: t,
                          description: desc.text,
                          subject: subject,
                          visibility: visibility,
                        );
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ok
                        ? showSnack(context, set == null ? "Đã tạo bộ thẻ" : "Đã lưu thay đổi")
                        : showSaveError(context, () => showForm(context, set: set));
                  }
                },
                child: Text(set == null ? "Tạo" : "Lưu"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    final p = context.palette;
    final decks = service.myDecks..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return BaseScaffold(
      title: "Quản lý bộ thẻ",
      floatingActionButton: FloatingActionButton(
        onPressed: () => showForm(context),
        tooltip: "Tạo bộ thẻ",
        child: const Icon(Icons.add),
      ),
      body: decks.isEmpty
          ? const EmptyState(
              icon: Icons.folder_open,
              title: "Chưa có bộ thẻ nào",
              message: "Bấm + để tạo bộ thẻ đầu tiên.",
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
              itemCount: decks.length,
              itemBuilder: (context, i) {
                final d = decks[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () =>
                        Navigator.push(context, MaterialPageRoute(builder: (_) => ListFlashcard(deckId: d.id))),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(d.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 4),
                                Text(
                                  "${d.cards.length} thẻ · ${d.isPublic ? "Công khai" : "Riêng tư"} · ${formatDate(d.updatedAt)}",
                                  style: TextStyle(fontSize: 13, color: p.textMuted),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            tooltip: "Sửa",
                            onPressed: () => showForm(context, set: d),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: p.error),
                            tooltip: "Xóa",
                            onPressed: () => confirmDeleteDeck(context, d),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
