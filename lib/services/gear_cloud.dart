// 회원의 기구 제보("이 헬스장에 이 기구가 있어요/없어요")를 모든 사용자와 공유하는 저장소.
//
//   gear_reports/{uid}__{헬스장}__{기구ID}   { uid, gym, gear, present, at }
//
// 사용자는 익명 로그인(uid)으로 구분하고, 보안 규칙(firestore.rules)으로 자기 제보만 쓸 수 있다.
// 운영자 보유 기구 등록은 운영자 인증(사업자 확인 등)이 생기기 전까지 공유하지 않는다
// — 누구나 B2B 화면을 열 수 있어서, 공유하면 아무나 헬스장 기구 목록을 바꿀 수 있기 때문.
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// 회원 제보 한 건
typedef CloudReport = ({String uid, String gym, String gear, bool present, DateTime? at});

/// 공유 저장소. 앱은 [FirestoreGearCloud], 테스트는 메모리 구현을 쓴다.
abstract class GearCloud {
  /// 이 기기(익명 사용자)의 id
  String get uid;

  /// 모든 회원의 제보. 바뀔 때마다 전체를 다시 보낸다.
  Stream<List<CloudReport>> watch();

  /// 내 제보 (같은 헬스장·기구면 덮어씀)
  Future<void> report(String gym, String gear, {required bool present});
}

/// Firestore 문서 id에 쓸 수 없는 '/'만 바꾼다
String gymDocId(String gym) => gym.replaceAll('/', '∕');

class FirestoreGearCloud implements GearCloud {
  final FirebaseFirestore db;
  @override
  final String uid;
  FirestoreGearCloud(this.db, this.uid);

  /// 익명 로그인 후 연결. 실패하면 예외 (호출하는 쪽에서 기기 저장만 쓰도록 처리).
  static Future<FirestoreGearCloud> connect({FirebaseAuth? auth, FirebaseFirestore? db}) async {
    final a = auth ?? FirebaseAuth.instance;
    final user = a.currentUser ?? (await a.signInAnonymously()).user;
    if (user == null) throw StateError('익명 로그인 실패');
    return FirestoreGearCloud(db ?? FirebaseFirestore.instance, user.uid);
  }

  CollectionReference<Map<String, dynamic>> get _reports => db.collection('gear_reports');

  @override
  Stream<List<CloudReport>> watch() => _reports.snapshots().map((s) => [
        for (final d in s.docs)
          if (d.data() case {'uid': final String uid, 'gym': final String gym, 'gear': final String gear, 'present': final bool present})
            (uid: uid, gym: gym, gear: gear, present: present, at: d.data()['at'] is Timestamp ? (d.data()['at'] as Timestamp).toDate() : null),
      ]);

  @override
  Future<void> report(String gym, String gear, {required bool present}) =>
      _reports.doc('${uid}__${gymDocId(gym)}__$gear').set({'uid': uid, 'gym': gym, 'gear': gear, 'present': present, 'at': FieldValue.serverTimestamp()});
}
