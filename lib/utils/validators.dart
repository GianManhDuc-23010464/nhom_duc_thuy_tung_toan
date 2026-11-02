// utils/validators.dart - KIỂM TRA DỮ LIỆU BIỂU MẪU
// Mẫu email đơn giản: có @, không có khoảng trắng, tên miền có đuôi ít nhất 2 ký tự
final RegExp _emailPattern = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]{2,}$');

// Trả về thông báo lỗi tiếng Việt, hoặc null khi email hợp lệ
String? validateEmail(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Vui lòng nhập email';
  }
  if (!_emailPattern.hasMatch(value.trim())) {
    return 'Email chưa đúng định dạng, ví dụ ban@email.com';
  }
  return null;
}
