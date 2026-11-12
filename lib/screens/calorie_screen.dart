import 'package:flutter/material.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

class CalorieScreen extends StatefulWidget {
  const CalorieScreen({super.key});
  @override
  State<CalorieScreen> createState() => _CalorieScreenState();
}

class _CalorieScreenState extends State<CalorieScreen> {
  int step = 1;
  int water = 5;
  AppState get s => AppState.I;

  void go(int n) => setState(() => step = n);

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: ValueKey(step), child: _screen());
  }

  Widget _screen() {
    switch (step) {
      case 2:
        return ScreenFrame(
          header: const StepTitle(eyebrow: '02 · Recognition · 03 · Nutrition', title: '음식을 분석하고 있어요', desc: '음식별 영역을 나눠 종류와 1인분 대비 양을 추정합니다.'),
          footer: [GoldButton('칼로리 결과 보기', onTap: () => go(3))],
          children: const [
            Viewfinder(child: SizedBox(width: 150, height: 150, child: CustomPaint(painter: _PlatePainter()))),
            AnalyzeLog(['이미지 전처리', '음식 영역 분할', '음식 종류 분류', '영양성분 · 칼로리 추정']),
          ],
        );
      case 3:
        return _result();
      case 4:
        return _today();
      default:
        return ScreenFrame(
          header: const StepTitle(eyebrow: '01 · Food Scan', title: '음식 사진을 올려주세요', desc: '한 접시를 위에서 담으면 음식 종류와 양을 더 정확히 추정합니다.'),
          footer: [GoldButton('사진으로 계산하기', onTap: () => go(2))],
          children: [
            DropZone('음식 사진 선택 또는 촬영', onTap: () => go(2)),
            const SizedBox(height: 16),
            Row(children: [for (final e in ['🍚', '🥗', '🍗']) Padding(padding: const EdgeInsets.only(right: 10), child: EmojiTile(e, size: 60, font: 18))]),
            const HintCard('Tip.', '밥·반찬이 한 프레임에 들어오면 각 음식을 따로 인식해 합산 칼로리를 계산합니다.'),
          ],
        );
    }
  }

  Widget _macro(String name, String g, double v, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 13),
        child: Column(children: [
          Row(children: [
            Container(width: 7, height: 7, color: c),
            const SizedBox(width: 6),
            Expanded(child: Text(name, style: F.inter(size: 11))),
            Text(g, style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300)),
          ]),
          const SizedBox(height: 6),
          Bar(v, color: c, track: C.goldA(.1)),
        ]),
      );

  Widget _food(String em, String n, String m, String kcal) => Divided(
        top: true,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 2),
        child: Row(children: [
          EmojiTile(em, size: 42, font: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(n, style: F.inter(size: 13, w: FontWeight.w500)),
              const SizedBox(height: 3),
              Text(m, style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(kcal, style: F.gnum(size: 16)),
            Text('kcal', style: F.inter(size: 9, color: C.textFaint)),
          ]),
        ]),
      );

  Widget _result() => ScreenFrame(
        header: const StepTitle(eyebrow: '03 · Result', title: '총 칼로리를 계산했어요', desc: '인식된 음식 4가지의 영양성분을 합산했습니다.'),
        footer: [GoldButton('오늘 식단에 기록', onTap: () => go(4)), GoldButton('다시 촬영하기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => go(1))],
        children: [
          Box(
            border: C.hairline,
            padding: const EdgeInsets.all(22),
            child: Row(children: [
              Ring(
                size: 92,
                stroke: 3,
                segments: const [MapEntry(.68, C.gold)],
                track: C.goldA(.14),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('642', style: F.serif(size: 26, w: FontWeight.w600, color: C.goldBright, h: 1)),
                  const SizedBox(height: 3),
                  Text('KCAL', style: F.inter(size: 8.5, color: C.textFaint, ls: .14)),
                ]),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('한식 · 한 상 차림 · 신뢰도 93%', style: F.inter(size: 9.5, color: C.gold, ls: .12, w: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text('제육덮밥 한 상', style: F.serif(size: 20)),
                  const SizedBox(height: 4),
                  Text('Spicy Pork Rice Set', style: F.inter(size: 11, color: C.textFaint).copyWith(fontStyle: FontStyle.italic)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 16),
          _macro('탄수화물', '78g · 49%', .49, C.carb),
          _macro('단백질', '34g · 21%', .21, C.protein),
          _macro('지방', '21g · 30%', .30, C.fat),
          const SectHead('인식된 음식', more: '수정', top: 20),
          _food('🍚', '흰쌀밥', '1공기 · 210g', '310'),
          _food('🥩', '제육볶음', '1인분 · 150g', '245'),
          _food('🥬', '상추·쌈채소', '1접시 · 60g', '15'),
          Container(decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))), child: _food('🍲', '된장국', '1그릇 · 200g', '72')),
          const HintCard('오늘 목표까지 858kcal.', '이 식사를 기록하면 목표 대비 자동으로 반영됩니다.', top: 16),
        ],
      );

  Widget _today() {
    Widget mt(String l, double v, String val, String goal, Color c) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [
            SizedBox(width: 58, child: Text(l, style: F.inter(size: 11, color: C.textDim))),
            const SizedBox(width: 11),
            Expanded(
              child: Container(
                height: 7,
                decoration: BoxDecoration(color: C.panel, border: Border.all(color: C.hairlineSoft)),
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(widthFactor: v, child: Container(color: c)),
              ),
            ),
            const SizedBox(width: 11),
            SizedBox(
              width: 78,
              child: Text.rich(TextSpan(children: [TextSpan(text: val, style: F.inter(size: 10.5)), TextSpan(text: ' / $goal', style: F.inter(size: 10.5, color: C.textDim))]), textAlign: TextAlign.right),
            ),
          ]),
        );
    Widget log(String t, String em, String n, String m, String kc) => Divided(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: Row(children: [
            SizedBox(width: 44, child: Text(t, style: F.inter(size: 9, color: C.gold, ls: .08))),
            const SizedBox(width: 12),
            SizedBox(width: 26, child: Text(em, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n, style: F.inter(size: 12)),
                const SizedBox(height: 2),
                Text(m, style: F.inter(size: 9.5, color: C.textFaint, w: FontWeight.w300)),
              ]),
            ),
            Text(kc, style: F.inter(size: 12, color: C.goldBright, w: FontWeight.w500)),
          ]),
        );
    Widget dm(String k, String v, Color c) => Expanded(
          child: Container(
            color: C.hairlineSoft,
            padding: const EdgeInsets.all(.5),
            child: Container(
              color: C.charcoal,
              padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 8),
              child: Column(children: [Text(k, style: F.inter(size: 9, color: C.textFaint, ls: .08)), const SizedBox(height: 5), Text(v, style: F.inter(size: 14, w: FontWeight.w500, color: c))]),
            ),
          ),
        );

    return ScreenFrame(
      header: const StepTitle(eyebrow: '04 · Today', title: '오늘의 식단', desc: '기록된 식사를 목표 칼로리와 비교해 보여줍니다.'),
      footer: [GoldButton('다른 음식 촬영하기', onTap: () => go(1)), GoldButton('단백질·건기식 마켓 보기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => s.go('market'))],
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 18),
          child: Center(
            child: Ring(
              size: 150,
              stroke: 5,
              segments: const [MapEntry(.62, C.goldBright), MapEntry(.12, C.goldDim)],
              track: C.goldA(.12),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('1,642', style: F.serif(size: 34, w: FontWeight.w600, color: C.goldBright, h: 1)),
                const SizedBox(height: 6),
                Text('/ 2,200 KCAL', style: F.inter(size: 9.5, color: C.textFaint, ls: .1)),
                const SizedBox(height: 3),
                Text('목표까지 558kcal', style: F.inter(size: 10, color: C.textDim)),
              ]),
            ),
          ),
        ),
        Row(children: [dm('탄수화물', '198g', C.carb), dm('단백질', '104g', C.protein), dm('지방', '52g', C.fat)]),
        Padding(padding: const EdgeInsets.only(top: 20, bottom: 6), child: Text('영양 목표 · 목표 대비', style: F.inter(size: 12, w: FontWeight.w500, ls: .04))),
        mt('단백질', .69, '104', '150g', const Color(0xFF8FB98A)),
        mt('탄수화물', .79, '198', '250g', C.goldBright),
        mt('지방', .79, '52', '66g', const Color(0xFFD8A05A)),
        Box(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Column(children: [
            Row(children: [
              Expanded(child: Text('💧 수분 섭취', style: F.inter(size: 11, color: C.textDim))),
              Text.rich(TextSpan(children: [
                TextSpan(text: '$water', style: F.gnum(size: 14)),
                TextSpan(text: ' / 8 컵 · ${(water * .25).toStringAsFixed(2)}L', style: F.inter(size: 11, color: C.textDim)),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              for (int i = 0; i < 8; i++)
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => water = (water == i + 1) ? i : i + 1),
                    child: Container(
                      height: 30,
                      margin: EdgeInsets.only(right: i < 7 ? 7 : 0),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: i < water ? const Color(0x8078AAD2) : C.hairlineSoft),
                        gradient: i < water ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x385A96C8), Color(0x0F5A96C8)]) : null,
                      ),
                      child: Text(i < water ? '💧' : '', style: const TextStyle(fontSize: 14)),
                    ),
                  ),
                ),
            ]),
          ]),
        ),
        Box(
          margin: const EdgeInsets.only(top: 16),
          border: C.goldDim,
          gradient: softGold(.10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('🤖 남은 558kcal, 이렇게 채워보세요', style: F.inter(size: 11, color: C.goldBright, w: FontWeight.w500)),
            const SizedBox(height: 8),
            Text.rich(TextSpan(style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300, h: 1.55), children: [
              TextSpan(text: '닭가슴살 샐러드 + 고구마 150g', style: F.inter(size: 11.5, w: FontWeight.w500)),
              const TextSpan(text: '을 추천해요. 단백질 46g을 더 채워 오늘 목표(150g)에 딱 맞고, 저지방이라 칼로리 부담도 적어요. 배달·밀프렙으로 바로 주문할 수 있어요.'),
            ])),
          ]),
        ),
        Padding(padding: const EdgeInsets.only(top: 20, bottom: 6), child: Text('식사 기록', style: F.inter(size: 12, w: FontWeight.w500, ls: .04))),
        log('아침', '🥣', '오트밀 · 바나나', '2가지 음식', '420'),
        log('점심', '🍚', '제육덮밥 한 상', '4가지 음식 · 방금 기록', '642'),
        log('간식', '🥤', '단백질 쉐이크', '1가지 음식', '180'),
        log('저녁', '🍗', '닭가슴살 샐러드', '3가지 음식', '400'),
      ],
    );
  }
}

/// 분석 화면의 접시 라인 일러스트 (원본 viewBox 120x120)
class _PlatePainter extends CustomPainter {
  const _PlatePainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 120, size.height / 120);
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = const Color(0xD9C9BFA0);
    canvas.drawCircle(const Offset(60, 60), 40, p);
    canvas.drawCircle(const Offset(60, 60), 27, p);
    final arc = Path()
      ..moveTo(44, 52)
      ..quadraticBezierTo(52, 43, 60, 52);
    canvas.drawPath(arc, p);
    canvas.drawCircle(const Offset(50, 66), 3, p);
    canvas.drawCircle(const Offset(68, 64), 4, p);
    canvas.drawCircle(const Offset(60, 72), 2.5, p);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
