import 'dart:io';

import 'package:camera/camera.dart';
import 'package:eyes_app/CameraPreviewPage.dart';
import 'package:eyes_app/main.dart';
import 'package:flutter/material.dart';
import 'package:tflite_v2/tflite_v2.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int currentMode = 0;
  bool isWorking = false;
  String result = "";
  late CameraController cameraController;
  CameraImage? imgCamera;

  loadModel() async {
    await Tflite.loadModel(
      model: 'assets/tflite/mobilenet_v1_1.0_224.tflite',
      labels: 'assets/tflite/mobilenet_v1_1.0_224.txt',
    );
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

  @override
  void initState() {
    super.initState();
    loadModel();
    initCamera();
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
              onTap: () async {
                if (!cameraController.value.isInitialized) {
                  return;
                }
                if (cameraController.value.isTakingPicture) {
                  return;
                }

                try {
                  await cameraController.setFlashMode(FlashMode.auto);
                  XFile file = await cameraController.takePicture();
                  await imageClassification(File(file.path));
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CameraPreviewPage(file, result),
                    ),
                  );
                } on CameraException catch (e) {
                  debugPrint('Error while taking picture: $e');
                  return;
                }
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width,
                    height: MediaQuery.of(context).size.height - 200,
                    child: AspectRatio(
                      aspectRatio: cameraController.value.aspectRatio,
                      child: CameraPreview(cameraController),
                    ),
                  ),
                  Center(
                    child: IconButton(
                      onPressed: () {
                        // Xử lý sự kiện chụp hình
                      },
                      icon: const Icon(Icons.camera),
                      color: Colors.blue,
                      iconSize: 90,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Ink(
                        decoration: const ShapeDecoration(
                          color: Colors.red, // Màu nền của icon button
                          shape: CircleBorder(
                              side: BorderSide(color: Colors.blue, width: 3.0)),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Xử lý sự kiện chụp hình
                          },
                          icon: const Icon(
                            Icons.description,
                            // Màu của biểu tượng
                          ),
                          color: Colors.white,
                          iconSize: 40,
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      Ink(
                        decoration: const ShapeDecoration(
                          color: Colors.green, // Màu nền của icon button
                          shape: CircleBorder(
                              side: BorderSide(color: Colors.blue, width: 3.0)),
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Xử lý sự kiện chụp hình
                          },
                          icon: const Icon(
                            Icons.emoji_objects,
                            // Màu của biểu tượng
                          ),
                          color: Colors.white,
                          iconSize: 40,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
