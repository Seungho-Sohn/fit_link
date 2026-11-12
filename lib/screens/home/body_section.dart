import 'package:flutter/material.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

AppState get _s => AppState.I;

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
        onTap: () => _s.go(AppPage.inbody),
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
