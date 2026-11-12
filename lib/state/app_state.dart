import 'dart:convert';
import 'package:flutter/material.dart';
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
    m.showSnackBar(SnackBar(
      content: Text(msg, textAlign: TextAlign.center, style: F.inter(size: 11.5, color: C.goldBright, ls: .04)),
      backgroundColor: const Color(0xF514120C),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(40, 0, 40, 90),
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
  final missions = seedMissions();
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
  String? curProductId;
  String? curStoreSeller;
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
    notifyListeners();
    Future.delayed(const Duration(milliseconds: 700), () => earnPoints(c.pointsEarned, '배달 주문 적립'));
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
        'missions': {for (final m in missions) m.name: m.progress},
        'dealsLeft': {for (final d in ptDeals) d.name: d.left},
        'cart': cart,
        'myOrders': myOrders,
        'dcart': dcart,
        'dfavs': dfavs.toList(),
      };

  /// 전부 파싱에 성공한 뒤에만 반영한다 (일부만 복원된 어중간한 상태 방지).
  void _restore(Map<String, dynamic> j) {
    if (j['schema'] != _schema) throw FormatException('알 수 없는 저장 형식: ${j['schema']}');
    final history = [for (final h in j['ptHistory'] as List) PointLog.fromJson(h as Map<String, dynamic>)];
    final missionProgress = (j['missions'] as Map).cast<String, int>();
    final dealsLeft = (j['dealsLeft'] as Map).cast<String, int>();
    // 목업 데이터에서 사라진 상품·메뉴는 버린다
    final savedCart = (j['cart'] as Map).cast<String, int>()..removeWhere((id, _) => !products.any((p) => p.id == id));
    final savedDcart = (j['dcart'] as Map).cast<String, int>()..removeWhere((id, _) => !dmenu.any((m) => m.id == id));
    final favs = (j['dfavs'] as List).cast<String>();

    onboarded = j['onboarded'] as bool;
    goal = j['goal'] as String;
    points = j['points'] as int;
    earned = j['earned'] as int;
    _attendedOn = j['attendedOn'] as String?;
    _stampWeek = j['stampWeek'] as String?;
    ptHistory
      ..clear()
      ..addAll(history);
    for (final m in missions) {
      m.progress = missionProgress[m.name] ?? m.progress;
    }
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
