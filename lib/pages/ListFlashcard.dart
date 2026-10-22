// ignore_for_file: file_names
// pages/ListFlashcard.dart - DANH SÁCH CRUD THẺ TRONG MỘT BỘ
// Thêm / sửa bằng bottom sheet, xóa có xác nhận; chỉ chủ bộ thẻ được sửa.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../theme/app_theme.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/common.dart';

class ListFlashcard extends StatelessWidget {
  final String deckId;
  const ListFlashcard({super.key, required this.deckId});

  // Bottom sheet thêm mới (card == null) hoặc sửa thẻ
  Future<void> _showForm(BuildContext context, {Flashcard? card}) async {
    final service = context.read<FlashcardService>();
    final term = TextEditingController(text: card?.term ?? '');
    final meaning = TextEditingController(text: card?.meaning ?? '');
    final note = TextEditingController(text: card?.note ?? '');
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
                card == null ? "Thêm thẻ" : "Sửa thẻ",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: term,
                autofocus: card == null,
                decoration: const InputDecoration(labelText: "Mặt trước (thuật ngữ / câu hỏi)"),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: meaning,
                decoration: InputDecoration(labelText: "Mặt sau (định nghĩa / đáp án)", errorText: error),
                maxLines: 3,
                minLines: 1,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: "Giải thích (không bắt buộc)"),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  if (term.text.trim().isEmpty || meaning.text.trim().isEmpty) {
                    setSheet(() => error = "Cần nhập cả mặt trước và mặt sau");
                    return;
                  }
                  final n = note.text.trim();
                  final ok = card == null
                      ? await service.addCard(
                          deckId,
                          Flashcard(term: term.text.trim(), meaning: meaning.text.trim(), note: n.isEmpty ? null : n),
                        )
                      : await service.updateCard(
                          deckId,
                          card.copyWith()
                            ..term = term.text.trim()
                            ..meaning = meaning.text.trim()
                            ..note = n.isEmpty ? null : n,
                        );
                  // Bộ thẻ nháp có thẻ hợp lệ thì chuyển sang sẵn sàng
                  final deck = service.deckById(deckId);
                  if (ok && deck != null && deck.isDraft && deck.validCards.isNotEmpty) {
                    await service.finishDeck(deckId);
                  }
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (context.mounted) {
                    ok
                        ? showSnack(context, card == null ? "Đã thêm thẻ" : "Đã lưu thẻ")
                        : showSaveError(context, () => _showForm(context, card: card));
                  }
                },
                child: Text(card == null ? "Thêm" : "Lưu"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, Flashcard card) async {
    final service = context.read<FlashcardService>();
    final ok = await confirmDialog(
      context,
      title: "Xóa thẻ?",
      content: "Bạn có chắc muốn xóa thẻ \"${card.term}\"? Thẻ cũng bị xóa khỏi lịch ôn tập.",
      confirmLabel: "Xóa",
      danger: true,
    );
    if (!ok) return;
    final done = await service.deleteCard(deckId, card.id);
    if (context.mounted) done ? showSnack(context, "Đã xóa thẻ") : showSaveError(context, () => _delete(context, card));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    final p = context.palette;
    final deck = service.deckById(deckId);
    if (deck == null) {
      return const BaseScaffold(
        title: "Thẻ",
        body: EmptyState(icon: Icons.error_outline, title: "Bộ thẻ đã bị xóa"),
      );
    }
    final own = service.isOwner(deck);

    return BaseScaffold(
      titleWidget: Text(deck.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      floatingActionButton: own
          ? FloatingActionButton(onPressed: () => _showForm(context), tooltip: "Thêm thẻ", child: const Icon(Icons.add))
          : null,
      body: deck.cards.isEmpty
          ? const EmptyState(icon: Icons.style, title: "Bộ thẻ chưa có thẻ nào", message: "Bấm + để thêm thẻ.")
          : LayoutBuilder(
              // Điện thoại 1 cột, màn hình rộng nhiều cột
              builder: (context, box) => GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 640,
                  mainAxisExtent: 112,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: deck.cards.length,
                itemBuilder: (context, i) {
                  final c = deck.cards[i];
                  return Card(
                    margin: EdgeInsets.zero,
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: own ? () => _showForm(context, card: c) : null,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 4, 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    c.term,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.meaning,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 13, color: p.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (own)
                              IconButton(
                                icon: Icon(Icons.delete_outline, color: p.error),
                                tooltip: "Xóa thẻ",
                                onPressed: () => _delete(context, c),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
