// 온보딩 소개 화면(대표이미지) → 3단계 질문으로 넘어가는지 확인한다.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fit_link/screens/onboarding.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> pumpOverlay(WidgetTester tester, {double textScale = 1}) async {
    tester.view.physicalSize = const Size(390 * 3, 700 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(size: const Size(390, 700), textScaler: TextScaler.linear(textScale)),
        child: const Scaffold(body: OnboardingOverlay()),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('처음에는 대표이미지 소개 화면, 시작하기를 누르면 1단계 질문', (tester) async {
    await pumpOverlay(tester);
    final hero = find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == heroImage);
    expect(hero, findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('짐비아 GYMVIA')), findsOneWidget); // 화면 낭독기용 이름
    expect(find.text('다음'), findsNothing);

    await tester.tap(find.text('시작하기'));
    await tester.pump(const Duration(milliseconds: 300));
    expect(hero, findsNothing);
    expect(find.text('다음'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('소개 화면은 글자 150%에서도 넘치지 않는다', (tester) async {
    await pumpOverlay(tester, textScale: 1.5);
    expect(find.text('시작하기'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
