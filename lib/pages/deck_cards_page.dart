// pages/deck_cards_page.dart - THÊM THẺ (bước 2/2) / QUẢN LÝ VÀ SẮP XẾP THẺ
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../widgets/common.dart';
import 'add_edit_flashcard_page.dart';
import '../utils/nav.dart';

class DeckCardsPage extends StatefulWidget {
  final String deckId;
  const DeckCardsPage({super.key, required this.deckId});

  @override
  State<DeckCardsPage> createState() => _DeckCardsPageState();
}

class _DeckCardsPageState extends State<DeckCardsPage> {
  bool _isSaving = false;

  void _addCard() => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditFlashcardPage(deckId: widget.deckId)),
      );

  void _editCard(Flashcard card) => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddEditFlashcardPage(deckId: widget.deckId, card: card)),
      );

  Future<void> _deleteCard(FlashcardService service, Flashcard card) async {
    final ok = await confirmDialog(
      context,
      title: "Xóa thẻ này?",
      content: "\"${card.term.isEmpty ? 'Thẻ chưa có nội dung' : card.term}\" sẽ bị xóa khỏi bộ thẻ và lịch ôn tập.",
      confirmLabel: "Xóa thẻ",
      danger: true,
    );
    if (!ok) return;
    if (await service.deleteCard(widget.deckId, card.id)) {
      if (mounted) showSnack(context, "Đã xóa thẻ");
    } else if (mounted) {
      showSaveError(context, () => _deleteCard(service, card));
    }
  }

  Future<void> _finish(FlashcardService service) async {
    final deck = service.deckById(widget.deckId)!;
    if (!deck.isDraft) {
      Navigator.pop(context);
      return;
    }
    setState(() => _isSaving = true);
    final ok = await service.finishDeck(deck.id);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (!ok) {
      showSaveError(context, () => _finish(service));
      return;
    }
    showSnack(context, "Bộ thẻ đã sẵn sàng để học");
    Navigator.pushReplacement(context, deckRoute(deck.id));
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    final deck = service.deckById(widget.deckId);
    if (deck == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Quản lý thẻ")),
        body: const EmptyState(icon: Icons.error_outline, title: "Bộ thẻ không còn tồn tại"),
      );
    }
    final creating = deck.isDraft;
    final valid = deck.validCards.length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(creating ? "Thêm thẻ" : "Quản lý thẻ"),
            Text(
              creating ? "Bước 2/2 · ${deck.title}" : deck.title,
              style: TextStyle(fontSize: 12, color: context.palette.textMuted),
            ),
          ],
        ),
      ),
      body: ResponsiveBody(child: Column(
        children: [
          const OfflineBanner(),
          if (creating)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: context.palette.brandSoft, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.info, color: context.palette.brandText, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "Bộ thẻ đang ở dạng bản nháp và đã được lưu. Bạn có thể thoát và quay lại thêm thẻ sau.",
                      style: TextStyle(fontSize: 12, color: context.palette.text),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: deck.cards.isEmpty
                ? EmptyState(
              icon: Icons.lightbulb_outline,
              title: "Chưa có thẻ nào",
              message: "Mặt trước là câu hỏi hoặc thuật ngữ, mặt sau là đáp án hoặc định nghĩa.",
              actions: [
                ElevatedButton.icon(onPressed: _addCard, icon: const Icon(Icons.add), label: const Text("Thêm thẻ đầu tiên")),
              ],
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: deck.cards.length + 1,
              itemBuilder: (context, i) {
                if (i == deck.cards.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      "$valid/${deck.cards.length} thẻ hợp lệ · Quiz cần ít nhất 2 thẻ, đủ 4 lựa chọn khi có từ 4 thẻ hoặc nhập thêm phương án sai.",
                      style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                    ),
                  );
                }
                final card = deck.cards[i];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    contentPadding: const EdgeInsets.only(left: 12, right: 0),
                    leading: CircleAvatar(
                      backgroundColor: card.isValid ? context.palette.brandSoft : context.palette.errorBg,
                      child: Text("${i + 1}", style: TextStyle(color: card.isValid ? context.palette.brandText : context.palette.error)),
                    ),
                    title: Text(
                      card.term.isEmpty ? "Thiếu mặt trước" : card.term,
                      style: TextStyle(fontWeight: FontWeight.bold, color: card.term.isEmpty ? context.palette.error : null),
                    ),
                    subtitle: Text(
                      card.meaning.isEmpty ? "Thiếu mặt sau" : card.meaning,
                      style: TextStyle(color: card.meaning.isEmpty ? context.palette.error : null),
                    ),
                    onTap: () => _editCard(card),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_upward, size: 20),
                          tooltip: "Chuyển lên",
                          onPressed: i == 0 ? null : () => service.moveCard(deck.id, card.id, -1),
                        ),
                        IconButton(
                          icon: const Icon(Icons.arrow_downward, size: 20),
                          tooltip: "Chuyển xuống",
                          onPressed: i == deck.cards.length - 1 ? null : () => service.moveCard(deck.id, card.id, 1),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete, color: context.palette.error, size: 20),
                          tooltip: "Xóa thẻ",
                          onPressed: () => _deleteCard(service, card),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      )),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add),
                  label: const Text("Thêm thẻ"),
                ),
              ),
              const SizedBox(height: 8),
              if (creating && valid == 0)
                Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text(
                    "Cần ít nhất 1 thẻ có đủ mặt trước và mặt sau để hoàn tất.",
                    style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                  ),
                ),
              ElevatedButton(
                onPressed: (valid == 0 && creating) || _isSaving ? null : () => _finish(service),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
                child: Text(creating ? "HOÀN TẤT BỘ THẺ" : "XONG", style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
