import 'dart:io';
import 'dart:typed_data';
import 'package:eyes_app/common/SpeakToText.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:image_picker/image_picker.dart';
import 'package:translator/translator.dart';

class MoneyPreviewPage extends StatefulWidget {
  MoneyPreviewPage(this.file, this.vision, {super.key});
  XFile file;
  final FlutterVision vision;

  @override
  State<MoneyPreviewPage> createState() => _ObjectPreviewPageState();
}

class _ObjectPreviewPageState extends State<MoneyPreviewPage> {
  GoogleTranslator translator = GoogleTranslator();
  String translate_text = '';

  late List<Map<String, dynamic>> yoloResults = [];
  File? imageFile;
  int imageHeight = 1;
  int imageWidth = 1;
  bool isLoaded = false;
  String output = '';

  @override
  void initState() {
    super.initState();
    loadYoloModel().then((value) {
      yoloOnImage().then((value) {});
    });
  }

  @override
  void dispose() async {
    flutterTts.stop();
    speak('Trở về màn hình chính');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);
    var width_screen = MediaQuery.of(context).size.width;
    var height_screen = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        width: width_screen,
        height: height_screen,
        color: Colors.white,
        child: Column(
          children: [
            Container(child: Image.file(picture)),
            const SizedBox(height: 30),
            Container(
              height: 70,
              alignment: Alignment.topLeft,
              padding: EdgeInsets.only(left: 15, right: 15),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                physics: AlwaysScrollableScrollPhysics(),
                child: Text(
                  yoloResults.isEmpty
                      ? 'Rất tiếc, có vẻ như không có tờ tiền nào cả, bạn có thể thử chụp lại một bức ảnh khác!'
                      : '${translate_text}',
                  style: TextStyle(
                    fontSize: 20.0,
                    decoration: TextDecoration.none,
                    color: Colors.black,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<String> translated() async {
    var translation = await translator
        .translate(output.isNotEmpty ? output : 'none', from: 'en', to: 'vi');
    final String out = translation.toString();
    setState(() {
      translate_text = translation.toString();
    });
    if (yoloResults.isEmpty) {
      speak(
          'Rất tiếc, có vẻ như không có tờ tiền nào cả, bạn có thể thử chụp lại một bức ảnh khác!');
    } else {
      speak('${translate_text}');
    }
    ;
    return out;
  }

  Future<void> loadYoloModel() async {
    await widget.vision.loadYoloModel(
        labels: 'assets/tflite/money_labels.txt',
        modelPath: 'assets/tflite/money_float32.tflite',
        modelVersion: "yolov8",
        quantization: false,
        numThreads: 2,
        useGpu: false);
    setState(() {
      isLoaded = true;
    });
  }

  yoloOnImage() async {
    yoloResults.clear();
    Uint8List byte = await widget.file.readAsBytes();
    final image = await decodeImageFromList(byte);
    imageHeight = image.height;
    imageWidth = image.width;
    final result = await widget.vision.yoloOnImage(
        bytesList: byte,
        imageHeight: image.height,
        imageWidth: image.width,
        iouThreshold: 0.8,
        confThreshold: 0.4,
        classThreshold: 0.5);

    output = '';
    Set<String> uniqueTags = Set<String>();

    result.forEach((element) {
      if (uniqueTags.add(element['tag'])) {
        output += element['tag'] + ', ';
      }
    });

    translated();
    if (result.isNotEmpty) {
      setState(() {
        yoloResults = result;
        output;
        isLoaded = true;
      });
    }
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (yoloResults.isEmpty) return [];

    double factorX = screen.width / (imageWidth);
    double imgRatio = imageWidth / imageHeight;
    double newWidth = imageWidth * factorX;
    double newHeight = newWidth / imgRatio;
    double factorY = newHeight / (imageHeight);

    double pady = (screen.height - newHeight) / 2;

    Color colorPick = const Color.fromARGB(255, 50, 233, 30);
    return yoloResults.map((result) {
      return Positioned(
        left: result["box"][0] * factorX,
        top: result["box"][1] * factorY + pady,
        width: (result["box"][2] - result["box"][0]) * factorX,
        height: (result["box"][3] - result["box"][1]) * factorY,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(10.0)),
            border: Border.all(color: Colors.pink, width: 2.0),
          ),
          child: Text(
            "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(0)}%",
            style: TextStyle(
              background: Paint()..color = colorPick,
              color: Colors.white,
              fontSize: 18.0,
            ),
          ),
        ),
      );
    }).toList();
  }
}
