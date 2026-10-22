// services/seed_data.dart - BỘ THẺ CÔNG KHAI MẪU VÀ HÀM SEED LÊN FIRESTORE
// Chạy một lần (xem lib/tools/seed.dart): đẩy các bộ thẻ mẫu lên decks/, bỏ qua bộ đã tồn tại.
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/flashcard.dart';
import '../models/flashcard_set.dart';
import 'data_store.dart';

// Trả về số bộ thẻ vừa thêm
Future<int> seedCommunityDecks(FirebaseFirestore db) async {
  final store = FirestoreDataStore(db);
  var added = 0;
  for (final d in communityDecks()) {
    if ((await db.collection('decks').doc(d.id).get()).exists) continue;
    await store.saveDeck(d);
    added++;
  }
  return added;
}

List<FlashcardSet> communityDecks() {
  FlashcardSet deck(String id, String title, String desc, String subject, List<List<String>> cards,
      {String userId = 'studymate', String ownerName = 'Cộng đồng Flashcard And Quizz', int daysAgo = 0}) {
    var i = 0;
    final at = DateTime.now().subtract(Duration(days: daysAgo));
    return FlashcardSet(
      id: id,
      userId: userId,
      ownerName: ownerName,
      createdAt: at,
      updatedAt: at,
      title: title,
      description: desc,
      subject: subject,
      visibility: 'public',
      cards: cards.map((c) => Flashcard(
        id: '${id}_${++i}',
        term: c[0],
        meaning: c[1],
        note: c.length > 2 ? c[2] : null,
      )).toList(),
    );
  }

  return [
    deck('seed_dart', 'Lập trình Dart cơ bản', 'Khái niệm Dart và Flutter hay gặp trong bài kiểm tra giữa kỳ.', 'Tin học đại cương', [
      ['Từ khóa nào khai báo hằng số xác định lúc biên dịch?', 'const', 'const tạo giá trị bất biến lúc biên dịch; final chỉ gán một lần lúc chạy.'],
      ['Khai báo kiểu cho phép null trong Dart thế nào?', 'Thêm dấu ? sau kiểu, ví dụ String?'],
      ['Widget nào có trạng thái thay đổi được?', 'StatefulWidget', 'StatefulWidget gắn với một State và gọi setState() để vẽ lại.'],
      ['Phương thức bắt buộc override trong mọi widget?', 'build(BuildContext context)'],
      ['Từ khóa chờ một Future hoàn thành?', 'await', 'await chỉ dùng trong hàm được đánh dấu async.'],
      ['Collection lưu cặp khóa – giá trị?', 'Map'],
    ]),
    deck('seed_history', 'Lịch sử Việt Nam 1945–1975', 'Các mốc sự kiện chính trong chương trình Lịch sử 12.', 'Lịch sử Đảng', [
      ['Cách mạng Tháng Tám thành công năm nào?', '1945'],
      ['Chiến dịch Điện Biên Phủ kết thúc năm nào?', '1954'],
      ['Hiệp định Pa-ri được ký năm nào?', '1973'],
      ['Tổng tiến công Mậu Thân diễn ra năm nào?', '1968'],
      ['Giải phóng miền Nam, thống nhất đất nước năm nào?', '1975'],
    ]),
    deck('seed_sql', 'Câu lệnh SQL thường dùng', 'SELECT, JOIN, GROUP BY và các mệnh đề hay gặp.', 'Tin học đại cương', [
      ['Mệnh đề lọc nhóm sau GROUP BY?', 'HAVING', 'WHERE lọc dòng trước khi gom nhóm, HAVING lọc sau khi gom nhóm.'],
      ['Lấy các dòng khớp ở cả hai bảng?', 'INNER JOIN'],
      ['Loại bỏ dòng trùng lặp trong kết quả?', 'SELECT DISTINCT'],
      ['Sắp xếp kết quả giảm dần?', 'ORDER BY ... DESC'],
      ['Đếm số dòng trong bảng?', 'COUNT(*)'],
      ['Lấy tất cả dòng bảng trái kể cả khi không khớp?', 'LEFT JOIN'],
    ], userId: 'user_quangminh', ownerName: 'Quang Minh', daysAgo: 5),
    deck('seed_ielts', 'IELTS Vocabulary – Environment', 'Từ vựng chủ đề môi trường cho Writing Task 2.', 'Tiếng Anh', [
      ['deforestation', 'nạn phá rừng'],
      ['emission', 'khí thải'],
      ['renewable', 'tái tạo được'],
      ['biodiversity', 'đa dạng sinh học'],
      ['sustainable', 'bền vững'],
    ]),
    deck('seed_grammar', 'Tiếng Anh – Ngữ pháp trắc nghiệm', 'Các điểm ngữ pháp hay gặp trong đề thi trắc nghiệm tiếng Anh.', 'Tiếng Anh', [
      ['She ___ to school every day.', 'goes'],
      ['If I ___ rich, I would travel the world.', 'were', 'Câu điều kiện loại 2 dùng "were" cho mọi ngôi.'],
      ['I have lived here ___ 2015.', 'since', '"since" + mốc thời gian; "for" + khoảng thời gian.'],
      ['He is interested ___ music.', 'in'],
      ['By the time we arrived, the film ___.', 'had started', 'Quá khứ hoàn thành diễn tả hành động xảy ra trước một hành động khác trong quá khứ.'],
      ['Neither Tom nor his friends ___ coming.', 'are', 'Với "neither ... nor", động từ chia theo chủ ngữ gần nhất.'],
      ['She suggested ___ to the cinema.', 'going', '"suggest" + V-ing.'],
      ['This is the book ___ I told you about.', 'which'],
    ]),
    deck('seed_philosophy', 'Triết học Mác – Lênin', 'Các câu hỏi trọng tâm ôn thi trắc nghiệm Triết học.', 'Triết học', [
      ['Vấn đề cơ bản của triết học là gì?', 'Mối quan hệ giữa vật chất và ý thức'],
      ['Theo chủ nghĩa duy vật biện chứng, quan hệ giữa vật chất và ý thức là gì?', 'Vật chất có trước, quyết định ý thức'],
      ['Quy luật nào chỉ ra nguồn gốc, động lực của sự phát triển?', 'Quy luật thống nhất và đấu tranh của các mặt đối lập'],
      ['Quy luật nào chỉ ra cách thức của sự phát triển?', 'Quy luật chuyển hóa từ những thay đổi về lượng thành những thay đổi về chất'],
      ['Quy luật nào chỉ ra khuynh hướng của sự phát triển?', 'Quy luật phủ định của phủ định'],
      ['Tiêu chuẩn của chân lý là gì?', 'Thực tiễn'],
      ['Lênin nêu định nghĩa vật chất trong tác phẩm nào?', 'Chủ nghĩa duy vật và chủ nghĩa kinh nghiệm phê phán'],
    ]),
    deck('seed_law', 'Pháp luật đại cương', 'Kiến thức cơ bản về nhà nước và pháp luật Việt Nam.', 'Pháp luật đại cương', [
      ['Hiến pháp hiện hành của Việt Nam được thông qua năm nào?', '2013'],
      ['Cơ quan quyền lực nhà nước cao nhất của nước CHXHCN Việt Nam?', 'Quốc hội'],
      ['Văn bản có hiệu lực pháp lý cao nhất?', 'Hiến pháp'],
      ['Cơ cấu của một quy phạm pháp luật gồm những bộ phận nào?', 'Giả định, quy định, chế tài'],
      ['Cơ quan thực hiện quyền tư pháp?', 'Tòa án nhân dân'],
      ['Người từ đủ bao nhiêu tuổi có năng lực hành vi dân sự đầy đủ (trừ trường hợp luật định)?', 'Đủ 18 tuổi'],
      ['Các hình thức thực hiện pháp luật gồm?', 'Tuân thủ, thi hành, sử dụng và áp dụng pháp luật'],
    ]),
  ];
}
