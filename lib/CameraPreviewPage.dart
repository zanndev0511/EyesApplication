import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraPreviewPage extends StatefulWidget {
  CameraPreviewPage(this.file, this.result, {super.key});
  XFile file;
  String result;

  @override
  State<CameraPreviewPage> createState() => _CameraPreviewPageState();
}

class _CameraPreviewPageState extends State<CameraPreviewPage> {
  @override
  Widget build(BuildContext context) {
    File picture = File(widget.file.path);
    return Scaffold(
      body: Center(
        child: Image.file(picture),
      ),
    );
  }
}
