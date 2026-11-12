import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

AppState get _s => AppState.I;

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
