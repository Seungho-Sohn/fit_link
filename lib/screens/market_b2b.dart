import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

/// B2B 화면들의 선택값. [MarketScreen]이 보관해서 B2B 화면 사이를 오가도 유지된다.
class B2BFilters {
  String b2bCat = '전체', usedCat = '전체';
  // 견적 폼
  String fOpen = '신규 오픈', fSize = '~30평';
  final Set<String> fItems = {};
}

/// 헬스장 운영자(B2B) 화면: 전용관 · 견적 폼 · 접수 완료 · 중고 거래 · 운영 대시보드
class B2BView extends StatefulWidget {
  final MarketView view;
  final B2BFilters filters;
  const B2BView(this.view, this.filters, {super.key});
  @override
  State<B2BView> createState() => _B2BViewState();
}

class _B2BViewState extends State<B2BView> {
  B2BFilters get _f => widget.filters;
  String get b2bCat => _f.b2bCat;
  set b2bCat(String v) => _f.b2bCat = v;
  String get usedCat => _f.usedCat;
  set usedCat(String v) => _f.usedCat = v;
  String get fOpen => _f.fOpen;
  set fOpen(String v) => _f.fOpen = v;
  String get fSize => _f.fSize;
  set fSize(String v) => _f.fSize = v;
  Set<String> get fItems => _f.fItems;

  @override
  Widget build(BuildContext context) => switch (widget.view) {
        MarketView.b2bForm => _b2bForm(),
        MarketView.b2bDone => _b2bDone(),
        MarketView.used => _used(),
        MarketView.dash => _dash(),
        _ => _b2b(),
      };

