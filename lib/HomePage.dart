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
        labels: 'assets/tflite/mobilenet_v1_1.0_224.txt');
  }

  initCamera() {
    cameraController = CameraController(cameras[1], ResolutionPreset.high);
    cameraController.initialize().then((value) {
      if (!mounted) {
        return;
      }
      setState(() {
        cameraController.startImageStream((imageFromStream) => {
              if (!isWorking)
                {
                  isWorking = true,
                  imgCamera = imageFromStream,
                  runModelOnStreamFrames(),
                }
            });
      });
    });
  }

  runModelOnStreamFrames() async {
    if (imgCamera != null) {
      var recognitions = await Tflite.runModelOnFrame(
          bytesList: imgCamera!.planes.map((plane) => plane.bytes).toList(),
          imageHeight: imgCamera!.height,
          imageWidth: imgCamera!.width,
          imageMean: 127.5,
          imageStd: 127.5,
          rotation: 90,
          numResults: 2,
          threshold: 0.1,
          asynch: true);

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

      isWorking = false;
    }
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
            child: Container(
              // margin: const EdgeInsets.only(top: 35),
              // height: 270,
              // width: 360,
              child: imgCamera == null
                  ? Container(
                      height: 270,
                      width: 360,
                      child: const Icon(
                        Icons.photo_camera_front,
                        color: Colors.blueAccent,
                        size: 40,
                      ),
                    )
                  : TextButton(
                      onPressed: () async {
                        if (!cameraController.value.isInitialized) {
                          return null;
                        }
                        if (cameraController.value.isTakingPicture) {
                          return null;
                        }

                        try {
                          await cameraController.setFlashMode(FlashMode.auto);
                          XFile file = await cameraController.takePicture();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      CameraPreviewPage(file)));
                        } on CameraException catch (e) {
                          debugPrint('Error while taking picture: $e');
                          return null;
                        }
                      },
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height,
                        child: AspectRatio(
                          aspectRatio: cameraController.value.aspectRatio,
                          child: CameraPreview(cameraController),
                        ),
                      ),
                      // Center(
                      //   child: Container(
                      //     margin: const EdgeInsets.only(top: 55.0),
                      //     child: SingleChildScrollView(
                      //       child: Text(
                      //         result,
                      //         style: const TextStyle(
                      //           backgroundColor: Colors.black87,
                      //           fontSize: 30.0,
                      //           color: Colors.white,
                      //         ),
                      //         textAlign: TextAlign.center,
                      //       ),
                      //     ),
                      //   ),
                      // )
                    ),
            ),
            // child: TextButton(
            //   onPressed: () {},
            //   child: Container(
            //     margin: const EdgeInsets.only(top: 35),
            //     // height: 270,
            //     // width: 360,
            //     child: imgCamera == null
            //         ? Container(
            //             height: 270,
            //             width: 360,
            //             child: const Icon(
            //               Icons.photo_camera_front,
            //               color: Colors.blueAccent,
            //               size: 40,
            //             ),
            //           )
            //         : Column(
            //             children: [
            //               AspectRatio(
            //                 aspectRatio: cameraController.value.aspectRatio,
            //                 child: CameraPreview(cameraController),
            //               ),
            //               Center(
            //                 child: Container(
            //                   margin: const EdgeInsets.only(top: 55.0),
            //                   child: SingleChildScrollView(
            //                     child: Text(
            //                       result,
            //                       style: const TextStyle(
            //                         backgroundColor: Colors.black87,
            //                         fontSize: 30.0,
            //                         color: Colors.white,
            //                       ),
            //                       textAlign: TextAlign.center,
            //                     ),
            //                   ),
            //                 ),
            //               )
            //             ],
            //           ),
            //   ),
            // ),
          ),
        ),
      ),
    );
  }
}
