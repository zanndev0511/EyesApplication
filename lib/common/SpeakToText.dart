import 'package:flutter_tts/flutter_tts.dart';

final FlutterTts flutterTts = FlutterTts();
speak(String text) async {
  await flutterTts
      .setLanguage("vi-VN"); // Đặt ngôn ngữ, có thể thay đổi theo nhu cầu
  await flutterTts.setPitch(1.0); // Đặt pitch
  await flutterTts.setSpeechRate(0.5); // Đặt tốc độ đọc

  await flutterTts.speak(text);
}
