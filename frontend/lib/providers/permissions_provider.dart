import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

class PermissionsNotifier extends StateNotifier<Set<String>> {
  final Ref ref;
  PermissionsNotifier(this.ref) : super(<String>{});

  Future<void> load() async {
    try {
      final res = await ref.read(rbacApiProvider).getMyPermissions();
      final list = (res.data?['permissions'] as List?)?.cast<String>() ?? const <String>[];
      state = list.toSet();
    } catch (_) {
      state = <String>{};
    }
  }

  void setAll(List<String> permissions) => state = permissions.toSet();

  void clear() => state = <String>{};
}

final permissionsProvider =
    StateNotifierProvider<PermissionsNotifier, Set<String>>((ref) => PermissionsNotifier(ref));
