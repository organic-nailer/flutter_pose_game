import 'package:barcode_reader_ml/camera_view.dart';
import 'package:barcode_reader_ml/pose_compare.dart';
import 'package:barcode_reader_ml/pose_painter.dart';
import 'package:barcode_reader_ml/pose_painter_engine.dart';
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
