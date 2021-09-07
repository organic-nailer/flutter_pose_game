import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BarcodeViewModel extends StateNotifier<List<BarcodeData>> {
  BarcodeViewModel() : super([]);

  int id = 0;

  Future _removeBarcode(int id) async {
    state = state.where((e) => e.id != id).toList();
  }

  Future onRemoveClicked(BarcodeData data) async {
    _removeBarcode(data.id);
  }

  Future addBarcode(String value) async {
    final created = DateTime.now();
    final newId = id++;
    state = [...state, BarcodeData(newId, value, created)];
  }
}

@immutable
class BarcodeData {
  final int id;
  final String value;
  final DateTime createdAt;
  const BarcodeData(this.id, this.value, this.createdAt);
}
