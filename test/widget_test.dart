// FIT LINK 기본 테스트.
// 글꼴은 assets/google_fonts/ 에 내장되어 있으므로 네트워크 없이 화면을 띄울 수 있다.
// 내장되지 않은 굵기·글꼴을 요청하면 google_fonts 가 오류를 던져 테스트가 실패한다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fit_link/main.dart';
import 'package:fit_link/state/app_state.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('FitLinkApp 진입 위젯 생성', () {
    const app = FitLinkApp();
    expect(app, isA<StatelessWidget>());
  });

  testWidgets('모든 화면이 내장 글꼴만으로 렌더링된다', (tester) async {
    tester.view.physicalSize = const Size(430 * 3, 932 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const FitLinkApp());
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('FIT LINK'), findsWidgets); // 온보딩 오버레이 포함

    final s = AppState.I;
    s.finishOnboard(0);
    for (final p in ['home', 'coach', 'live', 'inbody', 'gear', 'comm', 'market', 'delivery', 'cal', 'my', 'points']) {
      s.go(p);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: '화면 $p');
    }
    for (final v in ['b2b', 'b2bform', 'used', 'dash', 'cart']) {
      s.go('market');
      s.goMarket(v);
      await tester.pump(const Duration(milliseconds: 500));
      expect(tester.takeException(), isNull, reason: '마켓 $v');
    }
    s.openShop('s2');
    await tester.pump(const Duration(milliseconds: 500));

    s.go('home'); // 주기 타이머가 있는 화면을 정리
    await tester.pump(const Duration(seconds: 3));
  });
}
