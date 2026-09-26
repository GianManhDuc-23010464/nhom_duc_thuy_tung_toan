# Flashcard App

Ứng dụng học từ vựng bằng flashcard, xây dựng với Flutter cho Android và iOS. Người dùng có thể tạo bộ thẻ, học bằng cách lật thẻ, làm bài kiểm tra và theo dõi hoạt động học tập ngay trên thiết bị.

## Chức năng hiện có

- Đăng ký, đăng nhập và đăng xuất bằng tài khoản lưu cục bộ.
- Tạo, đổi tên, xóa và tìm kiếm bộ flashcard theo tên.
- Thêm, sửa và xóa thẻ với từ vựng, nghĩa, ghi chú và ảnh tùy chọn.
- Học bằng cách lật thẻ, chuyển thẻ, trộn thứ tự và đánh dấu thẻ thành thạo.
- Kiểm tra bằng cách nhập nghĩa của từ; xem số câu đúng, sai và tỷ lệ đúng.
- Xem thống kê số bộ thẻ, số thẻ đã học, mục tiêu mỗi ngày và chuỗi ngày học; hỗ trợ giao diện sáng/tối.

## Công nghệ

- Flutter và Dart (yêu cầu Dart tương thích với `sdk: ^3.9.0` trong `pubspec.yaml`).
- `shared_preferences` để lưu tài khoản, bộ thẻ và các chỉ số học tập trên thiết bị.
- `image_picker` và `path_provider` để chọn và lưu ảnh thẻ trong bộ nhớ ứng dụng.
- `fl_chart` để hiển thị biểu đồ thống kê; `provider` để quản lý giao diện.

## Cách chạy

Cài Flutter SDK, một thiết bị hoặc trình giả lập Android/iOS, rồi chạy:

```bash
git clone https://github.com/GianManhDuc-23010464/nhom_duc_thuy_tung_toan.git
cd nhom_duc_thuy_tung_toan
flutter pub get
flutter run
```

Nếu Flutter chưa nhận thiết bị, dùng `flutter doctor` và `flutter devices` để kiểm tra môi trường. Để chạy trên iOS cần macOS và Xcode.

## Cấu trúc mã nguồn

```text
lib/
├── main.dart       # Khởi động ứng dụng và điều hướng
├── models/         # User, Flashcard, FlashcardSet, SessionStats
├── pages/          # Đăng nhập, bộ thẻ, học, kiểm tra, thống kê, hồ sơ
├── services/       # Xác thực và lưu/quản lý flashcard
├── theme/          # Cấu hình giao diện
└── widgets/        # Thành phần giao diện dùng lại
```

## Lưu ý về bản hiện tại

Ứng dụng hoạt động cục bộ: dữ liệu thẻ được lưu dưới dạng JSON trong `SharedPreferences`, còn ảnh được lưu trong thư mục của ứng dụng. Dữ liệu **chưa đồng bộ giữa các thiết bị** và dự án **chưa tích hợp Firebase**.

Xác thực hiện dùng tài khoản lưu trên thiết bị và băm mật khẩu SHA-256 đơn giản, phù hợp để trình diễn, chưa phù hợp cho ứng dụng triển khai thực tế. Bài kiểm tra hiện ghi nhận kết quả tổng, chưa cập nhật độ thành thạo theo từng thẻ. File `test/widget_test.dart` vẫn là bài kiểm tra mẫu của Flutter, chưa phản ánh giao diện ứng dụng hiện tại.
## Màn hình Thống kê

### Chức năng
Màn hình Thống kê giúp người dùng theo dõi quá trình học tập trên ứng dụng Flashcard.

Các thông tin hiển thị:
- Tổng số bộ Flashcard.
- Tổng số thẻ Flashcard.
- Số thẻ đã học.
- Tiến độ học tập.
- Tỷ lệ ghi nhớ.
- Chuỗi ngày học liên tục.

### File thực hiện
`lib/pages/stats_page.dart`

### Điều hướng
Người dùng chọn **Thống kê** trên Bottom Navigation Bar để truy cập màn hình.

### Người thực hiện
Nguyễn Đình Tùng
