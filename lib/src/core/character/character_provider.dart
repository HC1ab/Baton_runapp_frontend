import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/storage_keys.dart';
import '../storage/shared_prefs_provider.dart';
import 'character_style.dart';

export '../storage/shared_prefs_provider.dart' show sharedPreferencesProvider;

final _logger = Logger();

/// Global selected character style.
///
/// Loaded from SharedPreferences on startup using [StorageKeys.coreColorCode].
/// Updated only after a successful PATCH /api/v1/myroom/core-color API call.
final selectedCharacterStyleProvider =
    NotifierProvider<SelectedCharacterStyleNotifier, CharacterStyle>(
  SelectedCharacterStyleNotifier.new,
);

class SelectedCharacterStyleNotifier extends Notifier<CharacterStyle> {
  @override
  CharacterStyle build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final savedCode = prefs.getString(StorageKeys.coreColorCode);
    if (savedCode != null) {
      _logger.d('CharacterStyle loaded: $savedCode');
      return CharacterStylePresets.fromCode(savedCode);
    }
    return CharacterStylePresets.defaultStyle;
  }

  /// Apply a new style and persist it to SharedPreferences.
  ///
  /// Must only be called after receiving a successful API response.
  /// This method has no network logic — caller controls the API flow.
  Future<void> setStyle(CharacterStyle style) async {
    state = style;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(StorageKeys.coreColorCode, style.code);
    _logger.i('CharacterStyle saved: ${style.code}');
  }
}
