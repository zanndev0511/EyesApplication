import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ObjectPreviewPage extends StatefulWidget {
  ObjectPreviewPage(this.file, this.result, {super.key});
  XFile file;
  String result;

  @override
  State<ObjectPreviewPage> createState() => _ObjectPreviewPageState();
}

class _ObjectPreviewPageState extends State<ObjectPreviewPage> {
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
