import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fit_link/main.dart';
import 'package:fit_link/state/app_state.dart';
import 'package:fit_link/state/router.dart';

/// 모든 화면 상태 (페이지 × 운영자 전용관 내부 화면)
List<AppState> everyNavState() => [
      for (final p in AppPage.values)
        if (p != AppPage.b2b) AppState.fresh()..page = p,
      for (final v in B2BPage.values)
        AppState.fresh()
          ..page = AppPage.b2b
          ..b2bPage = v,
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('주소 ↔ 화면 상태', () {
    test('모든 화면: 화면 → 주소 → 화면이 그대로 돌아온다', () {
      final states = everyNavState();
      expect(states.length, AppPage.values.length - 1 + B2BPage.values.length);
      final seen = <String>{};
      for (final a in states) {
        final loc = a.location;
        expect(seen.add(loc), isTrue, reason: '주소가 겹침: $loc');

        final b = AppState.fresh()..page = AppPage.comm; // 다른 화면에서 출발
        expect(b.applyLocation(Uri.parse(loc)), isTrue, reason: loc);
        expect(b.location, loc);
        expect(b.page, a.page, reason: loc);
        if (a.page == AppPage.b2b) expect(b.b2bPage, a.b2bPage, reason: loc);
      }
    });

    test('만들어지는 모든 주소가 라우터에 등록되어 있다', () {
      final patterns = [for (final p in routePaths) RegExp('^${p.replaceAll(RegExp(r':\w+'), '[^/]+')}\$')];
      for (final a in everyNavState()) {
        expect(patterns.any((r) => r.hasMatch(a.location)), isTrue, reason: '라우터에 없는 주소: ${a.location}');
      }
    });

    test('모르는 주소 · 빠진 마켓·배달·포인트 주소는 거부한다', () {
      final s = AppState.fresh();
      for (final bad in ['/nope', '/b2b/x', '/market', '/market/product/p1', '/market/b2b', '/delivery', '/my/points']) {
        expect(s.resolveLocation(Uri.parse(bad)), isNull, reason: bad);
        expect(s.applyLocation(Uri.parse(bad)), isFalse, reason: bad);
      }
      expect(s.page, AppPage.home); // 상태는 그대로
    });

    test('앱 안에서 화면이 바뀌면 바뀐 주소를 한 번만 알린다', () {
      final s = AppState.fresh();
      final sent = <String>[];
      s.onLocationChanged = sent.add;
      s.go(AppPage.gear);
      s.goB2B(B2BPage.quote);
      s.addPost('질문', 'x'); // 화면은 그대로 → 알리지 않음
      s.applyLocation(Uri.parse('/b2b/used')); // 주소에서 온 변경 → 다시 알리지 않음
      expect(sent, ['/gear', '/b2b/quote']);
    });

    test('주소로 다른 화면에 들어오면 그 화면을 새로 시작한다', () {
      final s = AppState.fresh();
      final seq = s.pageSeq;
      s.applyLocation(Uri.parse('/b2b/quote'));
      expect(s.pageSeq, seq + 1);
      s.applyLocation(Uri.parse('/b2b/dashboard')); // 같은 화면 안 이동
      expect(s.pageSeq, seq + 1);
    });
  });

  group('앱에서', () {
    setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

    Future<void> openApp(WidgetTester t) async {
      t.view.physicalSize = const Size(430 * 3, 932 * 3);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(const FitLinkApp());
      AppState.I
        ..finishOnboard(0)
        ..go(AppPage.home);
      await t.pump(const Duration(milliseconds: 300));
    }

    String currentPath(WidgetTester t) => GoRouter.of(t.element(find.byType(Shell))).routerDelegate.currentConfiguration.uri.path;

    Future<void> settle(WidgetTester t) => t.pump(const Duration(milliseconds: 300));

    testWidgets('딥링크로 들어오면 그 화면이 열리고, 잘못된 주소는 홈으로', (t) async {
      await openApp(t);
      final s = AppState.I;

      await t.binding.handlePushRoute('/b2b/gear');
      await settle(t);
      expect((s.page, s.b2bPage), (AppPage.b2b, B2BPage.gear));
      expect(find.text('보유 기구 등록'), findsWidgets);

      await t.binding.handlePushRoute('/gear');
      await settle(t);
      expect(s.page, AppPage.gear);

      await t.binding.handlePushRoute('/market/product/p6'); // 빠진 마켓 주소
      await settle(t);
      expect(s.page, AppPage.home);
      expect(currentPath(t), '/');

      s.go(AppPage.home);
      await t.pump(const Duration(seconds: 3)); // 화면 타이머 정리
    });

    testWidgets('앱에서 이동하면 주소가 따라 바뀐다', (t) async {
      await openApp(t);
      final s = AppState.I;
      s.go(AppPage.comm);
      await settle(t);
      expect(currentPath(t), '/comm');
      s.go(AppPage.b2b);
      s.goB2B(B2BPage.quote);
      await settle(t);
      expect(currentPath(t), '/b2b/quote');
      s.go(AppPage.gear);
      await settle(t);
      expect(currentPath(t), '/gear');
      s.go(AppPage.home);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('Android 뒤로 가기: 하위 화면 → 상위 화면 → 홈', (t) async {
      await openApp(t);
      final s = AppState.I;

      s.goB2B(B2BPage.dash);
      await settle(t);
      await t.binding.handlePopRoute();
      await settle(t);
      expect((s.page, s.b2bPage), (AppPage.b2b, B2BPage.home));
      await t.binding.handlePopRoute();
      await settle(t);
      expect(s.page, AppPage.my);
      await t.binding.handlePopRoute();
      await settle(t);
      expect(s.page, AppPage.home);
      expect(currentPath(t), '/');
      await t.pump(const Duration(seconds: 3));
    });
  });
}
