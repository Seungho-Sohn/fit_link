import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

AppState get _s => AppState.I;

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
