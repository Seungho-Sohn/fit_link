import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/equipment.dart';
import '../services/gear_cloud.dart';
import '../data/mock_data.dart';
import '../theme.dart';
import 'persistence.dart';
import 'routes.dart';

export 'routes.dart';

/// 앱 전체 상태(온보딩·커뮤니티·헬스장 기구 데이터)와 화면 전환(switchTab / openCoach …)을 한 곳에 모은 상태 객체.
/// 마켓·배달·포인트는 범위 조정(2026-11-21)으로 빠졌다 — 보관 태그 archive/store-delivery-points.
class AppState extends ChangeNotifier {
  AppState._();
  static final AppState I = AppState._();

  /// 단위 테스트용: 싱글턴과 분리된 초기 상태 인스턴스
  @visibleForTesting
  factory AppState.fresh() => AppState._();

  final messengerKey = GlobalKey<ScaffoldMessengerState>();

  /// 현재 시각. 테스트에서 날짜를 바꿔 끼울 수 있게 함수로 둔다.
  DateTime Function() now = DateTime.now;

  /* ---------- 온보딩 · 프로필 ---------- */
  bool onboarded = false;
  String goal = '근육량 증가';

  void finishOnboard(int? goalIdx) {
    const g = ['근육량 증가', '체지방 감량', '체형 유지'];
    if (goalIdx != null) goal = g[goalIdx];
    onboarded = true;
    page = AppPage.home;
    notifyListeners();
  }

  /* ---------- 화면 전환 ---------- */
  AppPage page = AppPage.home;
  int pageSeq = 0; // 같은 화면으로 다시 들어올 때 상태 초기화용 키

  /* ---------- 주소(URL) 연동 ---------- */
  // 화면 상태가 바뀌면 [notifyListeners]에서 주소를 갱신하고(→ GoRouter),
  // 주소가 바뀌면(딥링크·브라우저 뒤로 가기) [applyLocation]으로 화면 상태를 맞춘다.

  /// 주소를 바꾸는 함수. 앱에서는 GoRouter.go, 단위 테스트에서는 null(주소 연동 없음).
  void Function(String location)? onLocationChanged;
  String _reported = '/';

  /// 지금 화면 상태에 해당하는 주소
  String get location => locationOf(page: page, b2b: b2bPage);

  @override
  void notifyListeners() {
    super.notifyListeners();
    final loc = location;
    if (loc != _reported) {
      _reported = loc;
      onLocationChanged?.call(loc);
    }
  }

  /// 주소를 화면 상태로 해석. 모르는 주소면 null.
  NavTarget? resolveLocation(Uri uri) => parseLocation(uri);

  /// 주소에 맞춰 화면 상태를 바꾼다. 해석할 수 없는 주소면 아무것도 하지 않고 false.
  bool applyLocation(Uri uri) {
    final t = resolveLocation(uri);
    if (t == null) return false;
    if (t.page != page) pageSeq++; // 주소로 다른 화면에 들어오면 새로 시작
    page = t.page;
    b2bPage = t.b2b ?? b2bPage;
    _reported = location; // 주소에서 온 변경이므로 다시 보내지 않음
    notifyListeners();
    return true;
  }

  void go(AppPage p) {
    page = p;
    pageSeq++;
    if (p == AppPage.b2b) b2bPage = B2BPage.home;
    notifyListeners();
  }

  /* ---------- 헬스장 운영자 전용관 ---------- */
  B2BPage b2bPage = B2BPage.home;

  void goB2B(B2BPage v) {
    if (page != AppPage.b2b) {
      page = AppPage.b2b;
      pageSeq++;
    }
    b2bPage = v;
    notifyListeners();
  }

