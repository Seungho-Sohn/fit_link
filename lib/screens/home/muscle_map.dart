import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/* ================= 근육 밸런스 (머슬맵) ================= */
enum _Volume { enough, normal, low }

class MuscleMap extends StatelessWidget {
  const MuscleMap({super.key});
  @override
  Widget build(BuildContext context) {
    const items = [
      (part: '가슴', ratio: 1.0, sets: '16세트', label: '충분', level: _Volume.enough),
      (part: '등', ratio: .88, sets: '14세트', label: '충분', level: _Volume.enough),
      (part: '팔', ratio: .75, sets: '12세트', label: '충분', level: _Volume.enough),
      (part: '어깨', ratio: .56, sets: '9세트', label: '보통', level: _Volume.normal),
      (part: '복근', ratio: .44, sets: '7세트', label: '보통', level: _Volume.normal),
      (part: '하체', ratio: .25, sets: '4세트', label: '부족', level: _Volume.low),
    ];
    Color barC(_Volume v) => switch (v) { _Volume.enough => C.goldBright, _Volume.normal => C.goldDim, _Volume.low => C.cHigh };
    Color stC(_Volume v) => switch (v) { _Volume.enough => C.goldBright, _Volume.normal => C.textDim, _Volume.low => C.cHigh };
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
                    SizedBox(width: 30, child: Text(it.part, style: F.inter(size: 11))),
                    const SizedBox(width: 8),
                    Expanded(child: Bar(it.ratio, height: 6, color: barC(it.level))),
                    const SizedBox(width: 8),
                    SizedBox(width: 38, child: Text(it.sets, textAlign: TextAlign.right, style: F.inter(size: 9.5, color: C.textDim))),
                    SizedBox(width: 30, child: Text(it.label, textAlign: TextAlign.right, style: F.inter(size: 8.5, color: stC(it.level)))),
                  ]),
                ),
            ]),
          ),
        ]),
      ),
      const SizedBox(height: 11),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (final l in const [
          (label: '충분', color: C.goldBright),
          (label: '보통', color: C.goldDim),
          (label: '부족', color: Color(0xFF4A443A)),
        ]) ...[
          Container(width: 8, height: 8, color: l.color),
          const SizedBox(width: 4),
          Text(l.label, style: F.inter(size: 8.5, color: C.textFaint)),
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
