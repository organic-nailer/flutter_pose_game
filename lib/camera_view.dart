import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

typedef ImageListener = void Function(InputImage image);

class CameraView extends StatefulWidget {
  final ImageListener? listener;
  const CameraView({Key? key, this.listener}) : super(key: key);

  @override
  _CameraViewState createState() => _CameraViewState();
}

class _CameraViewState extends State<CameraView> {
  CameraController? _controller;
  CameraDescription? _camera;
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<CameraController>(
      future: initCamera(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Container(
            color: Colors.red.shade200,
            child: Center(child: Text(snapshot.error.toString())),
          );
        }
        if (snapshot.hasData) {
          final controller = snapshot.requireData;
          return CameraPreview(controller);
        }
        return const Center(
          child: Text("Loading..."),
        );
      },
    );
  }

  Future<CameraController> initCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw Exception("cannot connect");
    _camera = cameras[0];
    _controller =
        CameraController(_camera!, ResolutionPreset.medium, enableAudio: false);
    await _controller!.initialize();
    if (!mounted) throw Exception("leak");
    if (widget.listener != null) {
      _controller!.startImageStream(imageStreamListener);
    }
    return _controller!;
  }

  void imageStreamListener(CameraImage image) {
    if (_camera == null) return;
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(image.width.toDouble(), image.height.toDouble());

    final imageRotation =
        InputImageRotationMethods.fromRawValue(_camera!.sensorOrientation) ??
            InputImageRotation.Rotation_0deg;

    final inputImageFormat =
        InputImageFormatMethods.fromRawValue(image.format.raw) ??
            InputImageFormat.NV21;

    final planeData = image.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation,
      inputImageFormat: inputImageFormat,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);

    widget.listener?.call(inputImage);
  }
}
