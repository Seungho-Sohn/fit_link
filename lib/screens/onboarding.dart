import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// 첫 실행 온보딩 (목표 · 빈도 · 관심 3단계)
class OnboardingOverlay extends StatefulWidget {
  const OnboardingOverlay({super.key});
  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  int idx = 0;
  final List<int?> sel = [null, null, null];

  void next() {
    if (sel[idx] == null) {
      AppState.I.toast('하나를 선택해 주세요');
      return;
    }
    if (idx < obSteps.length - 1) {
      setState(() => idx++);
    } else {
      AppState.I.finishOnboard(sel[0]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = obSteps[idx];
    final pick = sel[idx];
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF0E0D0A), C.charcoal])),
      padding: const EdgeInsets.fromLTRB(26, 44, 26, 30),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.eye.toUpperCase(), style: F.serif(size: 13, color: C.gold, ls: .24, w: FontWeight.w600))),
          TapArea(onTap: () => AppState.I.finishOnboard(sel[0]), label: '온보딩 건너뛰기', minSize: 36, child: Text('건너뛰기', style: F.inter(size: 11, color: C.textFaint))),
        ]),
        const SizedBox(height: 12),
        Text(s.h, style: F.kr(size: 27, h: 1.3)),
        const SizedBox(height: 9),
        Text(s.p, style: F.kr(size: 12.5, w: FontWeight.w400, color: C.textDim, h: 1.65)),
        const SizedBox(height: 18),
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            for (int i = 0; i < s.opts.length; i++)
              GestureDetector(
                onTap: () => setState(() => sel[idx] = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  margin: const EdgeInsets.only(bottom: 9),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(border: Border.all(color: pick == i ? C.gold : C.hairline), color: pick == i ? C.goldA(.07) : null),
                  child: Row(children: [
                    Text(s.opts[i].icon, style: const TextStyle(fontSize: 22)),
                    const SizedBox(width: 13),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(s.opts[i].title, style: F.kr(size: 14, color: pick == i ? C.goldBright : C.ivory)),
                      const SizedBox(height: 2),
                      Text(s.opts[i].sub, style: F.inter(size: 10.5, color: C.textFaint, w: FontWeight.w300)),
                    ]),
                  ]),
                ),
              ),
            // 선택 결과 미리보기
            Box(
              margin: const EdgeInsets.only(top: 3),
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              child: pick == null
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Text('위에서 하나를 선택하면\nFIT LINK가 맞춰줄 설정을 미리 보여드려요',
                          textAlign: TextAlign.center, style: F.inter(size: 11, color: C.textFaint, w: FontWeight.w300, h: 1.6)),
                    )
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('✦  ${s.preview[pick].title}'.toUpperCase(), style: F.inter(size: 9, color: C.gold, ls: .16)),
                      const SizedBox(height: 8),
                      for (final it in s.preview[pick].items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            SizedBox(width: 20, child: Text(it.icon, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15))),
                            const SizedBox(width: 11),
                            Text(it.text, style: F.inter(size: 12)),
                          ]),
                        ),
                    ]),
            ),
            if (s.social != null && pick != null)
              Padding(
                padding: const EdgeInsets.only(top: 11),
                child: Text(s.social![pick], textAlign: TextAlign.center, style: F.inter(size: 10, color: C.goldBright)),
              ),
          ]),
        ),
        // 1단계에서만 WILD WEAR 브랜드 표시
        if (idx == 0)
          Center(
            child: Column(children: [
              Container(width: 44, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, C.goldDim, Colors.transparent]))),
              const SizedBox(height: 7),
              Text('PRESENTED BY', style: F.inter(size: 8, color: C.textFaint, ls: .34)),
              const WwHolo(width: 106, height: 102),
            ]),
          ),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (int i = 0; i < obSteps.length; i++)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == idx ? 18 : 6,
              height: 6,
              decoration: BoxDecoration(color: i == idx ? C.gold : C.hairline, borderRadius: BorderRadius.circular(3)),
            ),
        ]),
        const SizedBox(height: 16),
        GoldButton(idx < obSteps.length - 1 ? '다음' : 'FIT LINK 시작하기', onTap: next),
      ]),
    );
  }
}
