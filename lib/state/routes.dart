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
