import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;

/// App-wide configuration.
///
/// Mirrors dentaldb/lib/api.ts on the web app:
///   BASE_URL = NEXT_PUBLIC_API_URL (no /api/v1 suffix) — this file appends
///   /api/v1 itself, exactly like the web client does.
///
/// IMPORTANT (see dentaldb/.env.example): the web app's env var is
/// NEXT_PUBLIC_API_URL WITHOUT the /api/v1 suffix. Some other apps in this
/// codebase (e.g. an Expo app referenced in that file) use a DIFFERENT
/// convention (EXPO_PUBLIC_API_URL WITH /api/v1 already included). This
/// Flutter app follows the dentaldb/web convention: no suffix here, the
/// suffix is appended once in [ApiClient].
///
/// Override at build/run time with:
///   flutter run --dart-define=API_BASE_URL=https://your-backend.example.com
class AppConfig {
  AppConfig._();

  /// Same production origin the web admin dashboard talks to.
  /// Change this (or pass --dart-define=API_BASE_URL=...) to point at your
  /// own backend deployment.
  static const String _prodDefault = 'https://app.clinickarobar.com';

  /// For local development against a backend running on your machine.
  /// `10.0.2.2` is a special alias that ONLY resolves inside the Android
  /// emulator's virtual network — it means nothing on web, desktop, iOS
  /// Simulator, or a real device, so using it unconditionally there just
  /// hangs until the connect timeout fires. Everywhere except the Android
  /// emulator, `localhost` is correct as long as the backend runs on the
  /// same machine you're launching the app from.
  ///  - Android emulator: 10.0.2.2
  ///  - iOS Simulator / macOS / Windows / Linux desktop / web: localhost
  ///  - Physical device (Android or iOS): your machine's LAN IP — neither
  ///    default below is reachable from a separate physical device, so this
  ///    case always needs an explicit --dart-define=API_BASE_URL=...
  static String get _devDefault {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }

  static const String _envUrl = String.fromEnvironment('API_BASE_URL');

  static const bool isProduction = bool.fromEnvironment('dart.vm.product');

  static String get baseUrl {
    if (_envUrl.isNotEmpty) return _envUrl;
    return isProduction ? _prodDefault : _devDefault;
  }

  static String get apiUrl => '$baseUrl/api/v1';

  /// How often to silently refresh the auth session, mirroring
  /// AuthProvider.tsx's REFRESH_INTERVAL_MS (12 minutes).
  static const Duration refreshInterval = Duration(minutes: 12);
}
