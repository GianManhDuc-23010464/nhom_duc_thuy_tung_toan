// tools/seed.dart - ĐẨY BỘ THẺ CÔNG KHAI MẪU LÊN FIRESTORE (CHẠY MỘT LẦN)
// Chạy: flutter run -t lib/tools/seed.dart
// Các bộ mẫu thuộc tài khoản "Cộng đồng Flashcard And Quizz" nên cần chạy TRƯỚC khi deploy firestore.rules
// (khi Firestore còn ở chế độ test), vì rules chỉ cho chủ bộ thẻ tạo bộ thẻ.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import '../firebase_options.dart';
import '../services/seed_data.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  String message;
  try {
    final added = await seedCommunityDecks(FirebaseFirestore.instance);
    message = 'Đã thêm $added bộ thẻ mẫu (bỏ qua bộ đã tồn tại).';
  } catch (e) {
    message = 'Seed lỗi: $e';
  }
  debugPrint(message);
  runApp(MaterialApp(home: Scaffold(body: Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(message))))));
}
