import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

/* ================= 오늘의 헬스 소식 (날짜별 로테이션) ================= */
class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final doy = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final idx = doy % news.length;
    final feat = news[idx];
    String fmt(DateTime d) => '${d.month}월 ${d.day}일';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Row(children: [
          const LiveDot(size: 6),
          const SizedBox(width: 7),
          Expanded(child: Text('오늘의 헬스 소식', style: F.inter(size: 12, w: FontWeight.w500))),
          Text('${fmt(now)} · 매일 업데이트', style: F.inter(size: 9.5, color: C.textFaint)),
        ]),
      ),
      GestureDetector(
        onTap: () => _s.toast('전체 기사는 개발 버전에서 연결돼요'),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: C.goldDim), gradient: softGold(.10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(color: C.panel, border: Border(bottom: BorderSide(color: C.hairlineSoft))),
              child: Stack(children: [
                Center(child: Text(feat[1], style: const TextStyle(fontSize: 44))),
                Positioned(top: 0, left: 0, child: Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), child: Text(feat[0], style: F.inter(size: 8.5, w: FontWeight.w700, color: C.ink, ls: .08)))),
                Positioned(top: 9, right: 11, child: Text('TODAY', style: F.inter(size: 9, color: C.textDim, ls: .05))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(feat[2], style: F.inter(size: 14.5, w: FontWeight.w500, h: 1.4)),
                const SizedBox(height: 8),
                Text(feat[3], style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300, h: 1.6)),
                const SizedBox(height: 11),
                Text('자세히 보기 ›', style: F.inter(size: 10, color: C.goldBright, ls: .06)),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      for (int k = 1; k <= 3; k++) _pastRow(now.subtract(Duration(days: k)), news[((idx - k) % news.length + news.length) % news.length], fmt),
    ]);
  }

  Widget _pastRow(DateTime d, List<String> n, String Function(DateTime) fmt) => GestureDetector(
        onTap: () => _s.toast('지난 소식도 다시 볼 수 있어요'),
        child: Divided(
          top: true,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: Row(children: [
            EmojiTile(n[1], size: 38, font: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n[0], style: F.inter(size: 8.5, color: C.gold, ls: .1)),
                const SizedBox(height: 3),
                Text(n[2], style: F.inter(size: 11.5, h: 1.4)),
              ]),
            ),
            Text(fmt(d), style: F.inter(size: 9, color: C.textFaint)),
          ]),
        ),
      );
}

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

/* ================= 이번 주 운동 막대 ================= */
class WeekBars extends StatelessWidget {
  const WeekBars({super.key});
  @override
  Widget build(BuildContext context) {
    const d = [
      ['월', .55, true], ['화', .80, true], ['수', .12, false], ['목', .68, true], ['금', .90, true], ['토', .60, true], ['일', .08, false]
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(children: [
        Row(children: [
          Expanded(child: Text('이번 주 운동', style: F.inter(size: 12, w: FontWeight.w500))),
          Text('5 / 7일 달성', style: F.inter(size: 10, color: C.textFaint)),
        ]),
        const SizedBox(height: 14),
        SizedBox(
          height: 78,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < d.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: d[i][1] as double,
                          child: Container(
                            decoration: BoxDecoration(
                              color: (d[i][2] as bool) ? null : C.goldA(.15),
                              gradient: (d[i][2] as bool) ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.goldBright, C.goldDim]) : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(d[i][0] as String, style: F.inter(size: 8.5, color: i == 5 ? C.goldBright : C.textFaint)),
                  ]),
                ),
              ),
          ]),
        ),
      ]),
    );
  }
}

