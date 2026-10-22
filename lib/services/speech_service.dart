// services/speech_service.dart - PHÁT ÂM NỘI DUNG THẺ
// Gọi bộ đọc có sẵn của hệ điều hành qua kênh native (AppDelegate.swift / MainActivity.kt).
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SpeechService {
  static final SpeechService _instance = SpeechService._internal();
  factory SpeechService() => _instance;
  SpeechService._internal();

  static const MethodChannel _channel = MethodChannel('flashcard_app/speech');
  static final RegExp _vietnamese = RegExp(r'[ăâđêôơưáàảãạéèẻẽẹíìỉĩịóòỏõọúùủũụýỳỷỹỵ]', caseSensitive: false);

  // Trả về false nếu thiết bị không hỗ trợ đọc to
  Future<bool> speak(String text) async {
    if (text.trim().isEmpty) return false;
    try {
      final ok = await _channel.invokeMethod<bool>('speak', {
        'text': text,
        'language': _vietnamese.hasMatch(text) ? 'vi-VN' : 'en-US',
      });
      return ok ?? false;
    } catch (e) {
      debugPrint('❌ Lỗi phát âm: $e');
      return false;
    }
  }
}
