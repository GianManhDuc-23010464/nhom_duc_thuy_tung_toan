import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flashcard_app/entities/Genericclass.dart';
import 'package:flashcard_app/entities/people.dart';
import 'package:flashcard_app/entities/book.dart';
import 'package:flashcard_app/entities/student.dart';
import 'package:flashcard_app/models/flashcard_set.dart';
import 'package:flashcard_app/models/flashcard.dart';
import 'package:flashcard_app/models/user.dart';
import 'package:flashcard_app/widgets/generic_screen.dart';

// Screen cụ thể kế thừa GenericScreen<String> để test Câu 2
class TestStatelessScreen extends GenericScreen<String> {
  const TestStatelessScreen({super.key, required super.title, super.data});

  @override
  Widget buildBody(BuildContext context) {
    return Center(child: Text("Data: $data"));
  }
}

// Screen có trạng thái kế thừa GenericStatefulScreen<FlashcardSet> để test Câu 2
class TestStatefulScreen extends GenericStatefulScreen<FlashcardSet> {
  const TestStatefulScreen({super.key, required super.title, super.initialData});

  @override
  State<TestStatefulScreen> createState() => _TestStatefulScreenState();
}

class _TestStatefulScreenState
    extends GenericScreenState<TestStatefulScreen, FlashcardSet> {
  @override
  Widget buildContent(BuildContext context) {
    return Column(
      children: [
        Text("Tên bộ: ${screenData?.title ?? ''}"),
        Text("Mô tả: ${screenData?.description ?? ''}"),
      ],
    );
  }
}

void main() {
  group("Câu 1: Kiểm thử Entities kế thừa Genericclass<T>", () {
    test("1.1 Genericclass<T> hoạt động chính xác với kiểu tổng quát", () {
      final genericObj = Genericclass<String>(
        id: "ID-001",
        name: "Generics Base",
        description: "Lớp cơ sở tổng quát",
      );

      expect(genericObj.getId(), "ID-001");
      expect(genericObj.getName(), "Generics Base");
      expect(genericObj.getDescription(), "Lớp cơ sở tổng quát");

      genericObj.setId("ID-002");
      genericObj.setName("New Name");
      genericObj.setDescription("New Desc");

      expect(genericObj.getId(), "ID-002");
      expect(genericObj.getName(), "New Name");
      expect(genericObj.getDescription(), "New Desc");
    });

    test("1.2 People kế thừa Genericclass<Object> theo bài giảng", () {
      final people = People(
        id: 123,
        name: "Le Thu Nguyen",
        description: "Giảng viên",
      );

      final Object obj = people;
      expect(obj is Genericclass, isTrue);
      expect(people.getId(), 123);
      expect(people.getName(), "Le Thu Nguyen");
      expect(people.getDescription(), "Giảng viên");

      people.setName("Thầy Thu");
      expect(people.getName(), "Thầy Thu");
    });

    test("1.3 Book kế thừa Genericclass<Object> và có biến soluong riêng", () {
      final book = Book(
        id: "BK-99",
        name: "Dart & Flutter",
        description: "Sách lập trình di động",
        soluong: 100,
      );

      final Object obj = book;
      expect(obj is Genericclass, isTrue);
      expect(book.getId(), "BK-99");
      expect(book.getName(), "Dart & Flutter");
      expect(book.getSoluong(), 100);

      book.setSoluong(120);
      expect(book.getSoluong(), 120);
    });

    test("1.4 Student kế thừa Genericclass<Object> với mã sinh viên", () {
      final student = Student(
        id: "23010464",
        name: "Gian Manh Duc",
        description: "Khoa CNTT Phenikaa",
        email: "23010464@st.phenikaa-uni.edu.vn",
        studentCode: "23010464",
      );

      final Object obj = student;
      expect(obj is Genericclass, isTrue);
      expect(student.getId(), "23010464");
      expect(student.getName(), "Gian Manh Duc");
      expect(student.getStudentCode(), "23010464");
    });

    test("1.5 FlashcardSet kế thừa Genericclass<String> trong dự án cuối kỳ", () {
      final set = FlashcardSet(
        id: "SET-1",
        name: "Từ vựng N3",
        description: "Ngữ pháp và từ vựng",
        userId: "USER-1",
        cards: [],
      );

      final Object obj = set;
      expect(obj is Genericclass, isTrue);
      expect(set.getId(), "SET-1");
      expect(set.getName(), "Từ vựng N3");
      expect(set.title, "Từ vựng N3");
      expect(set.getDescription(), "Ngữ pháp và từ vựng");

      set.setName("Từ vựng N2");
      expect(set.getName(), "Từ vựng N2");
      expect(set.title, "Từ vựng N2");

      set.title = "Từ vựng N1";
      expect(set.getName(), "Từ vựng N1");
    });

    test("1.6 Flashcard kế thừa Genericclass<String> trong dự án cuối kỳ", () {
      final card = Flashcard(
        id: "C-1",
        term: "Inheritance",
        meaning: "Tính kế thừa trong hướng đối tượng",
        note: "OOP",
      );

      final Object obj = card;
      expect(obj is Genericclass, isTrue);
      expect(card.getId(), "C-1");
      expect(card.getName(), "Inheritance");
      expect(card.term, "Inheritance");
      expect(card.getDescription(), "Tính kế thừa trong hướng đối tượng");
      expect(card.meaning, "Tính kế thừa trong hướng đối tượng");
      expect(card.getNote(), "OOP");

      card.setDescription("Quan hệ Is-A giữa lớp con và lớp cha");
      expect(card.meaning, "Quan hệ Is-A giữa lớp con và lớp cha");
    });

    test("1.7 User kế thừa Genericclass<String> trong dự án cuối kỳ", () {
      final user = User(
        id: "U-1",
        username: "dinhtung",
        description: "Admin",
        email: "dinhtung@gmail.com",
        passwordHash: "hashPass",
        createdAt: DateTime.now(),
      );

      final Object obj = user;
      expect(obj is Genericclass, isTrue);
      expect(user.getId(), "U-1");
      expect(user.getName(), "dinhtung");
      expect(user.username, "dinhtung");
      expect(user.getEmail(), "dinhtung@gmail.com");
    });
  });

  group("Câu 2: Kiểm thử Screens [Layouts] kế thừa Generic Screen Layouts", () {
    testWidgets("2.1 TestStatelessScreen kế thừa GenericScreen<T> hiển thị chuẩn", (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: TestStatelessScreen(
            title: "Màn hình kiểm thử",
            data: "Nội dung mẫu",
          ),
        ),
      );

      expect(find.text("Màn hình kiểm thử"), findsOneWidget);
      expect(find.text("Data: Nội dung mẫu"), findsOneWidget);
    });

    testWidgets("2.2 TestStatefulScreen kế thừa GenericStatefulScreen<T> hiển thị chuẩn", (WidgetTester tester) async {
      final testSet = FlashcardSet(
        id: "S-10",
        name: "Lập trình mạng",
        description: "Học phần kỳ 1",
        userId: "U-10",
        cards: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: TestStatefulScreen(
            title: "Chi tiết môn học",
            initialData: testSet,
          ),
        ),
      );

      expect(find.text("Chi tiết môn học"), findsOneWidget);
      expect(find.text("Tên bộ: Lập trình mạng"), findsOneWidget);
      expect(find.text("Mô tả: Học phần kỳ 1"), findsOneWidget);
    });
  });
}
