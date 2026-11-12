import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

AppState get _s => AppState.I;

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
                    Text(bkDays[i].label, style: F.inter(size: 9, color: i == day ? C.goldBright : C.textDim)),
                    const SizedBox(height: 3),
                    Text(bkDays[i].date, style: F.serif(size: 14, w: FontWeight.w600)),
                  ]),
                ),
              ),
          ]),
        ),
        const SizedBox(height: 14),
        Text('시간 선택', style: F.inter(size: 10, color: C.textDim, ls: .05)),
        const SizedBox(height: 10),
        FlexGrid(
          columns: 3, ratio: 2.6, hSpacing: 8, vSpacing: 8,
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
        slot != null ? '${bkDays[day].date}일 $slot · 예약 확정' : '시간을 선택해주세요',
        upper: false,
        onTap: () {
          if (slot == null) {
            _s.toast('시간을 선택해주세요');
            return;
          }
          Navigator.pop(ctx);
          _s.toast('${t.nm} 트레이너 ${bkDays[day].date}일 $slot 예약 완료 🎉');
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
