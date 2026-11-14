import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import 'package:fit_link/data/mock_data.dart';
import 'package:fit_link/screens/gear_flow.dart';
import 'package:fit_link/services/location.dart';
import 'package:fit_link/services/photo_picker.dart';
import 'package:fit_link/state/app_state.dart';

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

  Future<PickedPhoto?> picked(BuildContext _) async => (bytes: _png, mediaType: 'image/png');

  Future<void> openFlow(WidgetTester t, Future<MyLocation> Function() locate) async {
    t.view.physicalSize = const Size(430 * 3, 932 * 3);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(MaterialApp(home: Scaffold(body: GearFlow(pick: picked, locate: locate, mapTiles: false))));
  }

  Future<void> tapText(WidgetTester t, String s, {Duration wait = const Duration(milliseconds: 400)}) async {
    await t.tap(find.text(s.toUpperCase()));
    await t.pump();
    await t.pump(wait);
  }

  Finder rich(String text) => find.textContaining(text, findRichText: true);

  testWidgets('사진 → 분석(끝나야 진행) → 후보 확인 → 매칭·필터 → 지도 핀 → 확정', (t) async {
    var located = 0;
    await openFlow(t, () async {
      located++;
      return (pos: gangnamStation, real: true);
    });

    // 1 → 2: 고른 사진으로 분석. 분석이 끝나기 전에는 결과 버튼이 꺼져 있다
    await tapText(t, '사진으로 계속하기');
    expect(find.text('분석 중…'), findsOneWidget);
    await t.tap(find.text('분석 중…'));
    await t.pump();
    expect(find.text('이 기구가 맞나요?'), findsNothing);
    await t.pump(const Duration(seconds: 4));

    // 3: 데모 후보 확인 — 첫 후보가 기본 선택, 다른 후보를 고르면 요약이 바뀐다
    await tapText(t, '분석 결과 보기');
    expect(find.text('이 기구가 맞나요?'), findsOneWidget);
    expect(find.text('데모 후보'), findsOneWidget);
    expect(rich('동일 모델 2곳.'), findsOneWidget); // Hammer Strength 프론트 풀다운
    await t.tap(find.text('뉴텍 · PLATE'));
    await t.pump();
    expect(rich('동일 모델 1곳.'), findsOneWidget);
    await t.tap(find.text('HAMMER STRENGTH · PLATE-LOADED'));
    await t.pump();

    // 4: 매칭 — 실제 거리, 일치 정도, 필터
    await tapText(t, '이 기구가 있는 헬스장 찾기');
    expect(located, 1);
    expect(find.text('같은 기구가 있는 헬스장 2곳'), findsOneWidget);
    final steelDist = distanceLabel(gangnamStation, gymByName('스틸핏 강남점').pos);
    expect(find.text('$steelDist · 4.8'), findsOneWidget);
    expect(find.text('같은 브랜드 · Hammer Strength 랫 풀다운'), findsOneWidget); // 코어짐24
    expect(find.text('바디스퀘어 논현'), findsOneWidget);

    await t.tap(find.text('동일 모델만'));
    await t.pump();
    expect(find.text('스틸핏 강남점'), findsOneWidget);
    expect(find.text('머슬팩토리 선릉'), findsOneWidget);
    expect(find.text('코어짐24 역삼'), findsNothing);

    await t.tap(find.text('24시간').first);
    await t.pump();
    expect(find.text('코어짐24 역삼'), findsOneWidget);
    expect(find.text('스틸핏 강남점'), findsNothing);

    // 5: 지도 핀으로 선택 변경
    await tapText(t, '지도에서 보기');
    expect(find.text('내 위치'), findsOneWidget);
    await t.tap(find.text('바디스퀘어 · 60'));
    await t.pump();
    expect(find.text('바디스퀘어 논현'), findsOneWidget); // 하단 카드

    // 6: 확정 — 대체 기구 문구와 을/를
    await tapText(t, '이 헬스장 선택');
    expect(rich('같은 종류의 Life Fitness 랫 풀다운을 보유 중이며'), findsOneWidget);
    expect(find.text('06:00–23:00'), findsOneWidget);
    expect(located, 1); // 위치는 한 번만 조회
  });

  testWidgets('사진 없이 직접 찾기 → 종류·모델 선택 → 매칭', (t) async {
    await openFlow(t, () async => (pos: gangnamStation, real: false));
    await tapText(t, '사진 없이 직접 찾기');
    expect(find.text('어떤 기구를 찾으세요?'), findsOneWidget);
    expect(find.text('기구를 골라 주세요'.toUpperCase()), findsOneWidget); // 고르기 전에는 진행 불가

    await t.tap(find.text('레그 프레스').first); // 종류 칩
    await t.pump();
    await t.tap(find.text('MATRIX · AURA'));
    await t.pump();
    await tapText(t, '이 기구가 있는 헬스장 찾기');
    expect(find.text('같은 기구가 있는 헬스장 1곳'), findsOneWidget); // 바디스퀘어 논현만 Matrix 보유
    expect(find.textContaining('강남역 기준'), findsOneWidget);
  });

  testWidgets('확정 화면에서 "없어요"라고 하면 그 헬스장이 매칭에서 빠진다', (t) async {
    addTearDown(AppState.I.gearReports.clear);
    await openFlow(t, () async => (pos: gangnamStation, real: false));
    await tapText(t, '사진 없이 직접 찾기');
    await t.tap(find.text('레그 프레스').first);
    await t.pump();
    await t.tap(find.text('MATRIX · AURA'));
    await t.pump();
    await tapText(t, '이 기구가 있는 헬스장 찾기');
    await tapText(t, '바디스퀘어 논현'); // 목록에서 선택 → 지도
    await tapText(t, '이 헬스장 선택');
    expect(find.text('이 기구가 실제로 있나요?'), findsOneWidget);
    expect(find.text('등록 정보'), findsOneWidget); // 정보 출처

    await t.tap(find.textContaining('없어요'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(AppState.I.gearReport('바디스퀘어 논현', 'matrix-leg-press'), isFalse);
    expect(find.textContaining('비슷한 기구가 있는 헬스장'), findsOneWidget); // 동일 모델 0곳 → 대체 기구 목록
    expect(find.text('바디스퀘어 논현'), findsNothing);
  });
}

/// 화면에 실제로 그릴 수 있는 1×1 PNG
final _png = base64Decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');
