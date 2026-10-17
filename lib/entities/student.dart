import 'Genericclass.dart';

class Student extends Genericclass<Object> {
  String email;
  String studentCode;

  Student({
    required String id,
    required String name,
    required String description,
    required this.email,
    required this.studentCode,
  }) : super(id: id, name: name, description: description);

  String getEmail() => email;
  void setEmail(String newEmail) => email = newEmail;

  String getStudentCode() => studentCode;
  void setStudentCode(String code) => studentCode = code;
}
