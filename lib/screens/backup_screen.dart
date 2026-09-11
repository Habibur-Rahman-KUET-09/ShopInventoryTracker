import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../providers/due_provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../repositories/backup_repository.dart';
import '../utils/formatters.dart';

/// Export the whole local database to a JSON file (to back up / move to a
/// new phone) and import it back in.
class BackupScreen extends StatefulWidget {
  const BackupScreen({super.key});

  @override
  State<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends State<BackupScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final json = BackupRepository().exportJson();
      final dir = await getTemporaryDirectory();
      final fileName =
          'dokan-hisab-backup-${DateTime.now().millisecondsSinceEpoch}.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'দোকান হিসাব ব্যাকআপ — ${Formatters.date(DateTime.now())}',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('এক্সপোর্ট ব্যর্থ হয়েছে: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (files.isEmpty) return;
    final picked = files.single;

    if (!mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ডেটা পুনরুদ্ধার করবেন?'),
        content: const Text(
          'এই ফাইল থেকে ডেটা আনলে বর্তমান সব পণ্য, বিক্রি ও বাকির হিসাব মুছে '
          'ফাইলের ডেটা দিয়ে প্রতিস্থাপিত হবে। এই কাজ ফিরিয়ে নেওয়া যাবে না।',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('বাতিল'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('এগিয়ে যান', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      final content = utf8.decode(await picked.readAsBytes());
      await BackupRepository().importJson(content);
      if (!mounted) return;
      context.read<ProductProvider>().refresh();
      context.read<SaleProvider>().refresh();
      context.read<DueProvider>().refresh();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ডেটা সফলভাবে পুনরুদ্ধার করা হয়েছে')),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ইম্পোর্ট ব্যর্থ হয়েছে: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ডেটা এক্সপোর্ট/ইমপোর্ট')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('ডেটা এক্সপোর্ট করুন'),
              subtitle: const Text(
                  'সব পণ্য, বিক্রি ও বাকির হিসাব একটি ফাইলে সংরক্ষণ/শেয়ার করুন'),
              onTap: _busy ? null : _export,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.download_outlined),
              title: const Text('ডেটা ইমপোর্ট করুন'),
              subtitle: const Text('আগের এক্সপোর্ট করা ফাইল থেকে ডেটা ফিরিয়ে আনুন'),
              onTap: _busy ? null : _import,
            ),
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}
