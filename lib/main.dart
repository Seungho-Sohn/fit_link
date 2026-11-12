import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'state/app_state.dart';
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

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  runApp(const FitLinkApp());
}

class FitLinkApp extends StatelessWidget {
  const FitLinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FIT LINK',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      scaffoldMessengerKey: AppState.I.messengerKey,
      home: const Shell(),
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
          canPop: s.page == 'home' && s.onboarded,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (s.page == 'market' && s.marketView != 'home') {
              s.goMarket('home');
            } else if (s.page == 'delivery' && s.delivView != 'home') {
              s.goDeliv('home');
            } else if (s.page == 'points') {
              s.go('my');
            } else if (s.page == 'live') {
              s.go('coach');
            } else {
              s.go('home');
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
                        _TabBar(current: s.navTab),
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
    final k = ValueKey('${s.page}-${s.pageSeq}');
    switch (s.page) {
      case 'coach':
        return CoachScreen(key: k);
      case 'live':
        return LiveCoachScreen(key: k);
      case 'inbody':
        return InbodyScreen(key: k);
      case 'gear':
        return GearFlow(key: k);
      case 'comm':
        return CommunityScreen(key: k);
      case 'market':
        return MarketScreen(key: k);
      case 'delivery':
        return DeliveryScreen(key: k);
      case 'cal':
        return CalorieScreen(key: k);
      case 'my':
        return MyScreen(key: k);
      case 'points':
        return PointsScreen(key: k);
      default:
        return HomeScreen(key: k);
    }
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
  final String current;
  const _TabBar({required this.current});

  static const tabs = [
    ['home', '홈', Icons.home_outlined],
    ['comm', '커뮤니티', Icons.people_outline],
    ['market', '마켓', Icons.shopping_cart_outlined],
    ['delivery', '배달', Icons.delivery_dining_outlined],
    ['cal', '칼로리', Icons.restaurant_outlined],
    ['my', '마이', Icons.person_outline],
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
              onTap: () => AppState.I.go(t[0] as String),
              child: Padding(
                padding: const EdgeInsets.only(top: 11, bottom: 13),
                child: Column(children: [
                  Icon(t[2] as IconData, size: 19, color: current == t[0] ? C.goldBright : C.textFaint),
                  const SizedBox(height: 5),
                  Text(t[1] as String, style: F.inter(size: 8.5, color: current == t[0] ? C.goldBright : C.textFaint)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }
}
