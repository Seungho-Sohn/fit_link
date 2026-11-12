import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'home_sections.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String pref = 'low'; // 'low' 한산 / 'high' 북적
  final Set<int> mateSent = {};

  AppState get s => AppState.I;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // 인사 + 연속 기록 배지
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('좋은 아침이에요 ☀️', style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300)),
              const SizedBox(height: 3),
              Text('회원님', style: F.serif(size: 23)),
            ]),
          ),
          Box(
            border: C.goldDim,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
            child: Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Column(children: [
                Text('12', style: F.gnum(size: 15)),
                Text('일 연속', style: F.inter(size: 8, color: C.textFaint)),
              ]),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 20), children: [
          _goalCard(),
          _heroScan(),
          _coachLaunch(),
          _quickRow(),
          ..._gymCrowd(),
          ..._mates(),
          ..._rewardChallenge(),
          _nudge(),
          const NewsSection(),
          _routineCard(),
          const WorkoutLogSection(),
          const WeekBars(),
          const ProgressSection(),
          const BodySection(),
          const StrengthTools(),
          const TrainerSection(),
          const MuscleMap(),
          const ProgramsSection(),
          const WatchSection(),
        ]),
      ),
    ]);
  }

  Widget _goalCard() => Box(
        border: C.hairline,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          Ring(
            size: 66,
            stroke: 3,
            segments: const [MapEntry(.62, C.goldBright)],
            track: C.goldA(.12),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('1,642', style: F.serif(size: 17, color: C.goldBright)),
              Text('/2,200', style: F.inter(size: 7.5, color: C.textFaint, ls: .1)),
            ]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('목표 · ${s.goal}'.toUpperCase(), style: F.inter(size: 9.5, color: C.gold, ls: .16)),
              const SizedBox(height: 5),
              Text('오늘 목표까지 558kcal', style: F.inter(size: 14, w: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('단백질 104g 섭취 · 목표의 74%', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
            ]),
          ),
        ]),
      );

  Widget _heroScan() {
    Widget step(String ic, String l, {bool match = false}) => Expanded(
          child: Column(children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: C.panel,
                gradient: match ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.goldA(.18), C.panel]) : null,
                border: Border.all(color: match ? C.goldDim : C.hairlineSoft),
              ),
              child: Text(ic, style: const TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 8),
            Text(l, textAlign: TextAlign.center, style: F.inter(size: 9, color: C.textDim, h: 1.3)),
          ]),
        );
    Widget arr() => Padding(padding: const EdgeInsets.only(top: 14), child: Text('→', style: F.inter(size: 13, color: C.goldDim)));

    return Box(
      onTap: () => s.go('gear'),
      margin: const EdgeInsets.only(top: 16),
      border: C.gold,
      gradient: softGold(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 17),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const LiveDot(),
          const SizedBox(width: 6),
          Expanded(child: Text('FIT LINK SIGNATURE · 특허 기술', style: F.inter(size: 9, color: C.gold, ls: .1))),
          Text('📍 강남구 · 내 주변', style: F.inter(size: 9.5, color: C.textDim)),
        ]),
        const SizedBox(height: 11),
        Text.rich(
          TextSpan(style: F.kr(size: 17, h: 1.45), children: const [
            TextSpan(text: '기구 사진 '),
            TextSpan(text: '한 장', style: TextStyle(color: C.goldBright)),
            TextSpan(text: '으로\n내 위치에서 '),
            TextSpan(text: '같은 기구', style: TextStyle(color: C.goldBright)),
            TextSpan(text: ' 있는 헬스장 찾기'),
          ]),
        ),
        const SizedBox(height: 16),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          step('📷', '기구 촬영'),
          arr(),
          step('🧠', 'AI 브랜드·\n모델 매칭', match: true),
          arr(),
          step('📍', '가장 가까운\n헬스장'),
        ]),
        const SizedBox(height: 16),
        GoldButton('＋ 기구 촬영하고 찾기', upper: false, onTap: () => s.go('gear')),
      ]),
    );
  }

  Widget _coachLaunch() => Box(
        onTap: () => s.go('coach'),
        margin: const EdgeInsets.only(top: 12),
        border: C.goldDim,
        gradient: softGold(),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold), gradient: RadialGradient(center: const Alignment(-.4, -.5), colors: [C.goldA(.28), C.panel])),
            child: const Text('✨', style: TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('AI COACH', style: F.inter(size: 9, color: C.gold, ls: .14)),
              const SizedBox(height: 5),
              Text('AI 코치에게 물어보기', style: F.inter(size: 14.5, w: FontWeight.w500)),
              const SizedBox(height: 4),
              Text('내 기록·눈바디·근육 밸런스를 아는 코치가 답해줘요', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
            ]),
          ),
          Text('›', style: F.inter(size: 18, color: C.goldBright)),
        ]),
      );

  Widget _quickRow() {
    Widget q(String ic, String l, String tab) => Expanded(
          child: Box(
            onTap: () => s.go(tab),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
            child: Column(children: [
              Text(ic, style: const TextStyle(fontSize: 19)),
              const SizedBox(height: 7),
              Text(l, style: F.inter(size: 9.5, color: C.textDim)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Row(children: [q('🍚', '음식 기록', 'cal'), q('🏆', '챌린지', 'comm'), q('🛍️', '마켓', 'market')]),
    );
  }

  /* ----- 오늘 가볼만한 헬스장 (면적 대비 밀집도) ----- */
  List<Widget> _gymCrowd() {
    final list = [...gyms]..sort((a, b) => pref == 'low' ? b.spp.compareTo(a.spp) : a.spp.compareTo(b.spp));
    final reason = pref == 'low' ? '지금 가장 여유로워요 · 1인당 공간 넉넉' : '지금 가장 붐벼요 · 활기·자극 최고';

    Widget prefBtn(String key, String e, String l, String d) {
      final on = pref == key;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => pref = key),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: EdgeInsets.only(right: key == 'low' ? 8 : 0),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
            decoration: BoxDecoration(border: Border.all(color: on ? C.gold : C.hairlineSoft), gradient: on ? softGold(.14) : null),
            child: Column(children: [
              Text(e, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 4),
              Text(l, style: F.inter(size: 11, w: FontWeight.w500, color: on ? C.ivory : C.textDim)),
              const SizedBox(height: 2),
              Text(d, style: F.inter(size: 8.5, color: on ? C.goldBright : C.textFaint)),
            ]),
          ),
        ),
      );
    }

    return [
      Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 6),
        child: Row(children: [
          const LiveDot(size: 6),
          const SizedBox(width: 7),
          Expanded(child: Text('오늘 가볼만한 헬스장', style: F.inter(size: 12, w: FontWeight.w500))),
          Text('방금 업데이트', style: F.inter(size: 9.5, color: C.textFaint)),
        ]),
      ),
      Text.rich(TextSpan(style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300), children: const [
        TextSpan(text: '단순 인원이 아니라 '),
        TextSpan(text: '면적(평수) 대비 밀집도', style: TextStyle(color: C.goldBright, fontWeight: FontWeight.w500)),
        TextSpan(text: '로 계산했어요. 원하는 분위기를 골라보세요.'),
      ])),
      const SizedBox(height: 11),
      Row(children: [prefBtn('low', '🧘', '한산한 곳', '여유롭게 · 대기 없이'), prefBtn('high', '🔥', '북적이는 곳', '활기차게 · 자극 받으며')]),
      const SizedBox(height: 14),
      for (int i = 0; i < list.length; i++) _gymCard(list[i], i == 0, reason),
    ];
  }

  Widget _gymCard(Gym g, bool pick, String reason) {
    final spp = g.spp;
    final lv = spp >= 3.0 ? ['여유', C.cLow] : (spp >= 1.5 ? ['보통', C.cMid] : ['혼잡', C.cHigh]);
    final col = lv[1] as Color;
    return Box(
      onTap: () => s.go('gear'),
      margin: const EdgeInsets.only(bottom: 10),
      border: pick ? C.gold : C.hairlineSoft,
      gradient: pick ? softGold(.10) : null,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      child: Column(children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(g.name, style: F.inter(size: 14, w: FontWeight.w500)),
                if (pick) ...[
                  const SizedBox(width: 7),
                  Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text('PICK', style: F.inter(size: 8, w: FontWeight.w700, color: C.ink, ls: .1))),
                ],
              ]),
              const SizedBox(height: 4),
              Text('${g.dist} · ${g.area}평', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
              if (pick) Padding(padding: const EdgeInsets.only(top: 7), child: Text(reason, style: F.inter(size: 10, color: C.goldBright))),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: '${g.now}', style: F.serif(size: 30, w: FontWeight.w600, color: col)),
              TextSpan(text: '명', style: F.inter(size: 11, color: C.textDim)),
            ])),
            const SizedBox(height: 4),
            Tag(lv[0] as String, color: col, border: col.op(.45), size: 9),
          ]),
        ]),
        const SizedBox(height: 13),
        Bar(g.dens / 100, gradient: LinearGradient(colors: [col.op(.5), col])),
        const SizedBox(height: 7),
        Row(children: [
          Expanded(child: Text('${g.area}평 · 1인당 ${spp.toStringAsFixed(1)}평', style: F.inter(size: 9.5, color: C.textFaint))),
          Text('밀집도 ${g.dens}%', style: F.inter(size: 9.5, color: col, w: FontWeight.w500)),
        ]),
      ]),
    );
  }

  /* ----- 운동 메이트 ----- */
  List<Widget> _mates() {
    const mates = [
      ['J', '지훈', '28 · 남', '스틸핏 강남 · 주로 저녁 7시', '근육량 증가', '3대 400+', '주 5회', '94%', 'on'],
      ['S', '서연', '26 · 여', '스틸핏 강남 · 주로 오전 10시', '체지방 감량', '유산소', '주 4회', '88%', 'on'],
      ['M', '민재', '31 · 남', '코어짐24 역삼 · 주로 저녁 8시', '체형 유지', '파워리프팅', '주 3회', '82%', ''],
    ];
    return [
      const ProgHead('🤝 운동 메이트', 'Workout Mate', '같은 헬스장 · 비슷한 목표 · 운동 시간이 맞는 메이트를 찾았어요.'),
      for (int i = 0; i < mates.length; i++)
        Box(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Stack(children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.goldDim), gradient: RadialGradient(center: const Alignment(-.4, -.5), colors: [C.goldA(.18), C.panel])),
                child: Text(mates[i][0], style: F.gnum(size: 19, color: mates[i][8] == 'on' ? C.goldBright : C.textDim)),
              ),
              if (mates[i][8] == 'on')
                Positioned(
                  right: 1,
                  bottom: 1,
                  child: Container(width: 10, height: 10, decoration: BoxDecoration(shape: BoxShape.circle, color: C.cLow, border: Border.all(color: C.onyx, width: 2))),
                ),
            ]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text.rich(TextSpan(children: [
                  TextSpan(text: mates[i][1], style: F.inter(size: 13, w: FontWeight.w500)),
                  TextSpan(text: '  ${mates[i][2]}', style: F.inter(size: 10, color: C.textFaint, w: FontWeight.w300)),
                ])),
                const SizedBox(height: 3),
                Text(mates[i][3], style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                const SizedBox(height: 8),
                Wrap(spacing: 5, children: [
                  Tag(mates[i][4], color: C.goldBright, border: C.goldDim, size: 8.5),
                  Tag(mates[i][5], size: 8.5),
                  Tag(mates[i][6], size: 8.5),
                ]),
              ]),
            ),
            Column(children: [
              Text(mates[i][7], style: F.gnum(size: 18)),
              Text('MATCH', style: F.inter(size: 7, color: C.textFaint, ls: .1)),
              const SizedBox(height: 9),
              LineButton(mateSent.contains(i) ? '신청됨 ✓' : '메이트 신청', size: 9.5, done: mateSent.contains(i), onTap: () {
                if (mateSent.contains(i)) return;
                setState(() => mateSent.add(i));
                s.toast('운동 메이트 신청을 보냈어요');
              }),
            ]),
          ]),
        ),
    ];
  }

  /* ----- 리워드 챌린지 ----- */
  List<Widget> _rewardChallenge() => [
        const ProgHead('🏆 리워드 챌린지', 'Reward Challenge', '참가는 무료! 돈 대신 포인트로 동기부여해요. 목표를 완주하면 WILD WEAR 적립 포인트, 1등에겐 보너스 포인트를 드려요.'),
        Box(
          border: C.goldDim,
          gradient: softGold(.12),
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('2주 · 주 4회 헬스 인증 챌린지', style: F.inter(size: 14.5, w: FontWeight.w500))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(color: C.live.op(.1), border: Border.all(color: C.live.op(.4))),
                child: Text('D-6', style: F.inter(size: 9.5, w: FontWeight.w600, color: C.live)),
              ),
            ]),
            const SizedBox(height: 13),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('완주 시 지급  ', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
              Text('2,000 P', style: F.gnum(size: 24)),
              Text('  참가비 0원', style: F.inter(size: 9.5, color: C.textFaint)),
            ]),
            const SizedBox(height: 9),
            Wrap(spacing: 18, children: [
              _stat('참가 ', '1,284명'),
              _stat('1등 보너스 ', '10,000P'),
              _stat('완주율 ', '71%'),
            ]),
            const SizedBox(height: 15),
            const Bar(.75, height: 7),
            const SizedBox(height: 7),
            Row(children: [
              Expanded(child: Text('인증 6 / 8회 · 현재 12위', style: F.inter(size: 9.5, color: C.textFaint))),
              Text('75% 달성 · 성공 페이스', style: F.inter(size: 9.5, color: C.textFaint)),
            ]),
            Box(
              margin: const EdgeInsets.only(top: 13),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              child: Text.rich(TextSpan(style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300), children: [
                const TextSpan(text: '🎁 이대로 완주하면 '),
                TextSpan(text: '2,000P', style: F.gnum(size: 15, color: C.cLow)),
                const TextSpan(text: ' 적립 · WILD WEAR 마켓에서 현금처럼 사용'),
              ])),
            ),
            GoldButton('오늘 운동 인증하기', upper: false, margin: const EdgeInsets.only(top: 12), onTap: () => s.toast('오늘 운동을 인증했어요 · 앞으로 2회!')),
          ]),
        ),
      ];

  Widget _stat(String k, String v) => Text.rich(TextSpan(children: [
        TextSpan(text: k, style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
        TextSpan(text: v, style: F.inter(size: 10, w: FontWeight.w500)),
      ]));

  Widget _nudge() => Container(
        margin: const EdgeInsets.only(top: 16),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
        decoration: BoxDecoration(color: C.live.op(.06), border: const Border(left: BorderSide(color: C.gold, width: 2))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('⏰', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 11),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('SMART REMINDER', style: F.inter(size: 9, color: C.live, ls: .12, w: FontWeight.w500)),
              const SizedBox(height: 5),
              Text('저녁 7시, 평소 운동하시던 시간이에요. 오늘의 광배 루틴 어떠세요?', style: F.inter(size: 11.5, w: FontWeight.w300, h: 1.5)),
            ]),
          ),
        ]),
      );

  Widget _routineCard() {
    const ex = [
      ['1', '랫풀다운', 'Hammer Strength · 4세트 × 12', '중강도'],
      ['2', '시티드 로우', 'Plate-Loaded · 4세트 × 10', '고강도'],
      ['3', '풀오버', '덤벨 · 3세트 × 15', '저강도'],
    ];
    return Container(
      margin: const EdgeInsets.only(top: 20),
      decoration: BoxDecoration(border: Border.all(color: C.hairlineSoft)),
      child: Column(children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 13),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AI 적응형 루틴 · 스틸핏 강남', style: F.inter(size: 9, color: C.gold, ls: .14)),
            const SizedBox(height: 6),
            Text('오늘의 광배 집중 루틴', style: F.inter(size: 15, w: FontWeight.w500)),
            const SizedBox(height: 4),
            Text('인식하신 Hammer Strength 기구로 구성했어요 · 약 45분', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
          ]),
        ),
        for (final e in ex)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(border: e == ex.last ? null : const Border(bottom: BorderSide(color: C.hairlineSoft))),
            child: Row(children: [
              SizedBox(width: 20, child: Text(e[0], style: F.serif(size: 14, color: C.goldDim))),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(e[1], style: F.inter(size: 12.5)),
                  const SizedBox(height: 2),
                  Text(e[2], style: F.inter(size: 9.5, color: C.textFaint, w: FontWeight.w300)),
                ]),
              ),
              Tag(e[3], color: C.goldBright, size: 9),
            ]),
          ),
      ]),
    );
  }
}
