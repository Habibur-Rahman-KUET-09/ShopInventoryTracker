import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/due_customer.dart';
import '../providers/due_provider.dart';
import '../theme/app_theme.dart';

/// Shared "pick or quick-add a customer" field, used on both the sale entry
/// and বাকি entry screens.
///
/// Typing a name that matches an existing customer lets the user select it
/// (auto-filling phone and every other detail from the stored record);
/// typing a new name offers a one-tap "নতুন গ্রাহক হিসেবে যোগ করুন" action.
class CustomerPickerField extends StatefulWidget {
  final DueCustomer? selected;
  final ValueChanged<DueCustomer?> onChanged;
  final String label;

  const CustomerPickerField({
    super.key,
    required this.selected,
    required this.onChanged,
    this.label = 'গ্রাহক (ঐচ্ছিক)',
  });

  @override
  State<CustomerPickerField> createState() => _CustomerPickerFieldState();
}

class _CustomerPickerFieldState extends State<CustomerPickerField> {
  late final TextEditingController _controller = TextEditingController(
    text: _displayText(widget.selected),
  );

  String _displayText(DueCustomer? c) {
    if (c == null) return '';
    return '${c.name}${c.phone.isNotEmpty ? ' • ${c.phone}' : ''}';
  }

  @override
  void didUpdateWidget(covariant CustomerPickerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected != widget.selected) {
      _controller.text = _displayText(widget.selected);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final result = await showModalBottomSheet<_PickResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _CustomerPickerSheet(),
    );
    if (result != null) widget.onChanged(result.customer);
  }

  @override
  Widget build(BuildContext context) {
    // A real (read-only) form field renders the floating label exactly like
    // every other input in the app; a bare InputDecorator misjudges the
    // label's vertical anchor and overlaps the box's top border.
    return TextFormField(
      controller: _controller,
      readOnly: true,
      showCursor: false,
      onTap: _open,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: 'গ্রাহক খুঁজুন বা নতুন যোগ করুন',
        suffixIcon: widget.selected != null
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => widget.onChanged(null),
              )
            : const Icon(Icons.person_search),
      ),
    );
  }
}

class _PickResult {
  final DueCustomer? customer;
  const _PickResult(this.customer);
}

class _CustomerPickerSheet extends StatefulWidget {
  const _CustomerPickerSheet();

  @override
  State<_CustomerPickerSheet> createState() => _CustomerPickerSheetState();
}

class _CustomerPickerSheetState extends State<_CustomerPickerSheet> {
  final _queryCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _queryCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dueProvider = context.watch<DueProvider>();
    final matches = dueProvider.searchByName(_query);
    final exactMatch = dueProvider.findByName(_query);

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'গ্রাহক নির্বাচন করুন',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).pop(const _PickResult(null)),
                child: const Text('গ্রাহক ছাড়াই'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _queryCtrl,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'গ্রাহকের নাম লিখুন',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          const SizedBox(height: 12),
          if (matches.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final c = matches[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryGreen.withValues(
                        alpha: 0.12,
                      ),
                      foregroundColor: AppTheme.primaryGreen,
                      child: Text(
                        c.name.isNotEmpty ? c.name.substring(0, 1) : '?',
                      ),
                    ),
                    title: Text(c.name),
                    subtitle: c.phone.isNotEmpty ? Text(c.phone) : null,
                    onTap: () => Navigator.of(context).pop(_PickResult(c)),
                  );
                },
              ),
            )
          else if (_query.trim().isNotEmpty) ...[
            Text(
              '"${_query.trim()}" নামে কোনো বিদ্যমান গ্রাহক নেই',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phoneCtrl,
              decoration: const InputDecoration(
                labelText: 'মোবাইল নম্বর (ঐচ্ছিক)',
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final name = _query.trim();
                final customer = await context.read<DueProvider>().addCustomer(
                  name: name,
                  phone: _phoneCtrl.text.trim(),
                );
                if (context.mounted) {
                  Navigator.of(context).pop(_PickResult(customer));
                }
              },
              icon: const Icon(Icons.person_add_alt_1),
              label: Text('"${_query.trim()}" নতুন গ্রাহক হিসেবে যোগ করুন'),
            ),
          ],
          if (exactMatch == null && _query.trim().isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'নাম লেখা শুরু করলে বিদ্যমান গ্রাহক দেখাবে, না থাকলে নতুন হিসেবে যোগ করার অপশন আসবে।',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
              ),
            ),
        ],
      ),
    );
  }
}
