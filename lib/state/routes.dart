/// 앱 화면 식별자. Navigator 대신 [AppState.page]에 담아 Shell이 화면을 고른다.
enum AppPage {
  // 하단 탭
  home,
  gear, // 헬스장 찾기 (시그니처: 기구 사진 → 같은 기구가 있는 헬스장)
  comm,
  cal,
  my,
  // 탭 위에 띄우는 하위 화면
  coach,
  live,
  inbody,
  b2b; // 헬스장 운영자 전용관 (마이 탭에서 진입)

  /// 하단 탭바에서 강조할 탭
  AppPage get tab => switch (this) {
        coach || live || inbody => home,
        b2b => my,
        _ => this,
      };

  /// 안드로이드 뒤로가기로 돌아갈 화면 (운영자 전용관 내부 화면은 Shell에서 따로 처리)
  AppPage get parent => switch (this) {
        live => coach,
        b2b => my,
        _ => home,
      };
}

/// 운영자 전용관 내부 화면
enum B2BPage { home, quote, quoteDone, used, dash, gear }

/* ===================== 주소(URL) ↔ 화면 ===================== */
// 웹에서는 주소창에 #/b2b/quote 처럼 보이고, 주소로 바로 들어오거나 브라우저 뒤로 가기를 하면
// 그 화면이 열린다. 화면 상태(AppState) → 주소 → 화면 상태로 바꿨을 때 항상 같아야 한다 (test/routes_test.dart).

/// 주소가 결정하는 화면 상태. null 인 값은 "주소가 정하지 않음 — 지금 값을 그대로 둠".
typedef NavTarget = ({AppPage page, B2BPage? b2b});

/// 지금 화면 상태를 주소로
String locationOf({required AppPage page, required B2BPage b2b}) => switch (page) {
      AppPage.home => '/',
      AppPage.gear => '/gear',
      AppPage.comm => '/comm',
      AppPage.cal => '/cal',
      AppPage.my => '/my',
      AppPage.coach => '/coach',
      AppPage.live => '/coach/live',
      AppPage.inbody => '/inbody',
      AppPage.b2b => switch (b2b) {
          B2BPage.home => '/b2b',
          B2BPage.quote => '/b2b/quote',
          B2BPage.quoteDone => '/b2b/quote/done',
          B2BPage.used => '/b2b/used',
          B2BPage.dash => '/b2b/dashboard',
          B2BPage.gear => '/b2b/gear',
        },
    };

/// 주소를 화면 상태로. 모르는 주소면 null.
NavTarget? parseLocation(Uri uri) {
  final seg = [for (final s in uri.pathSegments) if (s.isNotEmpty) s];
  NavTarget to(AppPage p) => (page: p, b2b: null);
  NavTarget b(B2BPage v) => (page: AppPage.b2b, b2b: v);

  return switch (seg) {
    [] => to(AppPage.home),
    ['gear'] => to(AppPage.gear),
    ['comm'] => to(AppPage.comm),
    ['cal'] => to(AppPage.cal),
    ['my'] => to(AppPage.my),
    ['coach'] => to(AppPage.coach),
    ['coach', 'live'] => to(AppPage.live),
    ['inbody'] => to(AppPage.inbody),
    ['b2b'] => b(B2BPage.home),
    ['b2b', 'quote'] => b(B2BPage.quote),
    ['b2b', 'quote', 'done'] => b(B2BPage.quoteDone),
    ['b2b', 'used'] => b(B2BPage.used),
    ['b2b', 'dashboard'] => b(B2BPage.dash),
    ['b2b', 'gear'] => b(B2BPage.gear),
    _ => null,
  };
}
