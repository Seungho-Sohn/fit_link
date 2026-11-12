import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fit_link/data/mock_data.dart';
import 'package:fit_link/state/app_state.dart';
import 'package:fit_link/state/persistence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // toast()가 GlobalKey에 접근

  /// 2026-11-12(목) 10:00 기준 시계
  var clock = DateTime(2026, 11, 12, 10);
  AppState newState(StateStore store) => AppState.fresh()
    ..now = (() => clock)
    ..attachStore(store);

  setUp(() => clock = DateTime(2026, 11, 12, 10));

  test('저장한 상태를 다음 실행에서 그대로 복원한다', () {
    final store = MemoryStore();
    final a = newState(store);
    a.finishOnboard(1);
    a.attend();
    a.earnPoints(300, '리뷰 작성');
    a.redeemDeal(a.ptDeals.first);
    a.addToCart('p1', 2);
    a.dAdd('d2');
    a.toggleFav('s1');
    for (final m in a.missions) {
      m.progress = m.goal;
    }
    a.claimStamp();

    final b = newState(MemoryStore(store.data));
    expect(b.toJson(), a.toJson());
    expect(b.onboarded, isTrue);
    expect(b.goal, '체지방 감량');
    expect(b.attended, isTrue);
    expect(b.stampClaimed, isTrue);
    expect(b.cart, {'p1': 2});
    expect(b.ptHistory.first.time, isNotNull);
  });

  test('저장 대상이 바뀔 때만 쓴다 (화면 이동은 저장하지 않음)', () {
    final store = MemoryStore();
    final s = newState(store);
    s.go(AppPage.market);
    s.goMarket(MarketView.cart);
    s.go(AppPage.my);
    expect(store.writes, 0);

    s.addToCart('p1', 1);
    expect(store.writes, 1);
  });

  test('저장본이 깨져 있거나 형식이 다르면 초기 상태로 시작한다', () {
    final defaults = AppState.fresh().toJson();
    for (final bad in ['{not json', '[]', jsonEncode({'schema': 999}), jsonEncode({'schema': 1, 'points': 'x'})]) {
      final s = newState(MemoryStore(bad));
      expect(s.toJson(), defaults, reason: bad);
    }
  });

  test('일부 필드만 잘못돼도 반쯤 복원된 상태가 되지 않는다', () {
    final good = AppState.fresh()..points = 77;
    final j = good.toJson()..['dfavs'] = 'oops'; // 마지막에 읽는 필드만 깨뜨림
    final s = newState(MemoryStore(jsonEncode(j)));
    expect(s.points, AppState.fresh().points);
  });

  test('목업 데이터에서 사라진 상품·메뉴는 장바구니에서 빠진다', () {
    final j = AppState.fresh().toJson()
      ..['cart'] = {'p1': 1, 'gone': 3}
      ..['dcart'] = {'gone': 1, 'd1': 2};
    final s = newState(MemoryStore(jsonEncode(j)));
    expect(s.cart, {'p1': 1});
    expect(s.dcart, {'d1': 2});
  });

  test('출석은 다음 날, 주간 보너스는 다음 주 월요일에 다시 열린다', () {
    final store = MemoryStore();
    final s = newState(store);
    s.attend();
    for (final m in s.missions) {
      m.progress = m.goal;
    }
    s.claimStamp();
    expect((s.attended, s.stampClaimed), (true, true));

    clock = DateTime(2026, 11, 13, 9); // 금
    expect((s.attended, s.stampClaimed), (false, true));

    clock = DateTime(2026, 11, 15, 23, 59); // 일 — 아직 같은 주
    expect(s.stampClaimed, isTrue);

    clock = DateTime(2026, 11, 16, 0, 1); // 월
    expect(s.stampClaimed, isFalse);

    final p = s.points;
    s.attend();
    s.claimStamp();
    expect(s.points, p + 10 + 500);
  });

  test('PrefsStore: SharedPreferences에 쓰고 다시 열어 읽는다', () async {
    SharedPreferences.setMockInitialValues({});
    final s = newState(await PrefsStore.open());
    s.addToCart('p6', 3);
    await Future<void>.delayed(Duration.zero); // 비동기 쓰기 완료 대기

    final reopened = newState(await PrefsStore.open());
    expect(reopened.cart, {'p6': 3});
  });

  group('PointLog', () {
    test('JSON 왕복 (목업 내역 · 실제 시각 내역)', () {
      for (final log in [const PointLog('출석 체크', 10, '8월 8일'), PointLog.timed('교환', -3900, DateTime(2026, 11, 12, 9, 30))]) {
        final back = PointLog.fromJson(jsonDecode(jsonEncode(log.toJson())) as Map<String, dynamic>);
        expect((back.reason, back.amount, back.when, back.time), (log.reason, log.amount, log.when, log.time));
      }
    });

    test('표시 시각: 방금 / 오늘 / M월 D일', () {
      final log = PointLog.timed('a', 1, DateTime(2026, 11, 12, 10));
      expect(log.label(DateTime(2026, 11, 12, 10, 0, 30)), '방금');
      expect(log.label(DateTime(2026, 11, 12, 18)), '오늘');
      expect(log.label(DateTime(2026, 11, 14)), '11월 12일');
      expect(const PointLog('a', 1, '8월 8일').label(DateTime(2026, 11, 14)), '8월 8일');
    });
  });
}
