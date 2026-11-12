import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/* ================= 근육 밸런스 (머슬맵) ================= */
class MuscleMap extends StatelessWidget {
  const MuscleMap({super.key});
  @override
  Widget build(BuildContext context) {
    const items = [
      ['가슴', 1.0, '16세트', '충분', 'hi'],
      ['등', .88, '14세트', '충분', 'hi'],
      ['팔', .75, '12세트', '충분', 'hi'],
      ['어깨', .56, '9세트', '보통', 'mid'],
      ['복근', .44, '7세트', '보통', 'mid'],
      ['하체', .25, '4세트', '부족', 'low'],
    ];
    Color barC(String k) => k == 'hi' ? C.goldBright : (k == 'mid' ? C.goldDim : C.cHigh);
    Color stC(String k) => k == 'hi' ? C.goldBright : (k == 'mid' ? C.textDim : C.cHigh);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('🗺️ 근육 밸런스', 'Muscle Map', '이번 주 부위별 볼륨이에요. 덜 자극한 부위를 채워 균형 있게 키워요.'),
      Box(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        child: Row(children: [
          SizedBox(width: 104, height: 196, child: CustomPaint(painter: _MusclePainter())),
          const SizedBox(width: 14),
          Expanded(
            child: Column(children: [
              for (final it in items)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(children: [
                    SizedBox(width: 30, child: Text(it[0] as String, style: F.inter(size: 11))),
                    const SizedBox(width: 8),
                    Expanded(child: Bar(it[1] as double, height: 6, color: barC(it[4] as String))),
                    const SizedBox(width: 8),
                    SizedBox(width: 38, child: Text(it[2] as String, textAlign: TextAlign.right, style: F.inter(size: 9.5, color: C.textDim))),
                    SizedBox(width: 30, child: Text(it[3] as String, textAlign: TextAlign.right, style: F.inter(size: 8.5, color: stC(it[4] as String)))),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 11),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final l in const [
          ['충분', C.goldBright],
          ['보통', C.goldDim],
          ['부족', Color(0xFF4A443A)]
        ]) ...[
          Container(width: 8, height: 8, color: l[1] as Color),
          const SizedBox(width: 4),
          Text(l[0] as String, style: F.inter(size: 8.5, color: C.textFaint)),
          const SizedBox(width: 12),
        ],
      ]),
      Box(
        margin: const EdgeInsets.only(top: 11),
        border: C.goldDim,
        gradient: softGold(.08),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Text.rich(TextSpan(style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300, h: 1.5), children: [
          const TextSpan(text: '⚠️ '),
          TextSpan(text: '하체 볼륨이 부족해요.', style: F.inter(size: 10.5, color: C.goldBright, w: FontWeight.w500)),
          const TextSpan(text: ' 주간 권장 대비 절반 수준이에요. 다음 운동에 스쿼트·레그프레스를 넣어 균형을 맞춰보세요.'),
        ])),
      ),
    ]);
  }
}

class _MusclePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 원본 viewBox 0 0 120 200 → 높이 196 기준으로 축소, 가로 중앙 정렬
    final sc = size.height / 200;
    canvas.translate((size.width - 120 * sc) / 2, 0);
    canvas.scale(sc);
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..color = C.onyx
      ..strokeWidth = 1;
    Paint fill(Color c) => Paint()..color = c;
    const hi = C.goldBright, mid = C.goldDim, low = Color(0xFF4A443A);
    void ell(double cx, double cy, double rx, double ry, Color c) {
      final r = Rect.fromCenter(center: Offset(cx, cy), width: rx * 2, height: ry * 2);
      canvas.drawOval(r, fill(c));
      canvas.drawOval(r, stroke);
    }

    canvas.drawCircle(const Offset(60, 16), 10, fill(const Color(0xFF3A352D)));
    canvas.drawCircle(const Offset(60, 16), 10, stroke);
    ell(38, 40, 12, 8, mid);
    ell(82, 40, 12, 8, mid);
    ell(50, 52, 9, 8, hi);
    ell(70, 52, 9, 8, hi);
    ell(28, 64, 6.5, 14, hi);
    ell(92, 64, 6.5, 14, hi);
    ell(25, 90, 5.5, 12, hi);
    ell(95, 90, 5.5, 12, hi);
    final core = RRect.fromRectAndRadius(const Rect.fromLTWH(51, 62, 18, 34), const Radius.circular(4));
    canvas.drawRRect(core, fill(mid));
    canvas.drawRRect(core, stroke);
    ell(50, 126, 9, 24, low);
    ell(70, 126, 9, 24, low);
    ell(50, 170, 6.5, 18, low);
    ell(70, 170, 6.5, 18, low);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
