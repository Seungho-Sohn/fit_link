import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/mock_data.dart';
import '../services/location.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/gym_map.dart';

/// 기구 매칭 결과 (목업): 헬스장 · 매칭 점수 · 평점 · 태그 · 운영 시간
const _matches = [
  (gym: '스틸핏 강남점', score: 98, rating: 4.8, tag1: 'Hammer Strength 동일모델', tag2: 'PT 가능', has: true, hours: '06:00–24:00'),
  (gym: '코어짐24 역삼', score: 91, rating: 4.6, tag1: 'Hammer Strength 동일라인', tag2: '24시간', has: true, hours: '24시간'),
  (gym: '바디스퀘어 논현', score: 42, rating: 4.4, tag1: '타사 브랜드 대체품', tag2: '주차가능', has: false, hours: '06:00–23:00'),
];

typedef _Match = ({String gym, int score, double rating, String tag1, String tag2, bool has, String hours});

const _filters = ['브랜드 일치만', '거리순', '평점순', '24시간'];

/// 시그니처 기능: 기구 사진 → AI 브랜드·모델 인식 → 동일 기구 보유 헬스장 매칭 (6단계)
class GearFlow extends StatefulWidget {
  /// 테스트에서 주입: 위치 조회, 지도 타일 표시 여부
  final Future<MyLocation> Function() locate;
  final bool mapTiles;
  const GearFlow({super.key, this.locate = currentLocation, this.mapTiles = true});
  @override
  State<GearFlow> createState() => _GearFlowState();
}

class _GearFlowState extends State<GearFlow> {
  int step = 1;
  int filter = 1; // 거리순: 처음엔 모든 헬스장을 가까운 순으로
  MyLocation? loc;
  String selected = _matches.first.gym;
  AppState get s => AppState.I;

  LatLng get here => loc?.pos ?? gangnamStation;
  Gym gymOf(_Match m) => gymByName(m.gym);
  _Match get sel => _matches.firstWhere((m) => m.gym == selected);

  void go(int n) {
    setState(() => step = n);
    if (n >= 4 && loc == null) _locate();
  }

  Future<void> _locate() async {
    final l = await widget.locate();
    if (mounted) setState(() => loc = l);
  }

  /// 선택한 필터에 맞춘 매칭 목록
  List<_Match> get matches {
    final list = [..._matches];
    switch (_filters[filter]) {
      case '브랜드 일치만':
        list.retainWhere((m) => m.has);
      case '거리순':
        list.sort((a, b) => metersBetween(here, gymOf(a).pos).compareTo(metersBetween(here, gymOf(b).pos)));
      case '평점순':
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case '24시간':
        list.retainWhere((m) => m.hours == '24시간');
    }
    return list;
  }

