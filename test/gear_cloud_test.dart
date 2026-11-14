import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/data/equipment.dart';
import 'package:fit_link/services/gear_cloud.dart';
import 'package:fit_link/state/app_state.dart';
import 'package:fit_link/state/persistence.dart';

/// 메모리 서버: 여러 기기(uid)가 같은 제보를 공유한다
class MemoryServer {
  final reports = <String, CloudReport>{};
  final _changes = StreamController<void>.broadcast();
  bool rejectWrites = false; // 보안 규칙이 막는 상황

  void changed() => _changes.add(null);
}

class MemoryCloud implements GearCloud {
  final MemoryServer server;
  @override
  final String uid;
  MemoryCloud(this.server, this.uid);

  @override
  Stream<List<CloudReport>> watch() async* {
    yield server.reports.values.toList();
    await for (final _ in server._changes.stream) {
      yield server.reports.values.toList();
    }
  }

  @override
  Future<void> report(String gym, String gear, {required bool present}) async {
    if (server.rejectWrites) throw StateError('permission-denied');
    server.reports['$uid|$gym|$gear'] = (uid: uid, gym: gym, gear: gear, present: present, at: DateTime(2026, 11, 14));
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

  Future<void> otherSays(String uid, bool present, {String at = gym}) async {
    await MemoryCloud(server, uid).report(at, gear, present: present);
    await pumpEventQueue();
  }

  group('여러 회원의 제보', () {
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
      expect(me.gearReportCount(gym), (present: 2, missing: 2));
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

  group('운영자 등록 (기기에만 저장)', () {
    test('운영자 등록은 서버에 올리지 않고, 다른 기기에는 보이지 않는다', () async {
      final owner = await device('owner');
      owner.registerGymGear(gym, ['lf-ins-row']);
      await pumpEventQueue();
      expect(server.reports, isEmpty);
      expect(owner.listedGear(gym), ['lf-ins-row']);

      final other = await device('other');
      expect(other.operatorListed(gym), isFalse);
      expect(other.listedGear(gym), gymGear[gym]);
    });

    test('내가 등록한 헬스장은 다른 회원들의 "없어요"보다 내 등록을 믿는다', () async {
      final owner = await device('owner');
      owner.registerGymGear(gym, [gear]);
      await otherSays('a', false);
      await otherSays('b', false);
      expect(owner.gymGearNow[gym], [gear]);
      expect(owner.gearReportCount(gym), (present: 0, missing: 2)); // 대시보드에는 제보 수가 보인다
    });
  });

  test('서버 연결 전에 쌓인 내 제보는 처음 연결할 때 올리고, 그 뒤로는 다시 올리지 않는다', () async {
    final store = MemoryStore();
    AppState.fresh()
      ..attachStore(store)
      ..reportGear(gym, gear, present: true)
      ..registerGymGear(AppState.myGym, ['hs-pl-pulldown']);

    final next = MemoryStore(store.data); // 다음 실행 (서버 설정이 들어간 새 버전)
    await device('me', store: next);
    expect(server.reports.keys, ['me|$gym|$gear']); // 운영자 등록은 올리지 않음

    server.reports.clear();
    await device('me', store: MemoryStore(next.data)); // 그다음 실행: 이미 올렸다는 표시가 저장돼 있음
    expect(server.reports, isEmpty);
  });

  test('처음 올리기가 실패하면(규칙이 막는 등) 다음 실행에서 다시 올린다', () async {
    final store = MemoryStore();
    AppState.fresh()
      ..attachStore(store)
      ..reportGear(gym, gear, present: true);

    server.rejectWrites = true;
    final first = MemoryStore(store.data);
    await device('me', store: first);
    expect(server.reports, isEmpty);

    server.rejectWrites = false;
    await device('me', store: MemoryStore(first.data));
    expect(server.reports.keys, ['me|$gym|$gear']);
  });

  test('Firestore 저장소: 익명 로그인 후 제보를 쓰고, 모든 회원의 제보로 다시 읽는다', () async {
    final db = FakeFirebaseFirestore();
    final cloud = await FirestoreGearCloud.connect(auth: MockFirebaseAuth(mockUser: MockUser(isAnonymous: true, uid: 'u1')), db: db);
    expect(cloud.uid, 'u1');
    await cloud.report('A/B 짐', gear, present: false);
    await FirestoreGearCloud(db, 'u2').report(gym, gear, present: true);

    expect((await db.collection('gear_reports').doc('u1__A∕B 짐__$gear').get()).exists, isTrue);
    final s = await cloud.watch().first;
    expect({for (final r in s) (r.uid, r.gym, r.present)}, {('u1', 'A/B 짐', false), ('u2', gym, true)});
    expect(s.every((r) => r.at != null), isTrue);
  });
}
