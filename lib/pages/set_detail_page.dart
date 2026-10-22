// pages/set_detail_page.dart - CHI TIẾT BỘ THẺ
import 'package:flutter/material.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/card_progress.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../services/speech_service.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import '../widgets/flip_card.dart';
import '../widgets/gradient_learn_button.dart';
import 'add_edit_flashcard_page.dart';
import 'add_set_page.dart';
import 'deck_cards_page.dart';
import 'home_page.dart' show confirmDeleteDeck;
import 'learn_rounds_page.dart';

class SetDetailPage extends StatefulWidget {
  final String deckId;
  const SetDetailPage({super.key, required this.deckId});

  @override
  State<SetDetailPage> createState() => _SetDetailPageState();
}

class _SetDetailPageState extends State<SetDetailPage> {
  CardStage? _filter;
  String _sort = 'orig'; // 'orig' | 'az' | 'star'
  final PageController _peekController = PageController(viewportFraction: 0.85);

  static const Map<CardStage, String> _stageLabels = {
    CardStage.notStudied: 'Chưa học',
    CardStage.learning: 'Đang học',
    CardStage.mastered: 'Thành thạo',
  };

  // Màu trạng thái: Chưa học xám, Đang học cam, Thành thạo xanh lá
  Color _stageColor(CardStage s) {
    final p = context.palette;
    return switch (s) { CardStage.notStudied => p.textMuted, CardStage.learning => p.warning, CardStage.mastered => p.success };
  }