  Future<void> _directions() async {
    final g = gymOf(sel);
    // 카카오맵 길찾기 공개 링크 (키 불필요). 앱이 있으면 앱, 없으면 웹으로 열린다.
    final url = Uri.parse('https://map.kakao.com/link/to/${Uri.encodeComponent(g.name)},${g.pos.latitude},${g.pos.longitude}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) s.toast('지도 앱을 열지 못했어요');
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 6단계 진행 바
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 2, 22, 16),
        child: Row(children: [
          for (int i = 1; i <= 6; i++)
            Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 6 ? 5 : 0),
                height: 1.5,
                color: i < step ? C.goldDim : (i == step ? C.gold : C.goldA(.16)),
              ),
            ),
        ]),
      ),
      Expanded(child: KeyedSubtree(key: ValueKey(step), child: _screen())),
    ]);
  }

  Widget _screen() {
    switch (step) {
      case 2:
        return ScreenFrame(
          header: const StepTitle(eyebrow: '02 · Recognition · 03 · Analysis', title: '기구를 분석하고 있습니다', desc: '이미지 특징을 추출해 기구의 종류와 모델을 식별합니다.'),
          footer: [GoldButton('분석 결과 보기', onTap: () => go(3))],
          children: const [
            Viewfinder(child: SizedBox(width: 140, height: 196, child: CustomPaint(painter: _MachinePainter()))),
            AnalyzeLog(['이미지 전처리', '객체 탐지', '기구 유형 분류', '브랜드 · 모델 대조']),
          ],
        );
      case 3:
        return ScreenFrame(
          header: const StepTitle(eyebrow: '03 · Result', title: '브랜드·모델까지 인식 완료', desc: '카테고리가 아닌 제조사·모델 단위로 특정했습니다.'),
          footer: [GoldButton('이 브랜드로 헬스장 찾기', onTap: () => go(4)), GoldButton('다시 촬영하기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => go(1))],
          children: [
            Box(
              border: C.hairline,
              padding: const EdgeInsets.all(24),
              child: Row(children: [
                Ring(size: 74, segments: const [MapEntry(.96, C.gold)], child: Text('96%', style: F.gnum(size: 16))),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('HAMMER STRENGTH · PLATE-LOADED', style: F.inter(size: 9.5, color: C.gold, ls: .2, w: FontWeight.w500)),
                    const SizedBox(height: 5),
                    Text('프론트 랫풀다운', style: F.serif(size: 21)),
                    const SizedBox(height: 4),
                    Text('Front Pulldown', style: F.inter(size: 11, color: C.textFaint).copyWith(fontStyle: FontStyle.italic)),
                  ]),
                ),
              ]),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.8,
              mainAxisSpacing: 1,
              crossAxisSpacing: 1,
              children: [
                _cell('제조사', 'Hammer Strength'),
                _cell('모델 매칭', '정확 일치', gold: true),
                _cell('타겟 부위', '광배근'),
                _cell('구동 방식', '플레이트 로디드'),
              ],
            ),
            const HintCard('브랜드 단위 검색.', '이 브랜드·모델과 동일한 기구를 보유한 헬스장만 우선 추천합니다.', top: 16),
            const SizedBox(height: 16),
            Text('다른 브랜드로 검색', style: F.inter(size: 10.5, color: C.textFaint, ls: .06)),
            const SizedBox(height: 9),
            Wrap(spacing: 6, runSpacing: 6, children: [for (final b in ['뉴텍머신', '사이벡스', '라이프피트니스']) Tag(b, color: C.textDim, border: C.hairline, size: 11)]),
          ],
        );
      case 4:
        final list = matches;
        return ScreenFrame(
          header: StepTitle(eyebrow: '04 · Matching', title: '해머스트렝스 보유 헬스장 ${_matches.where((m) => m.has).length}곳', desc: loc == null ? '내 위치를 확인하고 있어요…' : (loc!.real ? '내 위치 기준 거리예요.' : '위치를 확인할 수 없어 강남역 기준 거리예요.')),
          footer: [GoldButton('지도에서 보기', onTap: () => go(5))],
          children: [
            ChipRow(items: _filters, selected: _filters[filter], solid: true, onSelect: (v) => setState(() => filter = _filters.indexOf(v))),
            const SizedBox(height: 16),
            for (final m in list) _gym(m),
            if (list.isEmpty) Padding(padding: const EdgeInsets.only(top: 20), child: Text('조건에 맞는 헬스장이 없어요.', style: F.inter(size: 11, color: C.textFaint))),
          ],
        );
      case 5:
        final g = gymOf(sel);
        return ScreenFrame(
          header: StepTitle(eyebrow: '05 · Map', title: '지도에서 위치 확인', desc: loc?.real == true ? '내 위치 기준으로 매칭된 헬스장입니다.' : '위치 권한이 없으면 강남역을 기준으로 보여드려요.'),
          footer: [
            GoldButton('이 헬스장 선택', onTap: () => go(6)),
            GoldButton('리스트로 돌아가기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => go(4)),
          ],
          children: [
            GymMap(
              key: ValueKey(here),
              me: here,
              meIsReal: loc?.real ?? false,
              pins: [for (final m in _matches) (id: m.gym, pos: gymOf(m).pos, label: '${m.gym.split(' ').first} · ${m.score}')],
              selectedId: selected,
              onSelect: (id) => setState(() => selected = id),
              showTiles: widget.mapTiles,
            ),
            Box(
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              border: C.hairline,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(g.name, style: F.inter(size: 13, w: FontWeight.w500)),
                const SizedBox(height: 3),
                Text('${distanceLabel(here, g.pos)} · ${sel.tag1} · ${sel.score} 매칭', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
              ]),
            ),
          ],
        );
      case 6:
        final g = gymOf(sel);
        final d = distanceLabel(here, g.pos);
        return ScreenFrame(
          header: const StepTitle(eyebrow: '06 · Confirmed', title: '헬스장이 선택됐습니다'),
          footer: [
            GoldButton('길찾기 시작 (카카오맵)', onTap: _directions),
            GoldButton('이 운동에 필요한 장비, 마켓에서 보기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => s.go(AppPage.market)),
          ],
          children: [
            ConfirmHero(g.name, sel.has ? '선택한 Hammer Strength 기구를 보유 중이며,\n현재 위치에서 ${d.split(' · ').first} 거리입니다.' : '같은 브랜드는 없지만 대체 기구를 보유 중이며,\n현재 위치에서 ${d.split(' · ').first} 거리입니다.'),
            DetailList([
              ('기구 매칭률', '${sel.score}%'),
              ('거리', d.split(' · ').first),
              ('예상 도보', d.contains('도보') ? d.split('도보 ').last : '도보 1시간 이상'),
              ('운영 시간', sel.hours),
            ]),
          ],
        );
      default:
        return ScreenFrame(
          header: StepTitle(eyebrow: '← 홈', onBack: () => s.go(AppPage.home), title: '운동기구 사진을 올려주세요', desc: '기구 전체가 보이게 촬영하면 인식 정확도가 올라갑니다.'),
          footer: [GoldButton('사진으로 계속하기', onTap: () => go(2))],
          children: [
            DropZone('사진 선택 또는 촬영', onTap: () => go(2)),
            const SizedBox(height: 16),
            Row(children: [for (final e in ['🏋️', '🚴', '🏃']) Padding(padding: const EdgeInsets.only(right: 10), child: EmojiTile(e, size: 60, font: 18))]),
            const HintCard('Tip.', '브랜드 로고나 각인이 보이면 모델까지 더 정확하게 인식됩니다.'),
          ],
        );
    }
  }

  Widget _cell(String k, String v, {bool gold = false}) => Container(
        color: C.hairlineSoft,
        padding: const EdgeInsets.all(0.5),
        child: Container(
          color: C.charcoal,
          padding: const EdgeInsets.all(13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(k.toUpperCase(), style: F.inter(size: 9.5, color: C.textFaint, ls: .1)),
            const SizedBox(height: 5),
            Text(v, style: F.inter(size: 13.5, color: gold ? C.goldBright : C.ivory)),
          ]),
        ),
      );

  Widget _gym(_Match m) => GestureDetector(
        onTap: () {
          setState(() => selected = m.gym);
          go(5);
        },
        child: Divided(
          top: true,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(border: Border.all(color: C.hairline)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${m.score}', style: F.gnum(size: 14)),
                Text('MATCH', style: F.inter(size: 7, color: C.textFaint, ls: .1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(m.gym, style: F.inter(size: 14, w: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('${distanceLabel(here, gymOf(m).pos)} · ${m.rating}', style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300)),
                const SizedBox(height: 9),
                Wrap(spacing: 6, children: [
                  Tag(m.tag1, color: m.has ? C.goldBright : C.textFaint, border: m.has ? C.goldDim : C.hairlineSoft),
                  Tag(m.tag2),
                ]),
              ]),
            ),
          ]),
        ),
      );
}

/// 분석 화면의 기구 라인 일러스트 (원본 viewBox 100x140)
class _MachinePainter extends CustomPainter {
  const _MachinePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 140);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xD9C9BFA0);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 60, 14), const Radius.circular(2)), p);
    canvas.drawLine(const Offset(50, 34), const Offset(50, 90), p);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(35, 90, 30, 10), const Radius.circular(1)), p);
    canvas.drawLine(const Offset(30, 100), const Offset(30, 120), p);
    canvas.drawLine(const Offset(70, 100), const Offset(70, 120), p);
    canvas.drawLine(const Offset(20, 120), const Offset(80, 120), p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
