import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../constants/storage_keys.dart';
import '../storage/shared_prefs_provider.dart';
import '../../features/profile/constants/title_presets.dart';
import '../myroom/my_room_service.dart';
import 'character_style.dart';

export '../storage/shared_prefs_provider.dart' show sharedPreferencesProvider;

/// 현재 유저의 장착 칭호 표시 이름. 없으면 null.
/// myRoomProvider(서버)가 로드되면 우선 사용, 로딩 중엔 로컬 prefs 폴백.
final myEquippedTitleNameProvider = Provider<String?>((ref) {
  final myRoomAsync = ref.watch(myRoomProvider);
  return myRoomAsync.maybeWhen(
    data: (result) =>
        result.equippedTitle.isNotEmpty ? result.equippedTitle : null,
    orElse: () {
      final prefs = ref.watch(sharedPreferencesProvider);
      final code = prefs.getString(StorageKeys.equippedTitleCode);
      if (code == null || code.isEmpty) return null;
      return TitlePresets.nameFor(code);
    },
  );
});

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
