import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../models/patient.dart';
import '../../providers/branch_provider.dart';
import '../../providers/patient_provider.dart';
import '../../providers/permissions_provider.dart';

class PatientsListScreen extends ConsumerStatefulWidget {
  const PatientsListScreen({super.key});

  @override
  ConsumerState<PatientsListScreen> createState() => _PatientsListScreenState();
}

class _PatientsListScreenState extends ConsumerState<PatientsListScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(patientsListProvider.notifier).refresh();
    });
    _scrollCtrl.addListener(() {
      if (_scrollCtrl.position.pixels > _scrollCtrl.position.maxScrollExtent - 200) {
        ref.read(patientsListProvider.notifier).loadMore();
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
      ref.read(patientsListProvider.notifier).search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(patientsListProvider);
    final perms = ref.watch(permissionsProvider);
    final activeBranch = ref.watch(branchProvider).activeBranch;
    final canCreate = hasPermission(perms, Permission.patientCreate);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search patients by name or phone…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchCtrl.clear();
                          ref.read(patientsListProvider.notifier).search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (activeBranch == null)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppColors.warning),
                  SizedBox(width: 8),
                  Expanded(child: Text('Select a branch to see and add patients.')),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => ref.read(patientsListProvider.notifier).refresh(),
              child: _buildBody(state),
            ),
          ),
        ],
      ),
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (activeBranch == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Select a branch before adding a patient.')),
                  );
                  return;
                }
                final saved = await context.push<bool>('/patients/new');
                if (saved == true) ref.read(patientsListProvider.notifier).refresh();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add patient'),
            )
          : null,
    );
  }

  Widget _buildBody(PatientsListState state) {
    if (state.loading && state.patients.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.patients.isEmpty) {
      return _ErrorView(message: state.error!, onRetry: () => ref.read(patientsListProvider.notifier).refresh());
    }
    if (state.patients.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 80),
          Icon(Icons.people_outline, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Center(child: Text('No patients found')),
        ],
      );
    }
    return ListView.separated(
      controller: _scrollCtrl,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: state.patients.length + (state.hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        if (index >= state.patients.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        final p = state.patients[index];
        return _PatientTile(patient: p);
      },
    );
  }
}

class _PatientTile extends StatelessWidget {
  final Patient patient;
  const _PatientTile({required this.patient});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.1),
          child: Text(
            patient.firstName.isNotEmpty ? patient.firstName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
          ),
        ),
        title: Text(patient.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text([
          if (patient.opdNo != null && patient.opdNo!.isNotEmpty) 'OPD ${patient.opdNo}',
          if (patient.phone != null && patient.phone!.isNotEmpty) patient.phone!,
        ].join(' · ')),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push('/patients/${patient.id}'),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 40, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}