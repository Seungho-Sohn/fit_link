/// 앱 화면 식별자. Navigator 대신 [AppState.page]에 담아 Shell이 화면을 고른다.
enum AppPage {
  // 하단 탭
  home,
  comm,
  market,
  delivery,
  cal,
  my,
  // 탭 위에 띄우는 하위 화면
  coach,
  live,
  inbody,
  gear,
  points;

  /// 하단 탭바에서 강조할 탭
  AppPage get tab => switch (this) {
        coach || live || inbody || gear => home,
        points => my,
        _ => this,
      };

  /// 안드로이드 뒤로가기로 돌아갈 화면 (마켓·배달 내부 화면은 Shell에서 따로 처리)
  AppPage get parent => switch (this) {
        live => coach,
        points => my,
        _ => home,
      };
}

/// 마켓 탭 내부 화면
enum MarketView { home, detail, store, cart, done, b2b, b2bForm, b2bDone, used, dash }

/// 배달 탭 내부 화면
enum DelivView { home, store, cart, pay, done }

/* ===================== 주소(URL) ↔ 화면 ===================== */
// 웹에서는 주소창에 #/market/cart 처럼 보이고, 주소로 바로 들어오거나 브라우저 뒤로 가기를 하면
// 그 화면이 열린다. 화면 상태(AppState) → 주소 → 화면 상태로 바꿨을 때 항상 같아야 한다 (test/routes_test.dart).

/// 주소가 결정하는 화면 상태. null 인 값은 "주소가 정하지 않음 — 지금 값을 그대로 둠".
typedef NavTarget = ({AppPage page, MarketView? market, DelivView? deliv, String? product, String? seller, String? shop});

/// 지금 화면 상태를 주소로
String locationOf({
  required AppPage page,
  required MarketView market,
  required DelivView deliv,
  required String product,
  required String seller,
  required String shop,
}) {
  String enc(String s) => Uri.encodeComponent(s);
  return switch (page) {
    AppPage.home => '/',
    AppPage.comm => '/comm',
    AppPage.cal => '/cal',
    AppPage.my => '/my',
    AppPage.points => '/my/points',
    AppPage.coach => '/coach',
    AppPage.live => '/coach/live',
    AppPage.inbody => '/inbody',
    AppPage.gear => '/gear',
    AppPage.market => switch (market) {
        MarketView.home => '/market',
        MarketView.detail => '/market/product/${enc(product)}',
        MarketView.store => '/market/store/${enc(seller)}',
        MarketView.cart => '/market/cart',
        MarketView.done => '/market/done',
        MarketView.b2b => '/market/b2b',
        MarketView.b2bForm => '/market/b2b/quote',
        MarketView.b2bDone => '/market/b2b/quote/done',
        MarketView.used => '/market/used',
        MarketView.dash => '/market/dashboard',
      },
    AppPage.delivery => switch (deliv) {
        DelivView.home => '/delivery',
        DelivView.store => '/delivery/shop/${enc(shop)}',
        DelivView.cart => '/delivery/cart',
        DelivView.pay => '/delivery/pay',
        DelivView.done => '/delivery/done',
      },
  };
}

/// 주소를 화면 상태로. 모르는 주소면 null. (상품·매장 id가 실제로 있는지는 [AppState]가 확인)
NavTarget? parseLocation(Uri uri) {
  final seg = [for (final s in uri.pathSegments) if (s.isNotEmpty) s];
  NavTarget to(AppPage p, {MarketView? market, DelivView? deliv, String? product, String? seller, String? shop}) =>
      (page: p, market: market, deliv: deliv, product: product, seller: seller, shop: shop);
  NavTarget m(MarketView v, {String? product, String? seller}) => to(AppPage.market, market: v, product: product, seller: seller);
  NavTarget d(DelivView v, {String? shop}) => to(AppPage.delivery, deliv: v, shop: shop);

  return switch (seg) {
    [] => to(AppPage.home),
    ['comm'] => to(AppPage.comm),
    ['cal'] => to(AppPage.cal),
    ['my'] => to(AppPage.my),
    ['my', 'points'] => to(AppPage.points),
    ['coach'] => to(AppPage.coach),
    ['coach', 'live'] => to(AppPage.live),
    ['inbody'] => to(AppPage.inbody),
    ['gear'] => to(AppPage.gear),
    ['market'] => m(MarketView.home),
    ['market', 'product', final id] => m(MarketView.detail, product: id),
    ['market', 'store', final id] => m(MarketView.store, seller: id),
    ['market', 'cart'] => m(MarketView.cart),
    ['market', 'done'] => m(MarketView.done),
    ['market', 'b2b'] => m(MarketView.b2b),
    ['market', 'b2b', 'quote'] => m(MarketView.b2bForm),
    ['market', 'b2b', 'quote', 'done'] => m(MarketView.b2bDone),
    ['market', 'used'] => m(MarketView.used),
    ['market', 'dashboard'] => m(MarketView.dash),
    ['delivery'] => d(DelivView.home),
    ['delivery', 'shop', final id] => d(DelivView.store, shop: id),
    ['delivery', 'cart'] => d(DelivView.cart),
    ['delivery', 'pay'] => d(DelivView.pay),
    ['delivery', 'done'] => d(DelivView.done),
    _ => null,
  };
}
