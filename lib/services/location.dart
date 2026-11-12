import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

/// 위치를 못 받을 때(권한 거부·미지원·타임아웃) 쓰는 기준점. 목업 헬스장들이 강남 일대에 있다.
const gangnamStation = LatLng(37.4979, 127.0276);

typedef MyLocation = ({LatLng pos, bool real});

/// 현재 위치. 실패하면 [gangnamStation] (real == false).
Future<MyLocation> currentLocation({Duration timeout = const Duration(seconds: 8)}) async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) return (pos: gangnamStation, real: false);
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
    if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) return (pos: gangnamStation, real: false);
    final p = await Geolocator.getCurrentPosition(
      locationSettings: LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: timeout),
    );
    return (pos: LatLng(p.latitude, p.longitude), real: true);
  } catch (_) {
    return (pos: gangnamStation, real: false);
  }
}

const _distance = Distance();

/// 두 지점 사이 직선거리(m)
double metersBetween(LatLng a, LatLng b) => _distance.as(LengthUnit.Meter, a, b);

/// '450m · 도보 6분' / '1.6km · 도보 21분' / '12.3km' (도보 1시간 넘으면 도보 시간 생략)
String distanceLabel(LatLng from, LatLng to) {
  final m = metersBetween(from, to);
  final d = m < 1000 ? '${(m / 10).round() * 10}m' : '${(m / 1000).toStringAsFixed(1)}km';
  final walk = (m / 75).ceil(); // 분당 약 75m
  return walk <= 60 ? '$d · 도보 $walk분' : d;
}