/* ================= 내 운동 기록 (볼륨 · PR) ================= */
class ProgressSection extends StatelessWidget {
  const ProgressSection({super.key});
  @override
  Widget build(BuildContext context) {
    const vols = [.38, .52, .44, .66, .58, .72, .64, .88];
    Widget pr(String k, String v, String d, Color dc, {bool isNew = false}) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4.5),
            padding: const EdgeInsets.fromLTRB(8, 13, 8, 12),
            decoration: BoxDecoration(border: Border.all(color: isNew ? C.goldDim : C.hairlineSoft), gradient: isNew ? softGold(.10) : null),
            child: Stack(clipBehavior: Clip.none, children: [
              Center(
                child: Column(children: [
                  Text(k, style: F.inter(size: 10, color: C.textDim)),
                  const SizedBox(height: 5),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: v, style: F.serif(size: 21, w: FontWeight.w600)),
                    TextSpan(text: 'kg', style: F.inter(size: 9.5, color: C.textDim)),
                  ])),
                  const SizedBox(height: 5),
                  Text(d, style: F.inter(size: 9, color: dc, w: FontWeight.w500)),
                ]),
              ),
              if (isNew)
                Positioned(top: -13, right: -8, child: Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), child: Text('PR', style: F.inter(size: 7, w: FontWeight.w700, color: C.ink)))),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('📈 내 운동 기록', 'My Progress', '개인 최고 기록과 볼륨 변화를 한눈에. 성장이 보이면 더 오게 돼요.'),
      Box(
        margin: const EdgeInsets.only(bottom: 11),
        padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
        child: Column(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('이번 주 총 볼륨', style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300)),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '12,450', style: F.gnum(size: 27)),
                  TextSpan(text: ' kg', style: F.inter(size: 11, color: C.textDim)),
                ])),
              ]),
            ),
            Text.rich(TextSpan(children: [
              TextSpan(text: '▲ 8.2% ', style: F.inter(size: 10.5, color: C.cLow, w: FontWeight.w500)),
              TextSpan(text: '지난주 대비', style: F.inter(size: 10.5, color: C.textFaint, w: FontWeight.w300)),
            ])),
          ]),
          const SizedBox(height: 15),
          SizedBox(
            height: 50,
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              for (int i = 0; i < vols.length; i++)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 50 * vols[i],
                    decoration: BoxDecoration(
                      color: i == vols.length - 1 ? null : C.goldA(.16),
                      gradient: i == vols.length - 1 ? const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.goldBright, C.goldDim]) : null,
                    ),
                  ),
                ),
            ]),
          ),
          const SizedBox(height: 6),
          Row(children: [
            Text('7주전', style: F.inter(size: 8, color: C.textFaint)),
            const Spacer(),
            Text('이번주', style: F.inter(size: 8, color: C.textFaint)),
          ]),
        ]),
      ),
      Row(children: [
        pr('스쿼트', '140', '▲ 5kg', C.cLow),
        pr('벤치프레스', '100', '유지', C.textFaint),
        pr('데드리프트', '185', '▲ 10kg', C.cLow, isNew: true),
      ]),
      Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.5),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: const BoxDecoration(border: Border(left: BorderSide(color: C.hairlineSoft), right: BorderSide(color: C.hairlineSoft), bottom: BorderSide(color: C.hairlineSoft))),
        child: Row(children: [
          Expanded(child: Text('3대 합계', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300))),
          Text.rich(TextSpan(children: [
            TextSpan(text: '425', style: F.gnum(size: 15)),
            TextSpan(text: ' kg · ', style: F.inter(size: 11)),
            TextSpan(text: '상위 12%', style: F.inter(size: 11, color: C.goldBright)),
          ])),
        ]),
      ),
    ]);
  }
}

