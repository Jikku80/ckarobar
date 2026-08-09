import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/recall.dart';
import '../../providers/branch_provider.dart';
import '../../providers/core_providers.dart';
import '../../providers/recalls_provider.dart';

class RecallsScreen extends ConsumerStatefulWidget {
  const RecallsScreen({super.key});

  @override
  ConsumerState<RecallsScreen> createState() => _RecallsScreenState();
}

class _RecallsScreenState extends ConsumerState<RecallsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recallsProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(recallsProvider);
    final activeBranch = ref.watch(branchProvider).activeBranch;

    return Scaffold(
      body: activeBranch == null
          ? const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Select a branch to see recalls.')))
          : RefreshIndicator(
              onRefresh: () => ref.read(recallsProvider.notifier).refresh(),
              child: state.loading && state.groups.overdue.isEmpty && state.groups.thisWeek.isEmpty && state.groups.upcoming.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                      children: [
                        if (state.error != null) ...[
                          _ErrorBanner(message: state.error!),
                          const SizedBox(height: 12),
                        ],
                        Row(
                          children: [
                            Expanded(child: _StatCard(label: 'Total pending', value: state.stats.totalPending, color: AppColors.primary)),
                            const SizedBox(width: 10),
                            Expanded(child: _StatCard(label: 'Overdue', value: state.stats.overdueCount, color: AppColors.danger)),
                            const SizedBox(width: 10),
                            Expanded(child: _StatCard(label: 'Booked (mo.)', value: state.stats.bookedThisMonth, color: AppColors.success)),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _RecallSection(
                          title: 'Overdue',
                          recalls: state.groups.overdue,
                          dotColor: AppColors.danger,
                          emptyText: 'No overdue recalls 🎉',
                        ),
                        const SizedBox(height: 16),
                        _RecallSection(
                          title: 'This week',
                          recalls: state.groups.thisWeek,
                          dotColor: AppColors.warning,
                          emptyText: 'Nothing due this week.',
                        ),
                        const SizedBox(height: 16),
                        _RecallSection(
                          title: 'Upcoming',
                          recalls: state.groups.upcoming,
                          dotColor: AppColors.primary,
                          emptyText: 'No upcoming recalls.',
                        ),
                      ],
                    ),
            ),
      floatingActionButton: activeBranch == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const _AddRecallSheet(),
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add recall'),
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$value', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

class _RecallSection extends ConsumerWidget {
  final String title;
  final List<Recall> recalls;
  final Color dotColor;
  final String emptyText;

  const _RecallSection({
    required this.title,
    required this.recalls,
    required this.dotColor,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(width: 6),
            Text('(${recalls.length})', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 8),
        if (recalls.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(emptyText, style: TextStyle(color: Colors.grey.shade500)),
          )
        else
          ...recalls.map((r) => _RecallCard(recall: r)),
      ],
    );
  }
}

class _RecallCard extends ConsumerWidget {
  final Recall recall;
  const _RecallCard({required this.recall});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String dateLabel = recall.dueDate;
    try {
      dateLabel = DateFormat('MMM d, yyyy').format(DateTime.parse(recall.dueDate).toLocal());
    } catch (_) {}

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(recall.patient?.fullName ?? 'Patient', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
                _StatusChip(status: recall.status),
              ],
            ),
            const SizedBox(height: 4),
            Text('${recall.recallType.label} · Due $dateLabel', style: TextStyle(color: Colors.grey.shade600, fontSize: 12.5)),
            if ((recall.reason ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(recall.reason!, style: const TextStyle(fontSize: 13)),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (recall.status == RecallStatus.pending)
                  OutlinedButton(
                    onPressed: () => ref.read(recallsProvider.notifier).markContacted(recall.id),
                    child: const Text('Mark contacted'),
                  ),
                if (recall.status != RecallStatus.booked && recall.status != RecallStatus.cancelled)
                  ElevatedButton(
                    onPressed: () => showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => _BookAppointmentSheet(recall: recall),
                    ),
                    child: const Text('Book appointment'),
                  ),
                TextButton(
                  onPressed: () => ref.read(recallsProvider.notifier).sendNow(recall.id).then((_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder sent')));
                    }
                  }),
                  child: const Text('Send reminder'),
                ),
                if (recall.status != RecallStatus.cancelled)
                  TextButton(
                    onPressed: () => ref.read(recallsProvider.notifier).cancel(recall.id),
                    style: TextButton.styleFrom(foregroundColor: AppColors.danger),
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final RecallStatus status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      RecallStatus.pending => AppColors.warning,
      RecallStatus.contacted => AppColors.primary,
      RecallStatus.booked => AppColors.success,
      RecallStatus.cancelled => Colors.grey,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status.label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

/// Bottom sheet — add a recall for a patient. Patient is picked by typing
/// an id for now (no patient combobox yet); simplest correct flow is to
/// open this from a patient's detail screen where the id is already known,
/// or type the id directly.
class _AddRecallSheet extends ConsumerStatefulWidget {
  final String? initialPatientId;
  final String? initialPatientLabel;
  const _AddRecallSheet({this.initialPatientId, this.initialPatientLabel});

  @override
  ConsumerState<_AddRecallSheet> createState() => _AddRecallSheetState();
}

class _AddRecallSheetState extends ConsumerState<_AddRecallSheet> {
  late final TextEditingController _patientId;
  final _reason = TextEditingController();
  final _notes = TextEditingController();
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  RecallType _type = RecallType.checkup;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _patientId = TextEditingController(text: widget.initialPatientId ?? '');
  }

  @override
  void dispose() {
    _patientId.dispose();
    _reason.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_patientId.text.trim().isEmpty) {
      setState(() => _error = 'Patient id is required');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(recallsProvider.notifier).create({
        'patientId': _patientId.text.trim(),
        'dueDate': _dueDate.toIso8601String(),
        'recallType': _type.wireValue,
        if (_reason.text.trim().isNotEmpty) 'reason': _reason.text.trim(),
        if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to add recall');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Add recall', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _patientId,
              enabled: widget.initialPatientId == null,
              decoration: InputDecoration(
                labelText: 'Patient ID',
                helperText: widget.initialPatientLabel,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<RecallType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Recall type'),
              items: RecallType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.label))).toList(),
              onChanged: (v) => setState(() => _type = v ?? RecallType.checkup),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Due date'),
              subtitle: Text(DateFormat('MMM d, yyyy').format(_dueDate)),
              trailing: const Icon(Icons.calendar_today_outlined, size: 18),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _dueDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                  lastDate: DateTime.now().add(const Duration(days: 730)),
                );
                if (picked != null) setState(() => _dueDate = picked);
              },
            ),
            const SizedBox(height: 12),
            TextField(controller: _reason, decoration: const InputDecoration(labelText: 'Reason')),
            const SizedBox(height: 12),
            TextField(controller: _notes, decoration: const InputDecoration(labelText: 'Notes'), minLines: 2, maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add recall'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookAppointmentSheet extends ConsumerStatefulWidget {
  final Recall recall;
  const _BookAppointmentSheet({required this.recall});

  @override
  ConsumerState<_BookAppointmentSheet> createState() => _BookAppointmentSheetState();
}

