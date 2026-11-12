# FIT LINK — Flutter 이식본

`FIT_LINK_prototype.html`(단일 HTML 프로토타입)을 Flutter/Dart 앱으로 옮긴 프로젝트입니다.
화면 구성·문구·목업 데이터·인터랙션(포인트 적립, 장바구니, 휴식 타이머, 1RM 계산 등)을 HTML과 동일하게 재현했습니다.

> ※ **이 코드는 Flutter SDK가 없는 환경에서 작성되어 실제 컴파일·실행 검증을 하지 못했습니다.** 괄호 균형, const 오용, 커스텀 위젯 인자 검증 등 정적 점검만 마쳤습니다. 첫 실행 시 `flutter analyze` 결과를 알려주시면 바로 수정하겠습니다.

## 실행 방법

```bash
# 1) 압축을 푼 폴더에서 플랫폼 폴더(android/ios/web 등) 생성 — lib/·pubspec.yaml은 그대로 유지됩니다
flutter create . --project-name fit_link --org com.fitlink

# 2) 패키지 설치 후 실행
flutter pub get
flutter analyze
flutter run            # 에뮬레이터/실기기
flutter run -d chrome  # 웹으로 빠르게 확인
```

- 요구 버전: Flutter 3.24 이상 (Dart 3.5+) — `PopScope.onPopInvokedWithResult`, `switch` 표현식 사용
- 의존 패키지: `google_fonts` 하나뿐 (Inter · Cormorant Garamond · Bodoni Moda · Noto Serif KR을 런타임에 내려받음)

## 폴더 구조

```
lib/
├─ main.dart                 앱 진입점 · 셸(상단 워드마크 + 하단 6탭 + 온보딩 오버레이)
├─ theme.dart                CSS :root 색상 변수 → C 클래스, 폰트 헬퍼 F
├─ state/app_state.dart      전역 상태(포인트·장바구니·배달·찜·화면전환·토스트) — ChangeNotifier
├─ data/mock_data.dart       HTML <script>의 모든 하드코딩 데이터
├─ widgets/common.dart       공통 위젯(Box, GoldButton, Ring, LiveDot, WwHolo, Viewfinder …)
└─ screens/
   ├─ onboarding.dart        3단계 온보딩
   ├─ home_screen.dart       홈 상단(목표·시그니처 스캔·혼잡도·메이트·챌린지·루틴)
   ├─ home_sections.dart     홈 하단(뉴스·운동기록/휴식타이머·PR·눈바디·1RM/원판·PT예약·머슬맵·프로그램·워치)
   ├─ coach_screen.dart      AI 코치 채팅 + 실시간 코칭
   ├─ inbody_screen.dart     인바디 리포트
   ├─ gear_flow.dart         기구 사진 → 인식 → 결과 → 헬스장 매칭 → 지도 → 확정 (6단계)
   ├─ community_screen.dart  피드(댓글·글쓰기 시트)·챌린지·그룹·랭킹
   ├─ market_screen.dart     마켓 홈·타임특가·상세·스토어·장바구니 + B2B·견적폼·중고·운영대시보드
   ├─ delivery_screen.dart   헬스 배달(정렬·찜·메뉴·장바구니·결제·배달추적)
   ├─ calorie_screen.dart    음식 스캔 → 결과 → 오늘의 식단(수분 컵)
   └─ my_screen.dart         마이페이지 + WILD WEAR 포인트 허브
assets/images/               HTML에 base64로 박혀 있던 이미지 3종을 파일로 추출
```

## HTML → Flutter 대응

| HTML/JS | Flutter |
|---|---|
| `switchTab()`, `goMarket()`, `goDeliv()`, `openCoach()` | `AppState.go()` / `goMarket()` / `goDeliv()` |
| 전역 변수 `POINTS`, `cart`, `dcart`, `dfavs` | `AppState` 필드 + `notifyListeners()` |
| `toast()` | `ScaffoldMessenger` SnackBar |
| CSS `conic-gradient` 링 | `Ring` (CustomPainter `drawArc`) |
| `@keyframes pulse`, 스캔라인, 분석 로그 지연 | `AnimationController`, `AnimatedOpacity` |
| WILD WEAR 홀로그램 로고(mask-image + 그라데이션) | `ShaderMask` + 마스크 PNG |
| 인라인 SVG(실루엣·머슬맵·기구·접시) | CustomPainter로 좌표 그대로 재현 |
| 하단 시트(PT 예약·댓글·글쓰기) | `showModalBottomSheet` |
| `setInterval` 타이머 | `Timer.periodic` |

## 원본과 달라진 점 / 어려웠던 부분

1. **폰 목업 프레임 제거** — HTML의 검은 폰 테두리·노치는 브라우저 시연용이라 실제 앱에선 뺐고, 대신 태블릿·웹에서 폭을 430px로 제한합니다.
2. **아이콘** — 탭바 SVG 아이콘은 Material 아이콘으로 대체했습니다.
3. **한글 폰트** — Inter에는 한글 글리프가 없어 HTML과 마찬가지로 시스템 한글 폰트로 대체 표시됩니다. ※ **기기별로 글꼴 느낌이 HTML과 다를 수 있습니다.** 필요하면 Pretendard 등을 assets에 넣어 통일할 수 있습니다.
4. **AI 코치 답변의 굵은 글씨** — HTML `<b>` 강조는 단순화를 위해 일반 텍스트로 넣었습니다.
5. **사진 촬영·지도·워치 연동** — HTML도 실제 기능이 아닌 시연(목업)이므로 동일하게 목업으로 두었습니다. 실제 구현 시 `image_picker`, `google_maps_flutter`, `health` 패키지 등이 필요합니다.
6. **상태 영속성** — 포인트·장바구니 등은 앱 실행 중에만 유지됩니다(HTML도 새로고침 시 초기화). 저장이 필요하면 `shared_preferences` 등을 붙이면 됩니다.
7. ※ **세부 여백·글자 크기는 CSS px 값을 Flutter 논리 픽셀로 1:1 옮긴 것이라, 기기 해상도에 따라 HTML 화면과 약간 다르게 보일 수 있습니다.**
