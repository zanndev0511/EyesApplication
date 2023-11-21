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
    cameraController = CameraController(cameras[1], ResolutionPreset.high);
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
              child: Container(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height,
                child: AspectRatio(
                  aspectRatio: cameraController.value.aspectRatio,
                  child: CameraPreview(cameraController),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
