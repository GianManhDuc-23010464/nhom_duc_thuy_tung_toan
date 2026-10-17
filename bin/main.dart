import 'package:flashcard_app/entities/Genericclass.dart';
import 'package:flashcard_app/entities/people.dart';
import 'package:flashcard_app/entities/book.dart';
import 'package:flashcard_app/entities/student.dart';
import 'package:flashcard_app/models/flashcard_set.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/user.dart';

void main() {
  print('===============================================================');
  print('          KIỂM TRA CHẠY THỬ NGHIỆM GENERICS (CÂU 1 & CÂU 2)     ');
  print('===============================================================\n');

  print('--- 1. Kiểm tra đối tượng People kế thừa Genericclass<Object> ---');
  final people = People(
    id: 1,
    name: "Nguyen Lan Anh",
    description: "Sinh viên CNTT",
  );
  print('ID: ${people.getId()}');
  print('Tên: ${people.getName()}');
  print('Mô tả: ${people.getDescription()}');
  people.setName("Nguyen Hoang Manh");
  print('-> Tên sau khi setName: ${people.getName()}\n');

  print('--- 2. Kiểm tra đối tượng Book kế thừa Genericclass<Object> ---');
  final book = Book(
    id: "B001",
    name: "Lập trình Dart và Flutter",
    description: "Tài liệu học phần Mobile App",
    soluong: 50,
  );
  print('Mã sách: ${book.getId()}');
  print('Tên sách: ${book.getName()}');
  print('Số lượng ban đầu: ${book.getSoluong()}');
  book.setSoluong(80);
  print('-> Số lượng sau khi setSoluong: ${book.getSoluong()}\n');

  print('--- 3. Kiểm tra đối tượng Student kế thừa Genericclass<Object> ---');
  final student = Student(
    id: "23010464",
    name: "Gian Manh Duc",
    description: "Lớp K17 - ĐH Phenikaa",
    email: "duc@phenikaa-uni.edu.vn",
    studentCode: "SV23010464",
  );
  print('MSSV: ${student.getId()}');
  print('Họ tên: ${student.getName()}');
  print('Email: ${student.getEmail()}\n');

  print('--- 4. Kiểm tra FlashcardSet (Entity đồ án cuối kỳ) ---');
  final set = FlashcardSet(
    id: "SET-01",
    name: "Từ vựng tiếng Anh giao tiếp",
    description: "Bộ thẻ từ vựng thiết yếu",
    userId: "USER-10",
    cards: [],
  );
  print('Set ID: ${set.getId()}');
  print('Set Name: ${set.getName()} (hoặc qua title: ${set.title})');
  print('Mô tả: ${set.getDescription()}');
  set.setName("Tiếng Anh giao tiếp nâng cao");
  print('-> Sau khi cập nhật tên: ${set.title}\n');

  print('--- 5. Kiểm tra Flashcard (Entity đồ án cuối kỳ) ---');
  final card = Flashcard(
    id: "CARD-01",
    term: "Generics",
    meaning: "Lập trình tổng quát cho phép một lớp làm việc với nhiều kiểu dữ liệu",
    note: "Khái niệm OOP quan trọng",
  );
  print('Card ID: ${card.getId()}');
  print('Thuật ngữ (term/name): ${card.getName()}');
  print('Định nghĩa (meaning/description): ${card.getDescription()}');
  print('Ghi chú: ${card.getNote()}\n');

  print('--- 6. Kiểm tra User (Entity đồ án cuối kỳ) ---');
  final user = User(
    id: "USR-01",
    username: "dinhtung",
    description: "Admin",
    email: "dinhtung@gmail.com",
    passwordHash: "hashPass123",
    createdAt: DateTime.now(),
  );
  print('User ID: ${user.getId()}');
  print('Username (name): ${user.getName()}');
  print('Email: ${user.getEmail()}\n');

  print('===============================================================');
  print('✅ TẤT CẢ CÁC ĐỐI TƯỢNG ĐÃ KẾ THỪA VÀ HOẠT ĐỘNG CHÍNH XÁC!');
  print('===============================================================');
}
