// pages/test_page.dart - LÀM BÀI KIỂM TRA: chọn xong tự trượt sang câu sau, câu cuối có màn nộp bài
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import 'package:uuid/uuid.dart';
import '../logic/quiz_engine.dart';
import '../models/quiz.dart';
import '../services/connectivity_service.dart';
import '../services/flashcard_service.dart';
import '../utils/date_utils.dart';
import '../widgets/common.dart';
import 'quiz_result_page.dart';

class TestPage extends StatefulWidget {
  final QuizDraft draft; // Bài mới hoặc bản nháp đang làm dở

  const TestPage({super.key, required this.draft});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with WidgetsBindingObserver {
  late final FlashcardService _service = context.read<FlashcardService>();
  late final QuizDraft _q = widget.draft;
  final Stopwatch _stopwatch = Stopwatch()..start();
  late final int _elapsedBefore = widget.draft.elapsedSeconds;
  Timer? _ticker;
  bool _submitted = false;
  bool _advancing = false; // Đang chờ trượt sang câu sau
  bool _forward = true; // Hướng trượt
  late final TextEditingController _typedController = TextEditingController(
    text: widget.draft.typed[widget.draft.currentIndex] ?? '',
  );

  int get _elapsed => _elapsedBefore + _stopwatch.elapsed.inSeconds;
  int? get _remaining => _q.limitSeconds == null ? null : (_q.limitSeconds! - _elapsed).clamp(0, _q.limitSeconds!);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _submitted) return;
      if (_remaining == 0) {
        _submit(auto: true);
      } else if (_q.limitSeconds != null) {
        setState(() {});
      }
    });
  }

  // Ứng dụng xuống nền: lưu nháp để có thể làm tiếp
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _saveDraft();
    }
  }

  Future<bool> _saveDraft() {
    if (_submitted) return Future.value(true);
    _q.elapsedSeconds = _elapsed;
    return _service.saveQuizDraft(_q);
  }

  int get _total => _q.questions.length;
  bool get _atEnd => _q.currentIndex >= _total;
  // Hiện đáp án ngay: câu đã trả lời thì khóa, không chọn lại
  bool _locked(int i) => _q.instantFeedback && _q.answers.containsKey(i);

  void _pick(int option) {
    final i = _q.currentIndex;
    if (_advancing || _locked(i)) return;
    setState(() => _q.answers[i] = option);
    _saveDraft();
    _advanceAfterAnswer(i);
  }

  void _submitTyped() {
    final i = _q.currentIndex;
    final text = _typedController.text.trim();
    if (_advancing || _locked(i) || text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _q.typed[i] = text;
      _q.answers[i] = writtenMatches(text, _q.questions[i].correctText) ? 0 : 1;
    });
    _saveDraft();
    _advanceAfterAnswer(i);
  }

  // Chọn xong tự trượt sang câu tiếp theo (chờ lâu hơn khi hiện đáp án ngay)
  void _advanceAfterAnswer(int i) {
    _advancing = true;
    Timer(Duration(milliseconds: _q.instantFeedback ? 1200 : 300), () {
      _advancing = false;
      if (mounted && !_submitted && _q.currentIndex == i) _goTo(i + 1);
    });
  }

  void _goTo(int index) {
    final j = index.clamp(0, _total);
    setState(() {
      _forward = j >= _q.currentIndex;
      _q.currentIndex = j;
      _typedController.text = j < _total ? (_q.typed[j] ?? '') : '';
    });
    _saveDraft();
  }

  Future<void> _confirmSubmit() async {
    final blank = _total - _q.answeredCount;
    if (blank > 0) {
      final submit = await confirmDialog(
        context,
        title: "Nộp bài?",
        content: "Bạn còn $blank câu chưa trả lời. Câu bỏ trống được tính là sai.",
        cancelLabel: "Làm tiếp",
        confirmLabel: "Vẫn nộp bài",
      );
      if (!mounted || _submitted) return;
      if (!submit) {
        _goTo(List.generate(_total, (i) => i).firstWhere((i) => !_q.answers.containsKey(i)));
        return;
      }
    }
    _submit();
  }

  Future<void> _submit({bool auto = false}) async {
    if (_submitted) return; // Tránh nộp hai lần
    _submitted = true;
    _ticker?.cancel();
    final deck = _service.deckById(_q.deckId);
    if (deck == null) {
      Navigator.pop(context);
      return;
    }
    final duration = _q.limitSeconds == null ? _elapsed : _elapsed.clamp(0, _q.limitSeconds!);
    final online = context.read<ConnectivityService>().isOnline;
    final attempt = gradeAttempt(
      id: const Uuid().v4(),
      deck: deck,
      questions: _q.questions,
      answers: _q.answers,
      typed: _q.typed,
      durationSeconds: duration,
      takenAt: DateTime.now(),
      pendingSync: !online,
    );
    final ok = await _service.submitQuiz(attempt);
    if (!mounted) return;
    if (!ok) {
      _submitted = false;
      showSaveError(context, _submit);
      return;
    }
    // Đóng hộp thoại / bảng chọn đang mở (khi hết giờ tự nộp) trước khi chuyển trang
    final self = ModalRoute.of(context);
    Navigator.of(context).popUntil((route) => route == self);
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => QuizResultPage(attemptId: attempt.id)));
    if (auto) {
      showSnack(context, "Hết thời gian. Bài đã được nộp tự động.");
    } else if (!online) {
      showSnack(context, "Đã lưu kết quả trên máy, sẽ đồng bộ khi có mạng");
    }
  }

  // Thoát ngay: bài làm được lưu nháp, làm tiếp từ Trang chủ hoặc trang bộ thẻ
  Future<void> _close() async {
    if (_submitted) return;
    if (await _saveDraft()) {
      _submitted = true;
      if (mounted) Navigator.pop(context);
    } else if (mounted) {
      showSaveError(context, _saveDraft);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final deck = _service.deckById(_q.deckId);
    if (deck == null || _q.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Kiểm tra")),
        body: const EmptyState(icon: Icons.warning, title: "Không có câu hỏi để kiểm tra"),
      );
    }

    final remaining = _remaining;
    final shown = _atEnd ? _total : _q.currentIndex + 1;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_submitted) _close();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(icon: const Icon(Icons.close, size: 28), tooltip: "Lưu nháp và thoát", onPressed: _close),
          title: Text(
            "$shown / $_total",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: p.textMuted),
          ),
          centerTitle: true,
          actions: [
            if (remaining != null)
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Row(
                  children: [
                    Icon(Icons.timer, color: remaining <= 30 ? p.error : p.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      formatDuration(remaining),
                      style: TextStyle(fontWeight: FontWeight.bold, color: remaining <= 30 ? p.error : p.text),
                    ),
                  ],
                ),
              ),
          ],
          shape: const Border(),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: AnimatedProgressBar(value: _q.answeredCount / _total, backgroundColor: p.border, color: p.textMuted),
          ),
        ),
        body: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: ClipRect(
                child: AnimatedSwitcher(
                  duration: motion(context, 300),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  // Trượt ngang: câu mới vào từ phải (hoặc trái khi quay lại), câu cũ ra phía ngược lại
                  transitionBuilder: (child, anim) {
                    final incoming = child.key == ValueKey(_q.currentIndex);
                    final dx = (_forward ? 1.0 : -1.0) * (incoming ? 1 : -1);
                    return SlideTransition(
                      position: Tween(begin: Offset(dx, 0), end: Offset.zero).animate(anim),
                      child: child,
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey(_q.currentIndex),
                    child: ResponsiveBody(child: _atEnd ? _buildEnd() : _buildQuestion(_q.questions[_q.currentIndex])),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: ResponsiveBody(
              child: _atEnd
                  ? BusyButton(busy: _submitted, onPressed: _confirmSubmit, child: const Text("Nộp bài"))
                  : _buildNav(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(QuizQuestion q) {
    final p = context.palette;
    final i = _q.currentIndex;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(minHeight: MediaQuery.sizeOf(context).height * 0.22),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(q.question, style: TextStyle(fontSize: 24, color: p.text, height: 1.35)),
                if (q.isTrueFalse) ...[
                  const SizedBox(height: 16),
                  Divider(color: p.border),
                  const SizedBox(height: 16),
                  Text(q.statement ?? '', style: TextStyle(fontSize: 20, color: p.text, height: 1.35)),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          q.isWritten
              ? "Câu trả lời của bạn"
              : q.isTrueFalse
              ? "Chọn Đúng hoặc Sai"
              : "Chọn câu trả lời",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: p.textMuted),
        ),
        const SizedBox(height: 12),
        if (q.isWritten)
          _buildWritten(q, i)
        else if (q.isTrueFalse)
          Row(
            children: [
              Expanded(child: _buildOption(q, 0)),
              const SizedBox(width: 12),
              Expanded(child: _buildOption(q, 1)),
            ],
          )
        else
          for (var k = 0; k < q.options.length; k++) _buildOption(q, k),
      ],
    );
  }

  Widget _buildOption(QuizQuestion q, int k) {
    final p = context.palette;
    final i = _q.currentIndex;
    final chosen = _q.answers[i];
    final reveal = _locked(i);
    Color border = p.border;
    Color? bg;
    IconData? icon;
    if (reveal && k == q.correctIndex) {
      border = p.success;
      bg = p.successBg;
      icon = Icons.check_circle;
    } else if (reveal && k == chosen) {
      border = p.error;
      bg = p.errorBg;
      icon = Icons.cancel;
    } else if (chosen == k) {
      border = p.brand;
      bg = p.brandSoft;
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Material(
        color: bg ?? p.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          side: BorderSide(color: border, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.medium),
          onTap: reveal ? null : () => _pick(k),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    q.options[k],
                    textAlign: q.isTrueFalse ? TextAlign.center : TextAlign.start,
                    style: TextStyle(fontSize: 17, color: p.text, fontWeight: q.isTrueFalse ? FontWeight.w700 : null),
                  ),
                ),
                if (icon != null) Icon(icon, color: border),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWritten(QuizQuestion q, int i) {
    final p = context.palette;
    final reveal = _locked(i);
    final ok = _q.answers[i] == 0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _typedController,
          enabled: !reveal,
          minLines: 1,
          maxLines: 4,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submitTyped(),
          decoration: const InputDecoration(hintText: "Nhập đáp án"),
        ),
        const SizedBox(height: 12),
        if (reveal)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: ok ? p.successBg : p.errorBg,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            ),
            child: Text(
              ok ? "Chính xác!" : "Đáp án đúng: ${q.correctText}",
              style: TextStyle(fontWeight: FontWeight.w700, color: ok ? p.success : p.error),
            ),
          )
        else
          ValueListenableBuilder(
            valueListenable: _typedController,
            builder: (context, v, _) =>
                ElevatedButton(onPressed: v.text.trim().isEmpty ? null : _submitTyped, child: const Text("Trả lời")),
          ),
      ],
    );
  }

  // Chuyển câu: quay lại / bỏ qua
  Widget _buildNav() {
    final i = _q.currentIndex;
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left, size: 32),
          tooltip: "Câu trước",
          onPressed: i > 0 ? () => _goTo(i - 1) : null,
        ),
        const Spacer(),
        TextButton(onPressed: () => _goTo(i + 1), child: Text(_q.answers.containsKey(i) ? "Câu tiếp" : "Bỏ qua")),
        IconButton(icon: const Icon(Icons.chevron_right, size: 32), tooltip: "Câu tiếp", onPressed: () => _goTo(i + 1)),
      ],
    );
  }

  // Màn cuối: chọn lại đáp án hoặc nộp bài
  Widget _buildEnd() {
    final p = context.palette;
    final blank = _total - _q.answeredCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
      children: [
        Text(
          blank == 0 ? "Bạn đã trả lời hết câu hỏi!" : "Còn $blank câu chưa trả lời",
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: p.text),
        ),
        const SizedBox(height: 8),
        Text(
          _q.instantFeedback
              ? "Chạm vào số câu để xem lại. Nộp bài để xem kết quả."
              : "Chạm vào số câu để xem lại hoặc chọn lại đáp án trước khi nộp bài.",
          style: TextStyle(fontSize: 15, color: p.textMuted),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _total; i++)
              InkWell(
                onTap: () => _goTo(i),
                borderRadius: BorderRadius.circular(24),
                child: CircleAvatar(
                  radius: 24,
                  backgroundColor: _q.answers.containsKey(i) ? p.brand : p.brandSoft,
                  child: Text(
                    "${i + 1}",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: _q.answers.containsKey(i) ? Colors.white : p.text,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _typedController.dispose();
    super.dispose();
  }
}
