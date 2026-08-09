import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../providers/core_providers.dart';
import '../../providers/permissions_provider.dart';
import '../../core/permissions.dart';
import 'billing_list_screen.dart';

class InvoiceDetailScreen extends ConsumerStatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  ConsumerState<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends ConsumerState<InvoiceDetailScreen> {
  Invoice? _invoice;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref.read(billingApiProvider).getInvoice(widget.invoiceId);
      setState(() {
        _invoice = Invoice.fromJson(res.data as Map<String, dynamic>);
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load invoice';
        _loading = false;
      });
    }
  }

  Future<void> _recordPayment() async {
    if (_invoice == null) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _RecordPaymentSheet(invoice: _invoice!),
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final canManage = hasPermission(perms, Permission.billingManage);

    return Scaffold(
      appBar: AppBar(
        title: Text(_invoice?.invoiceNumber ?? 'Invoice'),
        actions: [
          if (_invoice != null && canManage)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final saved = await context.push<bool>('/billing/${_invoice!.id}/edit', extra: _invoice);
                if (saved == true) _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _invoice == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(_invoice!.patient?.fullName ?? 'Patient',
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: statusColor(_invoice!.status).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(_invoice!.status.label,
                                            style: TextStyle(color: statusColor(_invoice!.status), fontWeight: FontWeight.w600, fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(_fmtDate(_invoice!.createdAt), style: TextStyle(color: Colors.grey.shade600)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Items', style: TextStyle(fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 8),
                                  ..._invoice!.items.map((item) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text('${item.description} × ${item.quantity.toStringAsFixed(item.quantity == item.quantity.roundToDouble() ? 0 : 1)}'),
                                            ),
                                            Text(fmtNPR(item.total)),
                                          ],
                                        ),
                                      )),
                                  const Divider(),
                                  _totalsRow('Subtotal', fmtNPR(_invoice!.subtotal)),
                                  if (_invoice!.taxAmount > 0)
                                    _totalsRow('Tax (${_invoice!.taxPercent.toStringAsFixed(0)}%)', fmtNPR(_invoice!.taxAmount)),
                                  if (_invoice!.discountAmount > 0)
                                    _totalsRow('Discount', '- ${fmtNPR(_invoice!.discountAmount)}'),
                                  _totalsRow('Total', fmtNPR(_invoice!.total), bold: true),
                                  if (_invoice!.paidAmount > 0)
                                    _totalsRow('Paid', fmtNPR(_invoice!.paidAmount), color: AppColors.success),
                                  if (_invoice!.dueAmount > 0)
                                    _totalsRow('Due', fmtNPR(_invoice!.dueAmount), color: AppColors.danger),
                                ],
                              ),
                            ),
                          ),
                          if (_invoice!.paymentMethod != null) ...[
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Payment', style: TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text('Method: ${_invoice!.paymentMethod!.label}'),
                                    if ((_invoice!.paymentTransactionId ?? '').isNotEmpty)
                                      Text('Transaction ID: ${_invoice!.paymentTransactionId}'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if ((_invoice!.notes ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Notes', style: TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    Text(_invoice!.notes!),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                          if (canManage && _invoice!.dueAmount > 0 && _invoice!.status != InvoiceStatus.cancelled)
                            ElevatedButton.icon(
                              onPressed: _recordPayment,
                              icon: const Icon(Icons.payments_outlined),
                              label: const Text('Record payment'),
                            ),
                        ],
                      ),
                    ),
    );
  }

  Widget _totalsRow(String label, String value, {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: color)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  String _fmtDate(String iso) {
    try {
      return DateFormat('MMM d, yyyy · h:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  final Invoice invoice;
  const _RecordPaymentSheet({required this.invoice});

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  late final TextEditingController _amount;
  final _txnId = TextEditingController();
  PaymentMethod _method = PaymentMethod.cash;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(text: widget.invoice.dueAmount.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _amount.dispose();
    _txnId.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amount.text.trim());
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(billingApiProvider).markPaid(widget.invoice.id, {
        'paymentMethod': _method.wireValue,
        'amount': amount,
        if (_txnId.text.trim().isNotEmpty) 'transactionId': _txnId.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to record payment');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Record payment', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
            ],
            DropdownButtonFormField<PaymentMethod>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Payment method'),
              items: PaymentMethod.values
                  .where((m) => m != PaymentMethod.walletCredit)
                  .map((m) => DropdownMenuItem(value: m, child: Text(m.label)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? PaymentMethod.cash),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amount,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount (NPR)'),
            ),
            const SizedBox(height: 12),
            TextField(controller: _txnId, decoration: const InputDecoration(labelText: 'Transaction ID (optional)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Record payment'),
            ),
          ],
        ),
      ),
    );
  }
}