  Color _stageBg(CardStage s) {
    final p = context.palette;
    return switch (s) { CardStage.notStudied => p.background, CardStage.learning => p.warningBg, CardStage.mastered => p.successBg };
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    final set = service.deckById(widget.deckId);

    if (!service.isAvailable(set)) {
      return BaseScaffold(
        title: "Bộ thẻ",
        body: EmptyState(
          icon: Icons.error_outline,
          // Mở từ lịch sử kiểm tra sau khi bộ thẻ bị xóa: lịch sử vẫn giữ, chỉ bộ thẻ không còn
          title: set == null ? "Bộ thẻ đã bị xóa" : "Bộ thẻ không còn khả dụng",
          message: set == null
              ? "Kết quả kiểm tra cũ của bộ thẻ này vẫn được giữ trong lịch sử."
              : "Chủ sở hữu đã chuyển bộ thẻ sang riêng tư.",
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Quay lại"))],
        ),
      );
    }

    final own = service.isOwner(set);
    final validCount = set!.validCards.length;

    return BaseScaffold(
      titleWidget: Text(set.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      actions: [
        if (own)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AddSetPage(deckId: set.id))),
            tooltip: "Sửa thông tin bộ thẻ",
          )
        else
          IconButton(
            icon: Icon(service.isSaved(set.id) ? Icons.bookmark : Icons.bookmark_border),
            onPressed: () => _toggleSave(service, set),
            tooltip: service.isSaved(set.id) ? "Bỏ lưu" : "Lưu bộ thẻ",
          ),
        PopupMenuButton<String>(
          onSelected: (value) => _onMenu(value, service, set),
          itemBuilder: (BuildContext context) => [
            if (own) ...[
              _menuItem('manage', Icons.reorder, 'Quản lý và sắp xếp thẻ'),
            ] else ...[
              _menuItem('copy', Icons.copy, 'Sao chép thành bộ thẻ của tôi'),
            ],
            if (set.isPublic) _menuItem('share', Icons.share, 'Chia sẻ'),
            if (own) _menuItem('delete', Icons.delete, 'Xóa bộ thẻ', color: context.palette.error),
          ],
        ),
      ],
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: ResponsiveBody(child: _buildBody(service, set, own))),
        ],
      ),
      floatingActionButton: own
          ? FloatingActionButton(
        onPressed: () => _addCard(set),
        tooltip: "Thêm thẻ mới",
        child: const Icon(Icons.add),
      )
          : null,
      bottomNavigationBar: _buildBottomNavigationBar(service, set, validCount),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {Color? color}) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _onMenu(String value, FlashcardService service, FlashcardSet set) async {
    switch (value) {
      case 'manage':
        Navigator.push(context, MaterialPageRoute(builder: (_) => DeckCardsPage(deckId: set.id)));
        break;
      case 'copy':
        final copy = await service.copyDeck(set.id);
        if (!mounted) return;
        if (copy == null) {
          showSaveError(context, () => _onMenu(value, service, set));
          return;
        }
        showSnack(context, "Đã sao chép thành bộ thẻ riêng của bạn");
        Navigator.pushReplacement(context, deckRoute(copy.id));
        break;
      case 'share':
        _showShareSheet(set);
        break;
      case 'delete':
        if (await confirmDeleteDeck(context, set) && mounted) Navigator.pop(context);
        break;
    }
  }

  Future<void> _toggleSave(FlashcardService service, FlashcardSet set) async {
    final wasSaved = service.isSaved(set.id);
    if (await service.toggleSave(set.id)) {
      if (mounted) showSnack(context, wasSaved ? "Đã bỏ lưu bộ thẻ" : "Đã lưu vào Thư viện › Đã lưu");
    } else if (mounted) {
      showSaveError(context, () => _toggleSave(service, set));
    }
  }

  // Liên kết chia sẻ. Khi có backend sẽ dùng App Links / Dynamic Links.
  void _showShareSheet(FlashcardSet set) {
    final link = 'https://flashcardandquizz.app/d/${set.id}';
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Chia sẻ bộ thẻ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text("Gửi liên kết để người khác xem và lưu bộ thẻ công khai này."),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: context.palette.border, borderRadius: BorderRadius.circular(8)),
                child: SelectableText(link, style: TextStyle(color: context.palette.text)),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: link));
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) showSnack(context, "Đã sao chép liên kết");
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("Sao chép liên kết"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FlashcardService service, FlashcardSet set, bool own) {
    final valid = set.validCards;
    final draft = service.quizDraft;

    return ListView(
      padding: const EdgeInsets.only(bottom: 88),
      children: [
        if (valid.isNotEmpty) _buildPeek(set),
        _buildInfo(service, set, own),
        if (draft != null && draft.deckId == set.id) _buildDraftBanner(draft.answeredCount, draft.questions.length),
        if (valid.isNotEmpty) ...[
          _buildStatsHeader(service, set),
          _buildModes(service, set),
        ],
        _buildTermsHeader(own, set),
        if (set.cards.isEmpty)
          own
              ? EmptyState(
            icon: Icons.lightbulb_outline,
            title: "Bộ thẻ trống",
            message: "Hãy thêm thẻ đầu tiên để bắt đầu học!",
            actions: [
              ElevatedButton.icon(
                onPressed: () => _addCard(set),
                icon: const Icon(Icons.add),
                label: const Text("Thêm thẻ đầu tiên"),
              ),
            ],
          )
              : const EmptyState(icon: Icons.lightbulb_outline, title: "Bộ thẻ chưa có thẻ")
        else
          ..._buildCardList(service, set, own),
      ],
    );
  }

  // Băng xem nhanh: lật thử 10 thẻ đầu, nút mở rộng để học từ thẻ đó
  Widget _buildPeek(FlashcardSet set) {
    final peek = set.validCards.take(10).toList();
    return SizedBox(
      height: 200,
      child: PageView.builder(
        controller: _peekController,
        itemCount: peek.length,
        itemBuilder: (context, i) => Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Stack(
            children: [
              FlipCard(
                key: ValueKey('peek_${peek[i].id}'),
                frontText: peek[i].term,
                backText: peek[i].meaning,
                imagePath: peek[i].imagePath,
                height: 184,
              ),
              Positioned(
                left: 28,
                top: 4,
                child: IconButton(
                  icon: Icon(Icons.fullscreen, color: context.palette.textMuted),
                  tooltip: "Học từ thẻ ${i + 1}",
                  onPressed: () => startFlashcards(context, set.id, startIndex: set.validCards.indexOf(peek[i])),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfo(FlashcardService service, FlashcardSet set, bool own) {
    final author = own ? (service.user?.username ?? 'Bạn') : set.ownerName;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: context.palette.brand,
                child: Text(author.trim().isEmpty ? '?' : author.trim()[0].toUpperCase(),
                    style: const TextStyle(fontSize: 12, color: Colors.white)), // Chữ trắng trên nền xanh chàm
              ),
              Text(own ? "Bạn" : author, style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("· ${set.validCards.length} thuật ngữ", style: TextStyle(color: context.palette.textMuted)),
              Chip(
                visualDensity: VisualDensity.compact,
                avatar: Icon(set.isPublic ? Icons.public : Icons.lock, size: 14),
                label: Text(set.isPublic ? "Công khai" : "Riêng tư", style: const TextStyle(fontSize: 12)),
              ),
              if (set.isDraft)
                Chip(
                  visualDensity: VisualDensity.compact,
                  backgroundColor: context.palette.warningBg,
                  label: Text("Bản nháp", style: TextStyle(fontSize: 12, color: context.palette.text)),
                ),
            ],
          ),
          if (set.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(set.description, style: TextStyle(color: context.palette.textMuted)),
          ],
          if (set.isDraft && own) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => DeckCardsPage(deckId: set.id))),
              icon: const Icon(Icons.playlist_add_check),
              label: const Text("Tiếp tục thêm thẻ và hoàn tất"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDraftBanner(int answered, int total) {
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: context.palette.warningBg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.quiz, color: context.palette.warning),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Bạn có bài quiz đang làm dở",
                      style: TextStyle(fontWeight: FontWeight.bold, color: context.palette.text)),
                  Text("$answered/$total câu đã trả lời", style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
                ],
              ),
            ),
            TextButton(onPressed: () => discardQuizDraft(context), child: const Text("Hủy bài")),
            ElevatedButton(
              onPressed: () => resumeQuiz(context),
              child: const Text("Làm tiếp"),
            ),
          ],
        ),
      ),
    );
  }

  // Tiến độ của bạn: Chưa học / Đang học / Thành thạo (chạm để lọc danh sách thẻ)
  Widget _buildStatsHeader(FlashcardService service, FlashcardSet set) {
    final counts = service.stageCounts(set);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: cardDecoration(context),
      margin: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (final stage in CardStage.values)
            Expanded(
              child: MiniStat(
              label: _stageLabels[stage]!,
              value: "${counts[stage]}",
              icon: stage == CardStage.mastered
                  ? Icons.star
                  : stage == CardStage.learning
                  ? Icons.autorenew
                  : Icons.credit_card,
              color: _stageColor(stage),
              selected: _filter == stage,
              onTap: () => setState(() => _filter = _filter == stage ? null : stage),
              ),
            ),
        ],
      ),
    );
  }

  // Ba chế độ học: Thẻ ghi nhớ, Học (trắc nghiệm có phản hồi), Kiểm tra
  Widget _buildModes(FlashcardService service, FlashcardSet set) {
    final n = set.validCards.length;
    final mastered = service.stageCounts(set)[CardStage.mastered]!;
    final pos = service.positionOf(set.id);
    final need2 = n < 2 ? "Cần ít nhất 2 thẻ" : null;

    Widget mode(IconData icon, String title, String? subtitle, VoidCallback? onTap) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          enabled: onTap != null,
          leading: CircleAvatar(backgroundColor: context.palette.brandSoft, child: Icon(icon, color: context.palette.brandText)),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      );
    }

    return Column(
      children: [
        mode(Icons.style, "Thẻ ghi nhớ", pos > 0 ? "Đang ở thẻ ${pos + 1}/$n · gạt để phân loại" : "Lật thẻ, gạt trái/phải để phân loại",
            () => startFlashcards(context, set.id)),
        mode(Icons.school, "Học", need2 ?? "$mastered/$n thành thạo · đúng 2 lần liên tiếp",
            n < 2 ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => LearnRoundsPage(deckId: set.id)))),
        mode(Icons.quiz, "Kiểm tra", need2 ?? "Làm bài trắc nghiệm có chấm điểm",
            n < 2 ? null : () => openQuizSetup(context, set.id)),
      ],
    );
  }

  Widget _buildTermsHeader(bool own, FlashcardSet set) {
    const sortLabels = {'orig': 'Thứ tự gốc', 'az': 'A–Z', 'star': 'Gắn sao trước'};
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(child: Text("Thuật ngữ", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              PopupMenuButton<String>(
                initialValue: _sort,
                onSelected: (v) => setState(() => _sort = v),
                itemBuilder: (_) => sortLabels.entries
                    .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
                    .toList(),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    children: [
                      Text(sortLabels[_sort]!, style: TextStyle(color: context.palette.brandText)),
                      Icon(Icons.sort, color: context.palette.brandText, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_filter != null)
            Row(
              children: [
                Chip(label: Text("Đang lọc: ${_stageLabels[_filter]}")),
                TextButton(onPressed: () => setState(() => _filter = null), child: const Text("Bỏ lọc")),
              ],
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCardList(FlashcardService service, FlashcardSet set, bool own) {
    var cards = set.cards.toList();
    if (_filter != null) {
      cards = cards.where((c) => c.isValid && service.stageOfCard(c.id) == _filter).toList();
    }
    if (_sort == 'az') cards.sort((a, b) => a.term.toLowerCase().compareTo(b.term.toLowerCase()));
    if (_sort == 'star') {
      cards.sort((a, b) => (service.isStarred(b.id) ? 1 : 0) - (service.isStarred(a.id) ? 1 : 0));
    }
    if (cards.isEmpty) {
      return [Padding(padding: EdgeInsets.all(16), child: Text("Không có thẻ ở nhóm này.", style: TextStyle(color: context.palette.textMuted)))];
    }
    return [
      for (final card in cards)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildCardItem(service, set, card, own),
        ),
    ];
  }

  Widget _buildCardItem(FlashcardService service, FlashcardSet set, Flashcard card, bool own) {
    final stage = service.stageOfCard(card.id);
    final starred = service.isStarred(card.id);
    final tile = ListTile(
      leading: CircleAvatar(
        backgroundColor: _stageBg(stage),
        child: Icon(
          stage == CardStage.mastered ? Icons.check : stage == CardStage.learning ? Icons.autorenew : Icons.credit_card,
          color: _stageColor(stage),
          size: 20,
        ),
      ),
      title: Text(
        card.term.isEmpty ? "Thiếu mặt trước" : card.term,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: card.term.isEmpty ? context.palette.error : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(card.meaning.isEmpty ? "Thiếu mặt sau" : card.meaning,
              style: TextStyle(color: card.meaning.isEmpty ? context.palette.error : null)),
          if (card.note != null && card.note!.isNotEmpty)
            Text(
              card.note!,
              style: TextStyle(fontSize: 12, color: context.palette.textMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.volume_up, size: 20),
            tooltip: "Đọc to thẻ",
            onPressed: () => _speak('${card.term}. ${card.meaning}'),
          ),
          IconButton(
            icon: Icon(starred ? Icons.star : Icons.star_border, color: context.palette.yellow, size: 22),
            tooltip: starred ? "Bỏ gắn sao" : "Gắn sao",
            onPressed: () => _toggleStar(service, card.id),
          ),
        ],
      ),
      onTap: own ? () => _editCard(set, card) : null,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      clipBehavior: Clip.antiAlias,
      child: own
          ? Dismissible(
        key: Key('card_${card.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) => _deleteCard(service, set, card),
        background: Container(
          color: context.palette.error,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: tile,
      )
          : tile,
    );
  }

  Future<void> _speak(String text) async {
    if (!await SpeechService().speak(text) && mounted) {
      showSnack(context, "Thiết bị này chưa hỗ trợ đọc to.");
    }
  }

  Future<void> _toggleStar(FlashcardService service, String cardId) async {
    final was = service.isStarred(cardId);
    if (await service.toggleStar(cardId)) {
      if (mounted) showSnack(context, was ? "Đã bỏ gắn sao" : "Đã gắn sao thẻ cần chú ý");
    } else if (mounted) {
      showSaveError(context, () => _toggleStar(service, cardId));
    }
  }

  Widget _buildBottomNavigationBar(FlashcardService service, FlashcardSet set, int validCount) {
    final canQuiz = validCount >= 2;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: context.palette.card,
          border: Border(top: BorderSide(color: context.palette.border)),
        ),
        child: ResponsiveBody(child: GradientLearnButton(
          onPressed: () => startFlashcards(context, set.id),
          onTestPressed: canQuiz
              ? () => openQuizSetup(context, set.id)
              : () => showSnack(context, "Quiz cần ít nhất 2 thẻ có đủ mặt trước và mặt sau."),
          cardCount: validCount,
          isEnabled: validCount > 0,
          showTestButton: true,
          buttonText: service.positionOf(set.id) > 0 ? "Học tiếp" : "Học ngay",
        )),
      ),
    );
  }

  void _addCard(FlashcardSet set) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditFlashcardPage(deckId: set.id)),
    );
  }

  void _editCard(FlashcardSet set, Flashcard card) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditFlashcardPage(deckId: set.id, card: card)),
    );
  }

  Future<bool> _deleteCard(FlashcardService service, FlashcardSet set, Flashcard card) async {
    final ok = await confirmDialog(
      context,
      title: "Xóa thẻ?",
      content: "Bạn có chắc muốn xóa thẻ \"${card.term}\"? Thẻ cũng bị xóa khỏi lịch ôn tập.",
      confirmLabel: "Xóa",
      danger: true,
    );
    if (!ok) return false;
    final done = await service.deleteCard(set.id, card.id);
    if (!mounted) return done;
    if (done) {
      showSnack(context, "Đã xóa thẻ \"${card.term}\"");
    } else {
      showSaveError(context, () => service.deleteCard(set.id, card.id));
    }
    return done;
  }

  @override
  void dispose() {
    _peekController.dispose();
    super.dispose();
  }
}
