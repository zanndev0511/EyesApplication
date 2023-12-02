import 'dart:ffi';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:eyes_app/ObjectPreviewPage.dart';
import 'package:eyes_app/TextPreviewPage.dart';
import 'package:eyes_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_v2/tflite_v2.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentMode = 0;

  final FlutterTts flutterTts = FlutterTts();

  final List<IconData> iconList = [
    Icons.description,
    Icons.emoji_objects,
    // Add more icons as needed
  ];
  final List<Color> iconColor = [
    Colors.red,
    Colors.green
    // Add more icons as needed
  ];

  bool isWorking = false;
  String result = "";
  late CameraController cameraController;
  CameraImage? imgCamera;

  final SwiperController _swiperController = SwiperController();

  String scannedText = "";
  bool textScanning = false;

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/tflite/mobilenet_v1_1.0_224.tflite',
      labels: 'assets/tflite/mobilenet_v1_1.0_224.txt',
    );
  }

// Hàm để đọc từ
  speak(String text) async {
    await flutterTts
        .setLanguage("vi-VN"); // Đặt ngôn ngữ, có thể thay đổi theo nhu cầu
    await flutterTts.setPitch(1.0); // Đặt pitch
    await flutterTts.setSpeechRate(0.5); // Đặt tốc độ đọc

    await flutterTts.speak(text);
  }

  initCamera() {
    cameraController = CameraController(cameras[0], ResolutionPreset.high);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
  }

  checkCurrentMode() {
    switch (currentMode) {
      case 0:
        speak("Đây là chế độ đọc văn bản");
        break;
      case 1:
        speak("Đây là chế độ dò vật thể");
    }
  }

  imageClassification(File image) async {
    final List? recognitions = await Tflite.runModelOnImage(
      path: image.path,
      numResults: 6,
      threshold: 0.05,
      imageMean: 127.5,
      imageStd: 127.5,
    );

    result = '';

    recognitions!.forEach((response) {
      result += response['label'] +
          ' ' +
          (response['confidence'] as double).toStringAsFixed(2) +
          '\n\n';
    });
    setState(() {
      result;
    });
  }

  void _animateToCenter(int index) {
    // Animate the card to the center
    _swiperController.move(index);
  }

  getRecognisedText(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final textDetector = GoogleMlKit.vision.textRecognizer();
    RecognizedText recognizedText = await textDetector.processImage(inputImage);
    await textDetector.close();
    scannedText = '';

    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        scannedText = scannedText + line.text + "\n";
      }
    }
    setState(() {
      scannedText;
    });

    textScanning = false;
  }

  void takePicture() async {
    if (!cameraController.value.isInitialized) {
      return;
    }
    if (cameraController.value.isTakingPicture) {
      return;
    }
    try {
      await cameraController.setFlashMode(FlashMode.auto);
      XFile file = await cameraController.takePicture();

      if (currentMode == 0) {
        await getRecognisedText(file);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TextPreviewPage(scannedText),
          ),
        );
      } else if (currentMode == 1) {
        await imageClassification(File(file.path));
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ObjectPreviewPage(file, result),
          ),
        );
      }
    } on CameraException catch (e) {
      debugPrint('Error while taking picture: $e');
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
    checkCurrentMode();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    cameraController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SafeArea(
        child: Scaffold(
          body: Center(
            child: GestureDetector(
              onLongPress: takePicture,
              onHorizontalDragStart: (details) {
                setState(() {
                  if (currentMode < 1) {
                    ++currentMode;
                  } else {
                    currentMode = 0;
                  }
                  _animateToCenter(currentMode);
                  checkCurrentMode();
                });
              },
              child: Container(
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height - 100,
                      child: AspectRatio(
                        aspectRatio: cameraController.value.aspectRatio,
                        child: CameraPreview(cameraController),
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    Container(
                      height: 80,
                      child: Swiper(
                        itemBuilder: (BuildContext context, int index) {
                          return _buildIconWidget(
                              iconList[index], iconColor[index]);
                        },
                        itemCount: iconList.length,
                        viewportFraction: 0.25,
                        scale: 0.9,
                        loop: false,
                        onIndexChanged: (value) =>
                            {currentMode = value, checkCurrentMode()},
                        index: currentMode,
                        controller: _swiperController,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconWidget(IconData iconData, Color iconColor) {
    int iconIndex = iconList.indexOf(iconData);
    return Container(
      margin: EdgeInsets.all((currentMode == iconIndex) ? 0 : 5),
      decoration: ShapeDecoration(
          color: iconColor, // Màu nền của icon button
          shape: CircleBorder(
            side: BorderSide(
              color:
                  (currentMode == iconIndex) ? Colors.blue : Colors.transparent,
              width: 3.0,
            ),
          )),
      child: IconButton(
        onPressed: () {
          // Xử lý sự kiện chụp hình
        },
        icon: Icon(iconData),
        color: Colors.white,
        iconSize: (currentMode == iconIndex) ? 40 : 30,
      ),
    );
  }
}
