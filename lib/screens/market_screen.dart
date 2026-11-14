import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'market_b2b.dart';

AppState get _s => AppState.I;

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String cat = '전체';
  final b2b = B2BFilters(); // B2B 화면 간 이동해도 유지되도록 마켓 화면이 보관
  final search = TextEditingController();
  int qty = 1;
  bool added = false;
  Timer? dealTimer;
  String dealLeft = '--:--:--';

  @override
  void initState() {
    super.initState();
    _tick();
    dealTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final n = DateTime.now();
    final end = DateTime(n.year, n.month, n.day + 1);
    final s = end.difference(n).inSeconds;
    final h = (s ~/ 3600).toString().padLeft(2, '0');
    final m = (s % 3600 ~/ 60).toString().padLeft(2, '0');
    final ss = (s % 60).toString().padLeft(2, '0');
    if (mounted) setState(() => dealLeft = '종료까지 $h:$m:$ss');
  }

  @override
  void dispose() {
    dealTimer?.cancel();
    search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _s,
      builder: (_, __) => KeyedSubtree(
        key: ValueKey(_s.marketView),
        child: switch (_s.marketView) {
          MarketView.home => _home(),
          MarketView.detail => _detail(),
          MarketView.store => _store(),
          MarketView.cart => _cart(),
          MarketView.done => _done(),
          MarketView.b2b => B2BView(MarketView.b2b, b2b),
          MarketView.b2bForm => B2BView(MarketView.b2bForm, b2b),
          MarketView.b2bDone => B2BView(MarketView.b2bDone, b2b),
          MarketView.used => B2BView(MarketView.used, b2b),
          MarketView.dash => B2BView(MarketView.dash, b2b),
          MarketView.gymGear => B2BView(MarketView.gymGear, b2b),
        },
      ),
    );
  }

  void openProduct(String id) {
    setState(() {
      qty = 1;
      added = false;
    });
    _s.openProduct(id);
  }

  /* ================= 마켓 홈 ================= */
  Widget _home() {
    final q = search.text.trim().toLowerCase();
    final list = products.where((p) {
      final catOk = cat == '전체' || p.cat == cat;
      final qOk = q.isEmpty || p.name.toLowerCase().contains(q) || sellers[p.seller]!.name.toLowerCase().contains(q) || p.cat.toLowerCase().contains(q);
      return catOk && qOk;
    }).toList();

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: _wordmark('Healthcare', 'Marketplace', '여러 판매자의 장비 · 운동복 · 보충제 · 이용권을 한 곳에서')),
          GestureDetector(
            onTap: () => _s.goMarket(MarketView.cart),
            child: Stack(clipBehavior: Clip.none, children: [
              Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(border: Border.all(color: C.hairline)), child: const Icon(Icons.shopping_cart_outlined, size: 17, color: C.gold)),
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 16),
                  height: 16,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: C.gold, borderRadius: BorderRadius.circular(8)),
                  child: Text('${_s.cartCount}', style: F.inter(size: 9, w: FontWeight.w700, color: C.ink)),
                ),
              ),
            ]),
          ),
        ]),
      ),
      Expanded(
        child: ListView(padding: const EdgeInsets.fromLTRB(22, 0, 22, 20), children: [
          searchBar(search, '브랜드 · 상품 · 판매자 검색', () => setState(() {})),
          ChipRow(items: marketCats, selected: cat, solid: true, onSelect: (v) => setState(() => cat = v)),
          const SizedBox(height: 16),
          Box(
            onTap: () => _s.goMarket(MarketView.b2b),
            margin: const EdgeInsets.only(bottom: 16),
            border: C.gold,
            gradient: softGold(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(children: [
              const EmojiTile('🏢', size: 44, font: 22),
              const SizedBox(width: 13),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('FOR GYM OWNERS', style: F.serif(size: 9, w: FontWeight.w600, color: C.gold, ls: .14)),
                  const SizedBox(height: 4),
                  Text('헬스장 운영자 전용관', style: F.kr(size: 14.5)),
                  const SizedBox(height: 4),
                  Text('상업용 기구 도매가 · 대량구매 · 설치·A/S 포함', style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                ]),
              ),
              Text('›', style: F.inter(size: 18, color: C.goldBright)),
            ]),
          ),
          // 타임특가
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.fromLTRB(15, 14, 15, 15),
            decoration: BoxDecoration(
              border: Border.all(color: C.goldDim),
              gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [C.live.op(.10), C.goldA(.02)]),
            ),
            child: Column(children: [
              Row(children: [
                Expanded(child: Text('⚡ 오늘의 타임특가', style: F.inter(size: 12.5, w: FontWeight.w600))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: C.live.op(.1), border: Border.all(color: C.live.op(.35))),
                  child: Text(dealLeft, style: F.serif(size: 15, w: FontWeight.w600, color: C.live, ls: .06)),
                ),
              ]),
              const SizedBox(height: 13),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (final d in deals) _dealCard(productById(d.productId), d.off),
                ]),
              ),
            ]),
          ),
          const SectHead('인기 판매자 스토어', more: '전체보기'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final e in sellers.entries) _sellerMini(e.key, e.value)]),
          ),
          SectHead(cat == '전체' ? '전체 상품' : cat, more: '${list.length}개', top: 16),
          if (list.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 30), child: Center(child: Text('검색 결과가 없어요.', style: F.inter(size: 12, color: C.textFaint, w: FontWeight.w300))))
          else
            _grid(list),
        ]),
      ),
    ]);
  }

  Widget _wordmark(String l1, String l2, String desc) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(left: 4), child: Text(l1.toUpperCase(), style: F.bodoni(size: 11, w: FontWeight.w400, color: C.gold, ls: .62))),
        const SizedBox(height: 9),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => const LinearGradient(colors: [Color(0xFFF4ECD8), C.goldBright, C.gold, C.goldDim], stops: [.04, .46, .82, 1]).createShader(r),
          child: Text(l2.toUpperCase(), style: F.bodoni(size: 24, ls: .19)),
        ),
        Container(width: 30, height: 1, margin: const EdgeInsets.only(left: 4, top: 11), decoration: const BoxDecoration(gradient: LinearGradient(colors: [C.gold, Colors.transparent]))),
        const SizedBox(height: 9),
        Text(desc, style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300)),
      ]);

  Widget _dealCard(Product p, int off) {
    final now = (p.price * (100 - off) / 100 / 100).round() * 100;
    return GestureDetector(
      onTap: () => openProduct(p.id),
      child: SizedBox(
        width: 118,
        child: Padding(
          padding: const EdgeInsets.only(right: 11),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 82,
              decoration: BoxDecoration(color: C.panel, border: Border.all(color: C.hairlineSoft)),
              child: Stack(children: [
                Center(child: Text(p.emoji, style: const TextStyle(fontSize: 34))),
                Positioned(top: 0, left: 0, child: Container(color: C.live, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), child: Text('-$off%', style: F.inter(size: 10, w: FontWeight.w700, color: const Color(0xFF1A1207))))),
              ]),
            ),
            const SizedBox(height: 9),
            // 두 줄 높이를 항상 확보해 카드 높이를 맞춘다 (글자 배율 반영)
            SizedBox(height: MediaQuery.textScalerOf(context).scale(29), child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: F.inter(size: 10.5, h: 1.35))),
            const SizedBox(height: 4),
            Text(won(p.price), style: F.inter(size: 9.5, color: C.textFaint).copyWith(decoration: TextDecoration.lineThrough)),
            Text(won(now), style: F.gnum(size: 15)),
          ]),
        ),
      ),
    );
  }

  Widget _sellerMini(String id, Seller sl) {
    final feat = id == 'wildwear';
    return GestureDetector(
      onTap: () => _s.openSellerStore(id),
      child: Container(
        width: feat ? 74 : 62,
        margin: const EdgeInsets.only(right: 12, bottom: 6),
        child: Column(children: [
          Container(
            width: feat ? 66 : 52,
            height: feat ? 66 : 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: C.panel,
              border: Border.all(color: feat ? C.goldBright : (sl.official ? C.gold : C.hairline), width: feat ? 2 : 1),
              gradient: feat ? RadialGradient(center: const Alignment(-.36, -.48), colors: [const Color(0x52F5E3A8), C.goldA(.06), C.panel], stops: const [0, .6, 1]) : null,
              boxShadow: feat ? const [BoxShadow(color: Color(0x8CF0DA92), blurRadius: 18)] : null,
            ),
            child: feat ? const WwHolo(width: 52, height: 50, deep: false) : Text(sl.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(height: 7),
          if (feat) Text('★ OFFICIAL', style: F.inter(size: 7, color: C.gold, ls: .14)),
          Text(feat ? 'WILD WEAR' : sl.name.replaceAll(' Korea', ''),
              textAlign: TextAlign.center, maxLines: 2, style: F.serif(size: 10, w: FontWeight.w600, color: feat ? C.goldBright : C.textDim, h: 1.3)),
        ]),
      ),
    );
  }

  Widget _grid(List<Product> list) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: list.length,
        // 이미지 104 + 글자 영역 118 (글자 배율만큼 늘림)
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 104 + MediaQuery.textScalerOf(context).scale(118)),
        itemBuilder: (_, i) => _productCard(list[i]),
      );

  Widget _productCard(Product p) {
    final sl = sellers[p.seller]!;
    return GestureDetector(
      onTap: () => openProduct(p.id),
      child: Container(
        decoration: BoxDecoration(border: Border.all(color: C.hairlineSoft)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 104,
            decoration: BoxDecoration(
              color: C.panel,
              border: const Border(bottom: BorderSide(color: C.hairlineSoft)),
              image: p.img != null ? DecorationImage(image: AssetImage(p.img!), fit: BoxFit.cover) : null,
            ),
            child: Stack(children: [
              if (p.img == null) Center(child: Text(p.emoji, style: const TextStyle(fontSize: 28))),
              if (p.flag != null) Positioned(top: 0, left: 0, child: Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), child: Text(p.flag!, style: F.inter(size: 8, w: FontWeight.w700, color: C.ink, ls: .08)))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${sl.emoji} ${sl.name}', maxLines: 1, overflow: TextOverflow.ellipsis, style: F.inter(size: 8.5, color: C.gold, ls: .06)),
              const SizedBox(height: 5),
              Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: F.inter(size: 11.5, w: FontWeight.w500, h: 1.4)),
              const SizedBox(height: 6),
              Text(won(p.price), style: F.gnum(size: 13)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                TextSpan(text: '★ ${p.rating.toStringAsFixed(1)}', style: F.inter(size: 9.5, color: C.good, w: FontWeight.w500)),
                TextSpan(text: ' · 리뷰 ${p.reviews}', style: F.inter(size: 9.5, color: C.textFaint)),
              ])),
            ]),
          ),
        ]),
      ),
    );
  }

  /* ================= 상품 상세 ================= */
  Widget _detail() {
    final p = productById(_s.curProductId);
    final sl = sellers[p.seller]!;
    final revs = reviews[p.id] ?? defaultReviews;
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 마켓으로', onBack: () => _s.goMarket(MarketView.home), title: p.name, titleSize: 22),
      footer: [
        GoldButton(added ? '장바구니에 담았어요' : '장바구니 담기', onTap: () {
          _s.addToCart(p.id, qty);
          setState(() => added = true);
          Future.delayed(const Duration(milliseconds: 1100), () {
            if (mounted) setState(() => added = false);
          });
        }),
      ],
      children: [
        Container(
          height: 230,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.panel,
            border: Border.all(color: C.hairlineSoft),
            image: p.img != null ? DecorationImage(image: AssetImage(p.img!), fit: BoxFit.cover) : null,
          ),
          child: p.img == null ? Text(p.emoji, style: const TextStyle(fontSize: 56)) : null,
        ),
        Box(
          onTap: () => _s.openSellerStore(p.seller),
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            Avatar(sl.emoji, size: 40, border: C.gold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(sl.name, style: F.inter(size: 12.5, w: FontWeight.w500))),
                  if (sl.official) ...[const SizedBox(width: 6), _offBadge()],
                ]),
                const SizedBox(height: 3),
                Text(sl.meta, style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
              ]),
            ),
            Text('스토어 방문 ›', style: F.inter(size: 10, color: C.gold, ls: .05)),
          ]),
        ),
        const SizedBox(height: 16),
        Text(p.cat.toUpperCase(), style: F.inter(size: 10, color: C.gold, ls: .2)),
        const SizedBox(height: 6),
        Text(p.name, style: F.serif(size: 22)),
        const SizedBox(height: 9),
        Row(children: [
          Text(starStr(p.rating), style: F.inter(size: 12, color: C.goldBright, ls: .15)),
          const SizedBox(width: 8),
          Text('${p.rating.toStringAsFixed(1)} · 리뷰 ${p.reviews}개', style: F.inter(size: 11, color: C.textDim)),
        ]),
        const SizedBox(height: 12),
        Text(won(p.price), style: F.gnum(size: 20)),
        const SizedBox(height: 5),
        Text(p.ship, style: F.inter(size: 10.5, color: C.textFaint)),
        Container(
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.only(top: 14),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
          child: Text(p.desc, style: F.inter(size: 12, color: C.textDim, w: FontWeight.w300, h: 1.7)),
        ),
        Container(
          margin: const EdgeInsets.only(top: 16),
          padding: const EdgeInsets.only(top: 16),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
          child: Row(children: [
            Text('수량', style: F.inter(size: 11, color: C.textDim)),
            const Spacer(),
            qtyCtrl(qty, () => setState(() => qty = qty > 1 ? qty - 1 : 1), () => setState(() => qty++), big: true),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Expanded(child: Text('구매자 리뷰', style: F.inter(size: 12, w: FontWeight.w500, ls: .04))),
            Text('${p.reviews}개', style: F.inter(size: 10, color: C.textFaint)),
          ]),
        ),
        for (final r in revs)
          Divided(
            top: true,
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(r.author, style: F.inter(size: 11))),
                Text(r.stars, style: F.inter(size: 10, color: C.goldBright, ls: .1)),
              ]),
              const SizedBox(height: 7),
              Text(r.text, style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300, h: 1.6)),
            ]),
          ),
      ],
    );
  }

  Widget _offBadge() => Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), child: Text('공식', style: F.inter(size: 8, w: FontWeight.w700, color: C.ink, ls: .06)));

  /* ================= 판매자 스토어 ================= */
  Widget _store() {
    final id = _s.curStoreSeller;
    final sl = sellers[id]!;
    final list = products.where((p) => p.seller == id).toList();
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 마켓으로', onBack: () => _s.goMarket(MarketView.home)),
      children: [
        Divided(
          padding: const EdgeInsets.only(top: 2, bottom: 16),
          child: Row(children: [
            Avatar(sl.emoji, size: 56, border: C.gold),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Flexible(child: Text(sl.name, style: F.inter(size: 15, w: FontWeight.w500))),
                  if (sl.official) ...[const SizedBox(width: 7), _offBadge()],
                ]),
                const SizedBox(height: 5),
                Text('${sl.desc} · ${sl.meta}', style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
              ]),
            ),
          ]),
        ),
        SectHead('판매 상품', more: '${list.length}개', top: 16),
        _grid(list),
      ],
    );
  }

  /* ================= 장바구니 / 주문 완료 ================= */
  Widget _cart() {
    final empty = _s.cart.isEmpty;
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 계속 쇼핑', onBack: () => _s.goMarket(MarketView.home), title: '장바구니', titleSize: 24),
      footer: empty ? null : [GoldButton('주문하기', onTap: _s.checkout), GoldButton('쇼핑 계속하기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => _s.goMarket(MarketView.home))],
      children: empty
          ? [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 60),
                child: Text('장바구니가 비어 있어요.\n마켓에서 상품을 담아보세요.', textAlign: TextAlign.center, style: F.inter(size: 12, color: C.textFaint, w: FontWeight.w300, h: 1.7)),
              )
            ]
          : [
              for (final e in _s.cart.entries)
                Builder(builder: (_) {
                  final p = productById(e.key);
                  return Divided(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(children: [
                      EmojiTile(p.emoji, size: 52, font: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(p.name, style: F.inter(size: 12, w: FontWeight.w500)),
                          const SizedBox(height: 3),
                          Text('${sellers[p.seller]!.name} · ${e.value}개', style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                        ]),
                      ),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text(won(p.price * e.value), style: F.inter(size: 12, color: C.goldBright, w: FontWeight.w500)),
                        const SizedBox(height: 5),
                        GestureDetector(onTap: () => _s.removeFromCart(p.id), child: Text('삭제', style: F.inter(size: 9, color: C.textFaint))),
                      ]),
                    ]),
                  );
                }),
              _sumRow('상품금액', won(_s.cartTotal), top: 8),
              _sumRow('배송비', '0원'),
              Container(
                margin: const EdgeInsets.only(top: 6),
                padding: const EdgeInsets.only(top: 16, bottom: 6),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairline))),
                child: Row(children: [Expanded(child: Text('합계', style: F.inter(size: 13))), Text(won(_s.cartTotal), style: F.gnum(size: 17))]),
              ),
            ],
    );
  }

  Widget _sumRow(String k, String v, {double top = 0}) => Padding(
        padding: EdgeInsets.only(top: top + 3, bottom: 3),
        child: Row(children: [Expanded(child: Text(k, style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300))), Text(v, style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300))]),
      );

  Widget _done() => ScreenFrame(
        header: const StepTitle(eyebrow: 'Order', title: '주문이 완료됐어요', titleSize: 24),
        footer: [GoldButton('마켓으로 돌아가기', onTap: () => _s.goMarket(MarketView.home))],
        children: [
          const ConfirmHero('결제 완료', '여러 판매자의 상품이 한 번에 주문되었습니다.\n배송 현황은 마이페이지에서 확인할 수 있어요.'),
          DetailList([
            ('주문번호', 'FL-20260807-0412'),
            ('결제금액', won(_s.lastOrderTotal)),
            ('배송지', '서울 강남구 · 기본배송지'),
          ]),
        ],
      );
}
