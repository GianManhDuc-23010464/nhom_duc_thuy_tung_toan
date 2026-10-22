// utils/validators.dart - KIỂM TRA DỮ LIỆU BIỂU MẪU
final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Vui lòng nhập email';
  }
  if (!_emailPattern.hasMatch(value.trim())) {
    return 'Email chưa đúng định dạng, ví dụ ban@email.com';
  }
  return null;
}
