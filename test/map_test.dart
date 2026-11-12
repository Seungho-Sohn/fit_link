import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:fit_link/data/mock_data.dart';
import 'package:fit_link/screens/gear_flow.dart';
import 'package:fit_link/services/location.dart';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('거리 표시', () {
    test('1km 미만은 m, 이상은 km, 도보 1시간 넘으면 도보 시간 생략', () {
      expect(distanceLabel(gangnamStation, gangnamStation), '0m · 도보 0분');

      final m = metersBetween(gangnamStation, gymByName('스틸핏 강남점').pos);
      expect(m, inInclusiveRange(200, 600)); // 목업 좌표가 강남역 근처인지
      expect(distanceLabel(gangnamStation, gymByName('스틸핏 강남점').pos), matches(RegExp(r'^\d+0m · 도보 \d+분$')));

      expect(distanceLabel(gangnamStation, gymByName('아이언짐 삼성').pos), matches(RegExp(r'^3\.\dkm · 도보 \d+분$')));
      expect(distanceLabel(gangnamStation, const LatLng(35.1796, 129.0756)), matches(RegExp(r'^3\d\d\.\dkm$'))); // 부산
    });
  });

  testWidgets('기구 매칭 → 필터 → 지도에서 핀 선택 → 확정', (t) async {
    t.view.physicalSize = const Size(430 * 3, 932 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    var located = 0;
    Future<MyLocation> locate() async {
      located++;
      return (pos: gangnamStation, real: true);
    }

    await t.pumpWidget(MaterialApp(home: Scaffold(body: GearFlow(locate: locate, mapTiles: false))));
    Future<void> tapText(String s) async {
      await t.tap(find.text(s.toUpperCase()));
      await t.pump();
      await t.pump(const Duration(seconds: 4)); // 분석 로그 등 애니메이션
    }

    await tapText('사진으로 계속하기');
    await tapText('분석 결과 보기');
    await tapText('이 브랜드로 헬스장 찾기');

    // 4단계: 실제 거리 + 필터
    expect(located, 1);
    expect(find.textContaining('내 위치 기준 거리'), findsOneWidget);
    final steelDist = distanceLabel(gangnamStation, gymByName('스틸핏 강남점').pos);
    expect(find.text('$steelDist · 4.8'), findsOneWidget);
    expect(find.text('바디스퀘어 논현'), findsOneWidget);

    await t.tap(find.text('24시간').first);
    await t.pump();
    expect(find.text('코어짐24 역삼'), findsOneWidget);
    expect(find.text('스틸핏 강남점'), findsNothing);

    await t.tap(find.text('브랜드 일치만'));
    await t.pump();
    expect(find.text('바디스퀘어 논현'), findsNothing);

    // 5단계: 지도 핀으로 선택 변경
    await tapText('지도에서 보기');
    expect(find.text('내 위치'), findsOneWidget);
    await t.tap(find.text('바디스퀘어 · 42'));
    await t.pump();
    expect(find.text('바디스퀘어 논현'), findsOneWidget); // 하단 카드

    // 6단계: 선택한 헬스장으로 확정
    await tapText('이 헬스장 선택');
    expect(find.text('바디스퀘어 논현'), findsOneWidget);
    expect(find.textContaining('대체 기구를 보유 중'), findsOneWidget);
    expect(find.text('06:00–23:00'), findsOneWidget);
    expect(located, 1); // 위치는 한 번만 조회
  });
}
