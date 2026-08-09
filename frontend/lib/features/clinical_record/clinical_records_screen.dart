import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../models/clinical_record.dart';
import '../../providers/clinical_records_provider.dart';
import '../../providers/permissions_provider.dart';

class ClinicalRecordsScreen extends ConsumerStatefulWidget {
  const ClinicalRecordsScreen({super.key});

  @override
  ConsumerState<ClinicalRecordsScreen> createState() => _ClinicalRecordsScreenState();
}

class _ClinicalRecordsScreenState extends ConsumerState<ClinicalRecordsScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(clinicalRecordsListProvider.notifier).refresh();
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(clinicalRecordsListProvider.notifier).loadMore();
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
      ref.read(clinicalRecordsListProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(clinicalRecordsListProvider);
    final perms = ref.watch(permissionsProvider);
    final canCreate = hasPermission(perms, Permission.patientRecord);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search by patient name…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(clinicalRecordsListProvider.notifier).search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(clinicalRecordsListProvider.notifier).refresh(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                final saved = await context.push<bool>('/records/new');
                if (saved == true) ref.read(clinicalRecordsListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('New record'),
            )
          : null,
    );
  }

  Widget _buildBody(ClinicalRecordsState state) {
    if (state.loading && state.records.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.records.isEmpty) {
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
                onPressed: () => ref.read(clinicalRecordsListProvider.notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (state.records.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.folder_shared_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No clinical records found')),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: state.records.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= state.records.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return _RecordTile(record: state.records[index]);
      },
    );
  }
}

class _RecordTile extends StatelessWidget {
  final ClinicalRecord record;
  const _RecordTile({required this.record});

  @override
  Widget build(BuildContext context) {
    String dateLabel = '';
    try {
      dateLabel = DateFormat('MMM d, yyyy').format(DateTime.parse(record.createdAt).toLocal());
    } catch (_) {}

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: const CircleAvatar(
          backgroundColor: Color(0x1A2563EB),
          child: Icon(Icons.folder_shared_outlined, color: AppColors.primary, size: 20),
        ),
        title: Text(record.patient?.fullName ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            if ((record.diagnosisNotes ?? '').isNotEmpty) record.diagnosisNotes!,
            dateLabel,
          ].where((s) => s.isNotEmpty).join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: record.prescriptions.isNotEmpty
            ? Chip(
                label: Text('${record.prescriptions.length} Rx', style: const TextStyle(fontSize: 11)),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              )
            : null,
        onTap: () => context.push('/records/${record.id}'),
      ),
    );
  }
}