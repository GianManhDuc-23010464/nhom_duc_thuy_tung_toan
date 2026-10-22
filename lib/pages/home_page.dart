import 'package:flutter/material.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../main.dart' show TabNavigator;
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../utils/date_utils.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import '../widgets/set_card.dart';
import 'add_set_page.dart';
import 'learn_rounds_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  Future<void> _createSet() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddSetPage()),
    );
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() => _searching = false);
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();
    final p = context.palette;

    return BaseScaffold(
      body: Container(
        // Nền chuyển nhẹ từ tím nhạt ở đầu trang xuống nền chung
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [p.brandSoft, p.background],
            stops: const [0, 0.4],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: !service.isLoaded
                    ? const Center(child: CircularProgressIndicator())
                    : _searching
                    ? Column(
                        children: [
                          ResponsiveBody(maxWidth: 900, child: _buildSearchBar()),
                          Expanded(child: _buildSearchResults(service)),
                        ],
                      )
                    : service.isNewUser
                    ? Column(
                        children: [
                          ResponsiveBody(maxWidth: 900, child: _buildHeader(service)),
                          Expanded(child: _buildNewUser()),
                        ],
                      )
                    : _buildDashboard(service),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Đầu trang: nút tìm kiếm, chuỗi ngày học, ảnh đại diện
  Widget _buildHeader(FlashcardService service) {
    final p = context.palette;
    final user = service.user;
    final streak = service.streak;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          _CircleButton(
            tooltip: "Tìm bộ flashcard",
            onTap: () => setState(() => _searching = true),
            child: Icon(Icons.search, color: p.text),
          ),
          const Spacer(),
          // Chuỗi ngày học -> Thống kê
          Tooltip(
            message: "Chuỗi $streak ngày học",
            child: Material(
              color: p.yellow,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => context.read<TabNavigator>().go(TabNavigator.stats),
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_fire_department, size: 22, color: Color(0xFF282E3E)),
                      const SizedBox(width: 6),
                      Text(
                        "$streak",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF282E3E)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => context.read<TabNavigator>().go(TabNavigator.profile),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(color: p.card, shape: BoxShape.circle),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: p.brand,
                foregroundColor: Colors.white,
                child: Text(
                  (user?.username.trim().isNotEmpty ?? false) ? user!.username.trim()[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: "Tìm bộ flashcard...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear)
                    : null,
                fillColor: p.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          TextButton(onPressed: _closeSearch, child: const Text("Hủy")),
        ],
      ),
    );
  }

  Widget _buildNewUser() {
    return EmptyState(
      icon: Icons.folder_open,
      title: "Bắt đầu với bộ thẻ đầu tiên",
      message: "Tạo bộ thẻ từ nội dung bạn đang học, hoặc lưu một bộ thẻ có sẵn trong thư viện công khai.",
      actions: [
        ElevatedButton.icon(
          onPressed: _createSet,
          icon: const Icon(Icons.add),
          label: const Text("Tạo bộ thẻ đầu tiên"),
        ),
        OutlinedButton.icon(
          onPressed: () => context.read<TabNavigator>().openLibrary(tab: 'explore'),
          icon: const Icon(Icons.public),
          label: const Text("Khám phá thư viện công khai"),
        ),
      ],
    );
  }

  // Tìm trong bộ thẻ của tôi và đã lưu
  Widget _buildSearchResults(FlashcardService service) {
    final results = service.recentDecks
        .where((d) => '${d.title} ${d.description}'.toLowerCase().contains(_searchQuery))
        .toList();
    if (results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off,
        title: "Không tìm thấy bộ nào",
        message: "Thử tìm trong Thư viện › Khám phá.",
        actions: [
          OutlinedButton(
            onPressed: () => context.read<TabNavigator>().openLibrary(tab: 'explore'),
            child: const Text("Mở Khám phá"),
          ),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, c) => GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: setGridDelegate(c.maxWidth),
        itemCount: results.length,
        itemBuilder: (context, i) => _buildSetCard(service, results[i], i),
      ),
    );
  }

  Widget _buildDashboard(FlashcardService service) {
    final stats = service.stats;
    final due = service.dueList().length;
    final recent = service.recentDecks.take(4).toList();
    final suggestions = service.exploreDecks
        .where((d) => !service.isSaved(d.id) && !service.recentDecks.any((r) => r.title == d.title))
        .take(2)
        .toList();
    final hasContinue = service.continueDeck != null;

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          for (final w in [
            _buildHeader(service),
            if (hasContinue) ...[
              _buildSectionHeader("Học tiếp"),
              _buildContinueCard(service),
            ],
            if (service.quizDraft != null) _buildDraftCard(service),
            if (recent.isNotEmpty) ...[
              _buildSectionHeader("Gần đây", "Xem tất cả", () => context.read<TabNavigator>().openLibrary(tab: 'mine')),
              for (final s in recent) _buildDeckRow(service, s),
            ],
            if (due > 0) _buildReviewCard(due),
            _buildGoalCard(service, stats.todayCount, stats.dailyGoal, due),
            _buildCreateButton(),
            if (suggestions.isNotEmpty) ...[
              _buildSectionHeader("Gợi ý khám phá", "Thư viện công khai",
                  () => context.read<TabNavigator>().openLibrary(tab: 'explore')),
              for (final s in suggestions) _buildDeckRow(service, s),
            ],
          ])
            ResponsiveBody(maxWidth: 900, child: w),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, [String? action, VoidCallback? onTap]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: context.palette.text)),
          ),
          if (action != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              child: Text(action),
            ),
        ],
      ),
    );
  }

  // Một dòng bộ thẻ: ô icon vuông bên trái, tên + số thẻ + tác giả
  Widget _buildDeckRow(FlashcardService service, FlashcardSet set) {
    final p = context.palette;
    final own = service.isOwner(set);
    return InkWell(
      onTap: () => openDeck(context, set.id),
      onLongPress: own ? () => _showSetOptions(service, set) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(color: p.brandSoft, borderRadius: BorderRadius.circular(AppRadius.large)),
              child: Icon(Icons.filter_none, color: p.brandText, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(set.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
                  const SizedBox(height: 4),
                  Text(
                    "${set.validCards.length} thẻ · Tác giả: ${own ? "Bạn" : set.ownerName}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13, color: p.textMuted),
                  ),
                ],
              ),
            ),
            if (!own)
              IconButton(
                onPressed: () => _toggleSave(service, set),
                tooltip: service.isSaved(set.id) ? "Bỏ lưu" : "Lưu bộ thẻ",
                icon: Icon(service.isSaved(set.id) ? Icons.bookmark : Icons.bookmark_border, color: p.brandText),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetCard(FlashcardService service, FlashcardSet set, int index) {
    final own = service.isOwner(set);
    return SetCard(
      set: set,
      index: index,
      ownerLabel: own ? "Bạn" : set.ownerName,
      knownCount: service.touched(set) ? service.knownIn(set) : null,
      isSaved: own ? null : service.isSaved(set.id),
      onToggleSave: own ? null : () => _toggleSave(service, set),
      onTap: () => openDeck(context, set.id),
      onLongPress: own ? () => _showSetOptions(service, set) : null,
    );
  }

  Future<void> _toggleSave(FlashcardService service, FlashcardSet set) async {
    final wasSaved = service.isSaved(set.id);
    if (await service.toggleSave(set.id)) {
      if (mounted) showSnack(context, wasSaved ? "Đã bỏ lưu bộ thẻ" : "Đã lưu vào Thư viện › Đã lưu");
    } else if (mounted) {
      showSaveError(context, () => _toggleSave(service, set));
    }
  }

  // Thẻ "Học tiếp": bộ thẻ học gần nhất
  Widget _buildContinueCard(FlashcardService service) {
    final p = context.palette;
    final deck = service.continueDeck!;
    final n = deck.validCards.length;
    final percent = (service.learnCompletion(deck) * 100).round();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 20),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(deck.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text)),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: "Tùy chọn bộ thẻ",
                onPressed: () => _showContinueMenu(service, deck),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                // Tỉ lệ câu hỏi đã hoàn thành trong phần Học
                LinearProgressIndicator(
                  value: percent / 100,
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(6),
                  backgroundColor: p.background,
                  valueColor: AlwaysStoppedAnimation(p.success),
                ),
                const SizedBox(height: 12),
                Text(
                  "Đã hoàn thành $percent% số câu hỏi",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: p.textMuted),
                ),
                const SizedBox(height: 20),
                // Học tiếp bằng trắc nghiệm (cần ít nhất 2 thẻ để có phương án sai)
                ElevatedButton(
                  onPressed: () => n >= 2
                      ? Navigator.push(context, MaterialPageRoute(builder: (_) => LearnRoundsPage(deckId: deck.id)))
                      : startFlashcards(context, deck.id),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
                  ),
                  child: Text(percent > 0 ? "Tiếp tục" : "Bắt đầu học"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showContinueMenu(FlashcardService service, FlashcardSet deck) {
    final due = service.dueList(deckId: deck.id).length;
    final canQuiz = deck.validCards.length >= 2;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.open_in_new),
              title: const Text('Mở chi tiết bộ thẻ'),
              onTap: () {
                Navigator.pop(ctx);
                openDeck(context, deck.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.style),
              title: const Text('Học bằng thẻ ghi nhớ'),
              onTap: () {
                Navigator.pop(ctx);
                startFlashcards(context, deck.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.quiz),
              title: const Text('Làm Quiz'),
              subtitle: canQuiz ? null : const Text('Cần ít nhất 2 thẻ'),
              enabled: canQuiz,
              onTap: () {
                Navigator.pop(ctx);
                openQuizSetup(context, deck.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.repeat),
              title: Text(due > 0 ? 'Ôn tập · $due thẻ đến hạn' : 'Ôn tập'),
              subtitle: due > 0 ? null : const Text('Chưa có thẻ đến hạn'),
              enabled: due > 0,
              onTap: () {
                Navigator.pop(ctx);
                startReview(context, deckId: deck.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraftCard(FlashcardService service) {
    final draft = service.quizDraft!;
    final deck = service.deckById(draft.deckId);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: context.palette.warningBg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: context.palette.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text("Quiz đang làm dở", style: TextStyle(fontWeight: FontWeight.bold, color: context.palette.text)),
                ),
                Text("${draft.answeredCount}/${draft.questions.length} câu",
                    style: TextStyle(color: context.palette.textMuted, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 4),
            Text(deck?.title ?? "Bộ thẻ không còn tồn tại", style: TextStyle(color: context.palette.text)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => resumeQuiz(context),
                    child: const Text("Làm tiếp"),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(onPressed: () => discardQuizDraft(context), child: const Text("Hủy bài")),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Khối "Ôn tập hôm nay": nền chàm đậm, số thẻ đến hạn lớn
  Widget _buildReviewCard(int due) {
    final p = context.palette;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final deep = dark ? p.brandSoft : Color.lerp(p.brand, Colors.black, 0.55)!;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: deep, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("ÔN TẬP HÔM NAY",
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Colors.white.withValues(alpha: 0.8))),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text("$due", style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(width: 8),
              const Text("thẻ đến hạn ôn", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => startReview(context),
            icon: const Icon(Icons.replay, size: 20),
            label: const Text("Ôn tập ngay"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: deep,
              padding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Mục tiêu hôm nay: số thẻ đã học / mục tiêu, thanh tiến độ
  Widget _buildGoalCard(FlashcardService service, int today, int goal, int due) {
    final p = context.palette;
    final tomorrow = service.dueOn(addDays(service.today, 1));
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: p.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text("Mục tiêu hôm nay", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.text)),
              ),
              Text("${today > goal ? goal : today}/$goal thẻ", style: TextStyle(fontSize: 14, color: p.textMuted)),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: goal > 0 ? (today / goal).clamp(0, 1).toDouble() : 0,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: p.background,
          ),
          const SizedBox(height: 10),
          Text(
            today >= goal
                ? "Bạn đã đạt mục tiêu hôm nay."
                : due == 0 && tomorrow > 0
                ? "Còn ${goal - today} thẻ để đạt mục tiêu · ngày mai có $tomorrow thẻ đến hạn."
                : "Còn ${goal - today} thẻ nữa để đạt mục tiêu.",
            style: TextStyle(fontSize: 13, color: p.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: OutlinedButton.icon(
        onPressed: _createSet,
        icon: const Icon(Icons.add),
        label: const Text("Tạo bộ thẻ mới"),
        style: OutlinedButton.styleFrom(
          foregroundColor: p.text,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large)),
        ),
      ),
    );
  }

  // Nhấn giữ bộ thẻ của tôi để xem tùy chọn
  void _showSetOptions(FlashcardService service, FlashcardSet set) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.open_in_new),
                title: const Text('Mở bộ thẻ'),
                onTap: () {
                  Navigator.pop(ctx);
                  openDeck(context, set.id);
                },
              ),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Sửa thông tin'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => AddSetPage(deckId: set.id)));
                },
              ),
              ListTile(
                leading: Icon(Icons.delete, color: context.palette.error),
                title: Text('Xóa bộ thẻ', style: TextStyle(color: context.palette.error)),
                onTap: () {
                  Navigator.pop(ctx);
                  confirmDeleteDeck(context, set);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// Hộp thoại xóa bộ thẻ, nêu rõ dữ liệu liên quan bị xóa theo
Future<bool> confirmDeleteDeck(BuildContext context, FlashcardSet set) async {
  final service = context.read<FlashcardService>();
  final prog = set.cards.where((c) => service.progressOf(c.id) != null).length;
  final hist = service.history.where((a) => a.deckId == set.id).length;
  final ok = await confirmDialog(
    context,
    title: "Xóa bộ thẻ?",
    content: "\"${set.title}\" và ${set.cards.length} thẻ sẽ bị xóa vĩnh viễn."
        "${prog > 0 || hist > 0 ? " Tiến độ của $prog thẻ và $hist lần làm quiz liên quan cũng bị xóa." : ""}"
        "${set.isPublic ? " Người đã lưu bộ thẻ sẽ không mở được nữa." : ""}",
    confirmLabel: "Xóa",
    danger: true,
  );
  if (!ok) return false;
  final done = await service.deleteDeck(set.id);
  if (!context.mounted) return done;
  if (done) {
    showSnack(context, "Đã xóa bộ thẻ \"${set.title}\"");
  } else {
    showSaveError(context, () => service.deleteDeck(set.id));
  }
  return done;
}

// Nút tròn nền trắng ở đầu trang
class _CircleButton extends StatelessWidget {
  final Widget child;
  final String tooltip;
  final VoidCallback onTap;
  const _CircleButton({required this.child, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: context.palette.card,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: SizedBox(width: 52, height: 52, child: Center(child: child))),
      ),
    );
  }
}
