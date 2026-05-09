import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GPS Mock 여부를 앱 전역에서 참조
/// .env 파일의 USE_MOCK_GPS 값으로 제어
/// running_screen에서 ref.read(useMockGpsProvider) 로 사용
final useMockGpsProvider = Provider<bool>((ref) {
  return dotenv.env['USE_MOCK_GPS'] == 'true';
});
