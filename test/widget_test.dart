import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dokan_hisab/main.dart';
import 'package:dokan_hisab/repositories/hive_boxes.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('dokan_hisab_test');
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

  testWidgets('app boots to dashboard with Bangla bottom navigation',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DokanHisabApp());
    await tester.pumpAndSettle();

    expect(find.text('দোকান হিসাব'), findsOneWidget);
    expect(find.text('ড্যাশবোর্ড'), findsOneWidget);
    expect(find.text('বিক্রি'), findsOneWidget);
    expect(find.text('স্টক'), findsOneWidget);
    expect(find.text('বাকি'), findsOneWidget);
  });

  testWidgets('bottom navigation switches to stock screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(const DokanHisabApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('স্টক'));
    await tester.pumpAndSettle();

    expect(find.text('স্টক ম্যানেজমেন্ট'), findsOneWidget);
    expect(find.text('নতুন পণ্য'), findsOneWidget);
  });
}
