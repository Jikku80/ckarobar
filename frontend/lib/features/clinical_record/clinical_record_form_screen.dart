import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../models/clinical_record.dart';
import '../../providers/core_providers.dart';

class _RxDraft {
  final TextEditingController medicineName;
  final TextEditingController dosage;
  final TextEditingController frequency;
  final TextEditingController duration;
  final TextEditingController instructions;

  _RxDraft({
    String medicineName = '',
    String dosage = '',
    String frequency = '',
    String duration = '',
    String instructions = '',
  })  : medicineName = TextEditingController(text: medicineName),
        dosage = TextEditingController(text: dosage),
        frequency = TextEditingController(text: frequency),
        duration = TextEditingController(text: duration),
        instructions = TextEditingController(text: instructions);

  void dispose() {
    medicineName.dispose();
    dosage.dispose();
    frequency.dispose();
    duration.dispose();
    instructions.dispose();
  }
}

class ClinicalRecordFormScreen extends ConsumerStatefulWidget {
  final ClinicalRecord? record;
  final String? initialPatientId;
  const ClinicalRecordFormScreen({super.key, this.record, this.initialPatientId});

  @override
  ConsumerState<ClinicalRecordFormScreen> createState() => _ClinicalRecordFormScreenState();
}

class _ClinicalRecordFormScreenState extends ConsumerState<ClinicalRecordFormScreen> {
  late final TextEditingController _patientId;
  late final TextEditingController _diagnosis;
  late final TextEditingController _treatmentPlan;
  final List<_RxDraft> _prescriptions = [];
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.record != null;

  @override
  void initState() {
    super.initState();
    final r = widget.record;
    _patientId = TextEditingController(text: r?.patientId ?? widget.initialPatientId ?? '');
    _diagnosis = TextEditingController(text: r?.diagnosisNotes ?? '');
    _treatmentPlan = TextEditingController(text: r?.treatmentPlan ?? '');
    if (r != null) {
      for (final rx in r.prescriptions) {
        _prescriptions.add(_RxDraft(
          medicineName: rx.medicineName,
          dosage: rx.dosage ?? '',
          frequency: rx.frequency ?? '',
          duration: rx.duration ?? '',
          instructions: rx.instructions ?? '',
        ));
      }
    }
  }

  @override
  void dispose() {
    _patientId.dispose();
    _diagnosis.dispose();
    _treatmentPlan.dispose();
    for (final rx in _prescriptions) {
      rx.dispose();
    }
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

    final rxPayload = _prescriptions
        .where((rx) => rx.medicineName.text.trim().isNotEmpty)
        .map((rx) => {
              'medicineName': rx.medicineName.text.trim(),
              if (rx.dosage.text.trim().isNotEmpty) 'dosage': rx.dosage.text.trim(),
              if (rx.frequency.text.trim().isNotEmpty) 'frequency': rx.frequency.text.trim(),
              if (rx.duration.text.trim().isNotEmpty) 'duration': rx.duration.text.trim(),
              if (rx.instructions.text.trim().isNotEmpty) 'instructions': rx.instructions.text.trim(),
            })
        .toList();

    final payload = <String, dynamic>{
      'patientId': _patientId.text.trim(),
      if (_diagnosis.text.trim().isNotEmpty) 'diagnosisNotes': _diagnosis.text.trim(),
      if (_treatmentPlan.text.trim().isNotEmpty) 'treatmentPlan': _treatmentPlan.text.trim(),
      'prescriptions': rxPayload,
    };

    try {
      final api = ref.read(clinicalRecordsApiProvider);
      if (_isEdit) {
        await api.update(widget.record!.id, payload);
      } else {
        await api.create(payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to save record');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit clinical record' : 'New clinical record')),
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
            const SizedBox(height: 12),
            TextFormField(
              controller: _diagnosis,
              decoration: const InputDecoration(labelText: 'Diagnosis notes'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _treatmentPlan,
              decoration: const InputDecoration(labelText: 'Treatment plan'),
              minLines: 2,
              maxLines: 4,
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Prescriptions', style: TextStyle(fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () => setState(() => _prescriptions.add(_RxDraft())),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add medicine'),
                ),
              ],
            ),
            ..._prescriptions.asMap().entries.map((entry) => _RxCard(
                  rx: entry.value,
                  onRemove: () => setState(() => _prescriptions.removeAt(entry.key)),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saving ? null : _submit,
              child: _saving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Save changes' : 'Create record'),
            ),
          ],
        ),
      ),
    );
  }
}

class _RxCard extends StatelessWidget {
  final _RxDraft rx;
  final VoidCallback onRemove;
  const _RxCard({required this.rx, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(top: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rx.medicineName,
                    decoration: const InputDecoration(labelText: 'Medicine name', isDense: true),
                  ),
                ),
                IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: rx.dosage, decoration: const InputDecoration(labelText: 'Dosage', isDense: true))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: rx.frequency, decoration: const InputDecoration(labelText: 'Frequency', isDense: true))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: rx.duration, decoration: const InputDecoration(labelText: 'Duration', isDense: true))),
              ],
            ),
            const SizedBox(height: 8),
            TextField(controller: rx.instructions, decoration: const InputDecoration(labelText: 'Instructions', isDense: true)),
          ],
        ),
      ),
    );
  }
}