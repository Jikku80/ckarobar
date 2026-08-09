import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(const ProviderScope(child: DentalDbApp()));
}

class DentalDbApp extends ConsumerStatefulWidget {
  const DentalDbApp({super.key});

  @override
  ConsumerState<DentalDbApp> createState() => _DentalDbAppState();
}

class _DentalDbAppState extends ConsumerState<DentalDbApp> {
  @override
  void initState() {
    super.initState();
    // Kick off the same verify-session flow AuthProvider.tsx runs on mount:
    // GET /auth/me (refresh+retry once on failure) -> permissions -> branches.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(authProvider.notifier).bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'DentalDB',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
