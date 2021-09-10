import 'package:barcode_reader_ml/create_pose_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class PoseViewModel extends StateNotifier<List<PoseData>> {
  PoseViewModel() : super([]);

  int id = 0;

  Future _removeBarcode(int id) async {
    state = state.where((e) => e.id != id).toList();
  }

  Future onRemoveClicked(PoseData data) async {
    _removeBarcode(data.id);
  }

  Future addImage(RawPoseData value) async {
    final created = DateTime.now();
    final newId = id++;
    state = [
      ...state,
      PoseData(
          newId, value.poses, value.absoluteImageSize, value.rotation, created)
    ];
  }
}

@immutable
class PoseData {
  final int id;
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final DateTime createdAt;
  const PoseData(this.id, this.poses, this.absoluteImageSize, this.rotation,
      this.createdAt);
}
