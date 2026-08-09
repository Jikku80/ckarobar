import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_client.dart';
import '../../core/nepal_phone.dart';
import '../../models/patient.dart';
import '../../providers/branch_provider.dart';
import '../../providers/core_providers.dart';

class PatientFormScreen extends ConsumerStatefulWidget {
  final Patient? patient;
  const PatientFormScreen({super.key, this.patient});

  @override
  ConsumerState<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends ConsumerState<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _opdNo;
  late final TextEditingController _firstName;
  late final TextEditingController _lastName;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _age;
  late final TextEditingController _address;
  late final TextEditingController _emergencyName;
  late final TextEditingController _emergencyPhone;
  late final TextEditingController _allergies;
  late final TextEditingController _medicalConditions;
  late final TextEditingController _insuranceProvider;
  late final TextEditingController _insurancePolicyNumber;
  late final TextEditingController _notes;

  Gender _gender = Gender.unspecified;
  bool _saving = false;
  String? _error;

  bool get _isEdit => widget.patient != null;

  @override
  void initState() {
    super.initState();
    final p = widget.patient;
    _opdNo = TextEditingController(text: p?.opdNo ?? '');
    _firstName = TextEditingController(text: p?.firstName ?? '');
    _lastName = TextEditingController(text: p?.lastName ?? '');
    _email = TextEditingController(text: p?.email ?? '');
    _phone = TextEditingController(text: stripNepalPhonePrefix(p?.phone));
    _age = TextEditingController(text: p?.displayAge?.toString() ?? '');
    _address = TextEditingController(text: p?.address ?? '');
    _emergencyName = TextEditingController(text: p?.emergencyContactName ?? '');
    _emergencyPhone = TextEditingController(text: stripNepalPhonePrefix(p?.emergencyContactPhone));
    _allergies = TextEditingController(text: p?.allergies.join(', ') ?? '');
    _medicalConditions = TextEditingController(text: p?.medicalConditions.join(', ') ?? '');
    _insuranceProvider = TextEditingController(text: p?.insuranceProvider ?? '');
    _insurancePolicyNumber = TextEditingController(text: p?.insurancePolicyNumber ?? '');
    _notes = TextEditingController(text: p?.notes ?? '');
    _gender = p?.gender ?? Gender.unspecified;
  }

  @override
  void dispose() {
    for (final c in [
      _opdNo, _firstName, _lastName, _email, _phone, _age, _address,
      _emergencyName, _emergencyPhone, _allergies, _medicalConditions,
      _insuranceProvider, _insurancePolicyNumber, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> _splitCsv(String v) =>
      v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });

    final activeBranch = ref.read(branchProvider).activeBranch;
    final payload = <String, dynamic>{
      'opdNo': _opdNo.text.trim().isEmpty ? null : _opdNo.text.trim(),
      'firstName': _firstName.text.trim(),
      'lastName': _lastName.text.trim(),
      'email': _email.text.trim().isEmpty ? null : _email.text.trim(),
      'phone': toNepalPhonePayload(_phone.text.trim()),
      'ageYears': _age.text.trim().isEmpty ? null : int.tryParse(_age.text.trim()),
      'gender': _gender.wireValue,
      'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
      'emergencyContactName':
          _emergencyName.text.trim().isEmpty ? null : _emergencyName.text.trim(),
      'emergencyContactPhone': toNepalPhonePayload(_emergencyPhone.text.trim()),
      'allergies': _splitCsv(_allergies.text),
      'medicalConditions': _splitCsv(_medicalConditions.text),
      'insuranceProvider':
          _insuranceProvider.text.trim().isEmpty ? null : _insuranceProvider.text.trim(),
      'insurancePolicyNumber': _insurancePolicyNumber.text.trim().isEmpty
          ? null
          : _insurancePolicyNumber.text.trim(),
      'notes': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      if (!_isEdit) 'branchId': activeBranch?.id,
    };

    try {
      final api = ref.read(patientsApiProvider);
      if (_isEdit) {
        await api.update(widget.patient!.id, payload);
      } else {
        await api.create(payload);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (_) {
      setState(() => _error = 'Failed to save patient');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit patient' : 'Add patient')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (_error != null) ...[
                _ErrorBanner(message: _error!),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _firstName,
                      decoration: const InputDecoration(labelText: 'First name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _lastName,
                      decoration: const InputDecoration(labelText: 'Last name *'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _opdNo,
                decoration: const InputDecoration(labelText: 'OPD number'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: 'Phone (10 digits)', prefixText: '+977 '),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  return isValidNepalLocalPhone(v.trim()) ? null : 'Must be exactly 10 digits';
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
                  return ok ? null : 'Invalid email';
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Age (years)'),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final n = int.tryParse(v.trim());
                        if (n == null || n < 0 || n > 150) return 'Invalid age';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<Gender>(
                      value: _gender,
                      decoration: const InputDecoration(labelText: 'Gender'),
                      items: Gender.values
                          .map((g) => DropdownMenuItem(value: g, child: Text(g.label)))
                          .toList(),
                      onChanged: (v) => setState(() => _gender = v ?? Gender.unspecified),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                decoration: const InputDecoration(labelText: 'Address'),
                minLines: 1,
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              Text('Emergency contact', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emergencyName,
                decoration: const InputDecoration(labelText: 'Contact name'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emergencyPhone,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(labelText: 'Contact phone (10 digits)', prefixText: '+977 '),
              ),
              const SizedBox(height: 20),
              Text('Medical', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _allergies,
                decoration: const InputDecoration(labelText: 'Allergies (comma separated)'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _medicalConditions,
                decoration: const InputDecoration(labelText: 'Medical conditions (comma separated)'),
              ),
              const SizedBox(height: 20),
              Text('Insurance', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              TextFormField(
                controller: _insuranceProvider,
                decoration: const InputDecoration(labelText: 'Provider'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _insurancePolicyNumber,
                decoration: const InputDecoration(labelText: 'Policy number'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(labelText: 'Notes'),
                minLines: 2,
                maxLines: 4,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEdit ? 'Save changes' : 'Add patient'),
              ),
            ],
          ),
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