# FIT LINK

🌐 웹 데모: **https://seungho-sohn.github.io/fit_link/**

피트니스 종합 앱 **FIT LINK**의 Flutter 앱입니다. 단일 HTML 프로토타입(`FIT_LINK_prototype.html`)의 화면·문구·인터랙션을 옮긴 뒤,
데이터 저장·실제 지도·접근성 등을 더했습니다. 대부분의 데이터(헬스장, 상품, 게시글 등)는 아직 **목업**입니다.

## 실행

```bash
flutter pub get
flutter run -d chrome   # 웹으로 빠르게 확인
flutter run             # 연결된 Android/iOS 기기·에뮬레이터
```

- 요구 버전: **Flutter 3.44 이상 (Dart 3.12+)** — `go_router` 18 요구사항. 개발·CI는 Flutter 3.47.9.
- API 키나 별도 서버 없이 실행됩니다.
- 웹(`flutter run -d chrome`)은 실행할 때마다 새 크롬 프로필로 열려서, 저장된 데이터는 **F5 새로고침**으로는 유지되지만 다시 실행하면 초기화됩니다.

## 테스트

```bash
flutter analyze
flutter test                                # 전체
flutter test test/app_state_test.dart       # 파일 하나
flutter test --plain-name "출석"            # 이름에 '출석'이 들어간 테스트만
```

| 파일 | 내용 |
|---|---|
| `test/widget_test.dart` | 모든 화면을 띄워 오류·레이아웃 넘침이 없는지 (내장 글꼴만 사용) |
| `test/app_state_test.dart` | 포인트·등급·미션·장바구니·배달 결제 계산 |
| `test/persistence_test.dart` | 저장/복원, 깨진 저장본 처리, 날짜가 바뀔 때 출석·주간 보너스 |
| `test/map_test.dart` | 거리 표시, 헬스장 매칭 → 지도 → 확정 흐름 |
| `test/routes_test.dart` | 주소 ↔ 화면 변환(모든 화면), 딥링크, 잘못된 주소, Android 뒤로 가기 |
| `test/a11y_test.dart` | 버튼 이름, 터치 영역 24×24, 글자 150%/200%, 글자색 대비 |

GitHub에 push하거나 PR을 올리면 GitHub Actions가 `analyze`·`test`·웹 빌드를 자동으로 실행합니다 (`.github/workflows/ci.yml`).
`master`에 들어온 변경은 테스트를 통과하면 **https://seungho-sohn.github.io/fit_link/** 에 자동으로 배포됩니다.

## 주요 기능과 현재 상태

| 기능 | 상태 |
|---|---|
| 6개 탭(홈·커뮤니티·마켓·배달·칼로리·마이), 온보딩 | 프로토타입 화면 이식 완료 |
| 포인트·출석·미션·장바구니·찜 | 기기에 저장 (`shared_preferences`) |
| 헬스장 지도 | OpenStreetMap + 현재 위치, 카카오맵 길찾기 링크 (헬스장 목록은 목업) |
| 기구·음식 사진 인식, AI 코치 | 목업 결과 (AI 연동 작업본은 로컬 `archive/ai-features` 브랜치 — Anthropic API 키 필요) |
| 결제 | 목업 (토스페이먼츠 연동은 보류) |
| 접근성 | 스크린리더 이름, 터치 영역, 글자 대비, 글자 크기 150%까지 대응 |

## 폴더 구조

