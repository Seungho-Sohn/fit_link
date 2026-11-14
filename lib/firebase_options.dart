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

// 프로젝트 fit-link-6922f 공통 값
const _apiKey = 'AIzaSyDyvFdpo817LHDAIknylqvWs5CYDJ-vRx8';
const _projectId = 'fit-link-6922f';
const _senderId = '195223662588';
const _storageBucket = 'fit-link-6922f.firebasestorage.app';

const FirebaseOptions _web = FirebaseOptions(
  apiKey: _apiKey,
  appId: '1:195223662588:web:d35ef9e616965faa674c79',
  messagingSenderId: _senderId,
  projectId: _projectId,
  authDomain: 'fit-link-6922f.firebaseapp.com',
  storageBucket: _storageBucket,
);

const FirebaseOptions _android = FirebaseOptions(
  apiKey: _apiKey,
  appId: '1:195223662588:android:20d86b0a4736cec6674c79',
  messagingSenderId: _senderId,
  projectId: _projectId,
  storageBucket: _storageBucket,
);