/* ================= 눈바디 · 바디 변화 ================= */
class BodySection extends StatelessWidget {
  const BodySection({super.key});
  @override
  Widget build(BuildContext context) {
    Widget shot(bool after) => Expanded(
          child: Container(
            margin: EdgeInsets.only(right: after ? 0 : 10),
            decoration: BoxDecoration(border: Border.all(color: C.hairlineSoft)),
            child: Column(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
                decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
                child: Row(children: [
                  Expanded(child: Text(after ? '오늘 · 8월 10일' : '시작 · 5월 18일', style: F.inter(size: 9.5, color: C.textDim))),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: after ? '72.3' : '76.5', style: F.serif(size: 13, w: FontWeight.w600, color: after ? C.goldBright : C.ivory)),
                    TextSpan(text: ' kg', style: F.inter(size: 9, color: C.textFaint)),
                  ])),
                ]),
              ),
              Container(
                height: 158,
                decoration: BoxDecoration(color: after ? null : C.panel, gradient: after ? softGold(.13) : null),
                child: Stack(children: [
                  Center(child: BodySilhouette(after: after)),
                  Positioned(
                    top: 9,
                    left: 9,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(color: after ? C.gold : null, border: Border.all(color: after ? C.gold : C.hairlineSoft)),
                      child: Text(after ? 'AFTER' : 'BEFORE', style: F.inter(size: 8, w: FontWeight.w700, ls: .1, color: after ? C.ink : C.textDim)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
        );
    Widget bm(String k, String v, String u, String d) => Expanded(
          child: Box(
            margin: const EdgeInsets.symmetric(horizontal: 4.5),
            padding: const EdgeInsets.fromLTRB(6, 11, 6, 10),
            child: Column(children: [
              Text(k, style: F.inter(size: 9.5, color: C.textDim)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [TextSpan(text: v, style: F.serif(size: 18, w: FontWeight.w600)), TextSpan(text: u, style: F.inter(size: 8.5, color: C.textDim))])),
              const SizedBox(height: 5),
              Text(d, style: F.inter(size: 9, color: C.cLow, w: FontWeight.w500)),
            ]),
          ),
        );
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('🪞 눈바디 · 바디 변화', 'Body Progress', '같은 각도로 찍은 사진과 체성분으로 몸의 변화를 눈으로 확인해요.'),
      Row(children: [shot(false), shot(true)]),
      const SizedBox(height: 10),
      Row(children: [bm('체중', '72.3', 'kg', '▼ 4.2'), bm('체지방률', '14.2', '%', '▼ 3.1%p'), bm('골격근량', '34.6', 'kg', '▲ 1.8')]),
      const SizedBox(height: 11),
      Text.rich(TextSpan(style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300), children: [
        const TextSpan(text: '🤖 '),
        TextSpan(text: '눈바디 AI', style: F.inter(size: 10, color: C.goldBright, w: FontWeight.w500)),
        const TextSpan(text: '가 촬영 각도·조명을 자동 정렬해 12주간 변화를 비교해요.'),
      ])),
      GestureDetector(
        onTap: () => _s.go('inbody'),
        child: Container(
          margin: const EdgeInsets.only(top: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(border: Border.all(color: C.hairline)),
          child: Row(children: [
            Expanded(child: Text('📋 인바디 상세 리포트 보기 · 체성분·부위별 근육·기초대사량', style: F.inter(size: 10.5, color: C.goldBright))),
            Text('›', style: F.inter(size: 12, color: C.goldBright)),
          ]),
        ),
      ),
    ]);
  }
}

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

/* ================= PT 트레이너 매칭 + 예약 시트 ================= */
class TrainerSection extends StatelessWidget {
  const TrainerSection({super.key});

