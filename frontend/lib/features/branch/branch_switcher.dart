import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/branch.dart';
import '../../providers/auth_provider.dart';
import '../../providers/branch_provider.dart';
import '../../providers/core_providers.dart';

class BranchSwitcher extends ConsumerWidget {
  const BranchSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider);
    final user = ref.watch(authProvider).user;

    if (branchState.branches.isEmpty) return const SizedBox.shrink();

    final singleLocked = user != null &&
        !user.role.isOwnerTier &&
        branchState.branches.length == 1;

    if (singleLocked || branchState.branches.length == 1) {
      return _BranchPill(label: branchState.activeBranch?.name ?? branchState.branches.first.name, locked: true);
    }

    return PopupMenuButton<Branch>(
      tooltip: 'Switch branch',
      onSelected: (branch) async {
        if (user == null) return;
        final ok = ref.read(branchProvider.notifier).setActiveBranch(branch, user);
        if (ok) {
          await ref.read(localStoreProvider).setActiveBranchId(branch.id);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${branch.name} is not available right now')),
          );
        }
      },
      itemBuilder: (context) => branchState.branches.map((b) {
        final disabled = b.isLocked || !b.isActive;
        return PopupMenuItem<Branch>(
          value: b,
          enabled: !disabled,
          child: Row(
            children: [
              Icon(
                b.id == branchState.activeBranch?.id ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18,
                color: disabled ? Colors.grey.shade400 : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  b.name,
                  style: TextStyle(color: disabled ? Colors.grey.shade400 : null),
                ),
              ),
              if (b.isLocked)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                ),
            ],
          ),
        );
      }).toList(),
      child: _BranchPill(label: branchState.activeBranch?.name ?? 'Select branch', locked: false),
    );
  }
}

class _BranchPill extends StatelessWidget {
  final String label;
  final bool locked;
  const _BranchPill({required this.label, required this.locked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.storefront_outlined, size: 16),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 140),
            child: Text(label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          if (!locked) const Icon(Icons.expand_more, size: 16),
        ],
      ),
    );
  }
}
