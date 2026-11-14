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

/// HTML의 전역 JS 변수(POINTS, cart, dcart, dfavs …)와 화면 전환 함수
/// (switchTab / goMarket / goDeliv / openCoach …)를 한 곳에 모은 상태 객체.
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
  String get location =>
      locationOf(page: page, market: marketView, deliv: delivView, product: curProductId, seller: curStoreSeller, shop: curShopId);

  @override
  void notifyListeners() {
    super.notifyListeners();
    final loc = location;
    if (loc != _reported) {
      _reported = loc;
      onLocationChanged?.call(loc);
    }
  }

  /// 주소를 화면 상태로 해석. 모르는 주소이거나 없는 상품·판매자·매장이면 null.
  NavTarget? resolveLocation(Uri uri) {
    final t = parseLocation(uri);
    if (t == null) return null;
    if (t.product != null && !products.any((p) => p.id == t.product)) return null;
    if (t.seller != null && !sellers.containsKey(t.seller)) return null;
    if (t.shop != null && !dshops.any((s) => s.id == t.shop)) return null;
    return t;
  }

  /// 주소에 맞춰 화면 상태를 바꾼다. 해석할 수 없는 주소면 아무것도 하지 않고 false.
  bool applyLocation(Uri uri) {
    final t = resolveLocation(uri);
    if (t == null) return false;
    if (t.page != page) pageSeq++; // 주소로 다른 화면에 들어오면 새로 시작
    page = t.page;
    marketView = t.market ?? marketView;
    delivView = t.deliv ?? delivView;
    curProductId = t.product ?? curProductId;
    curStoreSeller = t.seller ?? curStoreSeller;
    curShopId = t.shop ?? curShopId;
    _reported = location; // 주소에서 온 변경이므로 다시 보내지 않음
    notifyListeners();
    return true;
  }

  void go(AppPage p) {
    page = p;
    pageSeq++;
    if (p == AppPage.market) marketView = MarketView.home;
    if (p == AppPage.delivery) delivView = DelivView.home;
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

  /* ---------- 포인트 ---------- */
  int points = 3200;
  int earned = 4200;
  String? _attendedOn; // 마지막 출석일 'yyyy-mm-dd'
  String? _stampWeek; // 주간 보너스를 받은 주의 월요일 'yyyy-mm-dd'
  bool get attended => _attendedOn == dayKey(now());
  bool get stampClaimed => _stampWeek == weekKey(now());
  final List<PointLog> ptHistory = [
    const PointLog('상품 리뷰 작성', 100, '8월 9일'),
    const PointLog('배달 주문 적립 (2%)', 154, '8월 8일'),
    const PointLog('출석 체크', 10, '8월 8일'),
    const PointLog('챌린지 완주 보너스', 2000, '8월 5일'),
  ];
  final List<Mission> _missions = seedMissions();
  String? _missionWeek; // 미션 진행도가 속한 주 (그 주 월요일 'yyyy-mm-dd')

  /// 이번 주 미션. 주가 바뀌었으면 진행도를 0으로 되돌린 뒤 돌려준다.
  List<Mission> get missions {
    _rollMissionWeek();
    return _missions;
  }

  void _rollMissionWeek() {
    final w = weekKey(now());
    if (_missionWeek == w) return;
    for (final m in _missions) {
      m.progress = 0;
    }
    _missionWeek = w;
  }

  /// 미션 진행 +1 (목표에서 멈춤). 화면 갱신 알림은 부르는 쪽이 보낸다.
  void _advance(MissionKind k) {
    final m = missions.firstWhere((m) => m.kind == k);
    if (m.progress < m.goal) m.progress++;
  }

  /// 리뷰 쓰기 (+100P, 리뷰 미션)
  void writeReview() {
    _advance(MissionKind.review);
    earnPoints(100, '리뷰 작성');
  }

  /// 운동 기록에서 개인 신기록 (PR 미션)
  void recordPersonalRecord() {
    _advance(MissionKind.personalRecord);
    notifyListeners();
  }
  final ptDeals = [
    PtDeal('🎗️', 'WILD WEAR 리프팅 스트랩', 38000, 3900, 47),
    PtDeal('🥤', '프로틴 1개월 정기권', 68000, 2900, 100),
    PtDeal('🎟️', '제휴 헬스장 1일 이용권', 15000, 990, 210),
    PtDeal('👕', 'WILD WEAR 컴프레션 티', 52000, 4500, 23),
  ];

  int get tierIdx {
    int idx = 0;
    for (int i = 0; i < tiers.length; i++) {
      if (earned >= tiers[i].min) idx = i;
    }
    return idx;
  }

  Tier get tier => tiers[tierIdx];
  String get pointsStr => '${comma(points)} P';

  void earnPoints(int n, String reason) {
    points += n;
    earned += n;
    ptHistory.insert(0, PointLog.timed(reason, n, now()));
    notifyListeners();
    toast('+${n}P 적립 · $reason');
  }

  void spendPoints(int n, String reason) {
    final used = n > points ? points : n; // 잔액 이상은 차감할 수 없으므로 실제 차감액만 기록
    points -= used;
    ptHistory.insert(0, PointLog.timed(reason, -used, now()));
    notifyListeners();
  }

  void attend() {
    if (attended) {
      toast('오늘은 이미 출석했어요');
      return;
    }
    _attendedOn = dayKey(now());
    _advance(MissionKind.attend);
    earnPoints(10, '출석 체크');
  }

  int get missionsDone => missions.where((m) => m.isDone).length;
  bool get missionsAllDone => missions.every((m) => m.isDone);

  void claimStamp() {
    if (!missionsAllDone || stampClaimed) return;
    _stampWeek = weekKey(now());
    earnPoints(500, '주간 미션 보너스');
  }

  void redeemDeal(PtDeal d) {
    if (points < d.pts) {
      toast('포인트가 ${comma(d.pts - points)}P 부족해요');
      return;
    }
    d.left--;
    spendPoints(d.pts, '${d.name} 교환');
    toast('🎉 ${d.name} 교환 완료!');
  }

  /* ---------- 마켓 ---------- */
  MarketView marketView = MarketView.home;
  String curProductId = 'p1';
  String curStoreSeller = 'wildwear';
  final Map<String, int> cart = {}; // productId → qty
  int lastOrderTotal = 0;
  String myOrders = '배달 2건 · 마켓 1건';

  void goMarket(MarketView v) {
    marketView = v;
    notifyListeners();
  }

  void openProduct(String id) {
    curProductId = id;
    page = AppPage.market;
    marketView = MarketView.detail;
    notifyListeners();
  }

  void openSellerStore(String seller) {
    curStoreSeller = seller;
    marketView = MarketView.store;
    notifyListeners();
  }

  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  int get cartTotal => cart.entries.fold(0, (a, e) => a + productById(e.key).price * e.value);

  void addToCart(String id, int qty) {
    cart[id] = (cart[id] ?? 0) + qty;
    notifyListeners();
  }

  void removeFromCart(String id) {
    cart.remove(id);
    notifyListeners();
  }

  void checkout() {
    if (cart.isEmpty) return;
    lastOrderTotal = cartTotal;
    myOrders = '$cartCount건';
    cart.clear();
    marketView = MarketView.done;
    notifyListeners();
  }

  /* ---------- 배달 ---------- */
  DelivView delivView = DelivView.home;
  String curShopId = 's2';
  final Map<String, int> dcart = {}; // menuId → qty (순서 유지)
  final Set<String> dfavs = {'s2'};
  bool dUsePts = false;
  int lastDelivTotal = 0;

  void goDeliv(DelivView v) {
    delivView = v;
    notifyListeners();
  }

  void openShop(String id) {
    curShopId = id;
    page = AppPage.delivery;
    delivView = DelivView.store;
    notifyListeners();
  }

  void toggleFav(String id) {
    if (dfavs.contains(id)) {
      dfavs.remove(id);
      toast('찜을 해제했어요');
    } else {
      dfavs.add(id);
      toast('찜한 매장에 추가했어요');
    }
    notifyListeners();
  }

  int get dCount => dcart.values.fold(0, (a, b) => a + b);
  int get dTotal => dcart.entries.fold(0, (a, e) => a + menuById(e.key).price * e.value);

  void dAdd(String id) {
    dcart[id] = (dcart[id] ?? 0) + 1;
    toast('${menuById(id).name} 담았어요');
    notifyListeners();
  }

  void dQty(String id, int d) {
    final q = (dcart[id] ?? 0) + d;
    if (q <= 0) {
      dcart.remove(id);
    } else {
      dcart[id] = q;
    }
    notifyListeners();
  }

  void reorder(List<String> ids, {bool fromMy = false}) {
    dcart
      ..clear()
      ..addEntries(ids.map((e) => MapEntry(e, 1)));
    page = AppPage.delivery;
    delivView = DelivView.cart;
    notifyListeners();
    toast(fromMy ? '장바구니에 다시 담았어요' : '지난 주문을 담았어요');
  }

  /// 배달 결제 금액 계산
  PayBreakdown payCalc() {
    final base = dTotal;
    final club = base < 1000 ? base : 1000;
    final after = base - club;
    final pts = dUsePts ? (points < after ? points : after) : 0;
    final total = after - pts;
    return PayBreakdown(
      subtotal: base,
      clubDiscount: club,
      pointsUsed: pts,
      total: total,
      pointsEarned: (total * tier.rate / 100).round(),
    );
  }

  void toggleDPts() {
    dUsePts = !dUsePts;
    notifyListeners();
  }

  void placeDOrder() {
    final c = payCalc();
    lastDelivTotal = c.total;
    if (c.pointsUsed > 0) spendPoints(c.pointsUsed, '배달 포인트 결제');
    dcart.clear();
    dUsePts = false;
    delivView = DelivView.done;
    _advance(MissionKind.delivery);
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () => earnPoints(c.pointsEarned, '배달 주문 적립'));
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

  /// 글쓰기. '운동 인증' 글은 주간 미션에 반영된다. (인증 글 +50P는 화면이 게시 직후 적립)
  Post addPost(String tag, String text) {
    final t = now();
    final post = Post('mine-${t.microsecondsSinceEpoch}', 'F', '회원님', tier.en, '', tag, text, tag == '운동 인증' ? '🔥' : '', 0, 0, false, at: t);
    myPosts.insert(0, post);
    if (myPosts.length > _maxMine) {
      final dropped = myPosts.removeLast();
      myComments.remove(dropped.id);
      likeOverrides.remove(dropped.id);
    }
    if (tag == '운동 인증') _advance(MissionKind.workoutPost);
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

  /// 리워드: 기구 정보를 처음 확인해 준 회원에게 주는 포인트
  static const gearReportReward = 30;

  /// 다른 회원들의 "없어요"가 이만큼 모이고 "있어요"보다 많으면 모두의 매칭에서 뺀다
  static const missingQuorum = 2;

  final Map<String, List<String>> operatorGear = {}; // 내가 운영자로 등록한 헬스장 → 기구 id (기본 데이터를 대체)
  final Map<String, bool> gearReports = {}; // 내 제보 '헬스장|기구id' → 있음(true) / 없음(false)
  bool _uploadedLocal = false; // 서버 연결 전에 쌓인 내 제보를 올렸는지

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

  /// 회원이 헬스장에 그 기구가 실제로 있는지 알려 준다. 처음 알려 준 기구면 포인트 적립.
  void reportGear(String gym, String gearId, {required bool present}) {
    final key = _reportKey(gym, gearId);
    final first = !gearReports.containsKey(key);
    gearReports[key] = present;
    if (_cloud case final c?) _upload(c, key, present);
    if (first) {
      earnPoints(gearReportReward, '기구 정보 확인');
    } else {
      notifyListeners();
      toast(present ? '"있어요"로 바꿨어요' : '"없어요"로 바꿨어요 · 매칭에서 빠져요');
    }
  }

  /* ---------- 저장 · 복원 ---------- */
  // 저장 대상: 사용자가 쌓은 데이터(온보딩·포인트·미션·장바구니·찜).
  // 화면 위치, 결제 화면 옵션, 직전 주문 금액 같은 일시적인 값은 저장하지 않는다.
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
        'points': points,
        'earned': earned,
        'attendedOn': _attendedOn,
        'stampWeek': _stampWeek,
        'ptHistory': [for (final h in ptHistory) h.toJson()],
        'missions': {for (final m in missions) m.kind.name: m.progress},
        'missionWeek': _missionWeek,
        'dealsLeft': {for (final d in ptDeals) d.name: d.left},
        'cart': cart,
        'myOrders': myOrders,
        'dcart': dcart,
        'dfavs': dfavs.toList(),
        'posts': [for (final p in myPosts) p.toJson()],
        'comments': {for (final e in myComments.entries) e.key: [for (final c in e.value) c.toJson()]},
        'likes': likeOverrides,
        'operatorGear': operatorGear,
        'gearReports': gearReports,
        'uploadedLocal': _uploadedLocal,
      };

  /// 전부 파싱에 성공한 뒤에만 반영한다 (일부만 복원된 어중간한 상태 방지).
  void _restore(Map<String, dynamic> j) {
    if (j['schema'] != _schema) throw FormatException('알 수 없는 저장 형식: ${j['schema']}');
    final history = [for (final h in j['ptHistory'] as List) PointLog.fromJson(h as Map<String, dynamic>)];
    // 미션은 종류 이름으로 저장. 예전 저장본(한글 이름 키, missionWeek 없음)은 새 주로 보고 0부터 시작
    final missionProgress = (j['missions'] as Map? ?? const {}).cast<String, int>();
    final missionWeek = j['missionWeek'] as String?;
    final posts = [for (final p in j['posts'] as List? ?? const []) Post.mine(p as Map<String, dynamic>)];
    final comments = {
      for (final e in (j['comments'] as Map? ?? const {}).entries)
        e.key as String: [for (final c in e.value as List) Comment.mine(c as Map<String, dynamic>)],
    };
    final likes = (j['likes'] as Map? ?? const {}).cast<String, bool>();
    final dealsLeft = (j['dealsLeft'] as Map).cast<String, int>();
    // 목업 데이터에서 사라진 상품·메뉴는 버린다
    final savedCart = (j['cart'] as Map).cast<String, int>()..removeWhere((id, _) => !products.any((p) => p.id == id));
    final savedDcart = (j['dcart'] as Map).cast<String, int>()..removeWhere((id, _) => !dmenu.any((m) => m.id == id));
    final favs = (j['dfavs'] as List).cast<String>();
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

    onboarded = j['onboarded'] as bool;
    goal = j['goal'] as String;
    points = j['points'] as int;
    earned = j['earned'] as int;
    _attendedOn = j['attendedOn'] as String?;
    _stampWeek = j['stampWeek'] as String?;
    ptHistory
      ..clear()
      ..addAll(history);
    _missionWeek = missionWeek;
    for (final m in _missions) {
      m.progress = (missionProgress[m.kind.name] ?? 0).clamp(0, m.goal);
    }
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
    for (final d in ptDeals) {
      d.left = dealsLeft[d.name] ?? d.left;
    }
    cart
      ..clear()
      ..addAll(savedCart);
    myOrders = j['myOrders'] as String;
    dcart
      ..clear()
      ..addAll(savedDcart);
    dfavs
      ..clear()
      ..addAll(favs);
    operatorGear
      ..clear()
      ..addAll(opGear);
    gearReports
      ..clear()
      ..addAll(reports);
    _uploadedLocal = uploaded;
  }
}

String _two(int n) => n.toString().padLeft(2, '0');

/// 날짜 키 'yyyy-mm-dd'
String dayKey(DateTime t) => '${t.year}-${_two(t.month)}-${_two(t.day)}';

/// 주 키: 그 주 월요일의 [dayKey]
String weekKey(DateTime t) => dayKey(DateTime(t.year, t.month, t.day - (t.weekday - 1)));

/// 배달 결제 금액 내역 (원)
class PayBreakdown {
  final int subtotal, clubDiscount, pointsUsed, total, pointsEarned;
  const PayBreakdown({required this.subtotal, required this.clubDiscount, required this.pointsUsed, required this.total, required this.pointsEarned});
}
