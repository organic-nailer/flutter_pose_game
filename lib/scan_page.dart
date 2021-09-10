import 'dart:io';

import 'package:barcode_reader_ml/camera_view.dart';
import 'package:barcode_reader_ml/create_pose_page.dart';
import 'package:barcode_reader_ml/pose_compare.dart';
import 'package:barcode_reader_ml/pose_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

final similarityProvider = StateProvider<double>((_) => 0);

class ScanPage extends StatefulWidget {
  final PoseData data;
  const ScanPage({Key? key, required this.data}) : super(key: key);

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
        title: const Text("Scan"),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CameraView(
              listener: (image) async {
                onImage(image, context);
                // final res = await onImage(image);
                // if (res != null) {
                //   Navigator.of(context).pop(res);
                // }
              },
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Card(
              color: Colors.white,
              child: SizedBox(
                width: 100,
                height: 200,
                child: CustomPaint(
                  painter: PosePainter(StaticPosePainterEngine(
                      widget.data.poses,
                      widget.data.absoluteImageSize,
                      widget.data.rotation)),
                ),
              ),
            ),
          ),
          Positioned.fill(
              child: CustomPaint(
            painter: PosePainter(engine),
          )),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Consumer(builder: (context, watch, child) {
                return Text(
                  watch(similarityProvider).state.toStringAsFixed(4),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                      color: Colors.red),
                );
              }),
            ),
          )
        ],
      ),
    );
  }

  void onImage(InputImage image, BuildContext context) async {
    if (!isBusy) processImage(image, context);
  }

  void processImage(InputImage image, BuildContext context) async {
    if (isBusy) return;
    isBusy = true;
    final rawData = await engine.update(image);
    if (rawData?.poses.isNotEmpty == true) {
      final currentPose = PoseCompare.transform(rawData!.poses.first);
      final sample = PoseCompare.transform(widget.data.poses.first);
      if (currentPose != null && sample != null) {
        context.read(similarityProvider).state =
            PoseCompare.compare(currentPose, sample);
      }
    }
    isBusy = false;
  }
}

abstract class IPosePainterEngine extends ChangeNotifier {
  List<Pose> get poses;
  Size? get absoluteImageSize;
  InputImageRotation? get rotation;
}

class StaticPosePainterEngine extends IPosePainterEngine {
  @override
  final List<Pose> poses;
  @override
  final Size absoluteImageSize;
  @override
  final InputImageRotation rotation;
  StaticPosePainterEngine(this.poses, this.absoluteImageSize, this.rotation);
}

class PosePainterEngine extends IPosePainterEngine {
  @override
  List<Pose> poses = [];
  @override
  Size? absoluteImageSize;
  @override
  InputImageRotation? rotation;
  PoseDetector poseDetector = GoogleMlKit.vision.poseDetector();
  PosePainterEngine();

  void close() {
    poseDetector.close();
  }

  Future<RawPoseData?> update(InputImage image) async {
    final poses = await poseDetector.processImage(image);
    if (image.inputImageData?.size != null &&
        image.inputImageData?.imageRotation != null) {
      this.poses = poses;
      absoluteImageSize = image.inputImageData!.size;
      rotation = image.inputImageData!.imageRotation;
      notifyListeners();
      return RawPoseData(this.poses, absoluteImageSize!, rotation!);
    }
    return null;
  }
}

class PosePainter extends CustomPainter {
  final IPosePainterEngine engine;
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

    for (var pose in engine.poses) {
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
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, leftPaint);
      paintLine(
          PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, leftPaint);
      paintLine(
          PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, rightPaint);
      paintLine(
          PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, rightPaint);
    }
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
