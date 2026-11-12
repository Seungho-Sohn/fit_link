import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

/* ================= 1RM · 원판 계산기 ================= */
class StrengthTools extends StatefulWidget {
  const StrengthTools({super.key});
  @override
  State<StrengthTools> createState() => _StrengthToolsState();
}

class _StrengthToolsState extends State<StrengthTools> {
  final w = TextEditingController(text: '100');
  final r = TextEditingController(text: '5');

  @override
  void dispose() {
    w.dispose();
    r.dispose();
    super.dispose();
  }

  double rnd(double x, double s) => (x / s).round() * s;

  void step(TextEditingController c, double d, bool reps) {
    var v = (double.tryParse(c.text) ?? 0) + d;
    if (reps) v = v.clamp(1, 20).toDouble();
    if (v < 0) v = 0;
    setState(() => c.text = v % 1 == 0 ? v.toInt().toString() : v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final wt = double.tryParse(w.text) ?? 0;
    var reps = int.tryParse(r.text) ?? 1;
    reps = math.max(1, math.min(reps, 20));
    final orm = reps == 1 ? wt : wt * (1 + reps / 30); // Epley 공식
    final w75 = rnd(orm * .75, 2.5);

    // 원판 계산
    final perSide = (w75 - 20) / 2;
    final plates = <double>[];
    double rem = perSide;
    for (final p in [25.0, 20.0, 15.0, 10.0, 5.0, 2.5, 1.25]) {
      while (rem >= p - .001) {
        plates.add(p);
        rem = double.parse((rem - p).toStringAsFixed(3));
      }
    }
    String pf(double p) => p % 1 == 0 ? p.toInt().toString() : p.toString();

    Widget field(String label, TextEditingController c, double d, bool isReps) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: F.inter(size: 9.5, color: C.textDim, w: FontWeight.w300)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(border: Border.all(color: C.hairlineSoft)),
              child: Row(children: [
                _stepBtn('−', () => step(c, -d, isReps)),
                Expanded(
                  child: TextField(
                    controller: c,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: F.serif(size: 19, w: FontWeight.w600),
                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.symmetric(vertical: 10)),
                  ),
                ),
                _stepBtn('+', () => step(c, d, isReps)),
              ]),
            ),
          ]),
        );
    Widget zone(String k, String p, double v) => Expanded(
          child: Box(
            margin: const EdgeInsets.symmetric(horizontal: 4.5),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 5),
            child: Column(children: [
              Text(k, style: F.inter(size: 9.5, color: C.textDim)),
              const SizedBox(height: 1),
              Text(p, style: F.inter(size: 8, color: C.textFaint)),
              const SizedBox(height: 5),
              Text.rich(TextSpan(children: [TextSpan(text: v.toStringAsFixed(1), style: F.serif(size: 16, w: FontWeight.w600)), TextSpan(text: 'kg', style: F.inter(size: 8, color: C.textDim))])),
            ]),
          ),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('🏋️ 1RM · 원판 계산기', 'Strength Tools', '든 무게와 횟수로 최대 중량(1RM)을 계산하고, 바벨에 낄 원판까지 알려줘요.'),
      Box(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [field('든 무게 (kg)', w, 2.5, false), const SizedBox(width: 10), field('반복 횟수', r, 1, true)]),
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.only(top: 15),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Expanded(child: Text('추정 1RM (최대 중량)', style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300))),
              Text.rich(TextSpan(children: [TextSpan(text: rnd(orm, .5).toStringAsFixed(1), style: F.gnum(size: 30)), TextSpan(text: ' kg', style: F.inter(size: 12, color: C.textDim))])),
            ]),
          ),
          const SizedBox(height: 14),
          Row(children: [zone('근력', '1~3RM · 90%', rnd(orm * .9, 2.5)), zone('근비대', '8~12RM · 75%', w75), zone('근지구력', '15RM+ · 65%', rnd(orm * .65, 2.5))]),
          Container(
            margin: const EdgeInsets.only(top: 16),
            padding: const EdgeInsets.only(top: 15),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text('원판 세팅 · 근비대 세트', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300))),
                Text.rich(TextSpan(children: [TextSpan(text: w75.toStringAsFixed(1), style: F.gnum(size: 14)), TextSpan(text: ' kg', style: F.inter(size: 10.5, color: C.textDim))])),
              ]),
              const SizedBox(height: 12),
              Wrap(spacing: 4, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(perSide <= 0 ? '빈 봉 (20kg)' : '바 20kg +', style: F.inter(size: 9, color: C.textFaint)),
                if (perSide > 0)
                  for (final p in plates)
                    Container(
                      constraints: const BoxConstraints(minWidth: 26),
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 7),
                      decoration: BoxDecoration(color: C.goldA(.07), border: Border.all(color: C.goldDim)),
                      child: Text(pf(p), textAlign: TextAlign.center, style: F.serif(size: 11, w: FontWeight.w600, color: C.goldBright)),
                    ),
              ]),
              const SizedBox(height: 10),
              Text(
                perSide <= 0
                    ? '바벨 무게보다 가벼워 원판이 필요 없어요.'
                    : '한쪽에 ${plates.isEmpty ? '없음' : '${plates.map(pf).join(' · ')} kg'} (양쪽 동일)${rem > .01 ? ' · 오차 ${rem.toStringAsFixed(2)}kg' : ''}',
                style: F.inter(size: 9.5, color: C.textFaint, w: FontWeight.w300),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }

  Widget _stepBtn(String t, VoidCallback f) => GestureDetector(
        onTap: f,
        child: SizedBox(width: 36, height: 42, child: Center(child: Text(t, style: F.inter(size: 18, color: C.goldBright)))),
      );
}
