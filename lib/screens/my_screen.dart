import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

/* ================= 마이페이지 ================= */
class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    Widget menu(String k, String v, {VoidCallback? onTap, bool gold = false, Widget? kw}) => GestureDetector(
          onTap: onTap,
          child: Divided(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(children: [
              Expanded(child: kw ?? Text(k, style: F.inter(size: 13))),
              Text(v, style: F.inter(size: 11, color: gold ? C.goldBright : C.textFaint)),
            ]),
          ),
        );
    Widget badge(String ic, String l, bool earned) => Expanded(
          child: Column(children: [
            Opacity(
              opacity: earned ? 1 : .32,
              child: Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, color: C.panel, border: Border.all(color: earned ? C.gold : C.hairline)),
                child: Text(ic, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(height: 6),
            Text(l, style: F.inter(size: 8.5, color: earned ? C.textDim : C.textFaint, h: 1.3)),
          ]),
        );
    return ScreenFrame(
      header: const StepTitle(eyebrow: 'My', title: '마이페이지'),
      children: [
        Divided(
          padding: const EdgeInsets.only(top: 4, bottom: 20),
          child: Row(children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold)),
              child: Text('F', style: F.serif(size: 18, color: C.goldBright)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('회원님', style: F.inter(size: 14.5, w: FontWeight.w500)),
                const SizedBox(height: 3),
                Text('FIT LINK 멤버십 · ${_s.tier.en} Tier · 🔥 12일 연속', style: F.serif(size: 12, w: FontWeight.w400, color: C.textDim)),
              ]),
            ),
          ]),
        ),
        const SectHead('내 배지', more: '전체 8개', top: 18),
        Row(children: [badge('🥇', '첫 운동', true), badge('🔥', '7일 연속', true), badge('💪', '챌린지 완주', true), badge('🏆', '랭킹 TOP3', false)]),
        const SizedBox(height: 6),
        menu('', _s.pointsStr, gold: true, onTap: () => _s.go(AppPage.points), kw: Text.rich(TextSpan(children: [
          TextSpan(text: '🏆 ', style: F.inter(size: 13)),
          TextSpan(text: 'WILD WEAR', style: F.serif(size: 14, w: FontWeight.w600, ls: .03)),
          TextSpan(text: ' 포인트', style: F.inter(size: 13)),
        ]))),
        menu('참여 중 챌린지', '2개 진행중'),
        menu('최근 배달 · 재주문', '프로틴키친 외 1건', onTap: () => _s.reorder(['d1', 'd2'], fromMy: true)),
        menu('주문 내역', _s.myOrders),
        menu('찜한 헬스장', '스틸핏 강남 외 2'),
        menu('기구 인식 이력', 'Hammer Strength 외 3'),
        menu('식단 기록', '오늘 1,642kcal'),
        menu('웨어러블 연동', 'Apple Health 연결됨'),
        menu('알림 설정', '›'),
      ],
    );
  }
}

/* ================= WILD WEAR 포인트 허브 ================= */
class PointsScreen extends StatelessWidget {
  const PointsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ti = _s.tierIdx;
    final t = tiers[ti];
    final next = ti + 1 < tiers.length ? tiers[ti + 1] : null;
    final done = _s.missionsDone;
    final all = _s.missionsAllDone;