  /* ================= B2B 운영자 전용관 ================= */
  Widget _b2b() {
    final list = b2bCat == '전체' ? b2bItems : b2bItems.where((i) => i.cat == b2bCat).toList();
    Widget ben(String i, String l) => Expanded(
          child: Box(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            child: Column(children: [Text(i, style: const TextStyle(fontSize: 17)), const SizedBox(height: 6), Text(l, style: F.inter(size: 8.5, color: C.textDim, h: 1.3))]),
          ),
        );
    Widget svc(String i, String t, String d, String go, MarketView to) => Box(
          onTap: () => _s.goMarket(to),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(i, style: const TextStyle(fontSize: 23)),
            const SizedBox(height: 9),
            Text(t, style: F.inter(size: 12.5, w: FontWeight.w500)),
            const SizedBox(height: 4),
            Text(d, style: F.inter(size: 9.5, color: C.textDim, w: FontWeight.w300, h: 1.45)),
            const SizedBox(height: 9),
            Text(go, style: F.inter(size: 9, color: C.goldBright)),
          ]),
        );
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 마켓', onBack: () => _s.goMarket(MarketView.home), title: '헬스장 운영자 전용관', titleSize: 23, desc: '상업용(commercial-grade) 기구를 도매가로. 신규 오픈·리뉴얼 견적을 받아보세요.'),
      footer: [
        GoldButton('🧾 매장 전체 견적 요청하기', upper: false, onTap: () => _s.goMarket(MarketView.b2bForm)),
        GoldButton('사업자 인증하고 도매가 보기', ghost: true, upper: false, margin: const EdgeInsets.only(top: 10), onTap: () => _s.goMarket(MarketView.b2bForm)),
      ],
      children: [
        Box(
          border: C.goldDim,
          gradient: softGold(.10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Text.rich(TextSpan(style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300, h: 1.65), children: [
            const TextSpan(text: '🏢 '),
            TextSpan(text: '사업자 인증 회원', style: F.inter(size: 11.5, color: C.goldBright, w: FontWeight.w500)),
            const TextSpan(text: '이면 상업용 헤비듀티 기구를 '),
            TextSpan(text: '도매가·부가세 별도', style: F.inter(size: 11.5, color: C.goldBright, w: FontWeight.w500)),
            const TextSpan(text: '로 구매할 수 있어요. 대량 구매 할인, 무료 배송·설치, 3년 A/S까지 지원합니다.'),
          ])),
        ),
        const SizedBox(height: 14),
        Row(children: [ben('💰', '도매가'), ben('🚚', '무료 설치'), ben('🛠️', '3년 A/S'), ben('📋', '리스·할부')]),
        const SizedBox(height: 18),
        ChipRow(items: b2bCats, selected: b2bCat, onSelect: (v) => setState(() => b2bCat = v)),
        SectHead(b2bCat == '전체' ? '전체 기구' : b2bCat, more: '${list.length}종', top: 12),
        for (final i in list)
          Box(
            margin: const EdgeInsets.only(bottom: 11),
            padding: const EdgeInsets.all(13),
            child: Row(children: [
              EmojiTile(i.em, size: 64, font: 30, badge: i.moq),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.brand, style: F.inter(size: 9, color: C.gold, ls: .04)),
                  const SizedBox(height: 3),
                  Text(i.name, style: F.inter(size: 12.5, w: FontWeight.w500)),
                  const SizedBox(height: 5),
                  Text(i.spec, style: F.inter(size: 9.5, color: C.textDim, w: FontWeight.w300, h: 1.4)),
                  const SizedBox(height: 8),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: '${won(i.price)}~', style: F.gnum(size: 15)),
                    TextSpan(text: '  도매가 · VAT 별도', style: F.inter(size: 9, color: C.textFaint)),
                  ])),
                ]),
              ),
              LineButton('견적담기', size: 10, padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8), onTap: () => _s.toast('${i.name} 견적을 담았어요')),
            ]),
          ),
        const SectHead('운영자 전용 서비스', more: '헬스장 창업·운영', top: 22),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: [
            svc('🔄', '중고 기구 거래', '안 쓰는 기구 판매 & 검수된 중고 매물 보기', '매물 보기 ›', MarketView.used),
            svc('📊', '운영 대시보드', '회원·매출·기구 A/S를 한눈에 관리', '대시보드 ›', MarketView.dash),
            svc('🏗️', '인테리어·시공', '바닥·거울·조명·동선 설계 · 턴키 시공', '견적 문의 ›', MarketView.b2bForm),
            svc('🧑‍🏫', 'PT·트레이너 채용', '검증된 트레이너 매칭 · 채용 공고 등록', '채용 의뢰 ›', MarketView.b2bForm),
          ],
        ),
      ],
    );
  }

  Widget _b2bForm() {
    Widget fg(String label, Widget child, {bool req = false}) => Padding(
          padding: const EdgeInsets.only(bottom: 17),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text.rich(TextSpan(children: [
              TextSpan(text: label, style: F.inter(size: 10.5, color: C.textDim, ls: .02)),
              if (req) TextSpan(text: ' *', style: F.inter(size: 10.5, color: C.cHigh)),
            ])),
            const SizedBox(height: 7),
            child,
          ]),
        );
    Widget input(String hint, {int lines = 1}) => TextField(
          maxLines: lines,
          style: F.inter(size: 12.5),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: F.inter(size: 12.5, color: C.textFaint),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.hairlineSoft)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.gold)),
          ),
        );
    Widget chips(List<String> items, bool Function(String) isOn, void Function(String) tap) => Wrap(spacing: 8, runSpacing: 8, children: [
          for (final c in items)
            GestureDetector(
              onTap: () => setState(() => tap(c)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(border: Border.all(color: isOn(c) ? C.gold : C.hairlineSoft), gradient: isOn(c) ? softGold(.13) : null),
                child: Text(c, style: F.inter(size: 11, color: isOn(c) ? C.ivory : C.textDim)),
              ),
            ),
        ]);
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 전용관', onBack: () => _s.goMarket(MarketView.b2b), title: '사업자 인증 · 견적 요청', titleSize: 22, desc: '정보를 남겨주시면 전담 매니저가 도매 견적과 함께 연락드려요.'),
      footer: [GoldButton('견적·상담 신청하기', upper: false, onTap: () => _s.goMarket(MarketView.b2bDone))],
      children: [
        fg('상호명', input('예: 스틸핏 강남점'), req: true),
        fg('사업자등록번호', input('000-00-00000'), req: true),
        fg('대표자명 · 연락처', input('홍길동 · 010-0000-0000'), req: true),
        fg('매장 주소', input('서울 강남구 …')),
        fg('오픈 유형', chips(['신규 오픈', '리뉴얼', '증설'], (c) => c == fOpen, (c) => fOpen = c), req: true),
        fg('매장 규모', chips(['~30평', '30~60평', '60~100평', '100평+'], (c) => c == fSize, (c) => fSize = c)),
        fg('관심 품목 (중복 선택)', chips(['파워랙', '셀렉토라이즈드', '유산소', '프리웨이트', '인테리어', '중고거래'], fItems.contains, (c) => fItems.contains(c) ? fItems.remove(c) : fItems.add(c))),
        fg('요청 사항', input('예산·희망 납기·필요 대수 등을 적어주세요', lines: 3)),
      ],
    );
  }

  Widget _b2bDone() => ScreenFrame(
        header: const StepTitle(eyebrow: 'Submitted'),
        footer: [GoldButton('전용관으로 돌아가기', upper: false, onTap: () => _s.goMarket(MarketView.b2b))],
        children: const [
          ConfirmHero('견적 요청이 접수됐어요', '사업자 인증 확인 후, 전담 매니저가\n영업일 1일 내 도매 견적과 함께 연락드립니다.'),
          DetailList([
            ['접수번호', 'WW-B2B-20260811-014'],
            ['담당', 'WILD WEAR B2B팀'],
            ['예상 회신', '영업일 1일 이내'],
          ]),
          HintCard('사업자 인증이 완료되면', '전용관 도매가·리스/할부 견적을 앱에서 바로 확인할 수 있어요.', top: 16),
        ],
      );

  /* ================= 중고 기구 거래 ================= */
  Widget _used() {
    final list = usedCat == '전체' ? usedItems : usedItems.where((i) => i.cat == usedCat).toList();
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 전용관', onBack: () => _s.goMarket(MarketView.b2b), title: '중고 기구 거래', titleSize: 22, desc: '검수·등급 인증된 상업용 중고 기구를 사고팔아요.'),
      footer: [GoldButton('＋ 내 기구 팔기 (무료 검수 신청)', upper: false, onTap: () => _s.goMarket(MarketView.b2bForm))],
      children: [
        ChipRow(items: usedCats, selected: usedCat, onSelect: (v) => setState(() => usedCat = v)),
        SectHead(usedCat == '전체' ? '전체 매물' : usedCat, more: '${list.length}건', top: 12),
        for (final i in list)
          Box(
            onTap: () => _s.toast('${i.name} 판매자와 채팅을 시작해요'),
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              EmojiTile(i.em, size: 62, font: 28, badge: i.st == 'hold' ? '예약중' : '판매중', badgeColor: i.st == 'hold' ? C.cHigh : C.cLow),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(i.name, style: F.inter(size: 12.5, w: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(i.cond, style: F.inter(size: 9.5, color: C.textDim, w: FontWeight.w300)),
                  const SizedBox(height: 5),
                  Text('📍 ${i.loc}', style: F.inter(size: 9, color: C.textFaint)),
                  const SizedBox(height: 7),
                  Text.rich(TextSpan(children: [
                    TextSpan(text: won(i.price), style: F.gnum(size: 15)),
                    TextSpan(text: '  ${won(i.was)}', style: F.inter(size: 9, color: C.textFaint).copyWith(decoration: TextDecoration.lineThrough)),
                  ])),
                ]),
              ),
              Tag(i.grade, color: C.goldBright, border: C.goldDim, size: 8.5),
            ]),
          ),
      ],
    );
  }

  /* ================= 운영 대시보드 ================= */
  Widget _dash() {
    Widget kpi(String l, String v, String u, String d, bool up) => Box(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: F.inter(size: 9.5, color: C.textDim)),
            const SizedBox(height: 5),
            Text.rich(TextSpan(children: [TextSpan(text: v, style: F.gnum(size: 22)), TextSpan(text: u, style: F.inter(size: 9, color: C.textFaint))])),
            const SizedBox(height: 5),
            Text(d, style: F.inter(size: 9, color: up ? C.cLow : C.cHigh)),
          ]),
        );
    Widget asRow(String e, String t, String d, String st, Color c) => Divided(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(children: [
            Text(e, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 11),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t, style: F.inter(size: 11.5)),
                const SizedBox(height: 2),
                Text(d, style: F.inter(size: 9, color: C.textFaint)),
              ]),
            ),
            Tag(st, color: c, border: c.op(.42), size: 9),
          ]),
        );
    const bars = [['3월', .52], ['4월', .61], ['5월', .58], ['6월', .72], ['7월', .80], ['8월', .92]];
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 전용관', onBack: () => _s.goMarket(MarketView.b2b), title: '운영 대시보드', titleSize: 22, desc: '스틸핏 강남점 · 2026년 8월'),
      footer: [
        GoldButton('🛠️ A/S 접수하기', upper: false, onTap: () => _s.toast('A/S 접수가 WILD WEAR B2B팀에 전달됐어요')),
        GoldButton('회원 관리 열기', ghost: true, upper: false, margin: const EdgeInsets.only(top: 10), onTap: () => _s.toast('회원 관리 화면은 개발 버전에서 연결돼요')),
      ],
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.75,
          children: [
            kpi('이번 달 매출', '3,240', ' 만원', '▲ 12% vs 전월', true),
            kpi('활성 회원', '412', ' 명', '▲ 23명 순증', true),
            kpi('이번 달 신규', '38', ' 명', '▲ 9 vs 전월', true),
            kpi('만료 예정(7일)', '17', ' 명', '재등록 유도 필요', false),
          ],
        ),
        const SectHead('최근 6개월 매출', more: '만원', top: 20),
        SizedBox(
          height: 112,
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (int i = 0; i < bars.length; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.5),
                  child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                    Container(
                      height: 96 * (bars[i][1] as double),
                      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: i == bars.length - 1 ? const [C.goldBright, C.gold] : const [C.goldBright, C.goldDim])),
                    ),
                    const SizedBox(height: 4),
                    Text(bars[i][0] as String, style: F.inter(size: 8, color: C.textFaint)),
                  ]),
                ),
              ),
          ]),
        ),
        const SectHead('기구 A/S 현황', more: '전체 42대', top: 14),
        asRow('🏃', '트레드밀 #3', '구동벨트 마모 · 점검 권장', '점검필요', C.cMid),
        asRow('🔩', '케이블 크로스오버 #1', '케이블 교체 수리 진행 중 (D-2)', '수리중', C.cHigh),
        asRow('🦵', '레그프레스 #2', '최근 점검 완료 · 정상', '정상', C.cLow),
        asRow('🏋️', '스미스머신 #1', '정기 점검 D-9', '정상', C.cLow),
        const HintCard('점검필요 1건 · 수리중 1건.', 'A/S는 구매처(WILD WEAR B2B)에서 무상 접수돼요.', top: 16),
      ],
    );
  }
}
