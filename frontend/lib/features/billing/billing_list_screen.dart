import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../models/invoice.dart';
import '../../providers/billing_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/permissions_provider.dart';

const _statusFilters = <String?>[null, 'not_yet_paid', 'partially_paid', 'paid', 'overdue', 'cancelled'];

String _statusFilterLabel(String? s) {
  if (s == null) return 'All';
  return InvoiceStatus.fromJson(s).label;
}

Color statusColor(InvoiceStatus status) => switch (status) {
      InvoiceStatus.draft => Colors.grey,
      InvoiceStatus.sent => AppColors.primary,
      InvoiceStatus.paid => AppColors.success,
      InvoiceStatus.partiallyPaid => AppColors.warning,
      InvoiceStatus.notYetPaid => Colors.orange,
      InvoiceStatus.overdue => AppColors.danger,
      InvoiceStatus.cancelled => Colors.grey,
      InvoiceStatus.refunded => Colors.purple,
    };

String fmtNPR(num v) => 'NPR ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => ',')}';

class BillingListScreen extends ConsumerStatefulWidget {
  const BillingListScreen({super.key});

  @override
  ConsumerState<BillingListScreen> createState() => _BillingListScreenState();
}

class _BillingListScreenState extends ConsumerState<BillingListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(invoicesListProvider.notifier).refresh();
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(invoicesListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      ref.read(invoicesListProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(invoicesListProvider);
    final perms = ref.watch(permissionsProvider);
    final activeBranch = ref.watch(branchProvider).activeBranch;
    final canManage = hasPermission(perms, Permission.billingManage);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by invoice # or patient…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(invoicesListProvider.notifier).search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: _statusFilters.map((s) {
                final selected = state.statusFilter == s;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(_statusFilterLabel(s)),
                    selected: selected,
                    onSelected: (_) => ref.read(invoicesListProvider.notifier).setStatusFilter(s),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(invoicesListProvider.notifier).refresh(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (activeBranch == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a branch before creating an invoice.')),
                  );
                  return;
                }
                final saved = await context.push<bool>('/billing/new');
                if (saved == true) ref.read(invoicesListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('New invoice'),
            )
          : null,
    );
  }

  Widget _buildBody(InvoicesState state) {
    if (state.loading && state.invoices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
              const SizedBox(height: 12),
              Text(state.error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () => ref.read(invoicesListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.invoices.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No invoices found')),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: state.invoices.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= state.invoices.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _InvoiceTile(invoice: state.invoices[index]);
      },
    );
  }
}

class _InvoiceTile extends StatelessWidget {
  final Invoice invoice;
  const _InvoiceTile({required this.invoice});

  @override
  Widget build(BuildContext context) {
    String dateLabel = '';
    try {
      dateLabel = DateFormat('MMM d, yyyy').format(DateTime.parse(invoice.createdAt).toLocal());
    } catch (_) {}

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        title: Text(invoice.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${invoice.patient?.fullName ?? "Patient"} · $dateLabel'),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(fmtNPR(invoice.total), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor(invoice.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(invoice.status.label, style: TextStyle(color: statusColor(invoice.status), fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        onTap: () => context.push('/billing/${invoice.id}'),
      ),
    );
  }
}