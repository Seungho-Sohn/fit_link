import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme.dart';

/// 지도 위 헬스장 핀
typedef GymPin = ({String id, LatLng pos, String label});

/// OpenStreetMap 타일 위에 내 위치와 헬스장 핀을 그리는 지도. API 키가 필요 없다.
///
/// OSM 공개 타일 서버는 개발·소량 사용용이다(타일 사용 정책). 실서비스 트래픽에는
/// 타일 제공 업체(또는 네이버·구글 등 상용 지도)로 바꿔야 한다 — [tileUrl]만 바꾸면 된다.
class GymMap extends StatelessWidget {
  final LatLng me;
  final bool meIsReal;
  final List<GymPin> pins;
  final String? selectedId;
  final ValueChanged<String> onSelect;

  /// 테스트에서는 false (네트워크로 타일을 받지 않음)
  final bool showTiles;
  final double height;

  static const tileUrl = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  const GymMap({
    super.key,
    required this.me,
    required this.meIsReal,
    required this.pins,
    required this.onSelect,
    this.selectedId,
    this.showTiles = true,
    this.height = 390,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(border: Border.all(color: C.hairlineSoft)),
      child: ClipRect(
        child: FlutterMap(
          options: MapOptions(
            backgroundColor: const Color(0xFF131109),
            initialCameraFit: CameraFit.coordinates(
              coordinates: [me, for (final p in pins) p.pos],
              padding: const EdgeInsets.fromLTRB(70, 60, 70, 40),
              maxZoom: 16,
            ),
            interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
          ),
          children: [
            if (showTiles)
              TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: 'kr.wildwear.fit_link',
                tileBuilder: darkModeTileBuilder, // 앱의 어두운 테마에 맞춰 반전
              ),
            MarkerLayer(
              alignment: Alignment.topCenter, // 핀 끝이 좌표를 가리키도록 마커 전체를 좌표 위에
              markers: [
                Marker(point: me, width: 90, height: 44, child: _Pin(meIsReal ? '내 위치' : '강남역 (기본)', me: true)),
                for (final p in pins)
                  Marker(
                    point: p.pos,
                    width: 150,
                    height: 44,
                    child: GestureDetector(onTap: () => onSelect(p.id), child: _Pin(p.label, selected: p.id == selectedId)),
                  ),
              ],
            ),
            const RichAttributionWidget(
              showFlutterMapAttribution: false,
              attributions: [TextSourceAttribution('OpenStreetMap contributors')],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  final String label;
  final bool me, selected;
  const _Pin(this.label, {this.me = false, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final size = selected ? 16.0 : 12.0;
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(color: const Color(0xE60A0A0B), border: Border.all(color: selected ? C.gold : C.hairlineSoft)),
        child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: F.inter(size: 9, ls: .03, color: selected ? C.goldBright : C.ivory)),
      ),
      const SizedBox(height: 4),
      Transform.rotate(
        angle: .785,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: me ? C.ivory : (selected ? C.goldBright : C.goldDim),
            border: Border.all(color: C.onyx),
          ),
        ),
      ),
    ]);
  }
}
