import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'package:dokan_hisab/models/due_transaction.dart';
import 'package:dokan_hisab/providers/due_provider.dart';
import 'package:dokan_hisab/repositories/due_repository.dart';
import 'package:dokan_hisab/repositories/hive_boxes.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync(
      'dokan_hisab_due_provider_test',
    );
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

  test(
    'addDueByName creates a new customer when the name is unknown',
    () async {
      final provider = DueProvider(DueRepository());
      final customer = await provider.addDueByName(
        name: 'করিম',
        phone: '017xxxxxxx',
        amount: 500,
      );

      expect(provider.customers, hasLength(1));
      expect(customer.totalDue, 500);
    },
  );

  test('addDueByName adds to the existing customer found by name (case-insensitive)', () async {
    final provider = DueProvider(DueRepository());
    await provider.addCustomer(
      name: 'করিম',
      phone: '017xxxxxxx',
      initialDue: 200,
    );

    final customer = await provider.addDueByName(name: 'করিম', amount: 300);

    expect(provider.customers, hasLength(1));
    expect(customer.totalDue, 500);
  });

  test('findByName is case-insensitive and trims whitespace', () async {
    final provider = DueProvider(DueRepository());
    await provider.addCustomer(name: 'সুমন মিয়া');

    expect(provider.findByName('  সুমন মিয়া  '), isNotNull);
    expect(provider.findByName('অস্তিত্বহীন'), isNull);
  });

  test('updateTransaction changes amount/type of an existing entry, keeping its id and date', () async {
    final provider = DueProvider(DueRepository());
    final customer = await provider.addCustomer(name: 'জামাল', initialDue: 500);
    final txn = customer.transactions.single;

    await provider.updateTransaction(
      customer.id,
      txn.id,
      amount: 300,
      type: DueTransactionType.paid,
    );

    final updated = provider.byId(customer.id)!.transactions.single;
    expect(updated.id, txn.id);
    expect(updated.amount, 300);
    expect(updated.type, DueTransactionType.paid);
    expect(provider.byId(customer.id)!.totalDue, -300);
  });

  test('deleteTransaction removes only the targeted entry', () async {
    final provider = DueProvider(DueRepository());
    final customer = await provider.addCustomer(
      name: 'নাসরিন',
      initialDue: 200,
    );
    await provider.addTransaction(customer.id, 100, DueTransactionType.paid);
    final toDelete = provider.byId(customer.id)!.transactions.first;

    await provider.deleteTransaction(customer.id, toDelete.id);

    final remaining = provider.byId(customer.id)!.transactions;
    expect(remaining, hasLength(1));
    expect(remaining.any((t) => t.id == toDelete.id), isFalse);
  });
}
