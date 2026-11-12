import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 시그니처 기능: 기구 사진 → AI 브랜드·모델 인식 → 동일 기구 보유 헬스장 매칭 (6단계)
class GearFlow extends StatefulWidget {
  const GearFlow({super.key});
  @override
  State<GearFlow> createState() => _GearFlowState();
}

class _GearFlowState extends State<GearFlow> {
  int step = 1;
  int filter = 0;
  AppState get s => AppState.I;

  void go(int n) => setState(() => step = n);

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
        return ScreenFrame(
          header: const StepTitle(eyebrow: '04 · Matching', title: '해머스트렝스 보유 헬스장 3곳', desc: '동일 브랜드·모델 보유 여부 기준으로 정렬했습니다.'),
          footer: [GoldButton('지도에서 보기', onTap: () => go(5))],
          children: [
            ChipRow(items: const ['브랜드 일치만', '거리순', '평점순', '24시간'], selected: const ['브랜드 일치만', '거리순', '평점순', '24시간'][filter], solid: true, onSelect: (v) => setState(() => filter = const ['브랜드 일치만', '거리순', '평점순', '24시간'].indexOf(v))),
            const SizedBox(height: 16),
            _gym('98', '스틸핏 강남점', '450m · 도보 6분 · 4.8', 'Hammer Strength 동일모델', 'PT 가능', true),
            _gym('91', '코어짐 24 역삼', '820m · 도보 11분 · 4.6', 'Hammer Strength 동일라인', '24시간', true),
            _gym('42', '바디플랜 피트니스', '1.1km · 도보 15분 · 4.4', '타사 브랜드 대체품', '주차가능', false),
          ],
        );
      case 5:
        return ScreenFrame(
          header: const StepTitle(eyebrow: '05 · Map', title: '지도에서 위치 확인', desc: '내 위치 기준으로 매칭된 헬스장입니다.'),
          footer: [GoldButton('리스트로 돌아가기', ghost: true, onTap: () => go(4))],
          children: [_map()],
        );
      case 6:
        return ScreenFrame(
          header: const StepTitle(eyebrow: '06 · Confirmed', title: '헬스장이 선택됐습니다'),
          footer: [
            GoldButton('길찾기 시작', onTap: () => go(5)),
            GoldButton('이 운동에 필요한 장비, 마켓에서 보기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => s.go(AppPage.market)),
          ],
          children: const [
            ConfirmHero('스틸핏 강남점', '선택한 Hammer Strength 기구를 보유 중이며,\n현재 위치에서 도보 6분 거리입니다.'),
            DetailList([
              ('기구 매칭률', '98%'),
              ('거리', '450m'),
              ('예상 도보', '6분'),
              ('운영 시간', '06:00–24:00'),
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

  Widget _gym(String n, String name, String meta, String tag1, String tag2, bool has) => GestureDetector(
        onTap: () => go(5),
        child: Divided(
          top: true,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 2),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(border: Border.all(color: C.hairline)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(n, style: F.gnum(size: 14)),
                Text('MATCH', style: F.inter(size: 7, color: C.textFaint, ls: .1)),
              ]),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: F.inter(size: 14, w: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(meta, style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300)),
                const SizedBox(height: 9),
                Wrap(spacing: 6, children: [
                  Tag(tag1, color: has ? C.goldBright : C.textFaint, border: has ? C.goldDim : C.hairlineSoft),
                  Tag(tag2),
                ]),
              ]),
            ),
          ]),
        ),
      );

  Widget _map() {
    Widget pin(double x, double y, String label, {bool me = false, bool sel = false}) => Align(
          alignment: Alignment(x * 2 - 1, y * 2 - 1),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Transform.rotate(
              angle: .785,
              child: Container(
                width: sel ? 18 : 14,
                height: sel ? 18 : 14,
                decoration: BoxDecoration(
                  color: me ? C.ivory : (sel ? C.goldBright : C.goldDim),
                  border: Border.all(color: C.onyx),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(9), topRight: Radius.circular(9), bottomRight: Radius.circular(9)),
                ),
              ),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xE60A0A0B), border: Border.all(color: C.hairlineSoft)),
              child: Text(label, style: F.inter(size: 9, ls: .03)),
            ),
          ]),
        );
    return Container(
      height: 390,
      decoration: BoxDecoration(color: const Color(0xFF131109), border: Border.all(color: C.hairlineSoft)),
      child: Stack(children: [
        const Positioned.fill(child: CustomPaint(painter: _GridPainter())),
        pin(.52, .74, '나', me: true),
        pin(.34, .34, '스틸핏 강남 · 98', sel: true),
        pin(.70, .26, '코어짐24 · 91'),
        pin(.78, .58, '바디플랜 · 42'),
        Positioned(
          left: 16,
          right: 16,
          bottom: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xF015140F), border: Border.all(color: C.hairline)),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('스틸핏 강남점', style: F.inter(size: 13, w: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('450m · Hammer Strength 보유 · 98 매칭', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
                ]),
              ),
              GestureDetector(
                onTap: () => go(6),
                child: Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9), child: Text('선택', style: F.inter(size: 10.5, w: FontWeight.w600, color: C.ink, ls: .08))),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = C.goldA(.06);
    for (double x = 0; x < size.width; x += 34) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 1, size.height), p);
    }
    for (double y = 0; y < size.height; y += 34) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
