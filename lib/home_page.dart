import 'dart:io';

import 'package:flutter/material.dart';

import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as image;

const String ssd = 'SSD MobileNet';
const String yolo = 'Tiny YOLOv2';

class HomePage extends StatefulWidget {
  const HomePage({required this.title, Key? key}) : super(key: key);

  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String _model = ssd;

  late File _image;

  double _imageWidth = 0;
  double _imageHeight = 0;

  bool _busy = false;
  List<dynamic>? _recognitions;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(elevation: 0, title: Text(widget.title)),
        body: const Center(),
        floatingActionButton: FloatingActionButton(
          tooltip: 'Pick Image',
          child: const Icon(Icons.add_a_photo),
          onPressed: _pickImage,
        ),
      );

  Future<void> _pickImage() async {
    final XFile? image =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    if (image == null) {
      return;
    }

    setState(() => _busy = true);

    await _predictImage(File(image.path));

    setState(() => _busy = false);
  }

  Future<void> _predictImage(File? image) async {
    if (image == null) {
      return;
    }

    switch (_model) {
      case ssd:
        await _predictSSD(image);
        break;
      case yolo:
        await _predictYOLO(image);
        break;

      default:
        throw Exception('Unknown model: $_model');
    }

    FileImage(image).resolve(const ImageConfiguration()).addListener(
      ImageStreamListener(
        (ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        },
      ),
    );

    setState(() => _image = image);
  }

  Future<void> _predictSSD(File image) async {
    final List<dynamic>? recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      numResultsPerClass: 1,
    );

    setState(() => _recognitions = recognitions);
  }

  Future<void> _predictYOLO(File image) async {
    final List<dynamic>? recognitions = await Tflite.detectObjectOnImage(
      path: image.path,
      model: 'YOLO',
      threshold: 0.3,
      imageMean: 0,
      imageStd: 255,
      numResultsPerClass: 1,
    );

    setState(() => _recognitions = recognitions);
  }
}
