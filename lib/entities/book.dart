import 'Genericclass.dart';

class Book extends Genericclass<Object> {
  int soluong = 0; // Thêm thuộc tính riêng và kế thừa các thuộc tính chung

  Book({
    required String id,
    required String name,
    required String description,
    required this.soluong,
  }) : super(id: id, name: name, description: description);

  // Chỉ cần định nghĩa các phương thức riêng, kế thừa các phương thức có sẵn
  int getSoluong() {
    return soluong;
  }

  int setSoluong(int newSoluong) {
    soluong = newSoluong;
    return soluong;
  }
}
