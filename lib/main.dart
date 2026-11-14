import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';
import 'services/gear_cloud.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'state/app_state.dart';
import 'state/persistence.dart';
import 'state/router.dart';
import 'theme.dart';
import 'screens/onboarding.dart';
import 'screens/home_screen.dart';
import 'screens/coach_screen.dart';
import 'screens/inbody_screen.dart';
import 'screens/gear_flow.dart';
import 'screens/community_screen.dart';
import 'screens/market_screen.dart';
import 'screens/delivery_screen.dart';
import 'screens/calorie_screen.dart';
import 'screens/my_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 글꼴은 전부 assets/google_fonts/ 에 내장 — 실행 중 네트워크 다운로드 금지
  GoogleFonts.config.allowRuntimeFetching = false;
  _registerFontLicenses();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  // 저장된 포인트·장바구니 등을 복원하고 이후 변경을 자동 저장.
  // 저장소를 열 수 없어도 앱은 저장 없이 실행한다.
  try {
    AppState.I.attachStore(await PrefsStore.open());
  } catch (e) {
    debugPrint('저장소를 열지 못해 저장 없이 실행합니다: $e');
  }
  runApp(const FitLinkApp());
  // 서버 연결은 화면을 띄운 뒤 뒤에서 — 오프라인이거나 설정이 없으면 기기 저장만 쓴다
  unawaited(_connectCloud());
}

/// Firebase 연결 (익명 로그인 → 헬스장 기구 등록·제보 공유)
Future<void> _connectCloud() async {
  final options = firebaseOptions;
  if (options == null) return;
  try {
    await Firebase.initializeApp(options: options);
    final cloud = await FirestoreGearCloud.connect().timeout(const Duration(seconds: 20));
    AppState.I.attachCloud(cloud);
  } catch (e) {
    debugPrint('서버에 연결하지 못해 기기 저장만 씁니다: $e');
  }
}

/// 내장 글꼴(SIL OFL)의 라이선스를 앱의 오픈소스 라이선스 화면에 등록
void _registerFontLicenses() {
  const files = {
    'Inter': 'assets/google_fonts/OFL-Inter.txt',
    'Cormorant Garamond': 'assets/google_fonts/OFL-CormorantGaramond.txt',
    'Bodoni Moda': 'assets/google_fonts/OFL-BodoniModa.txt',
    'Noto Serif KR': 'assets/google_fonts/OFL-NotoSerifKR.txt',
    'Pretendard': 'assets/fonts/pretendard/OFL.txt',
  };
  LicenseRegistry.addLicense(() async* {
    for (final e in files.entries) {
      yield LicenseEntryWithLineBreaks([e.key], await rootBundle.loadString(e.value));
    }
  });
}

/// 앱이 반영하는 최대 글자 배율
const maxTextScale = 1.5;

class FitLinkApp extends StatefulWidget {
  const FitLinkApp({super.key});

  @override
  State<FitLinkApp> createState() => _FitLinkAppState();
}

class _FitLinkAppState extends State<FitLinkApp> {
  // 주소(웹 #/market/cart 등)와 화면 상태를 맞추는 라우터 — lib/state/router.dart
  late final GoRouter _router = buildRouter(AppState.I, const Shell());

  @override
  void dispose() {
    AppState.I.onLocationChanged = null;
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'FIT LINK',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scaffoldMessengerKey: AppState.I.messengerKey,
      // 기기 글자 크기 설정은 150%까지 반영 (더 크면 고정 크기 카드·그리드가 깨짐 — test/a11y_test.dart)
      builder: (context, child) => MediaQuery.withClampedTextScaling(maxScaleFactor: maxTextScale, child: child!),
      routerConfig: _router,
    );
  }
}

class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) {
        return PopScope(
          // 안드로이드 뒤로가기: 하위 화면이면 홈/마켓 홈 등으로 복귀
          canPop: s.page == AppPage.home && s.onboarded,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (s.page == AppPage.market && s.marketView != MarketView.home) {
              s.goMarket(MarketView.home);
            } else if (s.page == AppPage.delivery && s.delivView != DelivView.home) {
              s.goDeliv(DelivView.home);
            } else {
              s.go(s.page.parent);
            }
          },
          child: Scaffold(
            backgroundColor: C.onyx,
            body: Center(
              // 태블릿·웹에서는 폰 폭(430)으로 가운데 정렬
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Container(
                  color: C.charcoal,
                  child: SafeArea(
                    child: Stack(children: [
                      Column(children: [
                        const _Wordmark(),
                        Expanded(child: _page(s)),
                        _TabBar(current: s.page.tab),
                      ]),
                      if (!s.onboarded) const Positioned.fill(child: OnboardingOverlay()),
                    ]),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _page(AppState s) {
    final k = ValueKey('${s.page.name}-${s.pageSeq}');
    return switch (s.page) {
      AppPage.home => HomeScreen(key: k),
      AppPage.comm => CommunityScreen(key: k),
      AppPage.market => MarketScreen(key: k),
      AppPage.delivery => DeliveryScreen(key: k),
      AppPage.cal => CalorieScreen(key: k),
      AppPage.my => MyScreen(key: k),
      AppPage.coach => CoachScreen(key: k),
      AppPage.live => LiveCoachScreen(key: k),
      AppPage.inbody => InbodyScreen(key: k),
      AppPage.gear => GearFlow(key: k),
      AppPage.points => PointsScreen(key: k),
    };
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 12),
      child: Column(children: [
        Text('FIT LINK', style: F.serif(size: 15, color: C.goldBright, ls: .42)),
        const SizedBox(height: 6),
        Container(width: 36, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, C.gold, Colors.transparent]))),
      ]),
    );
  }
}

class _TabBar extends StatelessWidget {
  final AppPage current;
  const _TabBar({required this.current});

  static const tabs = [
    (page: AppPage.home, label: '홈', icon: Icons.home_outlined),
    (page: AppPage.comm, label: '커뮤니티', icon: Icons.people_outline),
    (page: AppPage.market, label: '마켓', icon: Icons.shopping_cart_outlined),
    (page: AppPage.delivery, label: '배달', icon: Icons.delivery_dining_outlined),
    (page: AppPage.cal, label: '칼로리', icon: Icons.restaurant_outlined),
    (page: AppPage.my, label: '마이', icon: Icons.person_outline),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: C.charcoal, border: Border(top: BorderSide(color: C.hairlineSoft))),
      child: Row(children: [
        for (final t in tabs)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => AppState.I.go(t.page),
              child: Padding(
                padding: const EdgeInsets.only(top: 11, bottom: 13),
                child: Column(children: [
                  Icon(t.icon, size: 19, color: current == t.page ? C.goldBright : C.textFaint),
                  const SizedBox(height: 5),
                  Text(t.label, style: F.inter(size: 8.5, color: current == t.page ? C.goldBright : C.textFaint)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