  void openBook(BuildContext context, Trainer t) {
    int day = 0;
    String? slot;
    showGoldSheet(
      context,
      title: '${t.nm} 트레이너 예약',
      body: (ctx, setS) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Avatar(t.av, size: 46, border: C.goldDim),
          const SizedBox(width: 11),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${t.nm} 트레이너', style: F.kr(size: 13)),
            const SizedBox(height: 3),
            Text('★ ${t.rate} · ${t.gym} · 회당 ${t.price}원', style: F.inter(size: 9.5, color: C.goldBright)),
          ]),
        ]),
        const SizedBox(height: 16),
        Text('날짜 선택', style: F.inter(size: 10, color: C.textDim, ls: .05)),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i = 0; i < bkDays.length; i++)
              GestureDetector(
                onTap: () => setS(() {
                  day = i;
                  slot = null;
                }),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                  decoration: BoxDecoration(border: Border.all(color: i == day ? C.gold : C.hairlineSoft), gradient: i == day ? softGold(.14) : null),
                  child: Column(children: [
                    Text(bkDays[i][0], style: F.inter(size: 9, color: i == day ? C.goldBright : C.textDim)),
                    const SizedBox(height: 3),
                    Text(bkDays[i][1], style: F.serif(size: 14, w: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        Text('시간 선택', style: F.inter(size: 10, color: C.textDim, ls: .05)),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.6,
          children: [
            for (final tm in bkTimes)
              Builder(builder: (_) {
                final taken = day == 0 && (tm == '11:00' || tm == '18:00');
                final on = slot == tm;
                return GestureDetector(
                  onTap: taken ? null : () => setS(() => slot = tm),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(border: Border.all(color: on ? C.gold : C.hairlineSoft), gradient: on ? softGold(.14) : null),
                    child: Text(tm,
                        style: F.inter(size: 11, color: taken ? C.textFaint : (on ? C.ivory : C.textDim)).copyWith(decoration: taken ? TextDecoration.lineThrough : null)),
                  ),
                );
              }),
          ],
        ),
      ]),
      foot: (ctx, setS) => GoldButton(
        slot != null ? '${bkDays[day][1]}일 $slot · 예약 확정' : '시간을 선택해주세요',
        upper: false,
        onTap: () {
          if (slot == null) {
            _s.toast('시간을 선택해주세요');
            return;
          }
          Navigator.pop(ctx);
          _s.toast('${t.nm} 트레이너 ${bkDays[day][1]}일 $slot 예약 완료 🎉');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('🎯 PT 트레이너 매칭', 'Personal Trainer', '내 목표(근육량 증가)와 자주 가는 헬스장 기준으로 딱 맞는 트레이너를 찾았어요.'),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          for (final t in trainers)
            Box(
              width: 210,
              margin: const EdgeInsets.only(right: 11),
              padding: const EdgeInsets.all(15),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Avatar(t.av, size: 46, border: C.goldDim),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
                        Text('${t.nm} 트레이너 ', style: F.kr(size: 13)),
                        if (t.match) Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), child: Text('MATCH', style: F.inter(size: 8, color: C.ink))),
                      ]),
                      const SizedBox(height: 3),
                      Text('★ ${t.rate} · 리뷰 ${t.rev}', style: F.inter(size: 9.5, color: C.goldBright)),
                    ]),
                  ),
                ]),
                const SizedBox(height: 11),
                Wrap(spacing: 5, children: [for (final sp in t.spec) Tag(sp, color: C.textDim, size: 8.5)]),
                const SizedBox(height: 10),
                Text('📍 ${t.gym}', style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                const SizedBox(height: 6),
                Text.rich(TextSpan(children: [
                  TextSpan(text: '회당 ', style: F.inter(size: 10, color: C.textDim)),
                  TextSpan(text: '${t.price}원', style: F.gnum(size: 15)),
                ])),
                const SizedBox(height: 13),
                LineButton('예약하기', expand: true, size: 10.5, padding: const EdgeInsets.all(9), onTap: () => openBook(context, t)),
              ]),
            ),
        ]),
      ),
    ]);
  }
}

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

/* ================= 운동 프로그램 ================= */
class ProgramsSection extends StatefulWidget {
  const ProgramsSection({super.key});
  @override
  State<ProgramsSection> createState() => _ProgramsSectionState();
}

class _ProgramsSectionState extends State<ProgramsSection> {
  int? applied;
  static const progs = [
    ['beg', '초급', '초보 3분할', '주 3회 · 8주', '가슴 · 등 · 하체를 하루씩 나눠 기본기를 잡는 입문 루틴'],
    ['int', '중급', '브로스플릿 5분할', '주 5회 · 12주', '가슴·등·어깨·팔·하체를 부위별로 집중 공략하는 볼륨 루틴'],
    ['adv', '중상급', 'PPL 푸시·풀·레그', '주 6회 · 상시', '밀기·당기기·하체를 2사이클 돌려 주간 볼륨을 극대화'],
    ['beg', '초중급', '5×5 스트렝스', '주 3회 · 상시', '스쿼트·벤치·데드 3대 중량을 5×5로 꾸준히 올리는 근력 프로그램'],
    ['beg', '초급', '상하체 2분할', '주 4회 · 8주', '상체·하체를 번갈아 균형 있게 키우는 회복 친화 루틴'],
  ];

