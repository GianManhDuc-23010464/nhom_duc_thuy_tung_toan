// pages/learn_page.dart - HỌC BẰNG THẺ GHI NHỚ
// Chạm để lật; gạt trái: Đang học, gạt phải: Đã biết. Có hoàn tác và tự động phát.
import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'package:provider/provider.dart';
import '../models/flashcard.dart';
import '../services/flashcard_service.dart';
import '../services/speech_service.dart';
import '../widgets/common.dart';
import '../widgets/flip_card.dart';
import 'study_summary_page.dart';

class LearnPage extends StatefulWidget {
  final String deckId;
  final List<String>? cardIds; // Học một nhóm thẻ (gắn sao, đang học...)
  final int startIndex;
  const LearnPage({super.key, required this.deckId, this.cardIds, this.startIndex = 0});

  @override
  State<LearnPage> createState() => _LearnPageState();
}

class _LearnPageState extends State<LearnPage> {
  static const _autoDelay = Duration(seconds: 3);
  late final FlashcardService _service = context.read<FlashcardService>();
  final FlipCardController _flipController = FlipCardController();
  late List<String> _order;
  int currentIndex = 0;
  bool _flipped = false;
  bool _shuffled = false;
  bool _autoPlay = false;
  bool _backFirst = false; // Đảo mặt: hiện mặt sau trước
  Offset _enterFrom = Offset.zero; // Hướng thẻ xuất hiện (hoàn tác: bay về từ bên đã gạt)
  Timer? _autoTimer;
  final Set<String> _seen = {}; // Thẻ đã lật xem trong phiên
  final Set<String> _known = {}; // Gạt phải
  final Set<String> _learning = {}; // Gạt trái
  final List<int> _history = []; // Vị trí các thẻ đã qua, để hoàn tác
  final DateTime _start = DateTime.now();

  bool get _isSubset => widget.cardIds != null;

  @override
  void initState() {
    super.initState();
    final deck = _service.deckById(widget.deckId);
    final valid = deck?.validCards ?? [];
    _order = _isSubset
        ? widget.cardIds!.where((id) => valid.any((c) => c.id == id)).toList()
        : valid.map((c) => c.id).toList();
    currentIndex = widget.startIndex.clamp(0, _order.isEmpty ? 0 : _order.length - 1);
    // Học tiếp lượt dở: khôi phục số thẻ Đã biết / Đang học
    if (!_isSubset && currentIndex > 0) {
      _service.flashSortOf(widget.deckId).forEach((id, known) {
        if (_order.contains(id)) (known ? _known : _learning).add(id);
      });
    } else if (!_isSubset) {
      _service.saveFlashSort(widget.deckId, {});
    }
    _service.setLastDeck(widget.deckId);
  }

  void _saveSort() {
    if (_isSubset) return;
    _service.saveFlashSort(widget.deckId, {for (final id in _known) id: true, for (final id in _learning) id: false});
  }

  Flashcard? _cardAt(int i) {
    final deck = _service.deckById(widget.deckId);
    if (deck == null || i >= _order.length) return null;
    for (final c in deck.cards) {
      if (c.id == _order[i]) return c;
    }
    return null;
  }

  // Lật thẻ lần đầu: tính lượt học, thẻ chuyển sang Đang học
  void _onFlip(bool showingBack) {
    setState(() => _flipped = showingBack);
    if (showingBack) _markSeen(_order[currentIndex]);
  }

  void _markSeen(String id) {
    if (_seen.add(id)) _service.recordFlashcardSeen(id);
  }

  // Thẻ đã gạt xong: bỏ qua nếu thẻ hiện tại đã đổi (hoàn tác / tự động phát trong lúc thẻ đang bay)
  void _onSwiped(String cardId, bool known) {
    if (currentIndex >= _order.length || _order[currentIndex] != cardId) return;
    _advance(known);
  }

  // Sang thẻ sau; known: true gạt phải, false gạt trái, null tự động phát
  void _advance(bool? known) {
    final id = _order[currentIndex];
    _markSeen(id);
    if (known != null) {
      (known ? _known : _learning).add(id);
      (known ? _learning : _known).remove(id);
      _saveSort();
    }
    _enterFrom = Offset.zero;
    _history.add(currentIndex);
    final j = currentIndex + 1;
    if (j >= _order.length) {
      _finish();
      return;
    }
    setState(() {
      currentIndex = j;
      _flipped = false;
    });
    // Ghi nhớ vị trí để lần sau học tiếp
    if (!_isSubset && !_shuffled) _service.savePosition(widget.deckId, j);
    _scheduleAuto();
  }

