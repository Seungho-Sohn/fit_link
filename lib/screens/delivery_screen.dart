import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});
  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final search = TextEditingController();
  String sort = 'reco';
  bool favView = false;
  int delivMode = 0, payMode = 0;

  static const sorts = [['reco', '추천순'], ['rating', '별점순'], ['dist', '거리순'], ['tip', '배달비순'], ['time', '빠른배달순']];

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(_s.delivView),
      child: switch (_s.delivView) {
        DelivView.home => _home(),
        DelivView.store => _store(),
        DelivView.cart => _cart(),
        DelivView.pay => _pay(),
        DelivView.done => _done(),
      },
    );
  }

  /* ================= 매장 목록 ================= */
  Widget _home() {
    final q = search.text.trim().toLowerCase();
    final list = dshops.where((s) => (!favView || _s.dfavs.contains(s.id)) && (q.isEmpty || '${s.name}${s.tags}${s.menu}'.toLowerCase().contains(q))).toList();
    int cmp(DShop a, DShop b) {
      switch (sort) {
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'dist':
          return a.dist.compareTo(b.dist);
        case 'tip':
          return a.tip.compareTo(b.tip);
        case 'time':
          return a.time.compareTo(b.time);
        default:
          return (b.rating - b.dist * .2).compareTo(a.rating - a.dist * .2);
      }
    }

    list.sort(cmp);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(padding: const EdgeInsets.only(left: 4), child: Text('HEALTH', style: F.bodoni(size: 11, w: FontWeight.w400, color: C.gold, ls: .62))),
              const SizedBox(height: 9),
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFF4ECD8), C.goldBright, C.gold, C.goldDim], stops: [.04, .46, .82, 1]).createShader(r),
                child: Text('DELIVERY', style: F.bodoni(size: 24, ls: .19)),
              ),
              Container(width: 30, height: 1, margin: const EdgeInsets.only(left: 4, top: 11), decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.gold, Colors.transparent]))),
              const SizedBox(height: 9),
              Text('헬스인 전용 클린식 · 총알배송', style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300)),
            ]),
          ),
          GestureDetector(
            onTap: () => setState(() => favView = !favView),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(border: Border.all(color: favView ? C.goldDim : C.hairlineSoft)),
              child: Text('${favView ? '♥' : '♡'} 찜', style: F.inter(size: 10.5, color: favView ? C.live : C.textDim)),
            ),
          ),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 8, 22, 20), children: [
          searchBar(search, '매장 · 메뉴 검색 (예: 닭가슴살)', () => setState(() {})),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [for (final s in sorts) SelChip(s[1], on: sort == s[0], onTap: () => setState(() => sort = s[0]))]),
          ),
          const SizedBox(height: 14),
          Box(
            margin: const EdgeInsets.only(bottom: 13),
            border: C.gold,
            gradient: LinearGradient(colors: [C.goldA(.17), C.goldA(.03)]),
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
            child: Row(children: [
              const Text('🎫', style: TextStyle(fontSize: 21)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FIT 클럽 · 무료배달 무제한', style: F.inter(size: 12.5, w: FontWeight.w600, color: C.goldBright)),
                  const SizedBox(height: 3),
                  Text('월 3,990원 · 헬스 배달 배달팁 0원 + 클럽 전용가', style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                ]),
              ),
              GestureDetector(
                onTap: () => _s.toast('FIT 클럽 첫 달 무료로 시작했어요'),
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8), decoration: const BoxDecoration(gradient: goldGradient), child: Text('가입', style: F.inter(size: 10, w: FontWeight.w600, color: C.ink))),
              ),
            ]),
          ),
          SectHead(favView ? '찜한 매장' : '전체 매장', more: '${list.length}곳'),
          if (list.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 50),
              child: Text(favView ? '찜한 매장이 없어요.\n하트를 눌러 저장해보세요.' : '검색 결과가 없어요.', textAlign: TextAlign.center, style: F.inter(size: 12, color: C.textFaint, h: 1.7)),
            ),
          for (final s in list) _shopCard(s),
        ]),
      ),
    ]);
  }

  Widget _shopCard(DShop s) {
    final fav = _s.dfavs.contains(s.id);
    return Box(
      onTap: () => _s.openShop(s.id),
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(13),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 74,
          height: 74,
          child: Stack(children: [
            EmojiTile(s.em, size: 74, font: 33, badge: s.fast ? '⚡총알배송' : null, badgeColor: C.live),
            Positioned(
              top: 3,
              right: 3,
              child: GestureDetector(
                onTap: () => _s.toggleFav(s.id),
                child: Container(width: 22, height: 22, alignment: Alignment.center, color: const Color(0x8C0A0A0B), child: Text(fav ? '♥' : '♡', style: F.inter(size: 12, color: fav ? C.live : C.textFaint))),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 13),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(s.name, style: F.inter(size: 13.5, w: FontWeight.w500))),
              Text('★ ${s.rating}', style: F.inter(size: 10, color: C.goldBright)),
            ]),
            const SizedBox(height: 3),
            Text('${s.tags} · ${s.dist}km', style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
            const SizedBox(height: 8),
            Wrap(spacing: 10, runSpacing: 3, children: [
              Text('🛵 ${s.time}~${s.time + 6}분', style: F.inter(size: 9.5, color: C.textDim, w: FontWeight.w300)),
              Text('배달팁 ${s.tip == 0 ? '0원' : won(s.tip)}', style: F.inter(size: 9.5, color: C.textDim, w: FontWeight.w300)),
              Text('쿠팡이츠보다 ${s.cheap}%↓', style: F.inter(size: 9.5, color: C.cLow)),
            ]),
            Container(
              margin: const EdgeInsets.only(top: 9),
              padding: const EdgeInsets.only(top: 9),
              decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: s.menu, style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
                TextSpan(text: '  ${won(s.price)}', style: F.gnum(size: 14)),
                TextSpan(text: '  ${won(s.was)}', style: F.inter(size: 9.5, color: C.textFaint).copyWith(decoration: TextDecoration.lineThrough)),
              ])),
            ),
          ]),
        ),
      ]),
    );
  }

  /* ================= 매장 메뉴 ================= */
  Widget _store() {
    final s = dshops.firstWhere((x) => x.id == _s.curShopId, orElse: () => dshops[1]);
    final fav = _s.dfavs.contains(s.id);
    final cats = <String>[];
    for (final m in dmenu) {
      if (!cats.contains(m.cat)) cats.add(m.cat);
    }
    Widget info(String k, String v) => Expanded(
          child: Box(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
            child: Column(children: [Text(k, style: F.inter(size: 8.5, color: C.textFaint)), const SizedBox(height: 4), Text(v, style: F.inter(size: 11))]),
          ),
        );
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 배달 목록', onBack: () => _s.goDeliv(DelivView.home)),
      footer: _s.dCount > 0 ? [GoldButton('장바구니 보기 · ${_s.dCount}개 · ${won(_s.dTotal)}', upper: false, onTap: () => _s.goDeliv(DelivView.cart))] : null,
      children: [
        Divided(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(children: [
            EmojiTile(s.em, size: 64, font: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.name, style: F.kr(size: 20)),
                const SizedBox(height: 5),
                Text('★ ${s.rating} · 리뷰 ${200 + (s.rating * 180).round()}', style: F.inter(size: 11, color: C.goldBright)),
                const SizedBox(height: 4),
                Text('${s.tags} · ${s.dist}km', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
              ]),
            ),
            GestureDetector(
              onTap: () => _s.toggleFav(s.id),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: fav ? C.goldDim : C.hairlineSoft)),
                child: Text(fav ? '♥' : '♡', style: F.inter(size: 16, color: fav ? C.live : C.textFaint)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 15),
        Row(children: [info('배달', '⚡${s.time}~${s.time + 6}분'), info('배달팁', s.tip == 0 ? '0원' : won(s.tip)), info('최소주문', '12,000원')]),
        Box(
          margin: const EdgeInsets.only(top: 14),
          border: C.goldDim,
          gradient: softGold(.10),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Text.rich(TextSpan(style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300), children: [
            const TextSpan(text: '🎁 '),
            TextSpan(text: '리뷰 이벤트', style: F.inter(size: 11, color: C.goldBright, w: FontWeight.w500)),
            const TextSpan(text: ' · 첫 리뷰 남기면 프로틴바 or 아메리카노 증정!'),
          ])),
        ),
        GestureDetector(
          onTap: () => _s.reorder(['d1']),
          child: Container(
            margin: const EdgeInsets.only(top: 11),
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: C.hairline)),
            child: Row(children: [
              const Text('🔄', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('지난번 주문', style: F.inter(size: 9, color: C.textFaint)),
                  const SizedBox(height: 2),
                  Text('저염 닭가슴살 도시락 · 1개', style: F.inter(size: 11.5)),
                ]),
              ),
              Text('재주문 ›', style: F.inter(size: 10, color: C.goldBright)),
            ]),
          ),
        ),
        for (final c in cats) ...[
          Padding(padding: const EdgeInsets.only(top: 20, bottom: 2), child: Text(c, style: F.inter(size: 12.5, w: FontWeight.w600, ls: .02))),
          for (final m in dmenu.where((x) => x.cat == c))
            Divided(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(children: [
                EmojiTile(m.em, size: 56, font: 26, badge: m.best ? 'BEST' : null),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(m.name, style: F.inter(size: 12.5, w: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(m.desc, style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300, h: 1.4)),
                    const SizedBox(height: 7),
                    Text(won(m.price), style: F.gnum(size: 14)),
                  ]),
                ),
                GestureDetector(
                  onTap: () => _s.dAdd(m.id),
                  child: Container(width: 32, height: 32, alignment: Alignment.center, decoration: BoxDecoration(border: Border.all(color: C.gold)), child: Text('+', style: F.inter(size: 17, color: C.goldBright))),
                ),
              ]),
            ),
        ],
      ],
    );
  }

  /* ================= 장바구니 ================= */
  Widget _cart() {
    final empty = _s.dcart.isEmpty;
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 메뉴', onBack: () => _s.goDeliv(DelivView.store), title: '장바구니', titleSize: 22),
      footer: empty ? null : [GoldButton('결제하기', upper: false, onTap: () => _s.goDeliv(DelivView.pay))],
      children: empty
          ? [Padding(padding: const EdgeInsets.symmetric(vertical: 50), child: Text('장바구니가 비어 있어요.\n메뉴를 담아보세요.', textAlign: TextAlign.center, style: F.inter(size: 12, color: C.textFaint, h: 1.7)))]
          : [
              for (final e in _s.dcart.entries.toList())
                Divided(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(children: [
                    EmojiTile(menuById(e.key).em, size: 46, font: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(menuById(e.key).name, style: F.inter(size: 12)),
                        const SizedBox(height: 4),
                        Text(won(menuById(e.key).price * e.value), style: F.gnum(size: 11)),
                      ]),
                    ),
                    qtyCtrl(e.value, () => _s.dQty(e.key, -1), () => _s.dQty(e.key, 1)),
                  ]),
                ),
              const SizedBox(height: 18),
              _row('상품금액', won(_s.dTotal)),
              _row('배달팁', '0원'),
              _row('결제 예정', won(_s.dTotal), total: true),
            ],
    );
  }

  Widget _row(String k, String v, {bool total = false, Color? vc}) => Container(
        margin: EdgeInsets.only(top: total ? 6 : 0),
        padding: EdgeInsets.only(top: total ? 14 : 9, bottom: 9),
        decoration: BoxDecoration(border: total ? const Border(top: BorderSide(color: C.hairlineSoft)) : null),
        child: Row(children: [
          Expanded(child: Text(k, style: F.inter(size: total ? 13 : 12, color: total ? C.ivory : C.textDim, w: FontWeight.w300))),
          Text(v, style: total ? F.gnum(size: 17) : F.inter(size: 12, color: vc ?? C.textDim, w: FontWeight.w300)),
        ]),
      );

  /* ================= 주문 · 결제 ================= */
  Widget _pay() {
    final c = _s.payCalc();
    Widget sec(String title, Widget child) => Box(
          margin: const EdgeInsets.only(bottom: 11),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: F.inter(size: 9.5, color: C.textFaint, ls: .05)), const SizedBox(height: 6), child]),
        );
    Widget opts(List<List<String>> items, int sel, ValueChanged<int> f) => Row(children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => f(i)),
                child: Container(
                  margin: EdgeInsets.only(right: i < items.length - 1 ? 9 : 0, top: 3),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
                  decoration: BoxDecoration(border: Border.all(color: sel == i ? C.gold : C.hairlineSoft), gradient: sel == i ? softGold(.13) : null),
                  child: Column(children: [
                    Text(items[i][0], style: F.inter(size: 10.5, color: sel == i ? C.ivory : C.textDim)),
                    if (items[i].length > 1) Text(items[i][1], style: F.inter(size: 8, color: C.textFaint)),
                  ]),
                ),
              ),
            ),
        ]);
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 장바구니', onBack: () => _s.goDeliv(DelivView.cart), title: '주문 · 결제', titleSize: 22),
      footer: [GoldButton('${won(c.total)} 결제하기', upper: false, onTap: _s.placeDOrder)],
      children: [
        sec('배달 주소', Text.rich(TextSpan(children: [TextSpan(text: '서울 강남구 테헤란로 · 집 ', style: F.inter(size: 12.5)), TextSpan(text: '(현관 비밀번호 1234)', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300))]))),
        sec('배달 방식', opts(const [['알뜰배달', '묶음 · 0원'], ['한집배달', '직배송 · 2,000원']], delivMode, (i) => delivMode = i)),
        sec('결제 수단', opts(const [['FIT페이'], ['신용카드'], ['카카오페이']], payMode, (i) => payMode = i)),
        sec(
          '요청 사항',
          TextField(
            maxLines: 2,
            style: F.inter(size: 11),
            decoration: InputDecoration(
              hintText: '예: 문 앞에 놓아주세요 · 수저 안 주셔도 돼요',
              hintStyle: F.inter(size: 11, color: C.textFaint),
              contentPadding: const EdgeInsets.all(11),
              enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.hairlineSoft)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.gold)),
            ),
          ),
        ),
        sec(
          'WILD WEAR 포인트',
          Row(children: [
            Expanded(
              child: Text.rich(TextSpan(style: F.inter(size: 11, color: C.textDim), children: [
                const TextSpan(text: '보유 '),
                TextSpan(text: _s.pointsStr, style: F.inter(size: 11, color: C.goldBright)),
                const TextSpan(text: ' · 결제에 사용'),
              ])),
            ),
            GestureDetector(
              onTap: _s.toggleDPts,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 24,
                padding: const EdgeInsets.all(2),
                alignment: _s.dUsePts ? Alignment.centerRight : Alignment.centerLeft,
                decoration: BoxDecoration(color: _s.dUsePts ? C.gold : C.hairline, borderRadius: BorderRadius.circular(12)),
                child: Container(width: 20, height: 20, decoration: BoxDecoration(shape: BoxShape.circle, color: _s.dUsePts ? C.ink : C.ivory)),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 7),
        _row('상품금액', won(c.subtotal)),
        _row('배달팁', '0원'),
        _row('FIT 클럽 할인', '−${won(c.clubDiscount)}', vc: C.cLow),
        if (c.pointsUsed > 0) _row('포인트 사용', '−${won(c.pointsUsed)}', vc: C.cLow),
        _row('총 결제금액', won(c.total), total: true),
        _row('결제 시 적립 (등급 ${_s.tier.rateStr}%)', '+${comma(c.pointsEarned)}P', vc: C.goldBright),
      ],
    );
  }

  /* ================= 주문 완료 · 배달 추적 ================= */
  Widget _done() {
    const steps = ['주문접수', '조리완료', '픽업', '배달중', '도착'];
    return ScreenFrame(
      header: const StepTitle(eyebrow: '주문 완료'),
      footer: [GoldButton('홈으로', upper: false, onTap: () => _s.go(AppPage.home))],
      children: [
        const ConfirmHero('주문이 접수됐어요', '프로틴키친에서 조리를 시작합니다.\n실시간 배달 현황을 확인해보세요.'),
        Box(
          margin: const EdgeInsets.only(top: 20),
          border: C.goldDim,
          gradient: softGold(.12),
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
          child: Column(children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('● 조리 중', style: F.inter(size: 10, color: C.live, ls: .03)),
                  const SizedBox(height: 4),
                  Text('예상 도착까지', style: F.inter(size: 14, w: FontWeight.w500)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text.rich(TextSpan(children: [TextSpan(text: '18', style: F.gnum(size: 25)), TextSpan(text: '분', style: F.serif(size: 12, color: C.goldBright))])),
                const SizedBox(height: 4),
                Text('예상 도착', style: F.inter(size: 8.5, color: C.textFaint, ls: .05)),
              ]),
            ]),
            const SizedBox(height: 17),
            LayoutBuilder(builder: (_, cons) {
              final w = cons.maxWidth;
              return Stack(children: [
                Positioned(top: 5, left: w * .1, right: w * .1, child: Container(height: 1, color: C.hairline)),
                Positioned(top: 5, left: w * .1, child: Container(height: 1, width: w * .12, color: C.goldBright)),
                Row(children: [
                  for (int i = 0; i < steps.length; i++)
                    Expanded(
                      child: Column(children: [
                        Container(
                          width: 11,
                          height: 11,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == 0 ? C.goldBright : C.hairline,
                            boxShadow: i == 0 ? [BoxShadow(color: C.goldA(.22), spreadRadius: 4)] : null,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(steps[i], style: F.inter(size: 8, color: i == 0 ? C.goldBright : C.textFaint)),
                      ]),
                    ),
                ]),
              ]);
            }),
          ]),
        ),
        DetailList([
          const ['주문번호', 'FL-D-20260810-0027'],
          ['결제금액', won(_s.lastDelivTotal)],
        ]),
      ],
    );
  }
}
