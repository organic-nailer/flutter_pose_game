import 'dart:math' as Math;

import 'package:google_ml_kit/google_ml_kit.dart';

class PoseCompare {
  static List<PoseLandmarkType> usingLandmarks = [
    PoseLandmarkType.leftShoulder,
    //PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,
    PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,
    PoseLandmarkType.rightAnkle
  ];

  static List<List<double>>? transform(Pose pose) {
    print("transform: $pose");
    final basePoint = pose.landmarks[PoseLandmarkType.rightShoulder];
    if (basePoint == null) return null;
    final res = <List<double>>[];
    usingLandmarks.forEach((type) {
      if (!pose.landmarks.containsKey(type)) return null;
      final landmark = pose.landmarks[type]!;
      res.add([
        basePoint.x - landmark.x,
        basePoint.y - landmark.y,
        basePoint.z - landmark.z
      ]);
    });
    return res;
  }

  static double compare(List<List<double>> a, List<List<double>> b) {
    if (a.length != b.length) return 0;
    double sum = 0;
    for (int i = 0; i < a.length; i++) {
      sum += cosSimilarity(a[i], b[i]);
    }
    return sum / a.length;
  }

  static double cosSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    double inner = 0;
    double squareA = 0;
    double squareB = 0;
    for (int i = 0; i < a.length; i++) {
      inner += a[i] * b[i];
      squareA += a[i] * a[i];
      squareB += b[i] * b[i];
    }
    return inner / (Math.sqrt(squareA) * Math.sqrt(squareB));
  }
}
