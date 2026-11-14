import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/data/equipment.dart';
import 'package:fit_link/services/gear_cloud.dart';
import 'package:fit_link/state/app_state.dart';
import 'package:fit_link/state/persistence.dart';

/// 메모리 서버: 여러 기기(uid)가 같은 데이터를 공유한다
class MemoryServer {
  final ops = <String, OperatorEntry>{};
  final reports = <String, CloudReport>{};
  final _changes = StreamController<void>.broadcast();
  DateTime clock = DateTime(2026, 11, 14, 10);

  SharedGear get snapshot => (operators: Map.of(ops), reports: reports.values.toList());
  void changed() => _changes.add(null);
}

class MemoryCloud implements GearCloud {
  final MemoryServer server;
  @override
  final String uid;
  MemoryCloud(this.server, this.uid);

  @override
  Stream<SharedGear> watch() async* {
    yield server.snapshot;
    await for (final _ in server._changes.stream) {
      yield server.snapshot;
    }
  }

  @override
  Future<void> registerGym(String gym, List<String> gear) async {
    final cur = server.ops[gym];
    if (cur != null && cur.owner != uid) throw const GymOwnedByOther();
    server.ops[gym] = (gear: gear, owner: uid, at: server.clock);
    server.changed();
  }

  @override
  Future<void> report(String gym, String gear, {required bool present}) async {
    server.reports['$uid|$gym|$gear'] = (uid: uid, gym: gym, gear: gear, present: present, at: server.clock);
    server.changed();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // toast()가 GlobalKey에 접근
  const gym = '바디스퀘어 논현', gear = 'matrix-leg-press'; // 기본 데이터에서 보유

  late MemoryServer server;
  setUp(() => server = MemoryServer());

  Future<AppState> device(String uid, {StateStore? store}) async {
    final s = AppState.fresh();
    if (store != null) s.attachStore(store);
    s.attachCloud(MemoryCloud(server, uid));
    await pumpEventQueue();
    return s;
  }

  Future<void> otherSays(String uid, bool present) async {
    await MemoryCloud(server, uid).report(gym, gear, present: present);
    await pumpEventQueue();
  }

  group('여러 사용자의 제보', () {
    test('다른 회원 한 명의 "없어요"로는 빠지지 않고, 두 명 이상·"있어요"보다 많으면 모두의 매칭에서 빠진다', () async {
      final me = await device('me');
      await otherSays('a', false);
      expect(me.gymGearNow[gym], contains(gear));
      await otherSays('b', false);
      expect(me.gymGearNow[gym], isNot(contains(gear)));
      expect(me.reportCount(gym, gear), (present: 0, missing: 2));

      await otherSays('c', true);
      await otherSays('d', true); // 있어요 2 = 없어요 2 → 다시 포함
      expect(me.gymGearNow[gym], contains(gear));
      expect(me.gearSource(gym, gear), GearSource.member);
    });

    test('내 "없어요"는 나에게 바로 반영되고, 서버에도 올라가 다른 기기에서 보인다', () async {
      final me = await device('me');
      me.reportGear(gym, gear, present: false);
      await pumpEventQueue();
      expect(me.gymGearNow[gym], isNot(contains(gear)));
      expect(server.reports.containsKey('me|$gym|$gear'), isTrue);

      final other = await device('other');
      expect(other.reportCount(gym, gear), (present: 0, missing: 1));
      expect(other.gymGearNow[gym], contains(gear)); // 한 명은 정족수 미달
      expect(me.reportCount(gym, gear), (present: 0, missing: 1)); // 내 제보는 두 번 세지 않음
    });
  });

  group('운영자 등록 공유', () {
    test('한 기기의 운영자 등록이 다른 기기의 매칭에 반영되고, 등록 전 제보는 처리된 것으로 본다', () async {
      await otherSays('a', false);
      await otherSays('b', false);
      final member = await device('member');
      expect(member.gymGearNow[gym], isNot(contains(gear)));

      server.clock = server.clock.add(const Duration(hours: 1));
      final owner = await device('owner');
      owner.registerGymGear(gym, [gear, 'lf-ins-row']);
      await pumpEventQueue();

      expect(member.operatorListed(gym), isTrue);
      expect(member.listedGear(gym), ['lf-ins-row', gear]); // 카탈로그 순서
      expect(member.gymGearNow[gym], contains(gear)); // 등록 전 "없어요"는 무시
      expect(member.gearSource(gym, gear), GearSource.operator);
      expect(member.gearReportCount(gym), (present: 0, missing: 0));
    });

    test('다른 운영자가 먼저 등록한 헬스장은 내 등록이 되돌려진다', () async {
      await MemoryCloud(server, 'first').registerGym(gym, ['lf-ins-row']);
      final me = await device('me');
      me.registerGymGear(gym, [gear]);
      expect(me.operatorGear[gym], [gear]); // 일단 바로 반영
      await pumpEventQueue();
      expect(me.operatorGear.containsKey(gym), isFalse);
      expect(me.listedGear(gym), ['lf-ins-row']); // 서버의 등록을 따른다
      expect(server.ops[gym]!.owner, 'first');
    });
  });

  test('서버 연결 전에 쌓인 내 기록은 처음 연결할 때 한 번만 올린다', () async {
    final store = MemoryStore();
    final offline = AppState.fresh()..attachStore(store);
    offline.reportGear(gym, gear, present: true);
    offline.registerGymGear(AppState.myGym, ['hs-pl-pulldown']);

    final next = MemoryStore(store.data); // 다음 실행 (서버 설정이 들어간 새 버전)
    await device('me', store: next);
    expect(server.reports.keys, ['me|$gym|$gear']);
    expect(server.ops[AppState.myGym]!.gear, ['hs-pl-pulldown']);

    server.reports.clear();
    final again = await device('me', store: MemoryStore(next.data)); // 그다음 실행: 이미 올렸다는 표시가 저장돼 있음
    expect(again.cloudConnected, isTrue);
    expect(server.reports, isEmpty);
  });

  group('Firestore 저장소', () {
    late FakeFirebaseFirestore db;
    setUp(() => db = FakeFirebaseFirestore());

    test('익명 로그인 후 등록·제보를 쓰고, 공유 데이터로 다시 읽는다', () async {
      final cloud = await FirestoreGearCloud.connect(auth: MockFirebaseAuth(mockUser: MockUser(isAnonymous: true, uid: 'u1')), db: db);
      expect(cloud.uid, 'u1');
      await cloud.registerGym('A/B 짐', ['hs-pl-pulldown']);
      await cloud.report(gym, gear, present: false);

      expect((await db.collection('gym_gear').doc('A∕B 짐').get()).data()!['owner'], 'u1');
      expect((await db.collection('gear_reports').doc('u1__${gym}__$gear').get()).exists, isTrue);

      final s = await cloud.watch().first;
      expect(s.operators['A/B 짐']!.gear, ['hs-pl-pulldown']);
      expect(s.operators['A/B 짐']!.at, isNotNull);
      expect(s.reports.single, (uid: 'u1', gym: gym, gear: gear, present: false, at: s.reports.single.at));
    });

    test('다른 사람이 등록한 헬스장을 고치려 하면 GymOwnedByOther', () async {
      await FirestoreGearCloud(db, 'first').registerGym(gym, ['lf-ins-row']);
      await FirestoreGearCloud(db, 'first').registerGym(gym, ['lf-ins-row', gear]); // 본인은 수정 가능
      expect(FirestoreGearCloud(db, 'second').registerGym(gym, [gear]), throwsA(isA<GymOwnedByOther>()));
    });
  });
}
