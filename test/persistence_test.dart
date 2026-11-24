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
    a.addPost('운동 인증', '오늘 등 운동');
    a.registerGymGear(AppState.myGym, ['cybex-pulldown']);
    a.reportGear('코어짐24 역삼', 'hs-sel-pulldown', present: false);

    final b = newState(MemoryStore(store.data));
    expect(b.toJson(), a.toJson());
    expect(b.onboarded, isTrue);
    expect(b.goal, '체지방 감량');
    expect(b.feed.first.txt, '오늘 등 운동');
  });

  test('저장 대상이 바뀔 때만 쓴다 (화면 이동은 저장하지 않음)', () {
    final store = MemoryStore();
    final s = newState(store);
    s.go(AppPage.gear);
    s.goB2B(B2BPage.quote);
    s.go(AppPage.my);
    expect(store.writes, 0);

    s.addPost('질문', '분할 추천해 주세요');
    expect(store.writes, 1);
  });

  test('저장본이 깨져 있거나 형식이 다르면 초기 상태로 시작한다', () {
    final defaults = (AppState.fresh()..now = (() => clock)).toJson();
    for (final bad in ['{not json', '[]', jsonEncode({'schema': 999}), jsonEncode({'schema': 1, 'onboarded': 'x'})]) {
      final s = newState(MemoryStore(bad));
      expect(s.toJson(), defaults, reason: bad);
    }
  });

  test('일부 필드만 잘못돼도 반쯤 복원된 상태가 되지 않는다', () {
    final good = AppState.fresh()..finishOnboard(2);
    final j = good.toJson()..['gearReports'] = 'oops'; // 마지막에 읽는 필드만 깨뜨림
    final s = newState(MemoryStore(jsonEncode(j)));
    expect(s.onboarded, isFalse);
  });

  group('커뮤니티 저장', () {
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

    test('예전 저장본(포인트·미션·장바구니·찜 포함, 새 항목 없음)도 읽고, 빠진 기능의 값은 버린다', () {
      final j = {
        'schema': 1,
        'onboarded': true,
        'goal': '체형 유지',
        'points': 777,
        'earned': 4200,
        'ptHistory': [],
        'missions': {'출석 3일': 3},
        'dealsLeft': {},
        'cart': {'p1': 2},
        'myOrders': '1건',
        'dcart': {},
        'dfavs': ['s2'],
      };
      final s = newState(MemoryStore(jsonEncode(j)));
      expect((s.onboarded, s.goal), (true, '체형 유지'));
      expect(s.feed.length, seedPosts.length);
      expect(s.toJson().keys, isNot(contains('points')));
      expect(s.toJson().keys, isNot(contains('cart')));
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

    test('"없어요" 제보는 매칭에서 빼고, 다시 고칠 수 있다', () {
      final s = newState(MemoryStore());
      s.reportGear(gym, 'hs-pl-pulldown', present: true);
      expect(s.gearSource(gym, 'hs-pl-pulldown'), GearSource.member);

      s.reportGear(gym, 'hs-pl-pulldown', present: false);
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

  test('내 이용권(체인)이 다음 실행에도 남고, 데이터에서 사라진 체인은 버린다', () {
    final store = MemoryStore();
    final a = newState(store);
    a.toggleChain('스틸핏');
    expect(a.gymsForMe.map((g) => g.name), ['스틸핏 강남점', '스틸핏 역삼점']);
    a.toggleChain('코어짐24');
    a.toggleChain('스틸핏'); // 다시 누르면 해제
    final b = newState(MemoryStore(store.data));
    expect(b.myChains, {'코어짐24'});
    expect(b.gymsForMe.every((g) => g.chain == '코어짐24'), isTrue);
    b.clearChains();
    expect(b.gymsForMe.length, gyms.length);

    final j = a.toJson()..['myChains'] = ['스틸핏', '없어진 체인'];
    expect(newState(MemoryStore(jsonEncode(j))).myChains, {'스틸핏'});
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
    s.addPost('꿀팁', '물 많이 드세요');
    await Future<void>.delayed(Duration.zero); // 비동기 쓰기 완료 대기

    final reopened = newState(await PrefsStore.open());
    expect(reopened.feed.first.txt, '물 많이 드세요');
  });
}