  @override
  Widget build(BuildContext context) {
    Color lc(String k) => k == 'beg' ? C.cLow : (k == 'int' ? C.cMid : C.cHigh);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('🗂️ 운동 프로그램', 'Programs', '목표에 맞는 검증된 분할 프로그램을 골라 바로 시작해요.'),
      SizedBox(
        height: 200,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: progs.length,
          itemBuilder: (_, i) {
            final p = progs[i];
            final on = applied == i;
            return Box(
              width: 176,
              margin: const EdgeInsets.only(right: 11),
              padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Tag(p[1], color: lc(p[0]), border: lc(p[0]).op(.4), size: 8.5),
                const SizedBox(height: 11),
                Text(p[2], style: F.inter(size: 14, w: FontWeight.w500)),
                const SizedBox(height: 5),
                Text(p[3], style: F.inter(size: 10, color: C.goldBright)),
                const SizedBox(height: 8),
                Expanded(child: Text(p[4], style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300, h: 1.5))),
                LineButton(on ? '적용됨 ✓' : '적용하기', expand: true, done: on, size: 10.5, padding: const EdgeInsets.all(9), onTap: () {
                  if (on) return;
                  setState(() => applied = i);
                  _s.toast('이 프로그램을 내 루틴에 적용했어요');
                }),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

/* ================= 스마트워치 연동 ================= */
class WatchSection extends StatefulWidget {
  const WatchSection({super.key});
  @override
  State<WatchSection> createState() => _WatchSectionState();
}

class _WatchSectionState extends State<WatchSection> {
  bool apple = true;
  int hr = 142;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool isApple) {
      final on = apple == isApple;
      return Expanded(
        child: GestureDetector(
          onTap: () {
            setState(() => apple = isApple);
            _s.toast('${isApple ? '애플워치' : '갤럭시워치'} 연결됨');
          },
          child: Container(
            margin: EdgeInsets.only(right: isApple ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            alignment: Alignment.center,
            decoration: BoxDecoration(border: Border.all(color: on ? C.gold : C.hairlineSoft), gradient: on ? softGold(.14) : null),
            child: Text('⌚ $label', style: F.inter(size: 11, color: on ? C.ivory : C.textDim)),
          ),
        ),
      );
    }

    Widget vital(String l, String v, String u, {bool isHr = false}) => Box(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: F.inter(size: 9, color: C.textDim)),
            const SizedBox(height: 5),
            Text.rich(TextSpan(children: [
              TextSpan(text: v, style: F.serif(size: 22, w: FontWeight.w600, color: isHr ? C.cHigh : C.ivory)),
              TextSpan(text: u, style: F.inter(size: 9, color: C.textFaint)),
            ])),
          ]),
        );

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const ProgHead('⌚ 스마트워치 연동', 'Wearables', '애플워치·갤럭시워치를 연결해 심박·칼로리를 실시간으로 동기화해요.'),
      Box(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Column(children: [
          Row(children: [tab('Apple Watch', true), tab('Galaxy Watch', false)]),
          const SizedBox(height: 13),
          Row(children: [
            Expanded(child: Text('● ${apple ? '애플워치 Series 9' : '갤럭시워치 6 Classic'} 연결됨', style: F.inter(size: 9.5, color: C.cLow))),
            GestureDetector(
              onTap: () {
                setState(() => hr = 128 + math.Random().nextInt(24));
                _s.toast('워치 데이터를 동기화했어요');
              },
              child: Text('방금 동기화 · 새로고침 ↻', style: F.inter(size: 9.5, color: C.textFaint)),
            ),
          ]),
          const SizedBox(height: 13),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 9,
            crossAxisSpacing: 9,
            childAspectRatio: 2.3,
            children: [
              vital('❤️ 실시간 심박', '$hr', ' bpm', isHr: true),
              vital('🔥 소모 칼로리', '384', ' kcal'),
              vital('👟 걸음 수', '6,240', ''),
              vital('⏱️ 운동 시간', '52', ' 분'),
            ],
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: Text('심박존', style: F.inter(size: 10, color: C.textDim))),
            Text.rich(TextSpan(children: [
              TextSpan(text: 'Zone 4 · 무산소', style: F.inter(size: 10, color: C.cHigh, w: FontWeight.w600)),
              TextSpan(text: ' (고강도)', style: F.inter(size: 10, color: C.textDim)),
            ])),
          ]),
          const SizedBox(height: 7),
          Row(children: [
            for (final z in ['Z1', 'Z2', 'Z3', 'Z4', 'Z5'])
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: z == 'Z4' ? C.cHigh : null, border: Border.all(color: z == 'Z4' ? C.cHigh : C.hairlineSoft)),
                  child: Text(z, style: F.inter(size: 8, color: z == 'Z4' ? const Color(0xFF1A1207) : C.textFaint, w: z == 'Z4' ? FontWeight.w700 : FontWeight.w400)),
                ),
              ),
          ]),
        ]),
      ),
    ]);
  }
}
