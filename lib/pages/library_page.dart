// pages/library_page.dart - THƯ VIỆN: CỦA TÔI / ĐÃ LƯU / KHÁM PHÁ
import 'package:flutter/material.dart';
import '../widgets/base_scaffold.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../main.dart' show TabNavigator;
import '../models/flashcard_set.dart';
import '../services/flashcard_service.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import '../widgets/set_card.dart';
import 'add_set_page.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> with SingleTickerProviderStateMixin {
  static const _tabKeys = ['mine', 'saved', 'explore'];
  late final TabController _tabController = TabController(length: 3, vsync: this);
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  late final TabNavigator _nav;
  String _query = '';
  String _subject = 'Tất cả';
  String _sort = 'updated'; // 'updated' | 'name'

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.trim().toLowerCase()));
    _tabController.addListener(() => setState(() {}));
    _nav = context.read<TabNavigator>();
    _nav.addListener(_onNavRequest);
    WidgetsBinding.instance.addPostFrameCallback((_) => _onNavRequest());
  }

  // Trang chủ có thể mở Thư viện ở một tab cụ thể
  void _onNavRequest() {
    if (_nav.index != TabNavigator.library) return;
    final req = _nav.takeLibraryRequest();
    if (req.tab != null) _tabController.animateTo(_tabKeys.indexOf(req.tab!));
    if (req.focusSearch) _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<FlashcardService>();

    return BaseScaffold(
      title: "Thư viện",
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          tooltip: "Tạo bộ thẻ",
          onPressed: _createSet,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(108),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocus,
                decoration: InputDecoration(
                  hintText: "Tìm theo tên hoặc mô tả",
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: _searchController.clear)
                      : null,
                  filled: true,
                  fillColor: context.palette.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            TabBar(
              controller: _tabController,
              isScrollable: Breakpoints.isCompact(context),
              tabAlignment: Breakpoints.isCompact(context) ? TabAlignment.start : null,
              tabs: [
                Tab(text: "Của tôi (${service.myDecks.length})"),
                Tab(text: "Đã lưu (${service.savedIds.length})"),
                const Tab(text: "Khám phá"),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          if (!service.isLoaded)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else ...[
            _buildFilters(),
            Expanded(child: _buildList(service)),
          ],
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          for (final s in ['Tất cả', ...kSubjects])
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(s),
                selected: _subject == s,
                onSelected: (_) => setState(() => _subject = s),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(FlashcardService service) {
    final tab = _tabKeys[_tabController.index];
    List<FlashcardSet> available;
    List<String> missing = [];
    if (tab == 'mine') {
      available = service.myDecks;
    } else if (tab == 'saved') {
      available = [];
      for (final id in service.savedIds) {
        final d = service.deckById(id);
        if (service.isAvailable(d)) {
          available.add(d!);
        } else {
          missing.add(id);
        }
      }
    } else {
      available = service.exploreDecks;
    }

    if (available.isEmpty && missing.isEmpty) {
      return _buildTabEmpty(tab);
    }

    final shown = available
        .where((d) => _query.isEmpty || '${d.title} ${d.description}'.toLowerCase().contains(_query))
        .where((d) => _subject == 'Tất cả' || d.subject == _subject)
        .toList();
    if (_sort == 'name') {
      shown.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    } else {
      shown.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    }
    final filtered = _query.isNotEmpty || _subject != 'Tất cả';

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "${shown.length} bộ thẻ${filtered ? ' khớp bộ lọc' : ''}",
                  style: TextStyle(fontSize: 12, color: context.palette.textMuted),
                ),
              ),
              Text("Sắp xếp ", style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
              DropdownButton<String>(
                value: _sort,
                underline: const SizedBox.shrink(),
                style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface),
                items: const [
                  DropdownMenuItem(value: 'updated', child: Text("Mới cập nhật")),
                  DropdownMenuItem(value: 'name', child: Text("Tên A–Z")),
                ],
                onChanged: (v) => setState(() => _sort = v ?? 'updated'),
              ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty && missing.isEmpty
              ? EmptyState(
            icon: Icons.search_off,
            title: "Không tìm thấy bộ thẻ phù hợp",
            message: "Không có kết quả cho ${_query.isNotEmpty ? '"${_searchController.text.trim()}"' : 'bộ lọc này'}"
                "${_subject != 'Tất cả' ? ' trong môn $_subject' : ''}.",
            actions: [
              OutlinedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() => _subject = 'Tất cả');
                },
                child: const Text("Xóa bộ lọc"),
              ),
            ],
          )
              : LayoutBuilder(
            builder: (context, c) => GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              gridDelegate: setGridDelegate(c.maxWidth),
              itemCount: shown.length + missing.length,
              itemBuilder: (context, i) {
                if (i >= shown.length) {
                  final id = missing[i - shown.length];
                  return UnavailableSetCard(onUnsave: () => _toggleSave(service, id));
                }
                final d = shown[i];
                final own = service.isOwner(d);
                return SetCard(
                  set: d,
                  index: i,
                  ownerLabel: own ? "Bạn" : d.ownerName,
                  knownCount: service.touched(d) ? service.knownIn(d) : null,
                  isSaved: own ? null : service.isSaved(d.id),
                  onToggleSave: own ? null : () => _toggleSave(service, d.id),
                  onTap: () => openDeck(context, d.id),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabEmpty(String tab) {
    switch (tab) {
      case 'mine':
        return EmptyState(
          icon: Icons.folder_open,
          title: "Bạn chưa có bộ thẻ nào",
          message: "Tạo bộ thẻ đầu tiên để bắt đầu học bằng flashcard và quiz.",
          actions: [
            ElevatedButton.icon(onPressed: _createSet, icon: const Icon(Icons.add), label: const Text("Tạo bộ thẻ")),
          ],
        );
      case 'saved':
        return EmptyState(
          icon: Icons.bookmark_border,
          title: "Chưa lưu bộ thẻ nào",
          message: "Lưu bộ thẻ công khai để học lại nhanh. Lưu chỉ là đánh dấu, không tạo bản sao.",
          actions: [
            ElevatedButton(onPressed: () => _tabController.animateTo(2), child: const Text("Khám phá bộ thẻ")),
          ],
        );
      default:
        return const EmptyState(
          icon: Icons.public,
          title: "Chưa có bộ thẻ công khai",
          message: "Khi người dùng khác chia sẻ bộ thẻ, chúng sẽ xuất hiện ở đây.",
        );
    }
  }

  Future<void> _toggleSave(FlashcardService service, String id) async {
    final wasSaved = service.isSaved(id);
    if (await service.toggleSave(id)) {
      if (mounted) showSnack(context, wasSaved ? "Đã bỏ khỏi danh sách Đã lưu" : "Đã lưu vào Thư viện › Đã lưu");
    } else if (mounted) {
      showSaveError(context, () => _toggleSave(service, id));
    }
  }

  Future<void> _createSet() =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AddSetPage()));

  @override
  void dispose() {
    _nav.removeListener(_onNavRequest);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }
}