  // Quay lại thẻ trước, bỏ phân loại của thẻ đó
  void _undo() {
    if (_history.isEmpty) return;
    final i = _history.removeLast();
    final id = _order[i];
    final width = MediaQuery.sizeOf(context).width;
    setState(() {
      // Thẻ bay về từ phía đã gạt
      _enterFrom = _known.contains(id)
          ? Offset(width, 0)
          : _learning.contains(id)
          ? Offset(-width, 0)
          : Offset.zero;
      _known.remove(id);
      _learning.remove(id);
      currentIndex = i;
      _flipped = false;
    });
    if (!_isSubset && !_shuffled) _service.savePosition(widget.deckId, i);
    _saveSort();
    _scheduleAuto();
  }

  // Tự động phát: lật thẻ sau 3 giây, 3 giây sau sang thẻ tiếp theo
  void _scheduleAuto() {
    _autoTimer?.cancel();
    if (!_autoPlay) return;
    _autoTimer = Timer(_autoDelay, () {
      if (!mounted || !_autoPlay) return;
      if (!_flipped) {
        _flipController.flip();
        _scheduleAuto();
      } else {
        _advance(null);
      }
    });
  }

  void _toggleAutoPlay() {
    setState(() => _autoPlay = !_autoPlay);
    _scheduleAuto();
  }

