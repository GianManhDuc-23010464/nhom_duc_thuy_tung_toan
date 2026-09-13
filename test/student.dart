class Student {
  // Thuộc tính riêng tư
  final String _id;
  String _fullName;
  String _email;

  // Hàm khởi tạo
  Student(String id, String fullName, String email)
      : _id = id,
        _fullName = fullName,
        _email = email;

  // Getter: đọc thông tin sinh viên
  String get id => _id;
  String get fullName => _fullName;
  String get email => _email;

  // Cập nhật họ tên và email
  void updateInfo(String name, String email) {
    _fullName = name;
    _email = email;
  }

  // Hiển thị thông tin sinh viên
  void displayInfo() {
    print('Ma sinh vien: $_id');
    print('Ho va ten: $_fullName');
    print('Email: $_email');
  }
}