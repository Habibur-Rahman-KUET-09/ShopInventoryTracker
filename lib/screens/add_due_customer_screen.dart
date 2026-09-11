import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/due_customer.dart';
import '../providers/due_provider.dart';
import '../theme/app_theme.dart';

/// বাকি entry screen: typing an existing customer's name auto-fills their
/// phone and adds the amount to their running balance; typing a new name
/// creates that customer on save.
class AddDueCustomerScreen extends StatefulWidget {
  const AddDueCustomerScreen({super.key});

  @override
  State<AddDueCustomerScreen> createState() => _AddDueCustomerScreenState();
}

class _AddDueCustomerScreenState extends State<AddDueCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();

  DueCustomer? _existing;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _selectExisting(DueCustomer customer) {
    setState(() {
      _existing = customer;
      _nameCtrl.text = customer.name;
      _phoneCtrl.text = customer.phone;
    });
  }

  void _onNameChanged(String value) {
    setState(() {
      if (_existing != null && _existing!.name != value) {
        _existing = null;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dueProvider = context.read<DueProvider>();
    final name = _nameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text) ?? 0;

    if (_existing == null && dueProvider.findByName(name) == null) {
      await dueProvider.addDueByName(
        name: name,
        phone: _phoneCtrl.text.trim(),
        amount: amount,
      );
    } else {
      final target = _existing ?? dueProvider.findByName(name)!;
      if (amount > 0) {
        await dueProvider.addDueByName(name: target.name, amount: amount);
      }
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dueProvider = context.watch<DueProvider>();
    final suggestions = _existing == null
        ? dueProvider.searchByName(_nameCtrl.text)
        : const <DueCustomer>[];

    return Scaffold(
      appBar: AppBar(title: const Text('বাকি এন্ট্রি')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'গ্রাহকের নাম *',
                helperText: 'বিদ্যমান গ্রাহকের নাম লিখলে তালিকা থেকে বেছে নিন',
              ),
              onChanged: _onNameChanged,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'নাম লিখুন' : null,
            ),
            if (suggestions.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: suggestions
                      .map((c) => ListTile(
                            dense: true,
                            leading: const Icon(Icons.person_outline),
                            title: Text(c.name),
                            subtitle:
                                c.phone.isNotEmpty ? Text(c.phone) : null,
                            onTap: () => _selectExisting(c),
                          ))
                      .toList(),
                ),
              ),
            if (_existing != null)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppTheme.primaryGreen, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'বিদ্যমান গ্রাহক নির্বাচিত হয়েছে — বিস্তারিত স্বয়ংক্রিয়ভাবে এসেছে',
                        style: TextStyle(
                            color: AppTheme.primaryGreen.withValues(alpha: 0.9),
                            fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              enabled: _existing == null,
              decoration: const InputDecoration(labelText: 'মোবাইল নম্বর'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _amountCtrl,
              decoration: InputDecoration(
                labelText: 'বাকির পরিমাণ (৳)',
                helperText: _existing != null
                    ? 'বিদ্যমান বাকির সাথে যোগ হবে'
                    : 'না দিলে ০ ধরা হবে',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                if (double.tryParse(v) == null) return 'সঠিক পরিমাণ দিন';
                return null;
              },
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: Text(_existing != null ? 'বাকি যোগ করুন' : 'সংরক্ষণ করুন'),
            ),
          ],
        ),
      ),
    );
  }
}
