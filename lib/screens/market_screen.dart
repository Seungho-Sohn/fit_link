import 'dart:async';
import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});
  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  String cat = '전체', b2bCat = '전체', usedCat = '전체';
  final search = TextEditingController();
  int qty = 1;
  bool added = false;
  Timer? dealTimer;
  String dealLeft = '--:--:--';
  // B2B 견적 폼
  String fOpen = '신규 오픈', fSize = '~30평';
  final Set<String> fItems = {};

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
          'detail' => _detail(),
          'store' => _store(),
          'cart' => _cart(),
          'done' => _done(),
          'b2b' => _b2b(),
          'b2bform' => _b2bForm(),
          'b2bdone' => _b2bDone(),
          'used' => _used(),
          'dash' => _dash(),
          _ => _home(),
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
            onTap: () => _s.goMarket('cart'),
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
          _searchBar(search, '브랜드 · 상품 · 판매자 검색', () => setState(() {})),
          ChipRow(items: marketCats, selected: cat, solid: true, onSelect: (v) => setState(() => cat = v)),
          const SizedBox(height: 16),
          Box(
            onTap: () => _s.goMarket('b2b'),
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
              SizedBox(
                height: 170,
                child: ListView(scrollDirection: Axis.horizontal, children: [
                  for (final d in deals) _dealCard(productById(d[0] as String), d[1] as int),
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
            SizedBox(height: 29, child: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: F.inter(size: 10.5, h: 1.35))),
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
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, mainAxisExtent: 222),
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
    final p = productById(_s.curProductId ?? 'p1');
    final sl = sellers[p.seller]!;
    final revs = reviews[p.id] ?? defaultReviews;
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 마켓으로', onBack: () => _s.goMarket('home'), title: p.name, titleSize: 22),
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
            _qtyCtrl(qty, () => setState(() => qty = qty > 1 ? qty - 1 : 1), () => setState(() => qty++), big: true),
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
                Expanded(child: Text(r[0], style: F.inter(size: 11))),
                Text(r[1], style: F.inter(size: 10, color: C.goldBright, ls: .1)),
              ]),
              const SizedBox(height: 7),
              Text(r[2], style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300, h: 1.6)),
            ]),
          ),
      ],
    );
  }

  Widget _offBadge() => Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2), child: Text('공식', style: F.inter(size: 8, w: FontWeight.w700, color: C.ink, ls: .06)));

  /* ================= 판매자 스토어 ================= */
  Widget _store() {
    final id = _s.curStoreSeller ?? 'wildwear';
    final sl = sellers[id]!;
    final list = products.where((p) => p.seller == id).toList();
    return ScreenFrame(
      header: StepTitle(eyebrow: '← 마켓으로', onBack: () => _s.goMarket('home')),
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
      header: StepTitle(eyebrow: '← 계속 쇼핑', onBack: () => _s.goMarket('home'), title: '장바구니', titleSize: 24),
      footer: empty ? null : [GoldButton('주문하기', onTap: _s.checkout), GoldButton('쇼핑 계속하기', ghost: true, margin: const EdgeInsets.only(top: 10), onTap: () => _s.goMarket('home'))],
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
        footer: [GoldButton('마켓으로 돌아가기', onTap: () => _s.goMarket('home'))],
        children: [
          const ConfirmHero('결제 완료', '여러 판매자의 상품이 한 번에 주문되었습니다.\n배송 현황은 마이페이지에서 확인할 수 있어요.'),
          DetailList([
            const ['주문번호', 'FL-20260807-0412'],
            ['결제금액', won(_s.lastOrderTotal)],
            const ['배송지', '서울 강남구 · 기본배송지'],
          ]),
        ],
      );

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
    Widget svc(String i, String t, String d, String go, String to) => Box(
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
      header: StepTitle(eyebrow: '← 마켓', onBack: () => _s.goMarket('home'), title: '헬스장 운영자 전용관', titleSize: 23, desc: '상업용(commercial-grade) 기구를 도매가로. 신규 오픈·리뉴얼 견적을 받아보세요.'),
      footer: [
        GoldButton('🧾 매장 전체 견적 요청하기', upper: false, onTap: () => _s.goMarket('b2bform')),
        GoldButton('사업자 인증하고 도매가 보기', ghost: true, upper: false, margin: const EdgeInsets.only(top: 10), onTap: () => _s.goMarket('b2bform')),
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
            svc('🔄', '중고 기구 거래', '안 쓰는 기구 판매 & 검수된 중고 매물 보기', '매물 보기 ›', 'used'),
            svc('📊', '운영 대시보드', '회원·매출·기구 A/S를 한눈에 관리', '대시보드 ›', 'dash'),
            svc('🏗️', '인테리어·시공', '바닥·거울·조명·동선 설계 · 턴키 시공', '견적 문의 ›', 'b2bform'),
            svc('🧑‍🏫', 'PT·트레이너 채용', '검증된 트레이너 매칭 · 채용 공고 등록', '채용 의뢰 ›', 'b2bform'),
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
      header: StepTitle(eyebrow: '← 전용관', onBack: () => _s.goMarket('b2b'), title: '사업자 인증 · 견적 요청', titleSize: 22, desc: '정보를 남겨주시면 전담 매니저가 도매 견적과 함께 연락드려요.'),
      footer: [GoldButton('견적·상담 신청하기', upper: false, onTap: () => _s.goMarket('b2bdone'))],
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
        footer: [GoldButton('전용관으로 돌아가기', upper: false, onTap: () => _s.goMarket('b2b'))],
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
      header: StepTitle(eyebrow: '← 전용관', onBack: () => _s.goMarket('b2b'), title: '중고 기구 거래', titleSize: 22, desc: '검수·등급 인증된 상업용 중고 기구를 사고팔아요.'),
      footer: [GoldButton('＋ 내 기구 팔기 (무료 검수 신청)', upper: false, onTap: () => _s.goMarket('b2bform'))],
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
      header: StepTitle(eyebrow: '← 전용관', onBack: () => _s.goMarket('b2b'), title: '운영 대시보드', titleSize: 22, desc: '스틸핏 강남점 · 2026년 8월'),
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

/* ===== 공용: 검색창 / 수량 조절 ===== */
Widget _searchBar(TextEditingController c, String hint, VoidCallback onChanged) => Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 13),
      decoration: BoxDecoration(color: C.panel, border: Border.all(color: C.hairline)),
      child: Row(children: [
        const Icon(Icons.search, size: 15, color: C.goldDim),
        const SizedBox(width: 9),
        Expanded(
          child: TextField(
            controller: c,
            onChanged: (_) => onChanged(),
            style: F.inter(size: 12, w: FontWeight.w300),
            decoration: InputDecoration(border: InputBorder.none, hintText: hint, hintStyle: F.inter(size: 12, color: C.textFaint, w: FontWeight.w300), isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
      ]),
    );

Widget searchBar(TextEditingController c, String hint, VoidCallback onChanged) => _searchBar(c, hint, onChanged);

Widget _qtyCtrl(int q, VoidCallback minus, VoidCallback plus, {bool big = false}) => Container(
      decoration: BoxDecoration(border: Border.all(color: big ? C.hairline : C.hairlineSoft)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        GestureDetector(onTap: minus, child: SizedBox(width: big ? 34 : 28, height: big ? 34 : 30, child: Center(child: Text('−', style: F.inter(size: big ? 16 : 15, color: C.goldBright))))),
        SizedBox(width: big ? 38 : 22, child: Text('$q', textAlign: TextAlign.center, style: big ? F.inter(size: 13) : F.serif(size: 12, w: FontWeight.w600))),
        GestureDetector(onTap: plus, child: SizedBox(width: big ? 34 : 28, height: big ? 34 : 30, child: Center(child: Text('+', style: F.inter(size: big ? 16 : 15, color: C.goldBright))))),
      ]),
    );

Widget qtyCtrl(int q, VoidCallback minus, VoidCallback plus) => _qtyCtrl(q, minus, plus);