```
lib/
├─ main.dart                 앱 진입점 · 셸(상단 워드마크 + 하단 6탭 + 온보딩 오버레이), 저장소 연결, 글자 배율 상한
├─ theme.dart                색상 C · 글꼴 헬퍼 F (CSS :root 변수에서 옮김)
├─ state/
│  ├─ app_state.dart         전역 상태(포인트·장바구니·배달·찜·화면 전환·토스트) + 저장/복원
│  ├─ routes.dart            화면 식별자 enum (AppPage · MarketView · DelivView), 주소 ↔ 화면 변환
│  ├─ router.dart            GoRouter 설정 (등록된 주소 목록)
│  └─ persistence.dart       저장소 (SharedPreferences / 테스트용 메모리)
├─ services/location.dart    현재 위치(실패 시 강남역), 거리 계산·표시
├─ data/mock_data.dart       목업 데이터와 모델 클래스
├─ widgets/
│  ├─ common.dart            공통 위젯(Box, GoldButton, Ring, FlexGrid, TapArea, showGoldSheet …)
│  └─ gym_map.dart           OpenStreetMap 지도 + 헬스장 핀
└─ screens/
   ├─ onboarding.dart        3단계 온보딩
   ├─ home_screen.dart       홈 상단(목표·시그니처 스캔·혼잡도·메이트·챌린지·루틴)
   ├─ home/                  홈 하단 섹션(뉴스·운동기록·PR·눈바디·1RM·PT예약·머슬맵·프로그램·워치)
   ├─ coach_screen.dart      AI 코치 채팅 + 실시간 코칭
   ├─ inbody_screen.dart     인바디 리포트
   ├─ gear_flow.dart         기구 사진 → 인식 → 결과 → 헬스장 매칭 → 지도 → 확정 (6단계)
   ├─ community_screen.dart  피드(댓글·글쓰기)·챌린지·그룹·랭킹
   ├─ market_screen.dart     마켓 홈·타임특가·상세·스토어·장바구니
   ├─ market_b2b.dart        헬스장 운영자 전용관·견적·중고 거래·운영 대시보드
   ├─ delivery_screen.dart   헬스 배달(정렬·찜·메뉴·장바구니·결제·배달추적)
   ├─ calorie_screen.dart    음식 스캔 → 결과 → 오늘의 식단
   └─ my_screen.dart         마이페이지 + WILD WEAR 포인트 허브
assets/
├─ images/                   프로토타입의 이미지 3종
├─ fonts/pretendard/         한글 글꼴 (모든 영문 글꼴의 대체 글꼴)
└─ google_fonts/             Inter · Cormorant Garamond · Bodoni Moda · Noto Serif KR(서브셋) — 실행 중 다운로드 없음
```

## 개발 메모

- **화면 전환**은 `AppState.I.go(AppPage.x)` / `goMarket(...)` / `goDeliv(...)`로 합니다. 화면이 바뀌면 주소가 따라 바뀌고(`go_router`), 주소로 들어오거나 브라우저 뒤로 가기를 하면 그 화면이 열립니다.
  - 웹 주소 예: `…/fit_link/#/market/cart`, `#/market/product/p6`, `#/delivery/shop/s2`, `#/my/points`. 모르는 주소·없는 상품은 홈으로 갑니다.
  - 화면을 추가하면 `routes.dart`의 enum · `locationOf` · `parseLocation`, `router.dart`의 `routePaths`, `main.dart`의 `switch`를 함께 고칩니다. `test/routes_test.dart`가 빠진 곳을 잡아냅니다.
- **글꼴**은 모두 앱에 들어 있습니다. 새 굵기·글꼴을 쓰려면 `assets/google_fonts/`에 파일부터 추가해야 합니다 (없으면 실행 중 오류).
- **지도 타일**: OpenStreetMap 공개 타일 서버는 소량 사용만 허용합니다. 실서비스 전에는 타일 제공 업체로 바꿔야 합니다 (`GymMap.tileUrl`).
- **접근성 규칙**(버튼 이름, 터치 영역, 글자 대비, 고정 높이 금지)과 저장 구조 등 더 자세한 내용은 [`CLAUDE.md`](CLAUDE.md)에 있습니다.

## HTML 프로토타입 → Flutter 대응

| HTML/JS | Flutter |
|---|---|
| `switchTab()`, `goMarket()`, `goDeliv()`, `openCoach()` | `AppState.go()` / `goMarket()` / `goDeliv()` |
| 전역 변수 `POINTS`, `cart`, `dcart`, `dfavs` | `AppState` 필드 + `notifyListeners()` (기기에 저장) |
| `toast()` | `ScaffoldMessenger` SnackBar |
| CSS `conic-gradient` 링 | `Ring` (CustomPainter `drawArc`) |
| `@keyframes pulse`, 스캔라인, 분석 로그 지연 | `AnimationController`, `AnimatedOpacity` |
| WILD WEAR 홀로그램 로고(mask-image + 그라데이션) | `ShaderMask` + 마스크 PNG |
| 인라인 SVG(실루엣·머슬맵·기구·접시) | CustomPainter로 좌표 그대로 재현 |
| 하단 시트(PT 예약·댓글·글쓰기) | `showModalBottomSheet` (`showGoldSheet`) |
| `setInterval` 타이머 | `Timer.periodic` |

프로토타입과 다른 점: 폰 목업 프레임은 빼고 태블릿·웹에서 폭을 430px로 제한, 탭바 아이콘은 Material 아이콘으로 대체,
AI 코치 답변의 굵은 글씨는 일반 텍스트, 여백·글자 크기는 CSS px를 Flutter 논리 픽셀로 1:1 옮겼습니다.
