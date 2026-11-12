import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../theme.dart';
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
  bool attended = false;
  bool stampClaimed = false;
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
    ptHistory.insert(0, PointLog(reason, n, '방금'));
    notifyListeners();
    toast('+${n}P 적립 · $reason');
  }

  void spendPoints(int n, String reason) {
    points = points - n < 0 ? 0 : points - n;
    ptHistory.insert(0, PointLog(reason, -n, '방금'));
    notifyListeners();
  }

  void attend() {
    if (attended) {
      toast('오늘은 이미 출석했어요');
      return;
    }
    attended = true;
    earnPoints(10, '출석 체크');
  }

  int get missionsDone => missions.where((m) => m.isDone).length;
  bool get missionsAllDone => missions.every((m) => m.isDone);

  void claimStamp() {
    if (!missionsAllDone || stampClaimed) return;
    stampClaimed = true;
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
}

/// 배달 결제 금액 내역 (원)
class PayBreakdown {
  final int subtotal, clubDiscount, pointsUsed, total, pointsEarned;
  const PayBreakdown({required this.subtotal, required this.clubDiscount, required this.pointsUsed, required this.total, required this.pointsEarned});
}
