import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/storage_keys.dart';
import 'character_style.dart';

final _logger = Logger();

/// Provides [SharedPreferences] instance.
/// Override in tests with ProviderContainer overrides.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// Global selected character style.
///
/// Persists across app restarts via SharedPreferences.
/// When backend integration is ready, call [setStyle] only after
/// the backend confirms the change — the caller controls that flow.
final selectedCharacterStyleProvider =
    NotifierProvider<SelectedCharacterStyleNotifier, CharacterStyle>(
  SelectedCharacterStyleNotifier.new,
);

class SelectedCharacterStyleNotifier extends Notifier<CharacterStyle> {
  @override
  CharacterStyle build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedId = prefs.getString(StorageKeys.characterStyleId);
    if (savedId != null) {
      _logger.d('CharacterStyle loaded: $savedId');
      return CharacterStylePresets.fromId(savedId);
    }
    return CharacterStylePresets.defaultStyle;
  }

  /// Apply a new style and persist it.
  ///
  /// For backend-gated changes: call this only after receiving
  /// a successful API response. This method itself has no network logic.
  Future<void> setStyle(CharacterStyle style) async {
    if (style.isLocked) {
      _logger.w('Attempted to set locked style: ${style.id}');
      return;
    }
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(StorageKeys.characterStyleId, style.id);
    _logger.i('CharacterStyle saved: ${style.id}');
  }
}
