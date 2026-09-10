import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dokan_hisab/main.dart';
import 'package:dokan_hisab/repositories/hive_boxes.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dokan_hisab_flow_test');
    Hive.init(tempDir.path);
    await Hive.openBox<Map>(HiveBoxes.productsBox);
    await Hive.openBox<Map>(HiveBoxes.salesBox);
    await Hive.openBox<Map>(HiveBoxes.dueCustomersBox);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Future<void> addProduct(
    WidgetTester tester, {
    required String name,
    required String buyPrice,
    required String sellPrice,
    required String quantity,
  }) async {
    await tester.tap(find.text('স্টক'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('নতুন পণ্য'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'পণ্যের নাম *'), name);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'ক্রয় মূল্য (৳) *'), buyPrice);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'বিক্রয় মূল্য (৳) *'), sellPrice);
    await tester.enterText(
        find.widgetWithText(TextFormField, 'পরিমাণ (স্টক) *'), quantity);

    await tester.tap(find.text('সংরক্ষণ করুন'));
    await tester.pumpAndSettle();
  }

  testWidgets('adding a product shows it in the stock list',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DokanHisabApp());
    await tester.pumpAndSettle();

    await addProduct(
      tester,
      name: 'চাল (৫ কেজি)',
      buyPrice: '350',
      sellPrice: '400',
      quantity: '10',
    );

    expect(find.text('চাল (৫ কেজি)'), findsOneWidget);
    expect(find.text('10 পিস'), findsOneWidget);
  });

  testWidgets('low stock quantity is highlighted', (WidgetTester tester) async {
    await tester.pumpWidget(const DokanHisabApp());
    await tester.pumpAndSettle();

    await addProduct(
      tester,
      name: 'সাবান',
      buyPrice: '20',
      sellPrice: '30',
      quantity: '3',
    );

    expect(find.text('স্টক কম!'), findsOneWidget);
  });

  testWidgets('completing a sale reduces stock and records the sale',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DokanHisabApp());
    await tester.pumpAndSettle();

    await addProduct(
      tester,
      name: 'চিনি',
      buyPrice: '90',
      sellPrice: '110',
      quantity: '5',
    );

    await tester.tap(find.text('বিক্রি'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('নতুন বিক্রি'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();

    await tester.tap(find.textContaining('বিক্রি সম্পন্ন করুন'));
    await tester.pumpAndSettle();

    expect(find.text('বিক্রি সফলভাবে সংরক্ষণ হয়েছে'), findsOneWidget);

    await tester.tap(find.text('স্টক'));
    await tester.pumpAndSettle();
    expect(find.text('3 পিস'), findsOneWidget);
  });

  testWidgets('adding a due customer and a payment updates the balance',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DokanHisabApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('বাকি'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('নতুন গ্রাহক'));
    await tester.pumpAndSettle();

    await tester.enterText(
        find.widgetWithText(TextFormField, 'গ্রাহকের নাম *'), 'করিম');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'বাকির পরিমাণ (৳)'), '500');
    await tester.tap(find.text('সংরক্ষণ করুন'));
    await tester.pumpAndSettle();

    expect(find.text('করিম'), findsOneWidget);
    expect(find.text('৳500'), findsWidgets);

    await tester.tap(find.text('করিম'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('পরিশোধ'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '200');
    await tester.tap(find.text('সংরক্ষণ করুন'));
    await tester.pumpAndSettle();

    expect(find.text('৳300'), findsWidgets);
  });
}
