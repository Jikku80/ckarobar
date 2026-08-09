import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/nav_icons.dart';
import '../../core/permissions.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/permissions_provider.dart';
import '../branch/branch_switcher.dart';

class DashboardShell extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const DashboardShell({super.key, required this.child, required this.currentRoute});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final perms = ref.watch(permissionsProvider);
    final user = auth.user;

    final visibleItems =
        kNavItems.where((item) => hasPermission(perms, item.permission)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleFor(currentRoute)),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: BranchSwitcher()),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        (user?.firstName.isNotEmpty == true ? user!.firstName[0] : '?').toUpperCase(),
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? '',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            user?.role.label ?? '',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: visibleItems.map((item) {
                    final selected = item.route == currentRoute;
                    return ListTile(
                      leading: Icon(iconForKey(item.iconKey),
                          color: selected ? AppColors.primary : Colors.grey.shade700),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? AppColors.primary : Colors.black87,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: selected,
                      selectedTileColor: AppColors.primary.withOpacity(0.06),
                      onTap: () {
                        Navigator.of(context).pop();
                        if (!selected) context.go(item.route);
                      },
                    );
                  }).toList(),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Sign out', style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authProvider.notifier).logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
      body: child,
    );
  }

  String _titleFor(String route) {
    final match = kNavItems.where((i) => i.route == route);
    return match.isNotEmpty ? match.first.label : 'DentalDB';
  }
}

