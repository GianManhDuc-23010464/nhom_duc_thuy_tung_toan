// pages/sample_layout_page.dart - MÀN HÌNH MẪU THEO YÊU CẦU GIẢNG VIÊN (CÂU 5)
//
// Dựng lại layout mẫu "ChibaKanji": header + chuỗi ngày, lời chào, thẻ ôn tập hôm nay,
// biểu đồ 5 mức ghi nhớ và thanh điều hướng 4 tab. Màn hình độc lập, dùng dữ liệu mẫu,
// không đọc/ghi Firebase và không ảnh hưởng các chức năng khác của ứng dụng.
import 'package:flutter/material.dart';

// Bảng màu riêng của mẫu, không dùng AppPalette của ứng dụng
class _SampleColors {
  static const background = Color(0xFFFFF9EC);
  static const green = Color(0xFF3A7D34);
  static const yellow = Color(0xFFFDE7A6);
  static const navBar = Color(0xFFFFF3D6);
  static const navActive = Color(0xFFD5EBCB);
  static const border = Color(0xFFEDEBE4);
  static const text = Color(0xFF2B2A26);
  static const textMuted = Color(0xFF6B675E);
}

// Một cột của biểu đồ: số từ ở mức đó và màu của cột
class _Level {
  final int count;
  final Color color;
  const _Level(this.count, this.color);
}

class SampleLayoutPage extends StatefulWidget {
  const SampleLayoutPage({super.key});

  @override
  State<SampleLayoutPage> createState() => _SampleLayoutPageState();
}

class _SampleLayoutPageState extends State<SampleLayoutPage> {
  static const _levels = [
    _Level(3, Color(0xFFECB56F)),
    _Level(3, Color(0xFFE4CA57)),
    _Level(1, Color(0xFFC0C97A)),
    _Level(1, Color(0xFF90BC7B)),
    _Level(1, Color(0xFF5B9A63)),
  ];

  int _tab = 0; // Tab đang chọn ở thanh điều hướng dưới

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _SampleColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 20),
              _greeting(),
              const SizedBox(height: 18),
              _todayCard(),
              const SizedBox(height: 16),
              _progressCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // Tên ứng dụng và huy hiệu chuỗi ngày
  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'ChibaKanji',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: _SampleColors.green),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: _SampleColors.yellow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF2D998)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department_outlined, size: 18, color: Color(0xFFE4572E)),
              SizedBox(width: 6),
              Text('7 ngày', style: TextStyle(fontWeight: FontWeight.w700, color: _SampleColors.text)),
            ],
          ),
        ),
      ],
    );
  }

  // Ảnh đại diện mặt cười và lời chào
  Widget _greeting() {
    return Row(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: const BoxDecoration(color: _SampleColors.yellow, shape: BoxShape.circle),
          child: const Text('•ᴗ•', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chào Duy!',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: _SampleColors.text),
              ),
              Text(
                'Mỗi ngày một chút, nhớ lâu hơn.',
                style: TextStyle(fontSize: 15, color: _SampleColors.textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Thẻ "Đến giờ ôn rồi": nội dung bên trái, hai lá thẻ chồng nhau bên phải, nút ở dưới
  Widget _todayCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _SampleColors.yellow, borderRadius: BorderRadius.circular(26)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HÔM NAY',
                      style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF5B5546)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Đến giờ ôn rồi!',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _SampleColors.text),
                    ),
                    SizedBox(height: 4),
                    Text('3 từ đang chờ · khoảng 2 phút', style: TextStyle(fontSize: 15, color: Color(0xFF4F4A3D))),
                  ],
                ),
              ),
              _kanaCards(),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đây là màn hình mẫu, chưa có phiên ôn tập')),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: _SampleColors.green,
                shape: const StadiumBorder(),
              ),
              icon: const Icon(Icons.play_arrow_outlined),
              label: const Text('Ôn ngay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // Hai lá thẻ: lá sau nghiêng nhẹ, lá trước có chữ あ
  Widget _kanaCards() {
    Widget card({Widget? child}) => Container(
          width: 52,
          height: 68,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFF2D998)),
          ),
          child: child,
        );

    return SizedBox(
      width: 68,
      height: 76,
      child: Stack(
        children: [
          Positioned(top: 0, right: 0, child: Transform.rotate(angle: 0.12, child: card())),
          Positioned(
            bottom: 0,
            left: 0,
            child: card(
              child: const Text('あ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  // Thẻ tiến độ: tổng số từ và biểu đồ 5 mức
  Widget _progressCard() {
    final total = _levels.fold<int>(0, (sum, level) => sum + level.count);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _SampleColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BẠN ĐÃ HỌC',
                style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.6, color: _SampleColors.textMuted),
              ),
              TextButton(
                onPressed: () => setState(() => _tab = 2),
                style: TextButton.styleFrom(
                  foregroundColor: _SampleColors.green,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Xem sổ từ', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          Text(
            '$total từ vựng',
            style: const TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: _SampleColors.text),
          ),
          const SizedBox(height: 22),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < _levels.length; i++)
                  Expanded(child: _bar(_levels[i], i + 1)),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text('Mức càng cao, bạn càng nhớ lâu.', style: TextStyle(color: _SampleColors.textMuted)),
        ],
      ),
    );
  }

  // Một cột biểu đồ: chiều cao tỉ lệ với số từ so với mức nhiều nhất
  Widget _bar(_Level level, int index) {
    final maxCount = _levels.map((e) => e.count).reduce((a, b) => a > b ? a : b);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text('${level.count}', style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Container(
            height: 90 * level.count / maxCount,
            decoration: BoxDecoration(color: level.color, borderRadius: BorderRadius.circular(10)),
          ),
          const SizedBox(height: 6),
          Text('Mức $index', style: const TextStyle(fontSize: 13, color: _SampleColors.textMuted)),
        ],
      ),
    );
  }

  // Thanh điều hướng 4 tab
  Widget _bottomNav() {
    return NavigationBarTheme(
      data: const NavigationBarThemeData(
        backgroundColor: _SampleColors.navBar,
        indicatorColor: _SampleColors.navActive,
      ),
      child: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.alarm), label: 'Ôn tập'),
          NavigationDestination(icon: Icon(Icons.menu_book_outlined), label: 'Học mới'),
          NavigationDestination(icon: Icon(Icons.bookmark_border), label: 'Sổ từ'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Cá nhân'),
        ],
      ),
    );
  }
}
