import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

/// 대화 내역은 화면을 나갔다 와도 유지 (HTML도 DOM에 남아 있음)
final List<_Msg> _coachLog = [
  _Msg('bot', '안녕하세요 회원님 👋 12일 연속 달성 중이에요! 운동 기록·눈바디·근육 밸런스를 모두 보고 있으니, 오늘 뭘 하면 좋을지 편하게 물어보세요.'),
];

class _Msg {
  final String who; // bot | me | report
  final String text;
  _Msg(this.who, this.text);
}

/// 인바디 화면 등 외부에서 코치에게 질문을 넣을 때 사용
void coachAsk(String q, String a) {
  _coachLog.add(_Msg('me', q));
  _s.go(AppPage.coach);
  Future.delayed(const Duration(milliseconds: 450), () {
    _coachLog.add(_Msg('bot', a));
    if (_s.page == AppPage.coach) _s.go(AppPage.coach); // 다른 화면으로 이동했다면 강제로 끌고 오지 않음
  });
}

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _toBottom();
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void _toBottom() => WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scroll.hasClients) scroll.animateTo(scroll.position.maxScrollExtent, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
      });

  void add(String who, String text) {
    if (!mounted) return;
    setState(() => _coachLog.add(_Msg(who, text)));
    _toBottom();
  }

  void ask(String k) {
    if (k == 'report') {
      add('me', '📊 주간 리포트 보여줘');
      Future.delayed(const Duration(milliseconds: 400), () => add('report', ''));
      return;
    }
    final it = coachQ.firstWhere((x) => x.key == k);
    add('me', it.question);
    Future.delayed(const Duration(milliseconds: 350), () => add('bot', it.answer));
  }

  void send() {
    final v = input.text.trim();
    if (v.isEmpty) return;
    input.clear();
    add('me', v);
    Future.delayed(const Duration(milliseconds: 400),
        () => add('bot', '좋은 질문이에요! 실제 앱에서는 회원님의 운동 기록·눈바디·근육 밸런스·헬스장 혼잡도를 분석해 맞춤 답변을 드려요. 아래 추천 질문도 눌러보세요 👇'));
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
        child: Row(children: [
          TapArea(onTap: () => _s.go(AppPage.home), label: '뒤로 가기, 홈', minSize: 36, alignment: Alignment.centerLeft, child: Text('← 홈', style: F.inter(size: 13, color: C.gold))),
          const SizedBox(width: 13),
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold), gradient: RadialGradient(center: const Alignment(-.4, -.5), colors: [C.goldA(.28), C.panel])),
            child: const Text('✨', style: TextStyle(fontSize: 17)),
          ),
          const SizedBox(width: 11),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI 코치', style: F.inter(size: 13.5, w: FontWeight.w500)),
            const SizedBox(height: 2),
            Row(children: [
              Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: C.cLow)),
              const SizedBox(width: 4),
              Text('내 데이터 분석 중', style: F.inter(size: 9.5, color: C.cLow)),
            ]),
          ]),
        ]),
      ),
      Expanded(
        child: ListView.builder(
          controller: scroll,
          padding: const EdgeInsets.all(18),
          itemCount: _coachLog.length,
          itemBuilder: (_, i) => _bubble(_coachLog[i]),
        ),
      ),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(children: [
            _chip('🎯 실시간 코칭', () => _s.go(AppPage.live), solid: true),
            _chip('📊 주간 리포트', () => ask('report')),
            for (final q in coachQ) _chip(q.question, () => ask(q.key)),
          ]),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 16),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: input,
              onSubmitted: (_) => send(),
              style: F.inter(size: 12),
              decoration: InputDecoration(
                hintText: '코치에게 무엇이든 물어보세요',
                hintStyle: F.inter(size: 12, color: C.textFaint),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.hairlineSoft)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.gold)),
              ),
            ),
          ),
          const SizedBox(width: 9),
          GestureDetector(
            onTap: send,
            child: Container(width: 42, height: 42, alignment: Alignment.center, decoration: const BoxDecoration(gradient: goldGradient), child: Text('↑', style: F.inter(size: 16, color: C.ink))),
          ),
        ]),
      ),
    ]);
  }

  Widget _chip(String t, VoidCallback f, {bool solid = false}) => GestureDetector(
        onTap: f,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(gradient: solid ? goldGradient : null, border: Border.all(color: solid ? C.gold : C.goldDim)),
          child: Text(t, style: F.inter(size: 10.5, color: solid ? C.ink : C.goldBright, w: solid ? FontWeight.w600 : FontWeight.w400)),
        ),
      );

  Widget _bubble(_Msg m) {
    if (m.who == 'report') return _report();
    final me = m.who == 'me';
    return Align(
      alignment: me ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: math.min(MediaQuery.of(context).size.width, 430.0) * .72),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          gradient: me ? goldGradient : null,
          color: me ? null : C.panel,
          border: me ? null : Border.all(color: C.hairlineSoft),
        ),
        child: Text(m.text, style: F.inter(size: 12, h: 1.6, w: me ? FontWeight.w400 : FontWeight.w300, color: me ? C.ink : C.ivory)),
      ),
    );
  }

  Widget _report() {
    Widget rg(String l, String v, String u) => Box(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: F.inter(size: 9, color: C.textDim)),
            const SizedBox(height: 3),
            Text.rich(TextSpan(children: [TextSpan(text: v, style: F.gnum(size: 20)), TextSpan(text: u, style: F.inter(size: 9, color: C.cLow, w: FontWeight.w500))])),
          ]),
        );
    return Box(
      margin: const EdgeInsets.only(bottom: 12),
      border: C.goldDim,
      gradient: softGold(.10),
      padding: const EdgeInsets.all(15),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📊 이번 주 리포트', style: F.kr(size: 14)),
        const SizedBox(height: 3),
        Text('8월 4일 – 8월 10일 · 목표: ${_s.goal}', style: F.inter(size: 9.5, color: C.textFaint)),
        const SizedBox(height: 12),
        FlexGrid(
          columns: 2, ratio: 2.4, hSpacing: 9, vSpacing: 9,
          children: [rg('운동 일수', '4 / 5', ' 회'), rg('총 볼륨', '42,800', ' +8%'), rg('신규 PR', '2', ' 개'), rg('평균 심박', '138', ' bpm')],
        ),
        const SizedBox(height: 12),
        Text(
          '이번 주 등·팔 볼륨은 목표를 넘겼고 데드리프트에서 새 PR(185kg)을 세웠어요 🎉 다만 하체가 4세트로 부족했어요. 다음 주엔 하체 세션을 한 번 더 넣어 균형을 맞추는 걸 추천해요. 이 페이스면 목표 달성까지 순항 중이에요!',
          style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300, h: 1.6),
        ),
      ]),
    );
  }
}

