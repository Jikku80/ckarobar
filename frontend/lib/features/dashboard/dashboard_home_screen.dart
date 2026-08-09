import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nav_icons.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permissions_provider.dart';

class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final clinic = ref.watch(authProvider).clinic;
    final perms = ref.watch(permissionsProvider);

    final quickLinks = kNavItems
        .where((i) => i.route != '/dashboard' && i.route != '/settings')
        .where((i) => hasPermission(perms, i.permission))
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(permissionsProvider.notifier).load();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, ${user?.firstName ?? ''}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          clinic?.name ?? '',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.waving_hand_rounded, color: AppColors.warning, size: 28),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Quick access', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: quickLinks.map((item) {
              return _QuickLinkCard(
                label: item.label,
                icon: iconForKey(item.iconKey),
                onTap: () => context.go(item.route),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickLinkCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primary, size: 26),
              const SizedBox(height: 10),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}
