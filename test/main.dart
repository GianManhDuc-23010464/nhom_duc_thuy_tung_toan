import 'student.dart';

void main() {
  Student student = Student(
    '24100188',
    'Nguyen Dinh Tung',
    'tung@example.com',
  );

  print('=== THONG TIN BAN DAU ===');
  student.displayInfo();

  student.updateInfo(
    'Nguyen Tung',
    'ndt231006@gmail.com.com',
  );

  print('\n=== SAU KHI CAP NHAT ===');
  student.displayInfo();

  // Đọc thuộc tính thông qua getter
  print('\nMa sinh vien: ${student.id}');
}