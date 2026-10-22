// pages/learn_rounds_page.dart - HỌC THEO LƯỢT (trắc nghiệm có phản hồi ngay)
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../logic/learn_engine.dart';
import '../models/quiz.dart';
import '../services/flashcard_service.dart';
import '../utils/date_utils.dart';
import '../utils/nav.dart';
import '../widgets/common.dart';
import 'quiz_setup_page.dart';

class LearnRoundsPage extends StatefulWidget {
  final String deckId;
  const LearnRoundsPage({super.key, required this.deckId});

  @override
  State<LearnRoundsPage> createState() => _LearnRoundsPageState();
}

class _LearnRoundsPageState extends State<LearnRoundsPage> {
  static const _praise = ['Tuyệt vời!', 'Chính xác!', 'Làm tốt lắm!', 'Bạn nhớ rất tốt!'];
  late final FlashcardService _service = context.read<FlashcardService>();
  final Random _random = Random();
  LearnSession? _session;
  Timer? _autoNext;
  String _praiseText = '';
  bool _starredOnly = false; // Chỉ học thẻ gắn sao: không ghi đè tiến độ phần Học của cả bộ
  final TextEditingController _typed = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Còn phần Học làm dở thì làm tiếp; đã xong hết thì bắt đầu lại
    final deck = _service.deckById(widget.deckId);
    final saved = _service.learnScoreOf(widget.deckId);
    if (deck != null && saved != null && _service.learnCompletion(deck) < 1) {
      _session = LearnSession(
        deck,
        random: _random,
        savedScore: saved,
        savedRound: _service.learnRoundOf(widget.deckId),
      );
      _service.setLastDeck(widget.deckId);
    } else {
      _restart();
    }
  }

  void _restart({bool starredOnly = false}) {
    final deck = _service.deckById(widget.deckId);
    final old = _session;
    _autoNext?.cancel();
    _typed.clear();
    setState(() {
      _starredOnly = starredOnly;
      _session = deck == null
          ? null
          : (LearnSession(
                deck,
                random: _random,
                written: old?.written ?? false,
                onlyCardIds: starredOnly ? deck.cards.map((c) => c.id).where(_service.isStarred).toSet() : null,
              )
              ..reverse = old?.reverse ?? false
              ..shuffle = old?.shuffle ?? true);
    });
    _service.setLastDeck(widget.deckId);
    if (!starredOnly) _service.resetLearn(widget.deckId);
  }

  // -1: "Bạn không biết?"
  void _pick(int choice) {
    final s = _session!;
    if (s.isAnswered) return;
    final cardId = s.question!.cardId;
    final result = s.answer(choice);
    _praiseText = _praise[_random.nextInt(_praise.length)];
    setState(() {});
    // Lưu tiến độ ngay sau mỗi câu: thoát giữa chừng không mất kết quả
    final save = _starredOnly ? null : s;
    _service.recordLearnAnswer(cardId, result, session: save).then((ok) {
      if (!ok && mounted) showSaveError(context, () => _service.recordLearnAnswer(cardId, result, session: save));
    });
    _autoNext?.cancel();
    if (result.correct) {
      _autoNext = Timer(const Duration(milliseconds: 1100), () {
        if (mounted && identical(s, _session)) _next();
      });
    }
  }

  // Câu tự luận: chấm theo nội dung đã gõ
  void _submitTyped() {
    final s = _session!;
    final text = _typed.text.trim();
    if (s.isAnswered || text.isEmpty) return;
    FocusScope.of(context).unfocus();
    _pick(writtenMatches(text, s.question!.correctText) ? 0 : 1);
  }

  void _next() {
    _autoNext?.cancel();
    _typed.clear();
    final finished = _session!.next();
    if (finished) _service.completeSession();
    setState(() {});
  }

  // Thoát ngay: điểm từng câu đã lưu sau mỗi lần trả lời, mở lại sẽ làm tiếp
  void _close() {
    _autoNext?.cancel();
    Navigator.pop(context);
  }

  void _showSettings() {
    final s = _session!;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text("Trộn thứ tự thẻ"),
                subtitle: const Text("Áp dụng từ lượt sau"),
                value: s.shuffle,
                onChanged: (v) => setSheet(() => s.shuffle = v),
              ),
              SwitchListTile(
                title: const Text("Câu hỏi tự luận"),
                subtitle: const Text("Thẻ đã đúng 1 lần sẽ hỏi bằng cách gõ đáp án · từ câu sau"),
                value: s.written,
                onChanged: (v) => setSheet(() => s.written = v),
              ),
              SwitchListTile(
                title: const Text("Trả lời bằng thuật ngữ"),
                subtitle: const Text("Hỏi định nghĩa, chọn thuật ngữ · từ câu sau"),
                value: s.reverse,
                onChanged: (v) => setSheet(() => s.reverse = v),
              ),
              if (_starredOnly || s.deck.cards.where((c) => c.isValid && _service.isStarred(c.id)).length >= 2)
                ListTile(
                  leading: Icon(_starredOnly ? Icons.style : Icons.star),
                  title: Text(_starredOnly ? "Học tất cả thẻ" : "Chỉ học thẻ gắn sao"),
                  onTap: () {
                    Navigator.pop(ctx);
                    if (_starredOnly) {
                      final deck = s.deck;
                      final saved = _service.learnScoreOf(deck.id);
                      setState(() {
                        _starredOnly = false;
                        _session =
                            LearnSession(
                                deck,
                                random: _random,
                                written: s.written,
                                savedScore: saved,
                                savedRound: _service.learnRoundOf(deck.id),
                              )
                              ..reverse = s.reverse
                              ..shuffle = s.shuffle;
                      });
                    } else {
                      _restart(starredOnly: true);
                    }
                  },
                ),
              ListTile(
                leading: const Icon(Icons.restart_alt),
                title: const Text("Học lại từ đầu"),
                onTap: () {
                  Navigator.pop(ctx);
                  _restart();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _session;
    if (s == null || s.cardIds.length < 2) {
      return Scaffold(
        appBar: AppBar(title: const Text("Học")),
        body: const EmptyState(icon: Icons.school, title: "Cần ít nhất 2 thẻ hợp lệ để học"),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close), onPressed: _close),
          title: Text(s.phase == LearnPhase.done ? "Hoàn thành" : "Lượt ${s.round}"),
          centerTitle: true,
          actions: [
            if (s.phase != LearnPhase.done)
              IconButton(icon: const Icon(Icons.settings), tooltip: "Tùy chọn", onPressed: _showSettings),
          ],
        ),
        body: ResponsiveBody(
          child: Column(
            children: [
              const OfflineBanner(),
              _buildProgress(s),
              Expanded(
                child: ClipRect(
                  // Chuyển câu / sang màn tổng kết: trượt từ phải sang
                  child: AnimatedSwitcher(
                    duration: motion(context, 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, anim) {
                      final incoming = child.key == _stepKey(s);
                      return SlideTransition(
                        position: Tween(begin: Offset(incoming ? 1 : -1, 0), end: Offset.zero).animate(anim),
                        child: child,
                      );
                    },
                    child: KeyedSubtree(
                      key: _stepKey(s),
                      child: switch (s.phase) {
                        LearnPhase.question => _buildQuestion(s),
                        LearnPhase.roundSummary => _buildRoundSummary(s),
                        LearnPhase.done => _buildDone(s),
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(padding: const EdgeInsets.all(16), child: _buildBottom(s)),
        ),
      ),
    );
  }

  ValueKey<String> _stepKey(LearnSession s) =>
      ValueKey('${s.phase.name}_${s.round}_${s.queueIndex}_${identityHashCode(s)}');

  Widget _buildProgress(LearnSession s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          AnimatedProgressBar(
            value: s.target == 0 ? 0 : s.achieved / s.target,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
            backgroundColor: context.palette.border,
            color: context.palette.success,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Đạt ${s.achieved}/${s.target}", style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
              Text(
                "Thành thạo ${s.masteredCount}/${s.cardIds.length} thẻ",
                style: TextStyle(fontSize: 12, color: context.palette.textMuted),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(LearnSession s) {
    final q = s.question!;
    final done = s.isAnswered;
    final ok = s.lastAnswerCorrect;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                if (s.isRetry)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: context.palette.warningBg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text("Hãy thử lại lần nữa", style: TextStyle(fontSize: 12, color: context.palette.text)),
                  ),
                Text(
                  q.question,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          !done
              ? (q.isWritten ? "Gõ đáp án đúng" : "Chọn đáp án đúng")
              : ok
              ? _praiseText
              : s.answered == -1
              ? "Không sao, hãy ghi nhớ đáp án này nhé!"
              : "Đừng nản chí, học là một quá trình!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: !done
                ? context.palette.textMuted
                : ok
                ? context.palette.success
                : context.palette.error,
          ),
        ),
        const SizedBox(height: 12),
        if (q.isWritten) _buildWritten(s) else for (var i = 0; i < q.options.length; i++) _buildOption(s, i),
      ],
    );
  }

  Widget _buildWritten(LearnSession s) {
    final p = context.palette;
    final q = s.question!;
    final done = s.isAnswered;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Shake(
          active: done && !s.lastAnswerCorrect && s.answered != -1,
          child: TextField(
            controller: _typed,
            enabled: !done,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submitTyped(),
            decoration: InputDecoration(
              hintText: "Gõ đáp án",
              enabledBorder: done
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      borderSide: BorderSide(color: s.lastAnswerCorrect ? p.success : p.error, width: 2),
                    )
                  : null,
              disabledBorder: done
                  ? OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.medium),
                      borderSide: BorderSide(color: s.lastAnswerCorrect ? p.success : p.error, width: 2),
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (!done)
          ValueListenableBuilder(
            valueListenable: _typed,
            builder: (context, v, _) =>
                ElevatedButton(onPressed: v.text.trim().isEmpty ? null : _submitTyped, child: const Text("Trả lời")),
          )
        else if (!s.lastAnswerCorrect)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.successBg,
              borderRadius: BorderRadius.circular(AppRadius.medium),
              border: Border.all(color: p.success, width: 2),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text("Đáp án đúng: ${q.correctText}", style: TextStyle(color: p.text, fontSize: 16)),
                ),
                Icon(Icons.check_circle, color: p.success),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOption(LearnSession s, int i) {
    final q = s.question!;
    final done = s.isAnswered;
    Color? bg;
    Color border = context.palette.border;
    IconData? icon;
    if (done) {
      if (i == q.correctIndex) {
        bg = context.palette.successBg;
        border = context.palette.success;
        icon = Icons.check_circle;
      } else if (i == s.answered) {
        bg = context.palette.errorBg;
        border = context.palette.error;
        icon = Icons.cancel;
      }
    }
    // Sai: rung lựa chọn vừa chọn; đúng: đáp án đúng nảy nhẹ
    return Shake(
      active: done && i == s.answered && i != q.correctIndex,
      child: AnimatedScale(
        scale: done && i == q.correctIndex && s.lastAnswerCorrect ? 1.03 : 1,
        duration: motion(context, 180),
        curve: Curves.easeOutBack,
        child: _optionCard(s, i, bg, border, icon),
      ),
    );
  }

  Widget _optionCard(LearnSession s, int i, Color? bg, Color border, IconData? icon) {
    final q = s.question!;
    final done = s.isAnswered;
    return AnimatedContainer(
      duration: motion(context, 180),
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: bg ?? context.palette.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border, width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: done ? null : () => _pick(i),
          title: Text(q.options[i], style: TextStyle(color: bg != null ? context.palette.text : null, fontSize: 16)),
          trailing: icon != null ? Icon(icon, color: border) : null,
        ),
      ),
    );
  }

  Widget _buildRoundSummary(LearnSession s) {
    final deck = _service.deckById(widget.deckId)!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text("Bạn đã xong lượt ${s.round}", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          "Đã đạt ${s.achieved}/${s.target}. Thẻ trả lời sai sẽ được hỏi lại ở lượt sau.",
          style: TextStyle(color: context.palette.textMuted),
        ),
        const SizedBox(height: 12),
        for (final e in s.roundLog)
          Builder(
            builder: (_) {
              final card = deck.cards.firstWhere((c) => c.id == e.cardId);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: e.correct ? context.palette.successBg : context.palette.errorBg,
                    child: Icon(
                      e.correct ? Icons.check : Icons.close,
                      color: e.correct ? context.palette.success : context.palette.error,
                    ),
                  ),
                  title: Text(card.term, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(card.meaning),
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDone(LearnSession s) {
    final deck = _service.deckById(widget.deckId)!;
    final dur = DateTime.now().difference(s.startedAt).inSeconds;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 16),
        PopIn(child: Icon(Icons.emoji_events, size: 80, color: context.palette.yellow)),
        const SizedBox(height: 12),
        Text(
          "Bạn đã thành thạo ${s.cardIds.length} thẻ",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          "${deck.title} · ${s.round} lượt · ${formatDurationLong(dur)}",
          textAlign: TextAlign.center,
          style: TextStyle(color: context.palette.textMuted),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _tile("Câu đã trả lời", "${s.answers}", context.palette.brandText),
            _tile("Lần trả lời sai", "${s.wrongs}", context.palette.error),
          ],
        ),
      ],
    );
  }

  Widget _tile(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
              ),
              Text(label, style: TextStyle(fontSize: 12, color: context.palette.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottom(LearnSession s) {
    switch (s.phase) {
      case LearnPhase.question:
        return s.isAnswered
            ? ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Tiếp tục"),
              )
            : TextButton(
                onPressed: () => _pick(-1),
                style: TextButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                child: const Text("Bạn không biết?"),
              );
      case LearnPhase.roundSummary:
        return ElevatedButton(
          onPressed: () {
            setState(s.nextRound);
            _service.saveLearnRound(widget.deckId, s.round);
          },
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
          child: Text("Tiếp tục lượt ${s.round + 1}"),
        );
      case LearnPhase.done:
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => QuizSetupPage(deckId: widget.deckId)),
              ),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
              child: const Text("Làm bài Kiểm tra"),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _restart, child: const Text("Học lại")),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => backToDeck(context, widget.deckId),
                    child: const Text("Về bộ thẻ"),
                  ),
                ),
              ],
            ),
          ],
        );
    }
  }

  @override
  void dispose() {
    _autoNext?.cancel();
    _typed.dispose();
    super.dispose();
  }
}
