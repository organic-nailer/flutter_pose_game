import 'package:barcode_reader_ml/barcode_viewmodel.dart';
import 'package:barcode_reader_ml/main_list_page.dart';
import 'package:barcode_reader_ml/scan_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fast_ui_white/flutter_fast_ui_white.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

final barcodeViewModelProvider =
    StateNotifierProvider<BarcodeViewModel, List<BarcodeData>>((_) {
  return BarcodeViewModel();
});

void main() {
  initializeDateFormatting("ja_JP");
  runApp(ProviderScope(
      child: FastTheme(
    accentColor: Colors.pink,
    child: MyApp(),
  )));
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: FastTheme.of(context).theme,
      home: ScanPage(),
    );
  }
}
