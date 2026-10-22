// widgets/set_card.dart - THẺ BỘ HỌC PHẦN (thẻ trắng phẳng, viền mảnh)
import 'package:flutter/material.dart';
import '../models/flashcard_set.dart';
import '../theme/app_theme.dart';

class SetCard extends StatelessWidget {
  final FlashcardSet set;
  final int index;
  final String? ownerLabel; // "Bạn" hoặc tên tác giả
  final int? knownCount; // Hiện thanh tiến độ khi đã học
  final bool? isSaved; // null: không hiện nút lưu
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onToggleSave;

  const SetCard({
    super.key,
    required this.set,
    required this.index,
    required this.onTap,
    this.ownerLabel,
    this.knownCount,
    this.isSaved,
    this.onLongPress,
    this.onToggleSave,
  });

  bool get _isNew => DateTime.now().difference(set.createdAt).inDays < 7;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final total = set.validCards.length;

    return Material(
      color: p.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.large),
        side: BorderSide(color: p.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4, right: 4),
                      child: Text(
                        set.title,
                        style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w700, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  if (isSaved != null)
                    IconButton(
                      onPressed: onToggleSave,
                      visualDensity: VisualDensity.compact,
                      tooltip: isSaved! ? "Bỏ lưu" : "Lưu bộ thẻ",
                      icon: Icon(isSaved! ? Icons.bookmark : Icons.bookmark_border, color: p.brandText),
                    ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    _Pill(text: "$total thẻ", bg: p.brandSoft, fg: p.brandText),
                    if (set.isDraft) _Pill(text: "Bản nháp", bg: p.warningBg, fg: p.warning),
                    if (!set.isDraft && _isNew && isSaved == null) _Pill(text: "Mới", bg: p.yellow, fg: const Color(0xFF282E3E)),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  children: [
                    Icon(set.isPublic ? Icons.public : Icons.lock_outline, color: p.textMuted, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        ownerLabel != null ? "$ownerLabel · ${set.subject}" : set.subject,
                        style: TextStyle(color: p.textMuted, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              if (knownCount != null && total > 0) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: knownCount! / total,
                            minHeight: 6,
                            backgroundColor: p.border,
                            valueColor: AlwaysStoppedAnimation(p.success),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text("$knownCount/$total", style: TextStyle(color: p.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  const _Pill({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

// Bộ thẻ đã lưu nhưng bị xóa hoặc chuyển sang riêng tư
class UnavailableSetCard extends StatelessWidget {
  final VoidCallback onUnsave;
  const UnavailableSetCard({super.key, required this.onUnsave});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      decoration: BoxDecoration(
        color: p.background,
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: p.border),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: p.warning, size: 16),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  "Không còn khả dụng",
                  style: TextStyle(color: p.text, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              "Bộ thẻ đã bị xóa hoặc chuyển sang riêng tư. Tiến độ của bạn vẫn được giữ.",
              style: TextStyle(color: p.textMuted, fontSize: 12),
              overflow: TextOverflow.fade,
            ),
          ),
          TextButton(
            onPressed: onUnsave,
            style: TextButton.styleFrom(padding: EdgeInsets.zero, alignment: Alignment.centerLeft),
            child: const Text("Bỏ khỏi Đã lưu"),
          ),
        ],
      ),
    );
  }
}

// Lưới bộ thẻ: 2 cột trên điện thoại, nhiều cột hơn trên màn hình rộng.
// Chiều cao ô cố định theo nội dung (không theo tỷ lệ) để không tràn ở màn 320px.
SliverGridDelegate setGridDelegate(double width) => SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: width >= 1100 ? 4 : width >= 700 ? 3 : 2,
      mainAxisExtent: 168,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
    );
