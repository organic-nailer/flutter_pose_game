import 'package:barcode_reader_ml/create_pose_page.dart';
import 'package:barcode_reader_ml/main.dart';
import 'package:barcode_reader_ml/pose_painter.dart';
import 'package:barcode_reader_ml/pose_painter_engine.dart';
import 'package:barcode_reader_ml/pose_viewmodel.dart';
import 'package:barcode_reader_ml/scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import "package:intl/intl.dart";

class MainListPage extends ConsumerWidget {
  const MainListPage({Key? key}) : super(key: key);

  static final formatter = DateFormat("yyyy/MM/dd hh:mm");

  @override
  Widget build(context, watch) {
    final poses = watch(poseViewModelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Poses"),
      ),
      body: GridView.builder(
        gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: poses.length,
        itemBuilder: (context, index) {
          return AspectRatio(
            aspectRatio: 1,
            child: Card(
              child: InkWell(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ScanPage(data: poses[index])));
                },
                child: CustomPaint(
                  painter: PosePainter(
                      StaticPosePainterEngine.fromRaw(poses[index])),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          showPhotoDialog(context);
        },
      ),
    );
  }

  void showPhotoDialog(BuildContext context) async {
    await showDialog(
        context: context,
        builder: (context) => SimpleDialog(
              children: [
                SimpleDialogOption(
                  onPressed: () async {
                    final res = await Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const CreatePosePage()));
                    if (res is RawPoseData) {
                      await context
                          .read(poseViewModelProvider.notifier)
                          .addImage(res);
                      Navigator.pop(context);
                    }
                  },
                  child: const ListTile(
                    title: Text("写真を撮る"),
                    trailing: Icon(Icons.photo_camera),
                  ),
                )
              ],
            ));
  }
}
