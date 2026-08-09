import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../providers/branch_provider.dart';
import '../../providers/core_providers.dart';

class _ItemDraft {
  final TextEditingController description;
  final TextEditingController quantity;
  final TextEditingController unitPrice;
  _ItemDraft({String description = '', String quantity = '1', String unitPrice = '0'})
      : description = TextEditingController(text: description),
        quantity = TextEditingController(text: quantity),
        unitPrice = TextEditingController(text: unitPrice);

  double get total {
    final q = double.tryParse(quantity.text.trim()) ?? 0;
    final p = double.tryParse(unitPrice.text.trim()) ?? 0;
    return q * p;
  }

  void dispose() {
    description.dispose();
    quantity.dispose();
    unitPrice.dispose();
  }
}

class InvoiceFormScreen extends ConsumerStatefulWidget {
  final Invoice? invoice;
  final String? initialPatientId;
  const InvoiceFormScreen({super.key, this.invoice, this.initialPatientId});

  @override
  ConsumerState<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends ConsumerState<InvoiceFormScreen> {
  late final TextEditingController _patientId;
  late final TextEditingController _taxPercent;
  late final TextEditingController _discountAmount;
  late final TextEditingController _notes;
  final List<_ItemDraft> _items = [];
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;
    _patientId = TextEditingController(text: inv?.patientId ?? widget.initialPatientId ?? '');
    _taxPercent = TextEditingController(text: inv?.taxPercent.toStringAsFixed(0) ?? '0');
    _discountAmount = TextEditingController(text: inv?.discountAmount.toStringAsFixed(0) ?? '0');
    _notes = TextEditingController(text: inv?.notes ?? '');
    if (inv != null && inv.items.isNotEmpty) {
      for (final item in inv.items) {
        _items.add(_ItemDraft(
          description: item.description,
          quantity: item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 2),
          unitPrice: item.unitPrice.toStringAsFixed(0),
        ));
      }
    } else {
      _items.add(_ItemDraft());
    }
  }

  @override
  void dispose() {
    _patientId.dispose();
    _taxPercent.dispose();
    _discountAmount.dispose();
    _notes.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  double get _subtotal => _items.fold(0, (sum, i) => sum + i.total);
  double get _taxAmount => _subtotal * ((double.tryParse(_taxPercent.text.trim()) ?? 0) / 100);
  double get _discount => double.tryParse(_discountAmount.text.trim()) ?? 0;
  double get _total => (_subtotal + _taxAmount - _discount).clamp(0, double.infinity);

  Future<void> _submit() async {
    if (_patientId.text.trim().isEmpty) {
      setState(() => _error = 'Patient id is required');
      return;
    }
    final validItems = _items.where((i) => i.description.text.trim().isNotEmpty).toList();
    if (validItems.isEmpty) {
      setState(() => _error = 'Add at least one item');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final activeBranch = ref.read(branchProvider).activeBranch;
    final payload = <String, dynamic>{
      'patientId': _patientId.text.trim(),
      'items': validItems
          .map((i) => {
                'description': i.description.text.trim(),
                'quantity': double.tryParse(i.quantity.text.trim()) ?? 1,
                'unitPrice': double.tryParse(i.unitPrice.text.trim()) ?? 0,
                'total': i.total,
              })
          .toList(),
      'taxPercent': double.tryParse(_taxPercent.text.trim()) ?? 0,
      'discountAmount': _discount,
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      if (!_isEdit) 'branchId': activeBranch?.id,
    };

    try {
      final api = ref.read(billingApiProvider);
      if (_isEdit) {
        await api.updateInvoice(widget.invoice!.id, payload);
      } else {
        await api.createInvoice(payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to save invoice');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit invoice' : 'New invoice')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.danger)),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _patientId,
              enabled: widget.initialPatientId == null && !_isEdit,
              decoration: const InputDecoration(labelText: 'Patient ID *'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => setState(() => _items.add(_ItemDraft())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add item'),
                ),
              ],
            ),
            ..._items.asMap().entries.map((entry) => _ItemRow(
                  item: entry.value,
                  onRemove: _items.length > 1 ? () => setState(() => _items.removeAt(entry.key)) : null,
                  onChanged: () => setState(() {}),
                )),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _taxPercent,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Tax %'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _discountAmount,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Discount (NPR)'),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), minLines: 2, maxLines: 4),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _summaryRow('Subtotal', _subtotal),
                    _summaryRow('Tax', _taxAmount),
                    _summaryRow('Discount', -_discount),
                    const Divider(),
                    _summaryRow('Total', _total, bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save changes' : 'Create invoice'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
          Text('NPR ${value.toStringAsFixed(0)}', style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  final _ItemDraft item;
  final VoidCallback? onRemove;
  final VoidCallback onChanged;
  const _ItemRow({required this.item, required this.onRemove, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: item.description,
                  decoration: const InputDecoration(labelText: 'Description', isDense: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item.quantity,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Qty', isDense: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: item.unitPrice,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Price', isDense: true),
                  onChanged: (_) => onChanged(),
                ),
              ),
              if (onRemove != null)
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
            ],
          ),
          Align(
            alignment: Alignment.centerRight,
            child: Text('= NPR ${item.total.toStringAsFixed(0)}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}