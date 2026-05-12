# RunApp

RunApp은 러닝 기록을 측정하고, 주변 스팟(Spot)에 체크인하여 보상을 획득하는 **게이미피케이션 러닝 앱**입니다.
Flutter와 Riverpod을 사용하여 개발되었으며, 네이버 지도(Naver Map)를 기반으로 작동합니다.

# 터미널 실행
flutter run --dart-define=ENV=dev

## ✨ 주요 기능

- **러닝 트래킹**: 실시간 위치 추적, 이동 경로(Polyline) 그리기, 러닝 시간 및 점수 계산.
- **스팟 체크인**:
  - 주변 스팟 탐색 및 지도 표시.
  - 스팟 반경 15m 이내 접근 시 자동/수동 체크인 및 포인트 획득.
- **개발자 모드 (Mock Mode)**:
  - 실제 밖으로 나가지 않고도 테스트 가능한 **가상 위치 조작(Joystick)** 기능.
  - 자동 걷기(Auto Walk) 및 이동 속도 조절.
  - 가상 스팟 데이터 생성 (`MockSpotApi`).
- **UI/UX**:
  - **Glassmorphism**: 배경이 투과되는 세련된 글래스 카드 디자인 (`GlassCard`).
  - **Custom Bottom Bar**: 커스텀 디자인된 하단 네비게이션.
  - 다크 모드/라이트 모드 지원.

## 🛠 기술 스택

- **Framework**: Flutter
- **State Management**: Riverpod
- **Map**: flutter_naver_map (Naver Maps API)
- **Location**: geolocator
- **Network**: Dio
- **Architecture**: Feature-based Architecture

## 📂 프로젝트 구조

```text
lib/
├── src/
│   ├── app.dart                   # 앱 최상위 설정 (테마, 라우팅)
│   ├── core/                      # 공통 모듈 (Network, Session 등)
│   ├── design/                    # 디자인 시스템 (GlassCard, Theme, CustomBar)
│   └── features/                  # 기능별 모듈
│       ├── auth/                  # 인증 (로그인)
│       ├── map/                   # 지도, 위치 추적, Mock 컨트롤러
│       ├── run/                   # 러닝 기록 데이터 관리
│       └── spot/                  # 스팟 데이터 및 API
└── main.dart                      # 진입점 (Naver Map 초기화)
```


## 백엔드 연결

기본 Base URL은 `http://localhost:8080`입니다.

- 변경 위치: `lib/src/core/network/api_client.dart`
