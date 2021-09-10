import 'package:barcode_reader_ml/pose_viewmodel.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

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

  StaticPosePainterEngine.fromRaw(PoseData data)
      : this(data.poses, data.absoluteImageSize, data.rotation);
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
