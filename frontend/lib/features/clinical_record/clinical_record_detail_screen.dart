import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../models/clinical_record.dart';
import '../../providers/core_providers.dart';
import '../../providers/permissions_provider.dart';

class ClinicalRecordDetailScreen extends ConsumerStatefulWidget {
  final String recordId;
  const ClinicalRecordDetailScreen({super.key, required this.recordId});

  @override
  ConsumerState<ClinicalRecordDetailScreen> createState() => _ClinicalRecordDetailScreenState();
}

class _ClinicalRecordDetailScreenState extends ConsumerState<ClinicalRecordDetailScreen> {
  ClinicalRecord? _record;
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
      final res = await ref.read(clinicalRecordsApiProvider).get(widget.recordId);
      setState(() {
        _record = ClinicalRecord.fromJson(res.data as Map<String, dynamic>);
        _loading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load record';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final canEdit = hasPermission(perms, Permission.patientRecord);

    return Scaffold(
      appBar: AppBar(
        title: Text(_record?.patient?.fullName ?? 'Clinical record'),
        actions: [
          if (_record != null && canEdit)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final saved = await context.push<bool>('/records/${_record!.id}/edit', extra: _record);
                if (saved == true) _load();
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _record == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if ((_record!.doctorName ?? '').isNotEmpty || _record!.createdAt.isNotEmpty)
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if ((_record!.doctorName ?? '').isNotEmpty)
                                      Text('Dr. ${_record!.doctorName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 4),
                                    Text(_fmtDate(_record!.createdAt), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  ],
                                ),
                              ),
                            ),
                          if ((_record!.diagnosisNotes ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _SectionCard(title: 'Diagnosis', body: _record!.diagnosisNotes!),
                          ],
                          if ((_record!.treatmentPlan ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _SectionCard(title: 'Treatment plan', body: _record!.treatmentPlan!),
                          ],
                          if (_record!.prescriptions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Prescriptions', style: TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    ..._record!.prescriptions.map((rx) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(rx.medicineName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                              Text(
                                                [rx.dosage, rx.frequency, rx.duration]
                                                    .where((s) => (s ?? '').isNotEmpty)
                                                    .join(' · '),
                                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5),
                                              ),
                                              if ((rx.instructions ?? '').isNotEmpty)
                                                Text(rx.instructions!, style: const TextStyle(fontSize: 13)),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          if (_record!.visits.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Visit history', style: TextStyle(fontWeight: FontWeight.w700)),
                                    const SizedBox(height: 8),
                                    ..._record!.visits.map((v) => Padding(
                                          padding: const EdgeInsets.only(bottom: 8),
                                          child: Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Icon(Icons.event_note_outlined, size: 16, color: AppColors.primary),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(_fmtDate(v.date), style: const TextStyle(fontSize: 12.5)),
                                                    if (v.services.isNotEmpty)
                                                      Text(v.services.join(', '), style: TextStyle(color: Colors.grey.shade700, fontSize: 12.5)),
                                                    if ((v.notes ?? '').isNotEmpty) Text(v.notes!, style: const TextStyle(fontSize: 13)),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String body;
  const _SectionCard({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(body),
          ],
        ),
      ),
    );
  }
}