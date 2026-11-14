import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:fit_link/main.dart';
import 'package:fit_link/state/app_state.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  for (final width in [390.0, 1568.0]) {
    testWidgets('토스트가 폰 폭(430) 화면 안에 보인다 · 창 너비 $width', (t) async {
      t.view.physicalSize = Size(width, 773);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(const FitLinkApp()); // 실제 앱 구조 (폰 폭 Scaffold 등)
      AppState.I
        ..finishOnboard(0)
        ..goMarket(MarketView.gymGear);
      await t.pump(const Duration(milliseconds: 500));

      AppState.I.toast('저장했어요');
      await t.pump();
      await t.pump(const Duration(milliseconds: 300));

      final text = find.text('저장했어요');
      expect(text, findsOneWidget);
      final bar = t.getRect(find.descendant(of: find.byType(SnackBar), matching: find.byType(Material)).first);
      expect(bar.width, lessThanOrEqualTo(430));
      expect(bar.center.dx, closeTo(width / 2, 1));
      expect(t.takeException(), isNull);
    });
  }
}