/* ================= 실시간 코칭 (세트 → 90초 휴식 → 다음 세트) ================= */
class LiveCoachScreen extends StatefulWidget {
  const LiveCoachScreen({super.key});
  @override
  State<LiveCoachScreen> createState() => _LiveCoachScreenState();
}

class _LiveCoachScreenState extends State<LiveCoachScreen> with SingleTickerProviderStateMixin {
  int set = 1;
  bool resting = false, done = false;
  int restT = 90;
  Timer? timer;
  String? cueOverride;
  late final AnimationController pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();

  @override
  void dispose() {
    timer?.cancel();
    pulse.dispose();
    super.dispose();
  }

  void action() {
    if (done) {
      _s.go(AppPage.coach);
      return;
    }
    if (resting) {
      endRest();
      return;
    }
    if (set >= liveSteps.length) {
      setState(() {
        done = true;
        cueOverride = '🎉 운동 완료! 스쿼트 5세트 끝냈어요. 평균 심박 138bpm · 소모 320kcal. 오늘도 훌륭했어요!';
      });
      return;
    }
    setState(() {
      resting = true;
      restT = 90;
      cueOverride = '잘했어요! 90초 휴식하며 심박을 낮춰주세요. 물 한 모금 추천해요 💧';
    });
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => restT--);
      if (restT <= 0) endRest();
    });
  }

  void endRest() {
    timer?.cancel();
    setState(() {
      resting = false;
      cueOverride = null;
      set++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final st = liveSteps[set - 1];
    final mm = (restT ~/ 60).toString().padLeft(2, '0'), ss = (restT % 60).toString().padLeft(2, '0');
    return Column(children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
        child: Row(children: [
          TapArea(onTap: () => _s.go(AppPage.coach), label: '뒤로 가기, AI 코치', minSize: 36, alignment: Alignment.centerLeft, child: Text('← 코치', style: F.inter(size: 13, color: C.gold))),
          const Spacer(),
          const LiveDot(size: 6),
          const SizedBox(width: 6),
          Text('운동 중 · 실시간 코칭', style: F.inter(size: 10, color: C.live, ls: .1)),
          const Spacer(),
          TapArea(onTap: () => _s.go(AppPage.coach), label: '실시간 코칭 종료', minSize: 36, child: Text('종료', style: F.inter(size: 11, color: C.textDim))),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24), children: [
          Column(children: [
            Text('현재 운동', style: F.inter(size: 9.5, color: C.gold, ls: .14)),
            const SizedBox(height: 9),
            Text('바벨 스쿼트', style: F.kr(size: 25)),
            const SizedBox(height: 9),
            Text.rich(TextSpan(style: F.inter(size: 12, color: C.textDim), children: [
              const TextSpan(text: '세트 '),
              TextSpan(text: '$set', style: F.gnum(size: 17)),
              const TextSpan(text: ' / 5 · 8회 × 80kg'),
            ])),
          ]),
          const SizedBox(height: 20),
          Center(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (_, child) {
                final t = (pulse.value / .7).clamp(0.0, 1.0).toDouble();
                return Container(
                  width: 154,
                  height: 154,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: C.cHigh, width: 2),
                    gradient: RadialGradient(colors: [C.cHigh.op(.13), Colors.transparent]),
                    boxShadow: [BoxShadow(color: C.goldA(.45 * (1 - t)), spreadRadius: 7 * t)],
                  ),
                  child: child,
                );
              },
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Text('❤️', style: TextStyle(fontSize: 18)),
                Text('${st.bpm}', style: F.serif(size: 44, w: FontWeight.w600, color: C.cHigh, h: 1)),
                Text('BPM', style: F.inter(size: 9, color: C.textFaint, ls: .1)),
                const SizedBox(height: 5),
                Text(st.zone, style: F.inter(size: 9.5, color: C.cHigh)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          Box(
            border: C.goldDim,
            gradient: softGold(.12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('🎯', style: TextStyle(fontSize: 19)),
              const SizedBox(width: 12),
              Expanded(child: Text(cueOverride ?? st.cue, style: F.inter(size: 12, w: FontWeight.w300, h: 1.55))),
            ]),
          ),
          if (resting) ...[
            const SizedBox(height: 20),
            Center(child: Text('휴식 $mm:$ss', style: F.serif(size: 34, color: C.goldBright))),
          ],
        ]),
      ),
      GoldButton(done ? '코치로 돌아가기' : (resting ? '휴식 건너뛰기 →' : '세트 완료 ✓'), upper: false, margin: const EdgeInsets.fromLTRB(22, 0, 22, 18), onTap: action),
    ]);
  }
}
