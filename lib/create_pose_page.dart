import 'package:barcode_reader_ml/camera_view.dart';
import 'package:barcode_reader_ml/scan_page.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class CreatePosePage extends StatefulWidget {
  const CreatePosePage({Key? key}) : super(key: key);

  @override
  _CreatePosePageState createState() => _CreatePosePageState();
}

class _CreatePosePageState extends State<CreatePosePage> {
  bool isBusy = false;
  CustomPaint? customPaint;
  bool finished = false;
  bool shutterFlag = false;
  PosePainterEngine engine = PosePainterEngine();
  RawPoseData? data;
  @override
  void dispose() {
    engine.close();
    super.dispose();
  }

  void finishPage(BuildContext context, RawPoseData data) {
    if (finished) return;
    finished = true;
    Navigator.of(context).pop(data);
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
                if (!shutterFlag) {
                  data = await onImage(image);
                } else if (data != null) {
                  finishPage(context, data!);
                }
              },
            ),
          ),
          Positioned.fill(
              child: CustomPaint(
            painter: PosePainter(engine),
          ))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          shutterFlag = true;
        },
        child: const Icon(Icons.camera),
      ),
    );
  }

  Future<RawPoseData?> onImage(InputImage image) async {
    if (!isBusy) return await processImage(image);
    return null;
  }

  Future<RawPoseData?> processImage(InputImage image) async {
    if (isBusy) return null;
    isBusy = true;
    final res = await engine.update(image);
    isBusy = false;
    return res;
  }
}

@immutable
class RawPoseData {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  const RawPoseData(this.poses, this.absoluteImageSize, this.rotation);
}
