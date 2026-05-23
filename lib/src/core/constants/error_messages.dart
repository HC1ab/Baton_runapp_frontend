/// User-facing error message constants.
/// Never hardcode error strings outside this file.
abstract final class ErrorMessages {
  // --- Network ---
  static const networkError = '네트워크 연결을 확인해주세요.';
  static const timeoutError = '요청 시간이 초과됐어요. 다시 시도해주세요.';

  // --- Server ---
  static const serverError = '서버에 문제가 발생했어요. 잠시 후 다시 시도해주세요.';
  static const unknownError = '알 수 없는 오류가 발생했어요.';
  static const invalidResponse = '응답 형식이 올바르지 않아요.';

  // --- Auth ---
  static const unauthorized = '로그인이 필요해요.';
  static const tokenExpired = '로그인이 만료됐어요. 다시 로그인해주세요.';
  static const loginFailed = '이메일 또는 비밀번호를 확인해주세요.';
  static const emptyEmail = '이메일을 입력해주세요.';
  static const emptyPassword = '비밀번호를 입력해주세요.';
  static const invalidEmail = '올바른 이메일 형식이 아니에요.';

  // --- Running ---
  static const runningOnly = '러닝 중에만 체크인할 수 있어요.';
  static const locationDisabled = '위치 서비스가 꺼져 있어요.';
  static const locationPermissionDenied = '위치 권한이 필요해요.';

  // --- Spot ---
  static const spotRunNotFound = '존재하지 않는 러닝 기록이에요.';
  static const spotRunNotOwned = '본인의 러닝 기록이 아니에요.';
  static const spotAlreadyCheckedIn = '24시간 이내에 이미 체크인했어요.';
  static const spotOutOfRange = '반경 30m 밖에서는 체크인할 수 없어요.';
  static const spotNotFound = '존재하지 않는 스팟이에요.';
  static const spotAlreadyCheckedInCard = '24시간 이내 이미 체크인한 스팟이에요.';
}
