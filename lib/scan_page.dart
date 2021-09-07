import 'package:barcode_reader_ml/camera_view.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({Key? key}) : super(key: key);

  @override
  _ScanPageState createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  bool isBusy = false;
  BarcodeScanner barcodeScanner =
      GoogleMlKit.vision.barcodeScanner([BarcodeFormat.qrCode]);
  @override
  void dispose() {
    barcodeScanner.close();
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
                final res = await onImage(image);
                if (res != null) {
                  Navigator.of(context).pop(res);
                }
              },
            ),
          )
        ],
      ),
    );
  }

  Future<String?> onImage(InputImage image) async {
    if (!isBusy) return await processImage(image);
    return null;
  }

  Future<String?> processImage(InputImage image) async {
    isBusy = true;
    final results = await barcodeScanner.processImage(image);
    if (results.isNotEmpty) {
      results.forEach((element) {
        print("Barcode Detected: ${element.value.rawValue}");
      });
      return results.first.value.rawValue;
    }
    isBusy = false;
    return null;
  }
}
