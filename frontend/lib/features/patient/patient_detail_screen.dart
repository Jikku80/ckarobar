import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../models/patient.dart';
import '../../providers/core_providers.dart';
import '../../providers/permissions_provider.dart';

class PatientDetailScreen extends ConsumerStatefulWidget {
  final String patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  ConsumerState<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends ConsumerState<PatientDetailScreen> {
  Patient? _patient;
  List<dynamic> _history = [];
  bool _loading = true;
  bool _loadingHistory = false;
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
      final res = await ref.read(patientsApiProvider).get(widget.patientId);
      final patient = Patient.fromJson(res.data as Map<String, dynamic>);
      setState(() {
        _patient = patient;
        _loading = false;
      });
      _loadHistory();
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      setState(() {
        _error = 'Failed to load patient';
        _loading = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    setState(() => _loadingHistory = true);
    try {
      final res = await ref.read(patientsApiProvider).getHistory(widget.patientId);
      final data = res.data;
      final list = data is List ? data : (data?['data'] as List? ?? const []);
      setState(() => _history = list);
    } catch (_) {
      // Non-critical — leave history empty.
    } finally {
      if (mounted) setState(() => _loadingHistory = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete patient?'),
        content: Text('This will permanently delete ${_patient?.fullName}. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(patientsApiProvider).delete(widget.patientId);
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final perms = ref.watch(permissionsProvider);
    final canUpdate = hasPermission(perms, Permission.patientUpdate);
    final canDelete = hasPermission(perms, Permission.patientDelete);

    return Scaffold(
      appBar: AppBar(
        title: Text(_patient?.fullName ?? 'Patient'),
        actions: [
          if (_patient != null && canUpdate)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final saved = await context.push<bool>('/patients/${_patient!.id}/edit', extra: _patient);
                if (saved == true) _load();
              },
            ),
          if (_patient != null && canDelete)
            IconButton(icon: const Icon(Icons.delete_outline, color: AppColors.danger), onPressed: _confirmDelete),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _patient == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          _ProfileCard(patient: _patient!),
                          const SizedBox(height: 16),
                          _InfoCard(
                            title: 'Contact',
                            rows: [
                              if ((_patient!.phone ?? '').isNotEmpty) ('Phone', _patient!.phone!),
                              if ((_patient!.email ?? '').isNotEmpty) ('Email', _patient!.email!),
                              if ((_patient!.address ?? '').isNotEmpty) ('Address', _patient!.address!),
                            ],
                          ),
                          if ((_patient!.emergencyContactName ?? '').isNotEmpty ||
                              (_patient!.emergencyContactPhone ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InfoCard(
                              title: 'Emergency contact',
                              rows: [
                                if ((_patient!.emergencyContactName ?? '').isNotEmpty)
                                  ('Name', _patient!.emergencyContactName!),
                                if ((_patient!.emergencyContactPhone ?? '').isNotEmpty)
                                  ('Phone', _patient!.emergencyContactPhone!),
                              ],
                            ),
                          ],
                          if (_patient!.allergies.isNotEmpty || _patient!.medicalConditions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InfoCard(
                              title: 'Medical',
                              rows: [
                                if (_patient!.allergies.isNotEmpty)
                                  ('Allergies', _patient!.allergies.join(', ')),
                                if (_patient!.medicalConditions.isNotEmpty)
                                  ('Conditions', _patient!.medicalConditions.join(', ')),
                              ],
                            ),
                          ],
                          if ((_patient!.insuranceProvider ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InfoCard(
                              title: 'Insurance',
                              rows: [
                                ('Provider', _patient!.insuranceProvider!),
                                if ((_patient!.insurancePolicyNumber ?? '').isNotEmpty)
                                  ('Policy #', _patient!.insurancePolicyNumber!),
                              ],
                            ),
                          ],
                          if ((_patient!.notes ?? '').isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _InfoCard(title: 'Notes', rows: [('', _patient!.notes!)]),
                          ],
                          const SizedBox(height: 20),
                          Text('Visit history', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          if (_loadingHistory)
                            const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          else if (_history.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(16),
                              child: Text('No visits recorded yet.', style: TextStyle(color: Colors.grey.shade600)),
                            )
                          else
                            ..._history.map((h) => _HistoryTile(entry: h as Map<String, dynamic>)),
                        ],
                      ),
                    ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  final Patient patient;
  const _ProfileCard({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: Text(
                patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : '?',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 22),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (patient.opdNo != null && patient.opdNo!.isNotEmpty) _Tag('OPD ${patient.opdNo}'),
                      if (patient.displayAge != null) _Tag('${patient.displayAge} yrs'),
                      if (patient.gender != Gender.unspecified) _Tag(patient.gender.label),
                      if (patient.bloodGroup != null) _Tag(patient.bloodGroup!),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  const _Tag(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  const _InfoCard({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...rows.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: r.$1.isEmpty
                      ? Text(r.$2)
                      : RichText(
                          text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                              TextSpan(text: '${r.$1}: ', style: TextStyle(color: Colors.grey.shade600)),
                              TextSpan(text: r.$2),
                            ],
                          ),
                        ),
                )),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> entry;
  const _HistoryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final date = entry['scheduledAt'] ?? entry['createdAt'];
    String dateLabel = '';
    if (date is String) {
      try {
        dateLabel = DateFormat('MMM d, yyyy').format(DateTime.parse(date).toLocal());
      } catch (_) {
        dateLabel = date;
      }
    }
    final type = entry['type']?.toString() ?? entry['title']?.toString() ?? 'Visit';
    final notes = entry['diagnosis']?.toString() ?? entry['treatment']?.toString() ?? entry['notes']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.event_note_outlined, color: AppColors.primary),
        title: Text(type),
        subtitle: notes != null && notes.isNotEmpty ? Text(notes) : null,
        trailing: Text(dateLabel, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
      ),
    );
  }
}