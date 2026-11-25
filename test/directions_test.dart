import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/services/directions.dart';

void main() {
  test('네이버 지도 도보 길찾기 주소: 목적지·이름·appname (출발지는 현재 위치)', () {
    final u = naverRouteUri(37.4997, 127.03, '스틸핏 강남점');
    expect(u.scheme, 'nmap');
    expect(u.host, 'route');
    expect(u.path, '/walk');
    expect(u.queryParameters['dlat'], '37.4997');
    expect(u.queryParameters['dlng'], '127.03');
    expect(u.queryParameters['dname'], '스틸핏 강남점');
    expect(u.queryParameters['appname'], 'kr.gymvia.app');
    expect(u.queryParameters.containsKey('slat'), isFalse);
  });

  test('Android 모바일 웹은 intent 주소 (앱이 없으면 Play 스토어)', () {
    final s = naverRouteIntentUri(37.5, 127.0, '코어짐24 역삼').toString();
    expect(s, startsWith('intent://route/walk?dlat=37.5&dlng=127.0&dname='));
    expect(s, contains('appname=${Uri.encodeComponent(naverMapWebAppName)}'));
    expect(s, endsWith('#Intent;scheme=nmap;action=android.intent.action.VIEW;category=android.intent.category.BROWSABLE;package=com.nhn.android.nmap;end'));
  });

  Future<(DirectionsResult, List<String>)> run({required bool web, required TargetPlatform os, Set<String> works = const {}}) async {
    final tried = <String>[];
    final r = await openNaverDirections(37.5, 127.0, '헬스장', web: web, platform: os, open: (u) async {
      tried.add(u.scheme);
      return works.contains(u.scheme);
    });
    return (r, tried);
  }

  test('앱이 있으면 바로 열린다', () async {
    final (r, tried) = await run(web: false, os: TargetPlatform.android, works: {'nmap'});
    expect(r, DirectionsResult.opened);
    expect(tried, ['nmap']);
  });

  test('Android에 앱이 없으면 Play 스토어 (market → https 순서)', () async {
    expect((await run(web: false, os: TargetPlatform.android, works: {'market'})).$1, DirectionsResult.store);
    final (r, tried) = await run(web: false, os: TargetPlatform.android, works: {'https'});
    expect(r, DirectionsResult.store);
    expect(tried, ['nmap', 'market', 'https']);
  });

  test('iOS에 앱이 없으면 App Store', () async {
    final (r, tried) = await run(web: false, os: TargetPlatform.iOS, works: {'https'});
    expect(r, DirectionsResult.store);
    expect(tried, ['nmap', 'https']);
  });

  test('PC 웹은 열지 않고 안내만', () async {
    final (r, tried) = await run(web: true, os: TargetPlatform.windows);
    expect(r, DirectionsResult.unsupported);
    expect(tried, isEmpty);
  });

  test('Android 모바일 웹은 intent 주소 하나로 연다', () async {
    final (r, tried) = await run(web: true, os: TargetPlatform.android, works: {'intent'});
    expect(r, DirectionsResult.opened);
    expect(tried, ['intent']);
  });
}