class _BookAppointmentSheetState extends ConsumerState<_BookAppointmentSheet> {
  DateTime _scheduledAt = DateTime.now().add(const Duration(days: 1));
  String? _dentistId;
  List<dynamic> _doctors = [];
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  Future<void> _loadDoctors() async {
    final branchId = ref.read(branchProvider).activeBranch?.id;
    if (branchId == null) return;
    try {
      final res = await ref.read(branchDoctorsApiProvider).getDoctors(branchId);
      final data = res.data;
      setState(() => _doctors = data is List ? data : (data?['data'] as List? ?? const []));
    } catch (_) {}
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(recallsProvider.notifier).bookAppointment(widget.recall.id, {
        'scheduledAt': _scheduledAt.toIso8601String(),
        if (_dentistId != null) 'dentistId': _dentistId,
        'durationMinutes': 30,
      });
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to book appointment');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Book appointment for ${widget.recall.patient?.fullName ?? "patient"}',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 12),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: AppColors.danger)),
              const SizedBox(height: 8),
            ],
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Date & time'),
              subtitle: Text(DateFormat('MMM d, yyyy · h:mm a').format(_scheduledAt)),
              trailing: const Icon(Icons.event_outlined, size: 18),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _scheduledAt,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date == null || !mounted) return;
                final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_scheduledAt));
                if (time == null) return;
                setState(() => _scheduledAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
              },
            ),
            if (_doctors.isNotEmpty) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _dentistId,
                decoration: const InputDecoration(labelText: 'Dentist'),
                items: _doctors
                    .map<DropdownMenuItem<String>>((d) => DropdownMenuItem(
                          value: d['id'] as String,
                          child: Text('${d['firstName'] ?? ''} ${d['lastName'] ?? ''}'.trim()),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _dentistId = v),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Book appointment'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );
  }
}