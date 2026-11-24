import 'dart:async';
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

AppState get _s => AppState.I;

/* ================= 운동 기록 · 자동 휴식 타이머 ================= */
class _SetRow {
  final String prev;
  final TextEditingController kg, reps;
  bool done;
  _SetRow(this.prev, double k, int r, this.done)
      : kg = TextEditingController(text: k % 1 == 0 ? k.toInt().toString() : k.toString()),
        reps = TextEditingController(text: '$r');
}

class WorkoutLogSection extends StatefulWidget {
  const WorkoutLogSection({super.key});
  @override
  State<WorkoutLogSection> createState() => _WorkoutLogSectionState();
}

class _WorkoutLogSectionState extends State<WorkoutLogSection> {
  static const prevBest = 62.5;
  final rows = <_SetRow>[
    _SetRow('60kg × 12', 60, 12, true),
    _SetRow('60kg × 12', 60, 11, true),
    _SetRow('62.5kg × 10', 65, 10, false),
  ];
  final Set<int> prRows = {};
  Timer? timer;
  int restLeft = 0, restTotal = 90;
  bool restOn = false;

  @override
  void dispose() {
    timer?.cancel();
    for (final r in rows) {
      r.kg.dispose();
      r.reps.dispose();
    }
    super.dispose();
  }

  void toggle(int i) {
    final r = rows[i];
    setState(() => r.done = !r.done);
    if (r.done) {
      final kg = double.tryParse(r.kg.text) ?? 0;
      if (kg > prevBest) {
        _s.toast('🎉 랫풀다운 신기록! ${r.kg.text}kg');
        setState(() => prRows.add(i));
      }
      startRest(90);
    } else {
      skipRest();
    }
  }

  void startRest(int sec) {
    timer?.cancel();
    setState(() {
      restTotal = sec;
      restLeft = sec;
      restOn = true;
    });
    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => restLeft--);
      if (restLeft <= 0) {
        t.cancel();
        _s.toast('휴식 끝! 다음 세트 시작하세요 💪');
        Future.delayed(const Duration(milliseconds: 900), () {
          if (mounted) setState(() => restOn = false);
        });
      }
    });
  }

  void skipRest() {
    timer?.cancel();
    setState(() => restOn = false);
  }

  void addSet() {
    final last = rows.isNotEmpty ? double.tryParse(rows.last.kg.text) ?? 60.0 : 60.0;
    setState(() => rows.add(_SetRow('–', last, 10, false)));
  }

  @override
  Widget build(BuildContext context) {
    final mm = restLeft ~/ 60, ss = (restLeft % 60).toString().padLeft(2, '0');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('📋 운동 기록 · 자동 휴식 타이머', 'Workout Log', '세트를 체크하면 휴식 타이머가 자동으로 시작돼요. 이전 기록·PR도 함께 봐요.'),
      Box(
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('랫풀다운 · Hammer Strength', style: F.inter(size: 14, w: FontWeight.w500))),
            Text('이전 최고 62.5kg', style: F.inter(size: 9.5, color: C.goldBright)),
          ]),
          if (restOn)
            Box(
              margin: const EdgeInsets.only(top: 13),
              border: C.goldDim,
              gradient: softGold(.12),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
              child: Column(children: [
                Row(children: [
                  Text('휴식  ', style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                  Expanded(child: Text('$mm:$ss', style: F.serif(size: 19, w: FontWeight.w600, color: C.goldBright, ls: .04))),
                  LineButton('건너뛰기', done: true, size: 9.5, onTap: skipRest),
                ]),
                const SizedBox(height: 10),
                Bar(restTotal == 0 ? 0.0 : restLeft / restTotal, height: 4),
              ]),
            ),
          const SizedBox(height: 15),
          _gridRow(
            [
              Text('SET', textAlign: TextAlign.center, style: F.inter(size: 8.5, color: C.textFaint, ls: .05)),
              Text('이전', style: F.inter(size: 8.5, color: C.textFaint, ls: .05)),
              Text('KG', textAlign: TextAlign.center, style: F.inter(size: 8.5, color: C.textFaint, ls: .05)),
              Text('회', textAlign: TextAlign.center, style: F.inter(size: 8.5, color: C.textFaint, ls: .05)),
              Text('✓', textAlign: TextAlign.center, style: F.inter(size: 8.5, color: C.textFaint)),
            ],
            pad: const EdgeInsets.only(bottom: 9),
          ),
          for (int i = 0; i < rows.length; i++)
            _gridRow([
              Text('${i + 1}', textAlign: TextAlign.center, style: F.serif(size: 14, w: FontWeight.w600, color: rows[i].done ? C.goldBright : C.textDim)),
              prRows.contains(i) ? Text('PR 갱신', style: F.inter(size: 10, color: C.goldBright)) : Text(rows[i].prev, style: F.inter(size: 10, color: C.textFaint)),
              _numField(rows[i].kg, rows[i].done),
              _numField(rows[i].reps, rows[i].done),
              Center(
                child: GestureDetector(
                  onTap: () => toggle(i),
                  child: Container(
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: rows[i].done ? C.gold : null, border: Border.all(color: rows[i].done ? C.gold : C.hairlineSoft)),
                    child: Text(rows[i].done ? '✓' : '○', style: F.inter(size: 13, color: rows[i].done ? C.ink : C.textFaint)),
                  ),
                ),
              ),
            ], pad: const EdgeInsets.symmetric(vertical: 9)),
          GestureDetector(
            onTap: addSet,
            child: Container(
              margin: const EdgeInsets.only(top: 13),
              padding: const EdgeInsets.all(11),
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(border: Border.all(color: C.hairline)),
              child: Text('+ 세트 추가', style: F.inter(size: 11, color: C.goldBright)),
            ),
          ),
        ]),
      ),
    ]);
  }

  // grid-template-columns: 30px 1fr 58px 46px 34px
  Widget _gridRow(List<Widget> c, {required EdgeInsets pad}) => Container(
        padding: pad,
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
        child: Row(children: [
          SizedBox(width: 30, child: c[0]),
          const SizedBox(width: 8),
          Expanded(child: c[1]),
          const SizedBox(width: 8),
          SizedBox(width: 58, child: c[2]),
          const SizedBox(width: 8),
          SizedBox(width: 46, child: c[3]),
          const SizedBox(width: 8),
          SizedBox(width: 34, child: c[4]),
        ]),
      );

  Widget _numField(TextEditingController c, bool done) => TextField(
        controller: c,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        style: F.serif(size: 14, w: FontWeight.w600, color: done ? C.textDim : C.ivory),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: done ? Colors.transparent : C.hairlineSoft)),
          focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.gold)),
        ),
      );
}
