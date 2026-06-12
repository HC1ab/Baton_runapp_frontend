# Baton — 게이미피케이션 러닝 앱

Flutter 3.x / Riverpod 2.x / Google Maps / Android-first

> GPS 러닝 추적 · 스팟 체크인 · 그룹 러닝 · 소셜 피드 · 러닝 결과 공유 카드

---

## 실행

```bash
# 개발
flutter run --dart-define=ENV=dev

# 프로덕션
flutter run --dart-define=ENV=prod

# APK 빌드 
flutter build apk --release --dart-define=ENV=prod
```

---

## 주요 기능

### 러닝
- 실시간 GPS 추적 (거리 · 페이스 · 칼로리 · 경로 폴리라인)
- 나침반 연동 캐릭터 방향 회전
- 러닝 결과 이미지 공유 카드 (자유 배치 / NRC 스타일 / 한글 스타일)
  - 드래그 · 리사이즈 · 색상 개별 커스텀

### 스팟 체크인
- 반경 30m 이내 GPS 체크인 · 24h 쿨다운
- 체크인 시 포인트 지급

### 그룹 러닝
- WebSocket 실시간 참가자 위치 공유
- 방 생성 · 참여 · 나가기 · 호스트 종료

### 소셜
- 그룹 방 피드 (30초 폴링)
- 팔로우 · 팔로워 요청

### 캐릭터 & 프로필
- SVG 4레이어 구체 캐릭터 (색상 커스텀)
- 칭호 · 포인트샵 · 러닝 히스토리

---

## 기술 스택

| 분류 | 기술 |
|------|------|
| Framework | Flutter 3.x |
| State | Riverpod 2.x (NotifierProvider / FutureProvider) |
| 지도 | Google Maps Flutter |
| 네트워크 | Dio + AuthInterceptor (자동 토큰 갱신) |
| 실시간 | WebSocket |
| 인증 | JWT + Kakao 소셜로그인 |
| 저장 | SharedPreferences · flutter_secure_storage |
| 이미지 | gal · image_picker |
| 배포 | Firebase App Distribution (GitHub Actions) |

---

## 환경 설정

`.env.dev` / `.env.prod` 파일 루트에 생성:

```env
IS_DEV=true
USE_MOCK_GPS=true
API_BASE_URL=http://api.baton-running-app.kro.kr:8080
GOOGLE_MAPS_API_KEY=your_key
KAKAO_NATIVE_APP_KEY=your_key
```

> `.env.*` 파일은 `.gitignore`에 등록됨. CI/CD는 GitHub Secrets에서 주입.

---

## 프로젝트 구조

```
lib/
├── main.dart
├── firebase_options.dart
└── src/
    ├── app.dart
    ├── core/
    │   ├── constants/        # AppColors · AppSpacing · AppRoutes · ErrorMessages 등
    │   ├── network/          # Dio · AuthInterceptor · ApiClient
    │   ├── storage/          # SecureStorage · SharedPreferences
    │   ├── character/        # 캐릭터 스타일 프로바이더
    │   └── utils/            # FormatUtils · RunningUtils
    ├── common/
    │   └── widgets/          # CharacterSphereWidget 등 공용 위젯
    └── features/
        ├── auth/             # 로그인 · 회원가입 · JWT 관리
        ├── running/          # GPS 러닝 · 스팟 · 러닝 화면
        ├── run_share/        # 러닝 결과 공유 카드
        ├── social/           # 그룹 방 피드 · 소셜
        ├── group_running/    # WebSocket 그룹 러닝
        ├── profile/          # 프로필 · 히스토리
        ├── shop/             # 포인트샵
        └── spot/             # 스팟 목록
```

---

## CI/CD

`main` 브랜치 push 시 GitHub Actions 자동 실행:
1. `.env.prod` 복원 (Secrets 주입)
2. `google-services.json` / `GoogleService-Info.plist` 복원
3. `flutter build apk --release`
4. Firebase App Distribution → `testers` 그룹 배포
