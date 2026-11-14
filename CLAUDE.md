# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

FIT LINK is a Flutter port of a single-file HTML prototype (`FIT_LINK_prototype.html`, not in this repo). Screens, copy (Korean), mock data and interactions were reproduced 1:1 from the HTML/CSS/JS. There is no backend: data (gyms, products, posts) is mock, user state is persisted locally, the gym map is real (OpenStreetMap), and camera/AI/payment/watch features are still demo fakes. The README's "HTML 프로토타입 → Flutter 대응" table is the reference when matching behavior to the original prototype.

## Commands

```bash
flutter pub get
flutter analyze                       # lint (flutter_lints; prefer_const_constructors and avoid_print are disabled)
flutter test                          # all tests
flutter test test/app_state_test.dart # single file
flutter test --plain-name "출석"       # single test by name (substring)
flutter run -d chrome                 # quickest visual check; also windows / emulator
```

- Requires Flutter 3.44+ / Dart 3.12+ (`go_router` 18); development and CI use Flutter 3.47.9.
- CI (`.github/workflows/ci.yml`) runs `flutter analyze`, `flutter test` and `flutter build web` on every push to `master` and every PR — keep all three green. Pushes to `master` that pass are deployed to GitHub Pages (https://seungho-sohn.github.io/fit_link/), built with `--base-href /fit_link/` (in Git Bash locally, prefix `MSYS_NO_PATHCONV=1` or the path gets mangled).
- Tests: `test/app_state_test.dart` unit-tests `AppState` logic via `AppState.fresh()` (a non-singleton instance; needs `TestWidgetsFlutterBinding.ensureInitialized()` because `toast()` touches a `GlobalKey`). `test/widget_test.dart` pumps every `AppPage`/`MarketView`/`DelivView` and fails on any exception (layout overflow, missing font). New pages/views are covered automatically since it iterates the enums' `values`.

## Signature feature: gear → gyms with the same machine (`GearFlow`)

- Flow: photo (real `image_picker` via `lib/services/photo_picker.dart`) or "직접 찾기" → analysis → **user confirms a candidate or browses the catalog** → gym matching → map → confirm. The "분석 결과 보기" button stays disabled until the recognizer returns.
- Recognition is behind `GearRecognizer` (`lib/services/gear_recognizer.dart`). Only `DemoGearRecognizer` exists (fixed candidates, labelled "데모 후보" in the UI); an AI recognizer just implements the interface — the confirm screen stays human-in-the-loop.
- Rules live in `lib/data/equipment.dart` (`GearModel`, `matchLevel`: exact > same brand & category > same category, `matchGyms`). **Data comes from CSV**: `data/gear_catalog.csv`, `data/gyms.csv`, `data/gym_gear.csv` (Korean headers, guide in `data/README.md`) → `dart run tool/data/import_gym_data.dart` validates them (errors with file + spreadsheet row) and generates `lib/data/gym_data.dart` (`gearCatalog`, `gyms`, `gymGear`; re-exported by `equipment.dart` / `mock_data.dart`). Never edit `gym_data.dart` by hand — edit the CSV and rerun; `test/gym_data_test.dart` fails if they diverge. Parser/validator/generator: `tool/data/gym_data_csv.dart` (pure Dart). Data is still mock until partner-gym data arrives; keep the rules and `test/equipment_test.dart` checks.
- `GearFlow` takes `recognizer`, `pick`, `locate`, `mapTiles` for tests (`test/map_test.dart`).
- **Data loop** (on `AppState`, persisted): operators register their gym's gear in B2B (`MarketView.gymGear`, `/market/b2b/gear`, gym = `AppState.myGym`) → `operatorGear` replaces `gymGear` for that gym; members answer "이 기구가 실제로 있나요?" on step 6 → `gearReports` (`'gym|gearId'` → bool; "없어요" removes it from matching, first report +30P). Always match with `matchGyms(g, gear: s.gymGearNow)`, never the raw `gymGear`; `gearSource()` gives the trust label (`GearSource`: 등록 정보 / 운영자 등록 / 이용자 확인). Re-registering clears that gym's reports. Local-only for now; a backend would receive the same two actions.

## Map & location

- `GymMap` (`lib/widgets/gym_map.dart`) uses `flutter_map` + public OpenStreetMap tiles (no API key; OSM's tile policy only allows light use, so production needs a tile provider — swap `GymMap.tileUrl`). Tiles are dark-inverted via `darkModeTileBuilder`; attribution must stay visible.
- `lib/services/location.dart`: `currentLocation()` (geolocator) falls back to `gangnamStation` on any failure/denial, and `distanceLabel()` formats distances. Gym distances are always computed from coordinates on `Gym.pos` (mock gyms sit around Gangnam), never stored as strings.
- `GearFlow` steps 4–6 use the mock `_matches` list joined to `gyms` by name; it takes `locate` and `mapTiles` params so tests avoid the location plugin and tile network (`test/map_test.dart`). "길찾기" opens a public Kakao Map link via `url_launcher`.

## Accessibility (enforced by `test/a11y_test.dart`)

- Every tappable element needs a screen-reader label and a hit area ≥ 24×24 (WCAG 2.2 AA). For small text links/icons use `TapArea` (`lib/widgets/common.dart`): it enlarges only the hit area, adds `button`/`label`/`selected` semantics. `StepTitle` back links use 32px so the layout barely moves; use ≥36 for other standalone links.
- Text scale is clamped to `maxTextScale` (1.5) in `FitLinkApp.builder`; nothing may overflow up to that. Don't give text-bearing boxes fixed heights — use `FlexGrid` instead of `GridView.count(childAspectRatio:)`, scale fixed extents with `MediaQuery.textScalerOf(context).scale(...)`, and wrap text inside fixed-size graphics (rings, badges) in `FittedBox(fit: BoxFit.scaleDown)` (`Ring` already does).
- Text colors must keep ≥ 4.5:1 contrast on charcoal/panel/panel2/onyx (checked numerically in the test). `goldDim` and `hairline*` are for borders/decoration, not text.
- The test walks every `AppPage`/`MarketView`/`DelivView` plus the gear (1–6) and calorie (1–4) step flows; extend `everyScreen`/`stepFlows` when adding screens.

## Android release signing

- `android/app/build.gradle.kts` signs release builds with the key from `android/key.properties` (git-ignored; points at a keystore outside the repo) and falls back to the debug key when that file is absent, so PR/CI builds still work.
- `.github/workflows/release.yml`: pushing a `vX.Y.Z` tag runs tests, writes `key.properties` from repo Secrets, builds the APK with version name `X.Y.Z` and code `X*10000+Y*100+Z`, refuses to publish unless the APK is signed by `CN=FIT LINK`, then attaches it to a GitHub Release. Never commit keystores, passwords, or `key.properties`.

## App icon

- Source images are rendered by `tool/icon/make_icon_test.dart` (not under `test/`, so `flutter test` doesn't run it) into `assets/icon/`; `dart run flutter_launcher_icons` (config in `pubspec.yaml`) generates all platform icons. flutter_launcher_icons 0.14.4 wrongly rewrites `ASSETCATALOG_COMPILER_GENERATE_SWIFT_ASSET_SYMBOL_EXTENSIONS` in `ios/Runner.xcodeproj/project.pbxproj` and drops the trailing newline in `web/manifest.json` — revert both after running it.

## Fonts (all bundled — no runtime download)

- `main()` sets `GoogleFonts.config.allowRuntimeFetching = false`. `google_fonts` resolves each requested weight from `assets/google_fonts/<Family>-<Weight>.ttf` (e.g. `Inter-SemiBold.ttf`); files are the exact ones the package would download (sha256 = hash in the package source). **Using a family or weight/style not present there throws at runtime** — add the file first. Only normal (non-italic) styles are bundled; `NotoSerifKR` only has Regular and SemiBold.
- `NotoSerifKR-*.ttf` are **subsets** (KS X 1001 Hangul 2,350 + ASCII/Latin-1/punctuation + every character in `lib/**/*.dart` at subset time). If new `F.kr` copy uses rare syllables, they fall back to Pretendard; re-subset from the full font with `pyftsubset` if that matters.
- Pretendard (`assets/fonts/pretendard/`, declared under `flutter: fonts:` in pubspec) is set as `fontFamilyFallback` on every `F.*` Latin style and the theme text theme, so Korean renders identically on all devices.
- OFL license texts sit next to the fonts and are registered with `LicenseRegistry` in `main.dart`.
- Platform folders were generated by `flutter create` (Android package `kr.wildwear.fit_link`); app code lives entirely in `lib/`.

## Architecture

**Navigation is state-driven, with the URL kept in sync.** A single global singleton `AppState.I` (`lib/state/app_state.dart`, a `ChangeNotifier`) holds `page` (`AppPage` enum) plus tab-internal views (`marketView: MarketView`, `delivView: DelivView`), all defined in `lib/state/routes.dart` (re-exported by `app_state.dart`). `Shell` in `lib/main.dart` wraps everything in one `ListenableBuilder` on `AppState.I` and switches on `page` to pick the screen.

- Change screens via `AppState.I.go(AppPage.x)`, `goMarket(MarketView.x)`, `goDeliv(DelivView.x)` — these mirror the HTML's `switchTab()/goMarket()/goDeliv()`. Never call `context.go` directly; `AppState` stays the source of truth.
- URL sync (`lib/state/router.dart`, go_router): `AppState.notifyListeners` pushes `location` (via `onLocationChanged` = `GoRouter.go`) whenever the nav state's URL changes; router changes (deep links, browser back) call `AppState.applyLocation`. Every route renders the same `Shell` page (shared page key, no transition), so screen state survives URL changes. `locationOf`/`parseLocation` in `routes.dart` must round-trip for every page/view — `test/routes_test.dart` checks this and that each URL is in `routePaths`. Web uses hash URLs (`#/market/cart`) so GitHub Pages deep links work. Unit tests use `AppState.fresh()` with no router (`onLocationChanged` null).
- Bottom tabs: `home comm market delivery cal my`; sub-pages `coach live inbody gear points` sit on top of a tab. `AppPage.tab` gives the highlighted tab and `AppPage.parent` the Android-back target. Adding a page: add the enum value, the exhaustive `switch` in `Shell._page`, `locationOf`/`parseLocation` and `routePaths` (and `tab`/`parent` if not under home).
- Each screen gets `ValueKey('$page-$pageSeq')`; `go()` bumps `pageSeq`, so re-entering a page recreates it and resets its local `State`.
- Toasts go through `AppState.I.toast(msg)` (SnackBar via a global `messengerKey`), so they can be fired without a `BuildContext`.
- Shared app state (points/tier/missions, market cart, delivery cart/favorites, community posts/comments/likes, onboarding) lives on `AppState`; mutate it there and call `notifyListeners()`. Screens access it through a file-level `AppState get _s => AppState.I;` getter. Purely local UI state stays in each screen's `StatefulWidget`.
- **Persistence**: `main()` calls `AppState.I.attachStore(PrefsStore)` (`lib/state/persistence.dart`, `shared_preferences`, one JSON string under key `fit_link.app_state`). After that, every `notifyListeners()` re-serializes `toJson()` and writes only if it changed. To persist a new field, add it to both `toJson()` and `_restore()` in `app_state.dart`; `_restore` parses everything before assigning, and any error/schema mismatch falls back to defaults — bump `_schema` on incompatible changes. **Additive fields must be optional in `_restore`** (`j['x'] as List? ?? const []`) so saves from older app versions still restore points/carts (see the old-format test in `test/persistence_test.dart`). Navigation/view state and transient values (last order totals, pay options) are intentionally not saved.
- Community: seed posts/comments are constants (`seedPosts`, `seedComments` keyed by post id); only the user's own posts, comments and like overrides are stored. Weekly missions (`MissionKind`) advance from real actions (`attend`, `addPost('운동 인증')`, `placeDOrder`, `writeReview`, `recordPersonalRecord`) and reset when `weekKey(now())` changes — read them through the `missions` getter, which performs the rollover.
- Date-dependent flags are stored as dates, not bools: `attended` = last attendance day == today, `stampClaimed` = claim week (Monday key) == this week. Use `AppState.now()` (overridable clock) rather than `DateTime.now()` for anything date-based so tests can control time. Unit tests use `MemoryStore`; `SharedPreferences.setMockInitialValues` for `PrefsStore`.
- Onboarding is an overlay stacked on top of the shell until `onboarded` is true, not a separate route.
- Content is width-constrained to 430 logical px (phone width) on tablet/web.

**Styling conventions** (`lib/theme.dart`):
- `C` = color constants mapped 1:1 from the prototype's CSS `:root` variables (dark onyx/charcoal + gold palette). Use `C.goldA(o)` / `color.op(o)` instead of the deprecated `withOpacity`.
- `F` = text-style helpers (`F.inter`, `F.serif` (Cormorant), `F.bodoni`, `F.kr` (Noto Serif KR), `F.gnum` for gold numerals). Note `ls` is letter-spacing in **em** (multiplied by font size), matching CSS.
- CSS px values were transcribed directly as logical px.

**Other modules**:
- `lib/data/mock_data.dart` — all hardcoded data from the prototype's `<script>` plus model classes (`Mission`, `PointLog`, `Comment`, `Review`, `Product`, …) and helpers like `comma()`. Use model classes (shared/mutable data) or named-field records (screen-local `const` display data, e.g. `(part: '가슴', ratio: 1.0)`), never positional `List`s/`Map`s indexed with `[0]`/`['k']`. `AppState.payCalc()` returns a `PayBreakdown`.
- `lib/widgets/common.dart` — the shared UI kit (`Box`, `GoldButton`, `Ring`, `Viewfinder`, `AnalyzeLog`, `showGoldSheet`, `searchBar`, `qtyCtrl`, …). Controllers created for a `showGoldSheet` go in its `disposables:` — they are disposed when the sheet widget is removed (after the close animation), not on pop. Inline SVGs from the prototype are reproduced as `CustomPainter`s with the original coordinates (`parseSimplePath` converts simple SVG path strings).
- `lib/screens/` — one file per tab/flow; multi-step flows (gear recognition, calorie scan, market/delivery sub-views) keep their step as local or `AppState` view state rather than routes. The home tab is `home_screen.dart` (top) plus one file per lower section in `screens/home/` (barrel: `home/sections.dart`). The market tab is `market_screen.dart` (shopping views) plus `market_b2b.dart` (`B2BView`: gym-owner views); B2B selections live in a `B2BFilters` object owned by the market state so they survive switching between B2B views.