  void _finish() {
    _autoTimer?.cancel();
    if (!_isSubset && !_shuffled) _service.savePosition(widget.deckId, 0);
    if (!_isSubset) _service.saveFlashSort(widget.deckId, {});
    if (_seen.isNotEmpty) _service.completeSession();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => StudySummaryPage(
          deckId: widget.deckId,
          total: _order.length,
          seen: _seen.length,
          knownCount: _known.length,
          learningIds: _order.where(_learning.contains).toList(),
          starredIds: _order.where(_service.isStarred).toList(),
          durationSeconds: DateTime.now().difference(_start).inSeconds,
        ),
      ),
    );
  }

  // Thoát ngay: vị trí thẻ đã được lưu sau mỗi lần chuyển thẻ
  void _close() {
    _autoTimer?.cancel();
    if (_seen.isNotEmpty) _service.completeSession();
    Navigator.pop(context);
  }

  Future<void> _toggleStar(String cardId) async {
    if (!await _service.toggleStar(cardId) && mounted) {
      showSaveError(context, () => _toggleStar(cardId));
    }
  }

  Future<void> _speak(Flashcard card) async {
    final showingTerm = _flipped == _backFirst;
    if (!await SpeechService().speak(showingTerm ? card.term : card.meaning) && mounted) {
      showSnack(context, "Thiết bị này chưa hỗ trợ đọc to.");
    }
  }

  void _showSettings(Flashcard card) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (ctx, setSheet) => SwitchListTile(
                secondary: const Icon(Icons.swap_horiz),
                title: const Text("Hiện mặt sau trước"),
                subtitle: const Text("Đảo mặt trước và mặt sau của thẻ"),
                value: _backFirst,
                onChanged: (v) {
                  setSheet(() {});
                  setState(() {
                    _backFirst = v;
                    _flipped = false;
                  });
                },
              ),
            ),
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text("Xáo trộn thẻ"),
              subtitle: const Text("Vị trí học không được ghi nhớ trong lượt này"),
              onTap: () {
                Navigator.pop(ctx);
                setState(() {
                  _order.shuffle();
                  _shuffled = true;
                  _restartState();
                });
                _scheduleAuto();
              },
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt),
              title: const Text("Học lại từ đầu"),
              onTap: () {
                Navigator.pop(ctx);
                setState(_restartState);
                if (!_isSubset && !_shuffled) _service.savePosition(widget.deckId, 0);
                _saveSort();
                _scheduleAuto();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _restartState() {
    currentIndex = 0;
    _flipped = false;
    _enterFrom = Offset.zero;
    _known.clear();
    _learning.clear();
    _history.clear();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<FlashcardService>();
    final p = context.palette;
    final deck = _service.deckById(widget.deckId);
    final card = _cardAt(currentIndex);

    if (deck == null || card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Thẻ ghi nhớ")),
        body: const EmptyState(icon: Icons.lightbulb_outline, title: "Không có thẻ nào để học"),
      );
    }

    final starred = _service.isStarred(card.id);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close, size: 28), tooltip: "Đóng", onPressed: _close),
          title: Text(
            "${currentIndex + 1} / ${_order.length}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textMuted),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, size: 28),
              tooltip: "Tùy chọn",
              onPressed: () => _showSettings(card),
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: AnimatedProgressBar(value: currentIndex / _order.length, backgroundColor: p.border, color: p.text),
          ),
          shape: const Border(),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            // ĐẾM THẺ: trái Đang học (cam), phải Đã biết (xanh)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _countPill(_learning.length, p.warning, p.warningBg, left: true),
                  const Spacer(),
                  _countPill(_known.length, p.success, p.successBg, left: false),
                ],
              ),
            ),
            Expanded(
              child: ResponsiveBody(
                child: LayoutBuilder(builder: (context, box) => _buildSwipeCard(card, starred, box.maxHeight - 8)),
              ),
            ),
            // ĐIỀU KHIỂN: hoàn tác · gợi ý · tự động phát
            SafeArea(
              top: false,
              child: ResponsiveBody(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.undo, size: 30),
                        tooltip: "Quay lại thẻ trước",
                        onPressed: _history.isEmpty ? null : _undo,
                        color: p.text,
                      ),
                      Expanded(
                        child: Text(
                          _flipped ? "Gạt trái: đang học · phải: đã biết" : "Chạm vào thẻ để lật",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: p.text),
                        ),
                      ),
                      IconButton(
                        icon: Icon(_autoPlay ? Icons.pause : Icons.play_arrow, size: 32),
                        tooltip: _autoPlay ? "Tắt tự động phát" : "Bật tự động phát",
                        onPressed: _toggleAutoPlay,
                        color: _autoPlay ? p.brandText : p.text,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Thẻ gạt được: phải = Đã biết, trái = Đang học
  Widget _buildSwipeCard(Flashcard card, bool starred, double height) {
    final p = context.palette;
    return TweenAnimationBuilder<double>(
      key: ValueKey('enter_${card.id}_$currentIndex'),
      tween: Tween(begin: 0, end: 1),
      duration: motion(context, _enterFrom == Offset.zero ? 220 : 320),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.translate(
        offset: _enterFrom * (1 - t),
        child: Transform.scale(
          scale: 0.94 + 0.06 * t,
          child: Opacity(opacity: t, child: child),
        ),
      ),
      child: SwipeCard(
        key: const ValueKey('swipe-card'),
        cardKey: '${card.id}_$currentIndex',
        knownColor: p.success,
        knownBg: p.successBg,
        learningColor: p.warning,
        learningBg: p.warningBg,
        onSwiped: (known) => _onSwiped(card.id, known),
        child: Stack(
          children: [
            FlipCard(
              key: ValueKey('flip_${card.id}_${currentIndex}_$_backFirst'),
              frontText: _backFirst ? card.meaning : card.term,
              backText: _backFirst ? card.term : card.meaning,
              imagePath: _backFirst ? null : card.imagePath,
              explain: card.note,
              height: height,
              fontSize: 30,
              showSideLabel: false,
              controller: _flipController,
              onFlip: _onFlip,
            ),
            // Phát âm và gắn sao ở góc phải trên
            Positioned(
              top: 12,
              right: 28,
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => _speak(card),
                    tooltip: "Phát âm",
                    icon: Icon(Icons.volume_up_outlined, size: 28, color: p.textMuted),
                  ),
                  IconButton(
                    onPressed: () => _toggleStar(card.id),
                    tooltip: starred ? "Bỏ gắn sao" : "Gắn sao",
                    icon: AnimatedSwitcher(
                      duration: motion(context, 300),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: CurvedAnimation(parent: anim, curve: Curves.elasticOut),
                        child: child,
                      ),
                      child: Icon(
                        starred ? Icons.star : Icons.star_border,
                        key: ValueKey(starred),
                        size: 30,
                        color: starred ? p.yellow : p.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Ô đếm nằm sát mép màn hình
  Widget _countPill(int n, Color fg, Color bg, {required bool left}) {
    const r = Radius.circular(24);
    return Container(
      constraints: const BoxConstraints(minWidth: 56),
      padding: EdgeInsets.fromLTRB(left ? 16 : 20, 8, left ? 20 : 16, 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: fg.withValues(alpha: 0.5), width: 1.5),
        borderRadius: left
            ? const BorderRadius.only(topRight: r, bottomRight: r)
            : const BorderRadius.only(topLeft: r, bottomLeft: r),
      ),
      child: Align(
        alignment: left ? Alignment.centerLeft : Alignment.centerRight,
        widthFactor: 1,
        child: AnimatedCount(
          n,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: fg),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _flipController.dispose();
    super.dispose();
  }
}

// Thẻ kéo theo ngón tay, nghiêng theo hướng kéo. Thả chưa đủ ngưỡng thì bật về chỗ cũ,
// đủ ngưỡng (30% bề rộng hoặc vuốt nhanh) thì bay khỏi màn hình rồi báo [onSwiped].
class SwipeCard extends StatefulWidget {
  final Widget child;
  final String cardKey; // Đổi khi sang thẻ khác để đặt lại vị trí
  final ValueChanged<bool> onSwiped; // true: gạt phải
  final Color knownColor, knownBg, learningColor, learningBg;

  const SwipeCard({
    super.key,
    required this.child,
    required this.cardKey,
    required this.onSwiped,
    required this.knownColor,
    required this.knownBg,
    required this.learningColor,
    required this.learningBg,
  });

  @override
  State<SwipeCard> createState() => _SwipeCardState();
}

class _SwipeCardState extends State<SwipeCard> with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(vsync: this);
  Offset _drag = Offset.zero;
  Animation<Offset>? _anim;
  bool _flying = false;
  double _width = 400;

  Offset get _offset => _anim?.value ?? _drag;

  @override
  void didUpdateWidget(SwipeCard old) {
    super.didUpdateWidget(old);
    if (old.cardKey != widget.cardKey) {
      _ctl.stop();
      _anim = null;
      _drag = Offset.zero;
      _flying = false;
    }
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_flying) return;
    _ctl.stop();
    setState(() {
      _drag = _offset + Offset(d.delta.dx, d.delta.dy * 0.2);
      _anim = null;
    });
  }

  void _onEnd(DragEndDetails d) {
    if (_flying) return;
    final width = _width;
    final vx = d.velocity.pixelsPerSecond.dx;
    final dx = _drag.dx;
    final swipe = dx.abs() > width * 0.3 || (vx.abs() > 900 && vx.sign == dx.sign && dx.abs() > 20);
    if (swipe) {
      _flying = true;
      final right = dx > 0;
      final key = widget.cardKey;
      _animateTo(Offset((right ? 1.5 : -1.5) * width, _drag.dy), motion(context, 240), Curves.easeIn).then((_) {
        if (mounted && key == widget.cardKey) widget.onSwiped(right);
      });
    } else {
      // Bật về chỗ cũ có độ đàn hồi
      _animateTo(Offset.zero, motion(context, 520), Curves.elasticOut).then((_) {
        if (mounted && !_flying) setState(() => _drag = Offset.zero);
      });
    }
  }

  Future<void> _animateTo(Offset target, Duration duration, Curve curve) {
    if (duration == Duration.zero) {
      setState(() {
        _anim = null;
        _drag = target;
      });
      return Future.value();
    }
    _anim = Tween(begin: _drag, end: target).animate(CurvedAnimation(parent: _ctl, curve: curve));
    _ctl.duration = duration;
    return _ctl.forward(from: 0).orCancel.catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _width = box.maxWidth.isFinite ? box.maxWidth : 400;
        return GestureDetector(
          onHorizontalDragUpdate: _onUpdate,
          onHorizontalDragEnd: _onEnd,
          child: AnimatedBuilder(
            animation: _ctl,
            builder: (context, child) {
              final o = _offset;
              final width = _width;
              final t = (o.dx.abs() / (width * 0.3)).clamp(0.0, 1.0);
              final right = o.dx > 0;
              return Transform.translate(
                offset: o,
                child: Transform.rotate(
                  angle: o.dx / width * 0.25,
                  child: Stack(
                    children: [
                      child!,
                      // Nhãn hiện dần khi kéo
                      if (t > 0)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: t,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: (right ? widget.knownBg : widget.learningBg).withValues(alpha: 0.92),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: right ? widget.knownColor : widget.learningColor, width: 2),
                                ),
                                child: Text(
                                  right ? "Đã biết" : "Đang học",
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w800,
                                    color: right ? widget.knownColor : widget.learningColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
            child: widget.child,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }
}
