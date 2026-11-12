// 접근성 회귀 테스트
// - 누를 수 있는 모든 요소에 스크린리더용 이름이 있다 (labeledTapTargetGuideline)
// - 터치 영역이 WCAG 2.2 AA 최소 24×24 이상이다 (Android 권장 48×48은 목표지만 강제하지 않음)
// - 글자 크기를 150%(앱 상한)로 키워도 레이아웃이 넘치지 않는다
// - 팔레트의 글자색이 배경 위에서 WCAG AA 대비 4.5:1 이상이다
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fit_link/main.dart';
import 'package:fit_link/screens/calorie_screen.dart';
import 'package:fit_link/screens/gear_flow.dart';
import 'package:fit_link/services/location.dart';
import 'package:fit_link/state/app_state.dart';
import 'package:fit_link/theme.dart';

const wcagMinTarget = MinimumTapTargetGuideline(size: Size(24, 24), link: 'https://www.w3.org/WAI/WCAG22/Understanding/target-size-minimum');

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  void phone(WidgetTester t, {double textScale = 1}) {
    t.view.physicalSize = const Size(430 * 3, 932 * 3);
    t.view.devicePixelRatio = 3;
    if (textScale != 1) t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
  }

  /// 앱의 모든 화면(탭·하위 화면·마켓/배달 내부 화면)을 돌며 [check] 실행
  Future<void> everyScreen(WidgetTester t, Future<void> Function(String where) check) async {
    await t.pumpWidget(const FitLinkApp());
    await t.pump(const Duration(milliseconds: 500));
    await check('온보딩');
    final s = AppState.I..finishOnboard(0);
    Future<void> at(String where) async {
      await t.pump(const Duration(milliseconds: 500));
      await check(where);
    }

    for (final p in AppPage.values) {
      s.go(p);
      await at('화면 ${p.name}');
    }
    for (final v in MarketView.values) {
      s.go(AppPage.market);
      s.goMarket(v);
      await at('마켓 ${v.name}');
    }
    s.openShop('s2');
    s.dAdd('d1');
    for (final v in DelivView.values) {
      s.goDeliv(v);
      await at('배달 ${v.name}');
    }
    s.go(AppPage.coach);
    await t.pump();
    await t.tap(find.text('📊 주간 리포트'));
    await at('코치 주간 리포트');
    s.go(AppPage.home);
    await t.pump(const Duration(seconds: 3));
  }

  /// 단계형 화면(기구 인식 1~6, 칼로리 1~4)을 버튼을 눌러 진행하며 [check] 실행
  Future<void> stepFlows(WidgetTester t, Future<void> Function(String where) check) async {
    Future<void> tapGo(String label, String where) async {
      await t.tap(find.text(label.toUpperCase()));
      await t.pump();
      await t.pump(const Duration(seconds: 4));
      await check(where);
    }

    await t.pumpWidget(MaterialApp(
      home: Scaffold(body: GearFlow(locate: () async => (pos: gangnamStation, real: false), mapTiles: false)),
    ));
    await check('기구 1');
    await tapGo('사진으로 계속하기', '기구 2');
    await tapGo('분석 결과 보기', '기구 3');
    await tapGo('이 브랜드로 헬스장 찾기', '기구 4');
    await tapGo('지도에서 보기', '기구 5');
    await tapGo('이 헬스장 선택', '기구 6');

    await t.pumpWidget(const MaterialApp(home: Scaffold(body: CalorieScreen())));
    await check('칼로리 1');
    await tapGo('사진으로 계산하기', '칼로리 2');
    await tapGo('칼로리 결과 보기', '칼로리 3');
    await tapGo('오늘 식단에 기록', '칼로리 4');
  }

  Future<void> Function(String) guidelines(WidgetTester t, List<String> problems) => (where) async {
        for (final g in [labeledTapTargetGuideline, wcagMinTarget]) {
          final r = await g.evaluate(t);
          if (!r.passed) problems.add('[$where] ${r.reason}');
        }
      };

  testWidgets('모든 화면: 버튼 이름 · 최소 터치 영역', (t) async {
    phone(t);
    final handle = t.ensureSemantics();
    final problems = <String>[];
    await everyScreen(t, guidelines(t, problems));
    await stepFlows(t, guidelines(t, problems));
    handle.dispose();
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  for (final scale in [1.5, 2.0]) {
    testWidgets('글자 ${(scale * 100).round()}% 설정에서도 넘치지 않음 (앱 상한 ${(maxTextScale * 100).round()}%)', (t) async {
      phone(t, textScale: scale);
      final problems = <String>[];
      Future<void> noOverflow(String where) async {
        final e = t.takeException();
        if (e != null) problems.add('[$where] $e');
      }

      await everyScreen(t, noOverflow);
      await stepFlows(t, noOverflow);
      expect(problems, isEmpty, reason: problems.join('\n'));
    });
  }

  test('팔레트 글자색 대비 WCAG AA (4.5:1) 이상', () {
    double lum(Color c) {
      double ch(double v) => v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
      return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
    }

    double ratio(Color a, Color b) {
      final x = lum(a), y = lum(b);
      return (math.max(x, y) + 0.05) / (math.min(x, y) + 0.05);
    }

    const text = {'ivory': C.ivory, 'goldBright': C.goldBright, 'gold': C.gold, 'textDim': C.textDim, 'textFaint': C.textFaint, 'good': C.good, 'cLow': C.cLow, 'cMid': C.cMid, 'cHigh': C.cHigh, 'live': C.live};
    const bg = {'charcoal': C.charcoal, 'panel': C.panel, 'panel2': C.panel2, 'onyx': C.onyx};
    final fails = [
      for (final f in text.entries)
        for (final b in bg.entries)
          if (ratio(f.value, b.value) < 4.5) '${f.key} on ${b.key}: ${ratio(f.value, b.value).toStringAsFixed(2)}',
    ];
    expect(fails, isEmpty, reason: fails.join('\n'));
    expect(ratio(C.ink, C.gold), greaterThanOrEqualTo(4.5), reason: '금색 버튼 위 글자');
  });
}
