import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'app_state.dart';

/// GoRouter에 등록하는 주소 목록. [locationOf]가 만드는 주소와 [parseLocation]이 읽는 주소가
/// 모두 여기 있어야 한다 (test/routes_test.dart가 확인).
const routePaths = [
  '/',
  '/comm',
  '/cal',
  '/my',
  '/my/points',
  '/coach',
  '/coach/live',
  '/inbody',
  '/gear',
  '/market',
  '/market/product/:id',
  '/market/store/:id',
  '/market/cart',
  '/market/done',
  '/market/b2b',
  '/market/b2b/quote',
  '/market/b2b/quote/done',
  '/market/b2b/gear',
  '/market/used',
  '/market/dashboard',
  '/delivery',
  '/delivery/shop/:id',
  '/delivery/cart',
  '/delivery/pay',
  '/delivery/done',
];

/// 앱 라우터. 모든 주소가 같은 [shell] 페이지를 보여주고, 어떤 화면을 그릴지는 [AppState]가 정한다.
/// (같은 페이지 키를 쓰므로 주소가 바뀌어도 Shell과 그 안의 화면 상태가 유지된다)
///
/// - 화면 상태 → 주소: [AppState.onLocationChanged]가 [GoRouter.go]를 부른다.
/// - 주소 → 화면 상태: 라우터가 바뀌면 [AppState.applyLocation].
/// - 모르는 주소·없는 상품 id는 홈('/')으로 보낸다.
GoRouter buildRouter(AppState s, Widget shell) {
  final page = NoTransitionPage<void>(key: const ValueKey('shell'), child: shell);
  final router = GoRouter(
    initialLocation: s.location,
    redirect: (_, state) => s.resolveLocation(state.uri) == null ? '/' : null,
    onException: (_, __, router) => router.go('/'),
    routes: [for (final p in routePaths) GoRoute(path: p, pageBuilder: (_, __) => page)],
  );
  void sync() => s.applyLocation(router.routerDelegate.currentConfiguration.uri);
  router.routerDelegate.addListener(sync);
  s.onLocationChanged = router.go;
  return router;
}
