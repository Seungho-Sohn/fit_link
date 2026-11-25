import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// 네이버 지도 길찾기 (URL Scheme, 키·요금 없음).
///
/// 공식 가이드(네이버 클라우드 플랫폼 "Maps URL Scheme"):
/// - `nmap://route/walk?dlat=&dlng=&dname=&appname=` — 출발지(slat/slng)를 빼면 현재 위치에서 출발
/// - `appname` 필수: Android = applicationId, iOS = 번들 ID, 모바일 웹 = 웹 페이지 주소
/// - 앱이 없으면 Android는 Play 스토어, iOS는 App Store로 안내
/// - 웹(https) 길찾기 주소는 공식 문서에 없음 → PC 웹에서는 안내만
const naverMapAppId = 'kr.gymvia.app'; // Android applicationId = iOS 번들 ID
const naverMapWebAppName = 'https://seungho-sohn.github.io/fit_link/';
const naverMapPackage = 'com.nhn.android.nmap';
final naverMapPlayStore = Uri.parse('market://details?id=$naverMapPackage');
final naverMapPlayStoreWeb = Uri.parse('https://play.google.com/store/apps/details?id=$naverMapPackage');
final naverMapAppStore = Uri.parse('https://apps.apple.com/app/id311867728');

/// 도보 길찾기 쿼리 (목적지만 지정 — 출발지는 현재 위치)
String naverRouteQuery(double lat, double lng, String name, {String appName = naverMapAppId}) =>
    'dlat=$lat&dlng=$lng&dname=${Uri.encodeComponent(name)}&appname=${Uri.encodeComponent(appName)}';

/// 앱용: nmap://route/walk?…
Uri naverRouteUri(double lat, double lng, String name, {String appName = naverMapAppId}) =>
    Uri.parse('nmap://route/walk?${naverRouteQuery(lat, lng, name, appName: appName)}');

/// Android 모바일 웹용 intent 주소 — 앱이 없으면 브라우저가 Play 스토어로 보낸다
Uri naverRouteIntentUri(double lat, double lng, String name) => Uri.parse(
    'intent://route/walk?${naverRouteQuery(lat, lng, name, appName: naverMapWebAppName)}'
    '#Intent;scheme=nmap;action=android.intent.action.VIEW;category=android.intent.category.BROWSABLE;package=$naverMapPackage;end');

/// 길찾기 결과
enum DirectionsResult { opened, store, unsupported, failed }

typedef UrlOpener = Future<bool> Function(Uri url);

Future<bool> _open(Uri url) async {
  try {
    return await launchUrl(url, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false; // 처리할 앱이 없으면 예외가 나는 기기도 있다
  }
}

/// 네이버 지도 앱으로 [name]까지 도보 길찾기를 연다.
/// 앱이 없으면 스토어를 열고 [DirectionsResult.store], PC 웹이면 [DirectionsResult.unsupported].
Future<DirectionsResult> openNaverDirections(double lat, double lng, String name,
    {UrlOpener open = _open, bool? web, TargetPlatform? platform}) async {
  final isWeb = web ?? kIsWeb;
  final os = platform ?? defaultTargetPlatform;
  final android = os == TargetPlatform.android, ios = os == TargetPlatform.iOS;
  if (isWeb) {
    if (android) return await open(naverRouteIntentUri(lat, lng, name)) ? DirectionsResult.opened : DirectionsResult.failed;
    if (ios) {
      if (await open(naverRouteUri(lat, lng, name, appName: naverMapWebAppName))) return DirectionsResult.opened;
      return await open(naverMapAppStore) ? DirectionsResult.store : DirectionsResult.failed;
    }
    return DirectionsResult.unsupported;
  }
  if (await open(naverRouteUri(lat, lng, name))) return DirectionsResult.opened;
  if (android) {
    if (await open(naverMapPlayStore) || await open(naverMapPlayStoreWeb)) return DirectionsResult.store;
  } else if (ios) {
    if (await open(naverMapAppStore)) return DirectionsResult.store;
  }
  return DirectionsResult.failed;
}
