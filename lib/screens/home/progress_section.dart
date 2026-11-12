import 'package:flutter/material.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

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
