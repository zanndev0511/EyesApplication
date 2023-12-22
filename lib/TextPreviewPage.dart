import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TextPreviewPage extends StatefulWidget {
  TextPreviewPage(this.scannedText, {super.key});

  String scannedText;

  @override
  State<TextPreviewPage> createState() => _TextPreviewPageState();
}

class _TextPreviewPageState extends State<TextPreviewPage> {
  final FlutterTts flutterTts = FlutterTts();

  speak(String text) async {
    await flutterTts.setLanguage("vi-VN");
    await flutterTts.setPitch(1.0);
    await flutterTts.setSpeechRate(0.5);

    await flutterTts.speak(text);
  }

  @override
  void initState() {
    super.initState();
    speak(widget.scannedText);
  }

  @override
  void dispose() {
    flutterTts.stop();
    speak('Trở về màn hình chính');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background_text.jpeg'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(
                  20.0), // Đặt giá trị này theo mong muốn của bạn
            ),
            alignment: Alignment.center,
            margin: const EdgeInsets.only(left: 20.0, right: 20.0),
            padding: const EdgeInsets.all(5),
            child: Container(
              padding: const EdgeInsets.all(10),
              child: Text(
                widget.scannedText,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
