import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fit_link/main.dart';
import 'package:fit_link/state/app_state.dart';
import 'package:fit_link/state/router.dart';

/// 모든 화면 상태 (페이지 × 마켓/배달 내부 화면, 상품·판매자·매장 id 포함)
List<AppState> everyNavState() => [
      for (final p in AppPage.values)
        if (p != AppPage.market && p != AppPage.delivery) AppState.fresh()..page = p,
      for (final v in MarketView.values)
        AppState.fresh()
          ..page = AppPage.market
          ..marketView = v
          ..curProductId = 'p6'
          ..curStoreSeller = 'hammer',
      for (final v in DelivView.values)
        AppState.fresh()
          ..page = AppPage.delivery
          ..delivView = v
          ..curShopId = 's3',
    ];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('주소 ↔ 화면 상태', () {
    test('모든 화면: 화면 → 주소 → 화면이 그대로 돌아온다', () {
      final states = everyNavState();
      expect(states.length, AppPage.values.length - 2 + MarketView.values.length + DelivView.values.length);
      final seen = <String>{};
      for (final a in states) {
        final loc = a.location;
        expect(seen.add(loc), isTrue, reason: '주소가 겹침: $loc');

        final b = AppState.fresh()..page = AppPage.comm; // 다른 화면에서 출발
        expect(b.applyLocation(Uri.parse(loc)), isTrue, reason: loc);
        expect(b.location, loc);
        expect(b.page, a.page, reason: loc);
        if (a.page == AppPage.market) expect(b.marketView, a.marketView, reason: loc);
        if (a.page == AppPage.delivery) expect(b.delivView, a.delivView, reason: loc);
      }
    });

    test('만들어지는 모든 주소가 라우터에 등록되어 있다', () {
      final patterns = [for (final p in routePaths) RegExp('^${p.replaceAll(RegExp(r':\w+'), '[^/]+')}\$')];
      for (final a in everyNavState()) {
        expect(patterns.any((r) => r.hasMatch(a.location)), isTrue, reason: '라우터에 없는 주소: ${a.location}');
      }
    });

    test('모르는 주소 · 없는 상품/판매자/매장은 거부한다', () {
      final s = AppState.fresh();
      for (final bad in ['/nope', '/market/x', '/market/product/zzz', '/market/store/nobody', '/delivery/shop/s999', '/my/points/extra']) {
        expect(s.resolveLocation(Uri.parse(bad)), isNull, reason: bad);
        expect(s.applyLocation(Uri.parse(bad)), isFalse, reason: bad);
      }
      expect(s.page, AppPage.home); // 상태는 그대로
    });

    test('앱 안에서 화면이 바뀌면 바뀐 주소를 한 번만 알린다', () {
      final s = AppState.fresh();
      final sent = <String>[];
      s.onLocationChanged = sent.add;
      s.go(AppPage.market);
      s.openProduct('p6');
      s.addToCart('p6', 1); // 화면은 그대로 → 알리지 않음
      s.applyLocation(Uri.parse('/delivery/cart')); // 주소에서 온 변경 → 다시 알리지 않음
      expect(sent, ['/market', '/market/product/p6']);
    });

    test('주소로 다른 화면에 들어오면 그 화면을 새로 시작한다', () {
      final s = AppState.fresh();
      final seq = s.pageSeq;
      s.applyLocation(Uri.parse('/market/cart'));
      expect(s.pageSeq, seq + 1);
      s.applyLocation(Uri.parse('/market/product/p1')); // 같은 화면 안 이동
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

      await t.binding.handlePushRoute('/market/product/p6');
      await settle(t);
      expect((s.page, s.marketView, s.curProductId), (AppPage.market, MarketView.detail, 'p6'));
      expect(find.text('장바구니 담기'.toUpperCase()), findsOneWidget);

      await t.binding.handlePushRoute('/delivery/shop/s3');
      await settle(t);
      expect((s.page, s.delivView, s.curShopId), (AppPage.delivery, DelivView.store, 's3'));

      await t.binding.handlePushRoute('/market/product/zzz');
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
      s.go(AppPage.market);
      s.goMarket(MarketView.b2bForm);
      await settle(t);
      expect(currentPath(t), '/market/b2b/quote');
      s.openShop('s2');
      await settle(t);
      expect(currentPath(t), '/delivery/shop/s2');
      s.go(AppPage.home);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('Android 뒤로 가기: 하위 화면 → 상위 화면 → 홈', (t) async {
      await openApp(t);
      final s = AppState.I;

      s.go(AppPage.points);
      await settle(t);
      await t.binding.handlePopRoute();
      await settle(t);
      expect(s.page, AppPage.my);

      s.openProduct('p1');
      await settle(t);
      await t.binding.handlePopRoute();
      await settle(t);
      expect((s.page, s.marketView), (AppPage.market, MarketView.home));
      await t.binding.handlePopRoute();
      await settle(t);
      expect(s.page, AppPage.home);
      expect(currentPath(t), '/');
      await t.pump(const Duration(seconds: 3));
    });
  });
}
