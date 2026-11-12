import 'package:shared_preferences/shared_preferences.dart';

/// [AppState]를 JSON 문자열 하나로 읽고 쓰는 저장소.
/// 앱은 [PrefsStore], 단위 테스트는 [MemoryStore]를 쓴다.
abstract interface class StateStore {
  String? read();
  Future<void> write(String data);
}

/// 기기 저장소 (Android SharedPreferences · iOS NSUserDefaults · 웹 localStorage 등)
class PrefsStore implements StateStore {
  static const key = 'fit_link.app_state';
  final SharedPreferences _prefs;
  PrefsStore._(this._prefs);

  static Future<PrefsStore> open() async => PrefsStore._(await SharedPreferences.getInstance());

  @override
  String? read() => _prefs.getString(key);

  @override
  Future<void> write(String data) => _prefs.setString(key, data);
}

/// 메모리 저장소 (테스트용)
class MemoryStore implements StateStore {
  String? data;
  int writes = 0;
  MemoryStore([this.data]);

  @override
  String? read() => data;

  @override
  Future<void> write(String data) async {
    this.data = data;
    writes++;
  }
}
