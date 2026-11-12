// FIT LINK 화면 스모크 테스트.
// 글꼴은 assets/google_fonts/ 에 내장되어 있으므로 네트워크 없이 화면을 띄울 수 있다.
// 내장되지 않은 굵기·글꼴을 요청하거나 레이아웃이 넘치면 테스트가 실패한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fit_link/main.dart';
import 'package:fit_link/state/app_state.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('모든 화면이 내장 글꼴만으로 오류 없이 렌더링된다', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FitLinkApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('FIT LINK'), findsWidgets); // 온보딩 오버레이 포함

    Future<void> check(String what) async {
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: what);
    }

    final s = AppState.I;
    s.finishOnboard(0);
    for (final p in AppPage.values) {
      s.go(p);
      await check('화면 ${p.name}');
    }

    s.addToCart('p1', 1);
    for (final v in MarketView.values) {
      s.go(AppPage.market);
      s.goMarket(v);
      await check('마켓 ${v.name}');
    }

    s.openShop('s2');
    await check('배달 store');
    s.dAdd('d1');
    for (final v in DelivView.values) {
      s.goDeliv(v);
      await check('배달 ${v.name}');
    }

    s.go(AppPage.home); // 주기 타이머가 있는 화면을 정리
    await tester.pump(const Duration(seconds: 3));
  });
}
