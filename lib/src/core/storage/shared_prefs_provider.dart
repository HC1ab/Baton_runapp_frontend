import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides [SharedPreferences] instance.
/// Must be overridden in ProviderScope with the initialized instance.
/// Override in tests with ProviderContainer overrides.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});
