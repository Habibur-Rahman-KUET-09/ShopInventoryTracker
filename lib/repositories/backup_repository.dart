import 'dart:convert';

import 'package:hive/hive.dart';

import 'hive_boxes.dart';

/// Reads/writes the entire app database (products, sales, বাকি customers)
/// as a single JSON document, for the export/import (data backup) feature.
class BackupRepository {
  static const int formatVersion = 1;

  Map<String, dynamic> _boxToJson(Box<Map> box) {
    return box.toMap().map<String, dynamic>(
          (key, value) =>
              MapEntry(key.toString(), Map<String, dynamic>.from(value)),
        );
  }

  Map<String, dynamic> exportAll() {
    return {
      'app': 'dokan_hisab',
      'formatVersion': formatVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'products': _boxToJson(HiveBoxes.products),
      'sales': _boxToJson(HiveBoxes.sales),
      'dueCustomers': _boxToJson(HiveBoxes.dueCustomers),
    };
  }

  String exportJson() =>
      const JsonEncoder.withIndent('  ').convert(exportAll());

  /// Restores data from a previously exported JSON string. When
  /// [replaceExisting] is true (the default) all current data is cleared
  /// first; otherwise imported records are merged in, overwriting any
  /// existing record with the same id.
  Future<void> importJson(String jsonStr, {bool replaceExisting = true}) async {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! Map || decoded['app'] != 'dokan_hisab') {
      throw const FormatException('এটি দোকান হিসাব-এর ব্যাকআপ ফাইল নয়');
    }
    final data = decoded;

    if (replaceExisting) {
      await HiveBoxes.products.clear();
      await HiveBoxes.sales.clear();
      await HiveBoxes.dueCustomers.clear();
    }

    Future<void> restore(Box<Map> box, dynamic section) async {
      if (section is! Map) return;
      for (final entry in section.entries) {
        await box.put(entry.key, Map<String, dynamic>.from(entry.value as Map));
      }
    }

    await restore(HiveBoxes.products, data['products']);
    await restore(HiveBoxes.sales, data['sales']);
    await restore(HiveBoxes.dueCustomers, data['dueCustomers']);
  }
}
