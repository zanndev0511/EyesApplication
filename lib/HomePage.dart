import 'package:camera/camera.dart';
import 'package:card_swiper/card_swiper.dart';
import 'package:eyes_app/MoneyPreviewPage.dart';
import 'package:eyes_app/MySplashPage.dart';
import 'package:eyes_app/ObjectPreviewPage.dart';
import 'package:eyes_app/TextPreviewPage.dart';
import 'package:eyes_app/common/SpeakToText.dart';
import 'package:eyes_app/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:tflite_v2/tflite_v2.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentMode = 0;
  final List<IconData> iconList = [
    Icons.description,
    Icons.emoji_objects,
    Icons.payments,
  ];
  final List<Color> iconColor = [
    Colors.red,
    Colors.green,
    Colors.yellow.shade600,
  ];

  bool isWorking = false;
  late CameraController cameraController;
  CameraImage? imgCamera;

  final SwiperController _swiperController = SwiperController();

  String scannedText = "";
  bool textScanning = false;

  late FlutterVision vision;
  late List<Map<String, dynamic>> yoloResults;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;

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
        speak("Nhận dạng văn bản");
        break;
      case 1:
        speak("Nhận dạng vật thể");
      case 2:
        speak("Nhận dạng tiền tệ");
    }
  }

  void _animateToCenter(int index) {
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ObjectPreviewPage(file, vision),
          ),
        );
      } else if (currentMode == 2) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MoneyPreviewPage(file, vision),
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
    vision = FlutterVision();
    initCamera();
    checkCurrentMode();
  }

  @override
  void dispose() async {
    super.dispose();
    await Tflite.close();
    await vision.closeYoloModel();
    cameraController.dispose();
  }

  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Scaffold(
          body: Center(
            child: GestureDetector(
              onTap: takePicture,
              onHorizontalDragEnd: (DragEndDetails details) {
                if (details.primaryVelocity! > 0) {
                  setState(() {
                    if (currentMode > 0) {
                      // If currentMode is 3, reset it to 0 when swiping right
                      --currentMode;
                    } else {
                      // Otherwise, decrement currentMode
                      currentMode = 2;
                    }
                    _animateToCenter(currentMode);
                    checkCurrentMode();
                  });
                  print('Swiped right');
                } else if (details.primaryVelocity! < 0) {
                  setState(() {
                    if (currentMode < 2) {
                      // If currentMode is 3, reset it to 0 when swiping right
                      ++currentMode;
                    } else {
                      // Otherwise, decrement currentMode
                      currentMode = 0;
                    }
                    _animateToCenter(currentMode);
                    checkCurrentMode();
                  });

                  print('Swiped left');
                }
              },
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  color: Colors.black,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height - 200,
                        child: CameraPreview(cameraController),
                      ),
                      const SizedBox(height: 25.0),
                      Center(
                        child: Container(
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
                      ),
                    ],
                  ),
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
          color: iconColor,
          shape: CircleBorder(
            side: BorderSide(
              color:
                  (currentMode == iconIndex) ? Colors.blue : Colors.transparent,
              width: 3.0,
            ),
          )),
      child: IconButton(
        onPressed: () {},
        icon: Icon(iconData),
        color: Colors.white,
        iconSize: (currentMode == iconIndex) ? 40 : 30,
      ),
    );
  }
}
