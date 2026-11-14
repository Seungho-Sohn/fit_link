// Firebase 프로젝트 설정 (콘솔 → 프로젝트 설정 → 내 앱).
// 이 값들은 비밀이 아닌 공개 식별자다. 실제 보호는 firestore.rules(보안 규칙)가 한다.
// 값이 비어 있으면 앱은 서버 없이 기기 저장만 쓴다.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// 지금 플랫폼의 설정. 설정이 없는 플랫폼(Windows 등)이면 null.
FirebaseOptions? get firebaseOptions {
  if (kIsWeb) return _web;
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => _android,
    _ => null,
  };
}

// TODO(설정): 콘솔의 웹 앱 firebaseConfig 값을 넣는다.
const FirebaseOptions? _web = null;

// TODO(설정): Android 앱 ID를 넣는다 (apiKey·projectId 등은 웹 앱과 같다).
const FirebaseOptions? _android = null;