    Widget earn(String em, String t, String d, Widget right) => Box(
          margin: const EdgeInsets.only(bottom: 9),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Row(children: [
            Text(em, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: F.inter(size: 12.5, w: FontWeight.w500)),
                const SizedBox(height: 3),
                Text(d, style: F.inter(size: 9.5, color: C.textDim, w: FontWeight.w300)),
              ]),
            ),
            right,
          ]),
        );
    Widget eBtn(String l, VoidCallback f, {bool doneB = false}) => LineButton(l, done: doneB, size: 10, padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), onTap: f);

    return ScreenFrame(
      header: StepTitle(eyebrow: '← 마이', onBack: () => _s.go(AppPage.my), title: 'WILD WEAR 포인트', titleSize: 22),
      children: [
        // 잔액 카드
        Box(
          border: C.gold,
          gradient: softGold(.16),
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text('보유 포인트', style: F.inter(size: 10.5, color: C.textDim))),
              Tag('${t.name} · 적립률 ${t.rateStr}%', color: C.goldBright, border: C.goldDim, size: 9),
            ]),
            const SizedBox(height: 10),
            Text(_s.pointsStr, style: F.serif(size: 38, w: FontWeight.w600, color: C.goldBright, h: 1)),
            const SizedBox(height: 12),
            next != null
                ? Text.rich(TextSpan(style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300), children: [
                    TextSpan(text: next.name, style: F.inter(size: 10, w: FontWeight.w500)),
                    TextSpan(text: '까지 누적 ${comma(next.min - _s.earned)}P 남음'),
                  ]))
                : Text('최고 등급이에요 👑', style: F.inter(size: 10, color: C.textDim)),
            const SizedBox(height: 8),
            Bar(next == null ? 1.0 : (_s.earned - t.min) / (next.min - t.min), track: const Color(0x14FFFFFF)),
          ]),
        ),
        // 주간 미션 · 스탬프
        const SectHead('이번 주 미션 · 스탬프', more: 'D-4', top: 20),
        Box(
          border: C.goldDim,
          gradient: softGold(.10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
          child: Column(children: [
            Row(children: [
              Expanded(
                child: Text.rich(TextSpan(style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300), children: [
                  const TextSpan(text: '5개 미션 완료 시 '),
                  TextSpan(text: '+500P', style: F.gnum(size: 14)),
                  const TextSpan(text: ' 보너스'),
                ])),
              ),
              Text('$done / ${_s.missions.length}', style: F.gnum(size: 14)),
            ]),
            const SizedBox(height: 15),
            Row(children: [
              for (int i = 0; i < _s.missions.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i < _s.missions.length - 1 ? 9 : 0),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Builder(builder: (_) {
                        final on = _s.missions[i].isDone;
                        return Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: on ? C.gold : C.hairline),
                            gradient: on ? RadialGradient(center: const Alignment(-.4, -.5), colors: [C.goldA(.3), C.goldA(.06)]) : null,
                          ),
                          child: Text(on ? '✓' : '', style: F.inter(size: 16, color: C.goldBright)),
                        );
                      }),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            for (final m in _s.missions)
              Divided(
                top: true,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Builder(builder: (_) {
                  final ok = m.isDone;
                  return Row(children: [
                    Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: ok ? C.gold : null, border: Border.all(color: ok ? C.gold : C.hairline)),
                      child: Text(ok ? '✓' : '', style: F.inter(size: 9, color: C.ink)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(m.name, style: F.inter(size: 11.5, color: ok ? C.ivory : C.textDim))),
                    Text('${m.progress} / ${m.goal}', style: F.inter(size: 10, color: C.goldBright)),
                  ]);
                }),
              ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _s.claimStamp,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: all && !_s.stampClaimed ? goldGradient : null,
                  border: all && !_s.stampClaimed ? null : Border.all(color: C.hairlineSoft),
                ),
                child: Text(
                  _s.stampClaimed ? '이번 주 보너스 수령 완료 ✓' : (all ? '🎁 500P 보너스 받기' : '$done / ${_s.missions.length} 완료 · 미션을 더 채워보세요'),
                  style: F.inter(size: 11.5, w: FontWeight.w600, color: all && !_s.stampClaimed ? C.ink : C.textFaint),
                ),
              ),
            ),
          ]),
        ),
        // 포인트 전용 특가
        const SectHead('⚡ 포인트 전용 특가관', more: '한정 수량', top: 20),
        for (final d in _s.ptDeals)
          Box(
            margin: const EdgeInsets.only(bottom: 10),
            border: C.goldDim,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            child: Row(children: [
              EmojiTile(d.em, size: 48, font: 24, badge: '${d.left}개', badgeColor: C.live),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.name, style: F.inter(size: 12, w: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text('정가 ${won(d.was)}', style: F.inter(size: 9.5, color: C.textFaint).copyWith(decoration: TextDecoration.lineThrough)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${comma(d.pts)} P', style: F.gnum(size: 15)),
                const SizedBox(height: 7),
                LineButton('교환', size: 9.5, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), onTap: () => _s.redeemDeal(d)),
              ]),
            ]),
          ),
        // 적립 방법
        const SectHead('포인트 적립하기', more: '적립률 등급별 차등', top: 20),
        earn('📅', '매일 출석 체크', '앱 접속만 해도 하루 10P', eBtn(_s.attended ? '출석 완료 ✓' : '출석 +10P', _s.attend, doneB: _s.attended)),
        earn('💪', '운동 인증', '커뮤니티에 오운완 인증 시 +50P', eBtn('인증하러', () => _s.go(AppPage.comm))),
        earn('✍️', '리뷰 작성', '배달·상품 리뷰 작성 시 +100P', eBtn('리뷰쓰기', () => _s.earnPoints(100, '리뷰 작성'))),
        earn('🛒', '주문 적립', '배달·마켓 결제액의 등급별 적립률만큼', Text('자동 적립', style: F.inter(size: 10, color: C.goldBright))),
        earn('🎁', '친구 초대', '초대 코드로 가입 시 +500P', eBtn('초대하기', () => _s.toast('초대 링크를 복사했어요'))),
        // 등급표
        const SectHead('등급별 적립률', more: '누적 적립 기준', top: 20),
        for (int i = 0; i < tiers.length; i++)
          Box(
            margin: const EdgeInsets.only(bottom: 8),
            border: i == ti ? C.gold : C.hairlineSoft,
            gradient: i == ti ? softGold(.12) : null,
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
            child: Row(children: [
              Expanded(child: Text('${tiers[i].name}${i == ti ? ' · 현재' : ''}', style: F.inter(size: 11, w: FontWeight.w500, color: i == ti ? C.ivory : C.textDim))),
              Text('적립률 ${tiers[i].rateStr}%', style: F.inter(size: 10.5, color: C.goldBright)),
              SizedBox(width: 82, child: Text(tiers[i].min == 0 ? '가입 시' : '누적 ${comma(tiers[i].min)}P', textAlign: TextAlign.right, style: F.inter(size: 9, color: C.textFaint))),
            ]),
          ),
        // 내역
        const SectHead('적립 · 사용 내역', top: 20),
        for (final h in _s.ptHistory)
          Divided(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(h.reason, style: F.inter(size: 11.5)),
                  const SizedBox(height: 3),
                  Text(h.when, style: F.inter(size: 9, color: C.textFaint)),
                ]),
              ),
              Text('${h.signed}P', style: F.gnum(size: 14, color: h.isSpend ? C.cHigh : C.cLow)),
            ]),
          ),
        const HintCard('어디서 쓰나요?', '배달·마켓 결제 시 1P = 1원처럼 사용할 수 있어요. WILD WEAR 공식 스토어에서는 포인트 전용 특가도 있어요.', top: 16),
      ],
    );
  }
}
