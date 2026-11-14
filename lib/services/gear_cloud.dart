// 헬스장 보유 기구 데이터 루프를 모든 사용자와 공유하는 저장소.
//
// - 운영자 등록:  gym_gear/{헬스장}            { gym, gear: [기구ID], owner: uid, updatedAt }
// - 회원 제보:    gear_reports/{uid}__{헬스장}__{기구ID}  { uid, gym, gear, present, at }
//
// 사용자는 익명 로그인(uid)으로 구분한다. 보안 규칙은 firestore.rules:
// 헬스장은 처음 등록한 사람만 고칠 수 있고, 제보는 자기 것만 쓸 수 있다.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 운영자 등록 한 건
typedef OperatorEntry = ({List<String> gear, String owner, DateTime? at});

/// 회원 제보 한 건
typedef CloudReport = ({String uid, String gym, String gear, bool present, DateTime? at});

/// 서버에서 받은 공유 데이터
typedef SharedGear = ({Map<String, OperatorEntry> operators, List<CloudReport> reports});

const emptySharedGear = (operators: <String, OperatorEntry>{}, reports: <CloudReport>[]);

/// 다른 운영자가 이미 등록한 헬스장을 고치려 할 때
class GymOwnedByOther implements Exception {
  const GymOwnedByOther();
}

/// 공유 저장소. 앱은 [FirestoreGearCloud], 테스트는 메모리 구현을 쓴다.
abstract class GearCloud {
  /// 이 기기(익명 사용자)의 id
  String get uid;

  /// 공유 데이터가 바뀔 때마다 전체를 다시 보낸다
  Stream<SharedGear> watch();

  /// 운영자 등록. 다른 사람이 먼저 등록한 헬스장이면 [GymOwnedByOther].
  Future<void> registerGym(String gym, List<String> gear);

  /// 회원 제보 (같은 사람·헬스장·기구면 덮어씀)
  Future<void> report(String gym, String gear, {required bool present});
}

/// Firestore 문서 id에 쓸 수 없는 '/'만 바꾼다
String gymDocId(String gym) => gym.replaceAll('/', '∕');

class FirestoreGearCloud implements GearCloud {
  final FirebaseFirestore db;
  @override
  final String uid;
  FirestoreGearCloud(this.db, this.uid);

  /// 익명 로그인 후 연결. 실패하면 예외 (호출하는 쪽에서 로컬 저장만 쓰도록 처리).
  static Future<FirestoreGearCloud> connect({FirebaseAuth? auth, FirebaseFirestore? db}) async {
    final a = auth ?? FirebaseAuth.instance;
    final user = a.currentUser ?? (await a.signInAnonymously()).user;
    if (user == null) throw StateError('익명 로그인 실패');
    return FirestoreGearCloud(db ?? FirebaseFirestore.instance, user.uid);
  }

  CollectionReference<Map<String, dynamic>> get _gyms => db.collection('gym_gear');
  CollectionReference<Map<String, dynamic>> get _reports => db.collection('gear_reports');

  static DateTime? _time(Object? t) => t is Timestamp ? t.toDate() : null;

  @override
  Stream<SharedGear> watch() {
    late StreamController<SharedGear> out;
    var ops = <String, OperatorEntry>{};
    var reps = <CloudReport>[];
    var gotOps = false, gotReps = false;
    final subs = <StreamSubscription<Object?>>[];
    void emit() {
      if (gotOps && gotReps) out.add((operators: ops, reports: reps));
    }

    out = StreamController<SharedGear>(
      onListen: () {
        subs.add(_gyms.snapshots().listen((s) {
          ops = {
            for (final d in s.docs)
              if (d.data()['gym'] case final String gym)
                gym: (gear: [for (final g in d.data()['gear'] as List? ?? const []) '$g'], owner: '${d.data()['owner']}', at: _time(d.data()['updatedAt'])),
          };
          gotOps = true;
          emit();
        }, onError: out.addError));
        subs.add(_reports.snapshots().listen((s) {
          reps = [
            for (final d in s.docs)
              if (d.data() case {'uid': final String uid, 'gym': final String gym, 'gear': final String gear, 'present': final bool present})
                (uid: uid, gym: gym, gear: gear, present: present, at: _time(d.data()['at'])),
          ];
          gotReps = true;
          emit();
        }, onError: out.addError));
      },
      onCancel: () async {
        for (final s in subs) {
          await s.cancel();
        }
      },
    );
    return out.stream;
  }

  @override
  Future<void> registerGym(String gym, List<String> gear) async {
    final ref = _gyms.doc(gymDocId(gym));
    try {
      await db.runTransaction((tx) async {
        final cur = await tx.get(ref);
        final owner = cur.data()?['owner'];
        if (cur.exists && owner != uid) throw const GymOwnedByOther();
        tx.set(ref, {'gym': gym, 'gear': gear, 'owner': uid, 'updatedAt': FieldValue.serverTimestamp()});
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') throw const GymOwnedByOther();
      rethrow;
    }
  }

  @override
  Future<void> report(String gym, String gear, {required bool present}) =>
      _reports.doc('${uid}__${gymDocId(gym)}__$gear').set({'uid': uid, 'gym': gym, 'gear': gear, 'present': present, 'at': FieldValue.serverTimestamp()});
}
