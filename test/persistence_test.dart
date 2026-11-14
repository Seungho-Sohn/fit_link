import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fit_link/data/equipment.dart';
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

    clock = DateTime(2026, 11, 16, 0, 1); // 월 — 보너스와 미션 진행도 모두 새로 시작
    expect(s.stampClaimed, isFalse);
    expect(s.missionsDone, 0);

    final p = s.points;
    s.attend();
    s.claimStamp(); // 미션을 다 채우기 전에는 받을 수 없음
    expect(s.points, p + 10);
    for (final m in s.missions) {
      m.progress = m.goal;
    }
    s.claimStamp();
    expect(s.points, p + 10 + 500);
  });

  group('커뮤니티 · 미션 저장', () {
    test('내가 쓴 글 · 댓글 · 좋아요가 다음 실행에도 남는다', () {
      final store = MemoryStore();
      final a = newState(store);
      final mine = a.addPost('운동 인증', '오늘 하체 끝');
      a.addComment(mine, '나도 수고했다');
      final seed = seedPosts[0];
      a.addComment(seed, '멋져요');
      a.toggleLike(seed);
      a.toggleLike(seedPosts[1]); // 원래 좋아요 상태였던 글 → 취소

      final b = newState(MemoryStore(store.data));
      expect(b.feed.first.txt, '오늘 하체 끝');
      expect(b.feed.length, seedPosts.length + 1);
      expect(b.commentsOf(b.feed.first).single.text, '나도 수고했다');
      expect(b.commentsOf(seed).last.text, '멋져요');
      expect((b.isLiked(seed), b.likeCount(seed)), (true, seed.likes + 1));
      expect((b.isLiked(seedPosts[1]), b.likeCount(seedPosts[1])), (false, seedPosts[1].likes - 1));
      expect(b.commentCount(seed), seed.comments + 1);
      expect(b.toJson(), a.toJson());
    });

    test('좋아요를 두 번 누르면 원래대로 (저장할 기록도 없음)', () {
      final s = newState(MemoryStore());
      s.toggleLike(seedPosts[0]);
      s.toggleLike(seedPosts[0]);
      expect(s.likeOverrides, isEmpty);
      expect(s.likeCount(seedPosts[0]), seedPosts[0].likes);
    });

    test('같은 주에는 미션 진행도가 남고, 다음 주 월요일에 0이 된다', () {
      final store = MemoryStore();
      final a = newState(store);
      a.attend();
      a.addPost('운동 인증', 'x');
      expect(a.missionsDone, 0);

      clock = DateTime(2026, 11, 14, 8); // 토 — 다시 켬
      final b = newState(MemoryStore(store.data));
      int prog(AppState s, MissionKind k) => s.missions.firstWhere((m) => m.kind == k).progress;
      expect((prog(b, MissionKind.attend), prog(b, MissionKind.workoutPost)), (1, 1));

      clock = DateTime(2026, 11, 16, 8); // 월
      final c = newState(MemoryStore(store.data));
      expect(c.missions.every((m) => m.progress == 0), isTrue);
    });

    test('예전 형식 저장본(새 항목 없음)도 포인트·장바구니를 그대로 읽는다', () {
      final old = AppState.fresh()
        ..points = 777
        ..addToCart('p1', 2);
      final j = old.toJson()
        ..remove('missionWeek')
        ..remove('posts')
        ..remove('comments')
        ..remove('likes')
        ..remove('operatorGear')
        ..remove('gearReports')
        ..['missions'] = {'출석 3일': 3, '3대 기록 갱신': 0}; // 예전 키는 한글 이름
      final s = newState(MemoryStore(jsonEncode(j)));
      expect(s.points, 777);
      expect(s.cart, {'p1': 2});
      expect(s.feed.length, seedPosts.length);
      expect(s.missionsDone, 0); // 예전 진행도는 새 주로 보고 0부터
    });
  });

  group('헬스장 보유 기구 (운영자 등록 · 이용자 제보)', () {
    const gym = AppState.myGym; // 기본 데이터: hs-pl-pulldown 등 5종
    test('운영자 등록이 기본 데이터를 대체하고 매칭에 반영된다', () {
      final s = newState(MemoryStore());
      expect(s.gearSource(gym, 'hs-pl-pulldown'), GearSource.listed);
      final before = matchGyms(gearById('matrix-leg-press'), gear: s.gymGearNow);
      expect(before.firstWhere((m) => m.gym.name == gym).level, MatchLevel.alternative);

      s.registerGymGear(gym, ['matrix-leg-press', 'hs-pl-pulldown']);
      expect(s.listedGear(gym), ['hs-pl-pulldown', 'matrix-leg-press']); // 카탈로그 순서
      expect(s.gearSource(gym, 'matrix-leg-press'), GearSource.operator);
      final after = matchGyms(gearById('matrix-leg-press'), gear: s.gymGearNow);
      expect(after.first.gym.name, gym);
      expect(after.first.level, MatchLevel.exact);
      // 등록에서 뺀 기구는 더 이상 매칭되지 않음
      expect(matchGyms(gearById('lf-ins-row'), gear: s.gymGearNow).where((m) => m.gym.name == gym && m.level == MatchLevel.exact), isEmpty);
    });

    test('"없어요" 제보는 매칭에서 빼고, 처음 확인할 때만 포인트를 준다', () {
      final s = newState(MemoryStore());
      final p = s.points;
      s.reportGear(gym, 'hs-pl-pulldown', present: true);
      expect(s.points, p + AppState.gearReportReward);
      expect(s.gearSource(gym, 'hs-pl-pulldown'), GearSource.member);

      s.reportGear(gym, 'hs-pl-pulldown', present: false); // 고쳐도 포인트는 한 번만
      expect(s.points, p + AppState.gearReportReward);
      expect(s.gymGearNow[gym], isNot(contains('hs-pl-pulldown')));
      expect(s.gearReportCount(gym), (present: 0, missing: 1));

      s.registerGymGear(gym, ['hs-pl-pulldown']); // 운영자가 확인하면 제보는 처리 완료
      expect(s.gearReportCount(gym), (present: 0, missing: 0));
      expect(s.gymGearNow[gym], ['hs-pl-pulldown']);
    });

    test('등록·제보가 다음 실행에도 남고, 사라진 헬스장·기구 기록은 버린다', () {
      final store = MemoryStore();
      final a = newState(store);
      a.registerGymGear(gym, ['cybex-pulldown']);
      a.reportGear('코어짐24 역삼', 'hs-sel-pulldown', present: false);
      final b = newState(MemoryStore(store.data));
      expect(b.toJson(), a.toJson());
      expect(b.listedGear(gym), ['cybex-pulldown']);

      final j = a.toJson()
        ..['operatorGear'] = {gym: ['cybex-pulldown', 'gone'], '없는 헬스장': ['cybex-pulldown']}
        ..['gearReports'] = {'$gym|gone': true, '없는 헬스장|cybex-pulldown': false, 'broken': true, '$gym|cybex-pulldown': true};
      final c = newState(MemoryStore(jsonEncode(j)));
      expect(c.operatorGear, {gym: ['cybex-pulldown']});
      expect(c.gearReports, {'$gym|cybex-pulldown': true});
    });
  });

  test('글·댓글 시각 표시', () {
    final at = DateTime(2026, 11, 13, 10);
    expect(agoLabel(at, DateTime(2026, 11, 13, 10, 0, 30)), '방금');
    expect(agoLabel(at, DateTime(2026, 11, 13, 10, 12)), '12분 전');
    expect(agoLabel(at, DateTime(2026, 11, 13, 13, 5)), '3시간 전');
    expect(agoLabel(at, DateTime(2026, 11, 14, 9)), '11월 13일');
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
