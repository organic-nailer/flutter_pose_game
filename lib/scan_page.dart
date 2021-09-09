import 'dart:io';

import 'package:barcode_reader_ml/camera_view.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isBusy = false;
  CustomPaint? customPaint;
  PosePainterEngine engine = PosePainterEngine();
  @override
  void dispose() {
    engine.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Scan"),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraView(
              listener: (image) async {
                onImage(image);
                // final res = await onImage(image);
                // if (res != null) {
                //   Navigator.of(context).pop(res);
                // }
              },
            ),
          ),
          Positioned.fill(
              child: CustomPaint(
            painter: PosePainter(engine),
          ))
        ],
      ),
    );
  }

  void onImage(InputImage image) async {
    if (!isBusy) processImage(image);
  }

  void processImage(InputImage image) async {
    if (isBusy) return;
    isBusy = true;
    await engine.update(image);
    isBusy = false;
  }
}

class PosePainterEngine extends ChangeNotifier {
  List<Pose> poses = [];
  Size? absoluteImageSize;
  InputImageRotation? rotation;
  PoseDetector poseDetector = GoogleMlKit.vision.poseDetector();
  PosePainterEngine();

  void close() {
    poseDetector.close();
  }

  Future update(InputImage image) async {
    final poses = await poseDetector.processImage(image);
    print('Found ${poses.length} poses');
    if (image.inputImageData?.size != null &&
        image.inputImageData?.imageRotation != null) {
      this.poses = poses;
      this.absoluteImageSize = image.inputImageData!.size;
      this.rotation = image.inputImageData!.imageRotation;
      notifyListeners();
    }
  }
}

class PosePainter extends CustomPainter {
  final PosePainterEngine engine;
  PosePainter(this.engine) : super(repaint: engine);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    final leftPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.yellow;

    final rightPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.blueAccent;

    final rotation = engine.rotation;
    final absoluteImageSize = engine.absoluteImageSize;
    if (rotation == null || absoluteImageSize == null) return;

    engine.poses.forEach((pose) {
      pose.landmarks.forEach((_, landmark) {
        canvas.drawCircle(
            Offset(
              translateX(landmark.x, rotation, size, absoluteImageSize),
              translateY(landmark.y, rotation, size, absoluteImageSize),
            ),
            1,
            paint);
      });

      void paintLine(
          PoseLandmarkType type1, PoseLandmarkType type2, Paint paintType) {
        PoseLandmark joint1 = pose.landmarks[type1]!;
        PoseLandmark joint2 = pose.landmarks[type2]!;
        canvas.drawLine(
            Offset(translateX(joint1.x, rotation, size, absoluteImageSize),
                translateY(joint1.y, rotation, size, absoluteImageSize)),
            Offset(translateX(joint2.x, rotation, size, absoluteImageSize),
                translateY(joint2.y, rotation, size, absoluteImageSize)),
            paintType);
      }

      //Draw arms
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, leftPaint);
      paintLine(
          PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow,
          rightPaint);
      paintLine(
          PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, rightPaint);

      //Draw Body
      paintLine(
          PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, leftPaint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip,
          rightPaint);

      //Draw legs
      paintLine(
          PoseLandmarkType.leftHip, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightAnkle, rightPaint);
    });
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) => true;
}

double translateX(
    double x, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.Rotation_90deg:
      return x *
          size.width /
          (Platform.isIOS ? absoluteImageSize.width : absoluteImageSize.height);
    case InputImageRotation.Rotation_270deg:
      return size.width -
          x *
              size.width /
              (Platform.isIOS
                  ? absoluteImageSize.width
                  : absoluteImageSize.height);
    default:
      return x * size.width / absoluteImageSize.width;
  }
}

double translateY(
    double y, InputImageRotation rotation, Size size, Size absoluteImageSize) {
  switch (rotation) {
    case InputImageRotation.Rotation_90deg:
    case InputImageRotation.Rotation_270deg:
      return y *
          size.height /
          (Platform.isIOS ? absoluteImageSize.height : absoluteImageSize.width);
    default:
      return y * size.height / absoluteImageSize.height;
  }
}