  /* ---------- 토스트 ---------- */
  void toast(String msg) {
    final m = messengerKey.currentState;
    if (m == null) return;
    m.hideCurrentSnackBar();
    // 태블릿·웹에서도 폰 폭(430) 화면 안에 들어오게 좌우 여백을 넓힌다
    final w = MediaQuery.maybeSizeOf(m.context)?.width ?? 430;
    final side = 40 + (w > 430 ? (w - 430) / 2 : 0.0);
    m.showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center, style: F.inter(size: 11.5, color: C.goldBright, ls: .04)),
      backgroundColor: const Color(0xF514120C),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(side, 0, side, 90),
      shape: const RoundedRectangleBorder(side: BorderSide(color: C.goldDim)),
      duration: const Duration(milliseconds: 1600),
      elevation: 0,
    ));
  }

  /* ---------- 커뮤니티 ---------- */
  // 목업 글(seedPosts)은 앱에 들어 있고, 회원이 쓴 글 · 단 댓글 · 좋아요만 저장한다.
  static const _maxMine = 100; // 저장 용량을 위해 글·댓글은 최근 100개까지

  final List<Post> myPosts = []; // 최신 글이 앞
  final Map<String, List<Comment>> myComments = {}; // 글 id → 회원이 단 댓글
  final Map<String, bool> likeOverrides = {}; // 글 id → 원래와 다른 좋아요 상태

  List<Post> get feed => [...myPosts, ...seedPosts];
  bool isLiked(Post p) => likeOverrides[p.id] ?? p.liked;
  int likeCount(Post p) => p.likes + (isLiked(p) == p.liked ? 0 : (isLiked(p) ? 1 : -1));
  List<Comment> commentsOf(Post p) => [...?seedComments[p.id], ...?myComments[p.id]];
  int commentCount(Post p) => p.comments + (myComments[p.id]?.length ?? 0);

  void toggleLike(Post p) {
    final v = !isLiked(p);
    if (v == p.liked) {
      likeOverrides.remove(p.id);
    } else {
      likeOverrides[p.id] = v;
    }
    notifyListeners();
  }

  void addComment(Post p, String text) {
    final list = myComments[p.id] ??= [];
    list.add(Comment('F', '회원님', text, '', at: now()));
    if (list.length > _maxMine) list.removeAt(0);
    notifyListeners();
  }

  /// 글쓰기
  Post addPost(String tag, String text) {
    final t = now();
    final post = Post('mine-${t.microsecondsSinceEpoch}', 'F', '회원님', '', '', tag, text, tag == '운동 인증' ? '🔥' : '', 0, 0, false, at: t);
    myPosts.insert(0, post);
    if (myPosts.length > _maxMine) {
      final dropped = myPosts.removeLast();
      myComments.remove(dropped.id);
      likeOverrides.remove(dropped.id);
    }
    notifyListeners();
    return post;
  }

  /* ---------- 헬스장 보유 기구 (시그니처 기능 데이터 루프) ---------- */
  // 기본 데이터(gymGear) 위에 운영자 등록과 회원 제보를 얹어 매칭에 쓴다.
  // - 운영자 등록: 이 기기에만 저장 (운영자 인증이 생기기 전까지 공유하지 않음 — gear_cloud.dart)
  // - 회원 제보: 기기에 저장하고, 서버([GearCloud], Firebase)가 연결되면 올린다.
  //   다른 회원들의 제보는 서버에서 받아 [sharedReports]에 둔다 (기기에는 저장하지 않음).

  /// B2B 화면을 쓰는 운영자의 헬스장 (데모: 운영 대시보드의 매장)
  static const myGym = '스틸핏 강남점';

  /// 다른 회원들의 "없어요"가 이만큼 모이고 "있어요"보다 많으면 모두의 매칭에서 뺀다
  static const missingQuorum = 2;

  final Map<String, List<String>> operatorGear = {}; // 내가 운영자로 등록한 헬스장 → 기구 id (기본 데이터를 대체)
  final Map<String, bool> gearReports = {}; // 내 제보 '헬스장|기구id' → 있음(true) / 없음(false)
  bool _uploadedLocal = false; // 서버 연결 전에 쌓인 내 제보를 올렸는지

  /* ---------- 내 이용권 (체인 이용권 모드, F-SIG-8) ---------- */
  /// 이용권이 있는 체인. 비어 있으면 모든 헬스장에서 찾는다.
  final Set<String> myChains = {};

  /// 헬스장 찾기에 쓰는 헬스장: 이용권 체인을 골랐으면 그 체인 지점만
  List<Gym> get gymsForMe => myChains.isEmpty ? gyms : [for (final g in gyms) if (myChains.contains(g.chain)) g];

  void toggleChain(String chain) {
    if (!myChains.remove(chain)) myChains.add(chain);
    notifyListeners();
  }

  void clearChains() {
    if (myChains.isEmpty) return;
    myChains.clear();
    notifyListeners();
  }

  GearCloud? _cloud;
  StreamSubscription<List<CloudReport>>? _cloudSub;
  List<CloudReport> sharedReports = const [];
  bool get cloudConnected => _cloud != null;

  /// 서버 연결. 다른 회원들의 제보를 받기 시작하고, 연결 전에 쌓인 내 제보를 올린다.
  void attachCloud(GearCloud cloud) {
    _cloud = cloud;
    _cloudSub?.cancel();
    _cloudSub = cloud.watch().listen((s) {
      sharedReports = s;
      notifyListeners();
    }, onError: (Object e) => debugPrint('공유 데이터를 받지 못했어요: $e'));
    if (!_uploadedLocal) {
      final jobs = [
        for (final e in gearReports.entries) _upload(cloud, e.key, e.value),
      ];
      // 모두 올라가야 표시한다 (실패하면 다음 실행 때 다시 시도)
      Future.wait(jobs).then((ok) {
        if (ok.every((x) => x) && identical(_cloud, cloud)) {
          _uploadedLocal = true;
          notifyListeners();
        }
      });
    }
  }

  /// 내 제보를 서버에 올린다. 올라가면 true, 다시 시도해야 하면 false.
  Future<bool> _upload(GearCloud cloud, String key, bool present) {
    final (gym, id) = _splitKey(key);
    return cloud.report(gym, id, present: present).then((_) => true, onError: (Object e) {
      debugPrint('서버에 올리지 못했어요 (기기에는 저장됨): $e');
      return false;
    });
  }

  static String _reportKey(String gym, String gearId) => '$gym|$gearId';
  static (String, String) _splitKey(String k) {
    final i = k.lastIndexOf('|');
    return (k.substring(0, i), k.substring(i + 1));
  }

  /// 내 제보
  bool? gearReport(String gym, String gearId) => gearReports[_reportKey(gym, gearId)];

  /// 내가 운영자로 등록한 헬스장인지
  bool operatorListed(String gym) => operatorGear.containsKey(gym);

  /// 운영자 등록 → 기본 데이터 순으로 정한 보유 목록
  List<String> listedGear(String gym) => operatorGear[gym] ?? gymGear[gym] ?? const [];

  /// 기구 하나의 제보 수 (나 + 다른 회원)
  ({int present, int missing}) reportCount(String gym, String gearId) {
    var p = 0, m = 0;
    for (final r in sharedReports) {
      if (r.gym != gym || r.gear != gearId || r.uid == _cloud?.uid) continue;
      r.present ? p++ : m++;
    }
    switch (gearReport(gym, gearId)) {
      case true:
        p++;
      case false:
        m++;
      case null:
    }
    return (present: p, missing: m);
  }

  /// 매칭에서 뺄지: 내가 "없어요"라고 했거나, "없어요"가 [missingQuorum]개 이상이고 "있어요"보다 많을 때.
  /// 내가 운영자로 등록한 헬스장은 내 등록을 그대로 믿는다.
  bool gearMissing(String gym, String gearId) {
    if (gearReport(gym, gearId) == false) return true;
    if (operatorListed(gym)) return false;
    final c = reportCount(gym, gearId);
    return c.missing >= missingQuorum && c.missing > c.present;
  }

  /// 매칭에 쓰는 보유 기구
  Map<String, List<String>> get gymGearNow => {
        for (final g in gyms) g.name: [for (final id in listedGear(g.name)) if (!gearMissing(g.name, id)) id],
      };

  GearSource gearSource(String gym, String gearId) {
    if (operatorListed(gym)) return GearSource.operator;
    if (gearReport(gym, gearId) == true) return GearSource.member;
    final c = reportCount(gym, gearId);
    return c.present > 0 && c.present >= c.missing ? GearSource.member : GearSource.listed;
  }

  /// 헬스장 전체의 회원 제보 수: (있어요, 없어요)
  ({int present, int missing}) gearReportCount(String gym) {
    final ids = {
      for (final r in sharedReports)
        if (r.gym == gym) r.gear,
      for (final k in gearReports.keys)
        if (k.startsWith('$gym|')) _splitKey(k).$2,
    };
    var p = 0, m = 0;
    for (final id in ids) {
      final c = reportCount(gym, id);
      p += c.present;
      m += c.missing;
    }
    return (present: p, missing: m);
  }

  /// 운영자가 보유 기구를 등록·수정한다 (이 기기에만 저장). 내 이전 제보는 정리한다.
  void registerGymGear(String gym, Iterable<String> ids) {
    final set = ids.toSet();
    operatorGear[gym] = [for (final m in gearCatalog) if (set.contains(m.id)) m.id]; // 카탈로그 순서로
    gearReports.removeWhere((k, _) => k.startsWith('$gym|'));
    notifyListeners();
    toast('보유 기구 ${set.length}대를 등록했어요 · 기구 매칭에 바로 반영돼요');
  }

  /// 내 기구 제보 수 (이 기기에 있는 것)
  int get myReportCount => gearReports.length;

  /// 내 기구 제보를 서버와 이 기기에서 모두 지운다 (개인정보 삭제 요청).
  /// 서버에 올린 적이 있는데 지금 연결이 안 되면 지우지 않고 false.
  Future<bool> deleteMyReports() async {
    final cloud = _cloud;
    if (cloud == null && _uploadedLocal) {
      toast('서버에 연결되지 않아 지우지 못했어요. 인터넷 연결을 확인해 주세요');
      return false;
    }
    try {
      final n = cloud == null ? 0 : await cloud.deleteMine();
      final local = gearReports.length;
      gearReports.clear();
      notifyListeners();
      toast('내 기구 제보를 지웠어요 (서버 $n건 · 이 기기 $local건)');
      return true;
    } catch (e) {
      debugPrint('제보 삭제 실패: $e');
      toast('지우지 못했어요. 잠시 후 다시 시도해 주세요');
      return false;
    }
  }

  /// 회원이 헬스장에 그 기구가 실제로 있는지 알려 준다.
  void reportGear(String gym, String gearId, {required bool present}) {
    final key = _reportKey(gym, gearId);
    final first = !gearReports.containsKey(key);
    gearReports[key] = present;
    if (_cloud case final c?) _upload(c, key, present);
    notifyListeners();
    if (first) {
      toast('알려 주셔서 고마워요 · 기구 매칭에 반영됐어요');
    } else {
      toast(present ? '"있어요"로 바꿨어요' : '"없어요"로 바꿨어요 · 매칭에서 빠져요');
    }
  }

  /* ---------- 저장 · 복원 ---------- */
  // 저장 대상: 사용자가 쌓은 데이터(온보딩·커뮤니티 글·운영자 등록·기구 제보). 화면 위치는 저장하지 않는다.
  // 예전 저장본의 포인트·미션·장바구니·찜 항목은 읽지 않고 버린다 (다음 저장 때 사라짐).
  static const _schema = 1;
  StateStore? _store;
  String? _lastSaved;

  /// [store]에서 상태를 복원하고, 이후 상태가 바뀔 때마다 자동 저장한다.
  /// 저장본이 깨져 있으면 무시하고 초기 상태로 시작한다.
  void attachStore(StateStore store) {
    _store = store;
    final raw = store.read();
    if (raw != null) {
      try {
        _restore(jsonDecode(raw) as Map<String, dynamic>);
      } catch (e) {
        debugPrint('저장된 상태를 읽지 못해 초기 상태로 시작합니다: $e');
      }
    }
    _lastSaved = jsonEncode(toJson());
    addListener(_save);
  }

  void _save() {
    final store = _store;
    if (store == null) return;
    final data = jsonEncode(toJson());
    if (data == _lastSaved) return; // 화면 이동 등 저장 대상이 그대로면 건너뜀
    _lastSaved = data;
    store.write(data).catchError((Object e) => debugPrint('상태 저장 실패: $e'));
  }

  Map<String, Object?> toJson() => {
        'schema': _schema,
        'onboarded': onboarded,
        'goal': goal,
        'posts': [for (final p in myPosts) p.toJson()],
        'comments': {for (final e in myComments.entries) e.key: [for (final c in e.value) c.toJson()]},
        'likes': likeOverrides,
        'operatorGear': operatorGear,
        'gearReports': gearReports,
        'uploadedLocal': _uploadedLocal,
        'myChains': myChains.toList(),
      };

  /// 전부 파싱에 성공한 뒤에만 반영한다 (일부만 복원된 어중간한 상태 방지).
  void _restore(Map<String, dynamic> j) {
    if (j['schema'] != _schema) throw FormatException('알 수 없는 저장 형식: ${j['schema']}');
    final posts = [for (final p in j['posts'] as List? ?? const []) Post.mine(p as Map<String, dynamic>)];
    final comments = {
      for (final e in (j['comments'] as Map? ?? const {}).entries)
        e.key as String: [for (final c in e.value as List) Comment.mine(c as Map<String, dynamic>)],
    };
    final likes = (j['likes'] as Map? ?? const {}).cast<String, bool>();
    // 기구 데이터: 예전 저장본에는 없다. 목업에서 사라진 헬스장·기구는 버린다
    bool knownGym(Object? g) => gyms.any((x) => x.name == g);
    bool knownGear(Object? id) => gearCatalog.any((m) => m.id == id);
    final opGear = {
      for (final e in (j['operatorGear'] as Map? ?? const {}).entries)
        if (knownGym(e.key)) e.key as String: [for (final id in e.value as List) if (knownGear(id)) id as String],
    };
    final reports = Map<String, bool>.of((j['gearReports'] as Map? ?? const {}).cast<String, bool>())
      ..removeWhere((k, _) {
        final i = k.indexOf('|');
        return i < 0 || !knownGym(k.substring(0, i)) || !knownGear(k.substring(i + 1));
      });
    final uploaded = j['uploadedLocal'] as bool? ?? false;
    final chains = [for (final c in j['myChains'] as List? ?? const []) if (gymChains.contains(c)) c as String]; // 데이터에서 사라진 체인은 버림

    onboarded = j['onboarded'] as bool;
    goal = j['goal'] as String;
    myPosts
      ..clear()
      ..addAll(posts);
    final ids = {for (final p in [...posts, ...seedPosts]) p.id}; // 없는 글에 달린 기록은 버림
    myComments
      ..clear()
      ..addEntries(comments.entries.where((e) => ids.contains(e.key)));
    likeOverrides
      ..clear()
      ..addEntries(likes.entries.where((e) => ids.contains(e.key)));
    operatorGear
      ..clear()
      ..addAll(opGear);
    gearReports
      ..clear()
      ..addAll(reports);
    _uploadedLocal = uploaded;
    myChains
      ..clear()
      ..addAll(chains);
  }
}
