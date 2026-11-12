import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'coach_screen.dart';

class InbodyScreen extends StatelessWidget {
  const InbodyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = AppState.I;
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 홈', onBack: () => s.go(AppPage.home), title: '인바디 리포트', titleSize: 24, desc: '2026년 8월 10일 측정 · 12주 전 대비'),
      footer: [
        GoldButton('이 결과로 AI 코치 상담받기', upper: false, onTap: () {
          coachAsk('인바디 결과 상담해줘',
              '인바디 82점 · 근육형이에요! 골격근은 표준 이상인데 하체 근육이 표준 하단이라 상·하체 불균형이 보여요. 다음 4주간 하체 볼륨을 주당 4→10세트로 늘리고, 단백질을 하루 116g 이상 유지하면 균형이 빠르게 잡혀요 💪');
        }),
      ],
      children: [
        Box(
          border: C.goldDim,
          gradient: softGold(.12),
          padding: const EdgeInsets.all(18),
          child: Row(children: [
            Ring(
              size: 86,
              stroke: 5,
              border: false,
              segments: const [MapEntry(.82, C.goldBright)],
              track: C.goldA(.12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('82', style: F.gnum(size: 26)),
                Text('SCORE', style: F.inter(size: 7.5, color: C.textFaint, ls: .1)),
              ]),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('표준 이상 · 근육형', style: F.kr(size: 16)),
                const SizedBox(height: 6),
                Text.rich(TextSpan(style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300, h: 1.5), children: [
                  const TextSpan(text: '골격근이 표준을 웃돌고 체지방은 표준 범위예요. 지난 분기 대비 '),
                  TextSpan(text: '+6점', style: F.inter(size: 10.5, color: C.goldBright, w: FontWeight.w600)),
                  const TextSpan(text: ' 상승했어요.'),
                ])),
              ]),
            ),
          ]),
        ),
        const SectHead('체성분 분석', more: '표준 대비', top: 20),
        for (final r in const [
          // fill: 막대 길이, std: 표준선 위치 (0~1)
          (name: '체중', fill: .72, std: .78, value: '72.3', unit: 'kg'),
          (name: '골격근량', fill: .88, std: .66, value: '34.6', unit: 'kg'),
          (name: '체지방량', fill: .52, std: .60, value: '10.3', unit: 'kg'),
          (name: '체수분', fill: .80, std: .70, value: '45.2', unit: 'L'),
          (name: '단백질', fill: .84, std: .68, value: '12.4', unit: 'kg'),
        ])
          Divided(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(children: [
              SizedBox(width: 66, child: Text(r.name, style: F.inter(size: 11, color: C.textDim))),
              const SizedBox(width: 11),
              Expanded(
                child: LayoutBuilder(builder: (_, c) {
                  return SizedBox(
                    height: 15,
                    child: Stack(clipBehavior: Clip.none, children: [
                      Positioned(
                        top: 3,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 9,
                          decoration: BoxDecoration(color: C.panel, border: Border.all(color: C.hairlineSoft)),
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(widthFactor: r.fill, child: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.goldDim, C.goldBright])))),
                        ),
                      ),
                      // 표준선
                      Positioned(left: c.maxWidth * r.std, top: 0, bottom: 0, child: Container(width: 1, color: C.textFaint)),
                    ]),
                  );
                }),
              ),
              const SizedBox(width: 11),
              SizedBox(
                width: 74,
                child: Text.rich(
                  TextSpan(children: [TextSpan(text: r.value, style: F.serif(size: 14, w: FontWeight.w600)), TextSpan(text: r.unit, style: F.inter(size: 8.5, color: C.textFaint))]),
                  textAlign: TextAlign.right,
                ),
              ),
            ]),
          ),
        const SectHead('부위별 근육', more: '균형도', top: 20),
        Row(children: [
          const SizedBox(width: 90, child: Center(child: _RegionFigure())),
          const SizedBox(width: 18),
          Expanded(
            child: Column(children: [
              _region('왼팔 / 오른팔', '3.1 / 3.2', '균형', true),
              _region('몸통', '26.4', '이상', true),
              _region('왼다리 / 오른다리', '9.4 / 9.1', '표준', false),
            ]),
          ),
        ]),
        const HintCard('하체 근육이 표준 하단이에요.', '상·하체 균형을 위해 스쿼트·레그프레스 볼륨을 늘려보세요. (AI 코치도 같은 진단이에요)', top: 13),
        const SectHead('핵심 지표', top: 20),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 9,
          mainAxisSpacing: 9,
          childAspectRatio: 2.3,
          children: [
            _kv('BMI', '22.1', ' 정상'),
            _kv('체지방률', '14.2', ' %'),
            _kv('기초대사량', '1,680', ' kcal'),
            _kv('내장지방 레벨', '4', ' / 20 · 양호'),
          ],
        ),
      ],
    );
  }

  Widget _region(String k, String v, String lv, bool good) => Divided(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(child: Text(k, style: F.inter(size: 11, color: C.textDim))),
          Text.rich(TextSpan(children: [TextSpan(text: v, style: F.gnum(size: 13)), TextSpan(text: 'kg', style: F.inter(size: 11, color: C.textDim))])),
          const SizedBox(width: 8),
          Tag(lv, color: good ? C.cLow : C.cMid, border: (good ? C.cLow : C.cMid).op(.4), size: 8.5),
        ]),
      );

  Widget _kv(String k, String v, String u) => Box(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(k, style: F.inter(size: 9.5, color: C.textDim)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(children: [TextSpan(text: v, style: F.gnum(size: 21)), TextSpan(text: u, style: F.inter(size: 9, color: C.textFaint))])),
        ]),
      );
}

/// 부위별 근육 라인 일러스트 (원본 SVG 64x150)
class _RegionFigure extends StatelessWidget {
  const _RegionFigure();
  @override
  Widget build(BuildContext context) => SizedBox(width: 54, height: 126, child: CustomPaint(painter: _RegionPainter()));
}

class _RegionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 64, sy = size.height / 150;
    canvas.scale(sx, sy);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..color = C.gold
      ..strokeWidth = 1.4;
    final fill = Paint()..color = C.goldA(.15);
    canvas.drawCircle(const Offset(32, 12), 8, fill);
    canvas.drawCircle(const Offset(32, 12), 8, line);
    canvas.drawPath(parseSimplePath('M24 22 L16 27 L13 52', 1, 1), line);
    canvas.drawPath(parseSimplePath('M40 22 L48 27 L51 52', 1, 1), line);
    final torso = RRect.fromRectAndRadius(const Rect.fromLTWH(24, 22, 16, 34), const Radius.circular(3));
    canvas.drawRRect(torso, fill);
    canvas.drawRRect(torso, line);
    canvas.drawLine(const Offset(27, 58), const Offset(23, 108), line);
    canvas.drawLine(const Offset(37, 58), const Offset(41, 108), line);
    final arm = Paint()..color = C.goldA(.2);
    canvas.drawCircle(const Offset(20, 40), 3, arm);
    canvas.drawCircle(const Offset(20, 40), 3, line);
    canvas.drawCircle(const Offset(44, 40), 3, arm);
    canvas.drawCircle(const Offset(44, 40), 3, line);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
