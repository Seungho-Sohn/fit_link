import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/common.dart';

AppState get _s => AppState.I;

// 앱 실행 중 유지되는 커뮤니티 데이터
final List<Post> _posts = seedPosts();
final Map<Post, List<List<String>>> _comments = seedComments(_posts);
final List<Group> _groups = seedGroups();
final List<Challenge> _challenges = seedChallenges();

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String view = 'feed';
  static const tabs = [['feed', '피드'], ['chal', '챌린지'], ['group', '그룹'], ['rank', '랭킹']];

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('COMMUNITY', style: F.serif(size: 12, w: FontWeight.w600, color: C.gold, ls: .28)),
          const SizedBox(height: 5),
          Text('커뮤니티', style: F.serif(size: 26, w: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('같이 운동하는 사람들과 인증하고, 챌린지로 경쟁해요', style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300)),
        ]),
      ),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
        child: Row(children: [
          for (final t in tabs)
            GestureDetector(
              onTap: () => setState(() => view = t[0]),
              child: Container(
                margin: const EdgeInsets.only(right: 22),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: view == t[0] ? C.gold : Colors.transparent, width: 1.5))),
                child: Text(t[1], style: F.inter(size: 12, color: view == t[0] ? C.goldBright : C.textFaint, ls: .03)),
              ),
            ),
        ]),
      ),
      Expanded(
        child: ListView(
          key: ValueKey(view),
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 20),
          children: switch (view) {
            'chal' => _chal(),
            'group' => _group(),
            'rank' => _rank(),
            _ => _feed(),
          },
        ),
      ),
    ]);
  }

  /* ---------------- 피드 ---------------- */
  List<Widget> _feed() => [
        Box(
          onTap: _compose,
          margin: const EdgeInsets.only(top: 14, bottom: 14),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(children: [
            const Avatar('F', size: 34, border: C.goldDim, serif: true),
            const SizedBox(width: 11),
            Expanded(child: Text('오늘 운동·식단을 인증해보세요 📸', style: F.inter(size: 11.5, color: C.textFaint))),
            Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), child: Text('인증', style: F.inter(size: 10, w: FontWeight.w600, color: C.ink))),
          ]),
        ),
        for (final p in _posts) _post(p),
      ];

  Widget _post(Post p) => Divided(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Avatar(p.av, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(p.name, style: F.inter(size: 12, w: FontWeight.w500)),
                  const SizedBox(width: 6),
                  Container(color: C.goldDim, padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), child: Text(p.tier, style: F.inter(size: 7.5, color: C.ink, ls: .04))),
                ]),
                const SizedBox(height: 2),
                Text(p.time, style: F.inter(size: 9.5, color: C.textFaint, w: FontWeight.w300)),
              ]),
            ),
            Tag(p.tag, color: C.gold, size: 9),
          ]),
          const SizedBox(height: 11),
          Text(p.txt, style: F.inter(size: 12, w: FontWeight.w300, h: 1.6)),
          const SizedBox(height: 11),
          if (p.img.isNotEmpty)
            Container(
              height: 150,
              margin: const EdgeInsets.only(bottom: 11),
              alignment: Alignment.center,
              decoration: BoxDecoration(color: C.panel, border: Border.all(color: C.hairlineSoft)),
              child: Text(p.img, style: const TextStyle(fontSize: 40)),
            ),
          Row(children: [
            _act(p.liked ? Icons.favorite : Icons.favorite_border, '${p.likes}', p.liked ? C.live : C.textDim, () {
              setState(() {
                p.liked = !p.liked;
                p.likes += p.liked ? 1 : -1;
              });
            }),
            _act(Icons.chat_bubble_outline, '${p.comments}', C.textDim, () => _openComments(p)),
            _act(Icons.ios_share, '공유', C.textDim, () => _s.toast('공유 링크를 복사했어요')),
          ]),
        ]),
      );

  Widget _act(IconData ic, String t, Color c, VoidCallback f) => GestureDetector(
        onTap: f,
        child: Padding(
          padding: const EdgeInsets.only(right: 18),
          child: Row(children: [Icon(ic, size: 14, color: c), const SizedBox(width: 6), Text(t, style: F.inter(size: 11, color: c))]),
        ),
      );

  void _openComments(Post p) {
    final input = TextEditingController();
    showGoldSheet(
      context,
      title: '댓글',
      body: (ctx, setS) {
        final list = _comments[p] ?? [];
        if (list.isEmpty) {
          return SizedBox(height: 140, child: Center(child: Text('첫 댓글을 남겨보세요.', style: F.inter(size: 12, color: C.textFaint))));
        }
        return Column(children: [
          for (final c in list)
            Divided(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Avatar(c[0], size: 30, border: C.goldDim, serif: true),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text.rich(TextSpan(children: [
                      TextSpan(text: c[1], style: F.inter(size: 11, w: FontWeight.w500)),
                      TextSpan(text: '  ${c[3]}', style: F.inter(size: 9, color: C.textFaint, w: FontWeight.w300)),
                    ])),
                    const SizedBox(height: 4),
                    Text(c[2], style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300, h: 1.5)),
                  ]),
                ),
              ]),
            ),
        ]);
      },
      foot: (ctx, setS) {
        void post() {
          final v = input.text.trim();
          if (v.isEmpty) return;
          (_comments[p] ??= []).add(['F', '회원님', v, '방금']);
          p.comments++;
          input.clear();
          setS(() {});
          setState(() {});
          _s.toast('댓글을 남겼어요');
        }

        return Row(children: [
          Expanded(
            child: TextField(
              controller: input,
              onSubmitted: (_) => post(),
              style: F.inter(size: 12),
              decoration: InputDecoration(
                hintText: '댓글 남기기...',
                hintStyle: F.inter(size: 12, color: C.textFaint),
                isDense: true,
                contentPadding: const EdgeInsets.all(12),
                enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.hairlineSoft)),
                focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.gold)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: post,
            child: Container(padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13), decoration: const BoxDecoration(gradient: goldGradient), child: Text('등록', style: F.inter(size: 12, color: C.ink, w: FontWeight.w500))),
          ),
        ]);
      },
    );
  }

  void _compose() {
    final ta = TextEditingController();
    String tag = '운동 인증';
    showGoldSheet(
      context,
      title: '인증 · 글쓰기',
      body: (ctx, setS) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 7, runSpacing: 7, children: [
          for (final t in ['운동 인증', '식단 인증', '꿀팁', '질문']) SelChip(t, on: tag == t, onTap: () => setS(() => tag = t)),
        ]),
        const SizedBox(height: 12),
        TextField(
          controller: ta,
          maxLines: 4,
          style: F.inter(size: 12.5, h: 1.6),
          decoration: InputDecoration(
            hintText: '오늘의 운동·식단을 인증해보세요! (예: 오운완 💪 등 운동 완료)',
            hintStyle: F.inter(size: 12.5, color: C.textFaint),
            contentPadding: const EdgeInsets.all(13),
            enabledBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.hairlineSoft)),
            focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.zero, borderSide: BorderSide(color: C.gold)),
          ),
        ),
        const SizedBox(height: 12),
        Row(children: [
          for (final e in ['📷', '＋'])
            GestureDetector(
              onTap: () => _s.toast('사진 첨부는 개발 버전에서 연결돼요'),
              child: Container(
                width: 52,
                height: 52,
                margin: const EdgeInsets.only(right: 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(border: Border.all(color: C.hairline)),
                child: Text(e, style: F.inter(size: 18, color: C.textFaint)),
              ),
            ),
        ]),
      ]),
      foot: (ctx, setS) => GoldButton('게시하기', upper: false, onTap: () {
        final v = ta.text.trim().isEmpty ? '오운완 💪 오늘도 완료!' : ta.text.trim();
        _posts.insert(0, Post('F', '회원님', 'Gold', '방금', tag, v, tag == '운동 인증' ? '🔥' : '', 0, 0, false));
        Navigator.pop(ctx);
        setState(() {});
        _s.toast('인증글을 게시했어요 🎉');
        if (tag == '운동 인증' || tag == '식단 인증') {
          Future.delayed(const Duration(milliseconds: 700), () => _s.earnPoints(50, tag));
        }
      }),
    );
  }

  /* ---------------- 챌린지 ---------------- */
  List<Widget> _chal() => [
        const SizedBox(height: 14),
        for (final c in _challenges)
          Box(
            margin: const EdgeInsets.only(bottom: 14),
            padding: EdgeInsets.zero,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.em, style: const TextStyle(fontSize: 26)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.title, style: F.inter(size: 14, w: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(c.desc, style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                    ]),
                  ),
                  c.joined
                      ? Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3), child: Text('참여중', style: F.inter(size: 8.5, w: FontWeight.w700, color: C.ink)))
                      : Tag(c.badge, color: c.live ? C.live : C.textFaint, border: c.live ? C.live.op(.4) : C.hairlineSoft, size: 8.5),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                child: Column(children: [
                  if (c.joined) ...[
                    Bar(c.prog / 100, color: null),
                    const SizedBox(height: 9),
                    Row(children: [
                      Expanded(child: Text('진행률', style: F.inter(size: 9.5, color: C.textFaint, w: FontWeight.w300))),
                      Text(c.meta, style: F.inter(size: 9.5, color: C.goldBright, w: FontWeight.w500)),
                    ]),
                  ] else
                    Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(children: [Text(c.meta, style: F.inter(size: 9.5, color: C.textFaint, w: FontWeight.w300))])),
                  const SizedBox(height: 2),
                  GestureDetector(
                    onTap: () {
                      final was = c.joined;
                      setState(() {
                        if (!c.joined) {
                          c.joined = true;
                          if (c.prog < 5) c.prog = 5;
                          if (c.meta.startsWith('다음') || c.meta.startsWith('5')) c.meta = '1 / 30일 완료';
                        } else {
                          c.prog = c.prog + 3 > 100 ? 100 : c.prog + 3;
                        }
                      });
                      _s.toast(was ? '오늘 인증 완료 🔥' : '🎉 챌린지에 참여했어요!');
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(11),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(border: Border.all(color: c.joined ? C.goldDim : C.hairline)),
                      child: Text(c.joined ? '참여 중 · 오늘 인증하기' : '챌린지 참여하기'.toUpperCase(), style: F.inter(size: 11, color: c.joined ? C.textFaint : C.goldBright, ls: .1)),
                    ),
                  ),
                ]),
              ),
            ]),
          ),
      ];

  /* ---------------- 그룹 ---------------- */
  List<Widget> _group() => [
        const SectHead('내 주변 운동 그룹', more: '강남구', top: 14),
        for (final g in _groups)
          Box(
            margin: const EdgeInsets.only(bottom: 11),
            child: Row(children: [
              EmojiTile(g.em, size: 46, font: 23),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name, style: F.inter(size: 13, w: FontWeight.w500)),
                  const SizedBox(height: 4),
                  Text(g.desc, style: F.inter(size: 10, color: C.textDim, w: FontWeight.w300)),
                  const SizedBox(height: 6),
                  Text('멤버 ${comma(g.members)}명', style: F.inter(size: 9, color: C.goldBright)),
                ]),
              ),
              LineButton(g.joined ? '참여중' : '참여', done: g.joined, size: 10.5, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), onTap: () {
                setState(() {
                  g.joined = !g.joined;
                  g.members += g.joined ? 1 : -1;
                });
                _s.toast(g.joined ? '그룹에 참여했어요' : '그룹을 나갔어요');
              }),
            ]),
          ),
      ];

  /* ---------------- 랭킹 ---------------- */
  List<Widget> _rank() => [
        Box(
          margin: const EdgeInsets.only(top: 14, bottom: 16),
          border: C.goldDim,
          color: C.goldA(.07),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
          child: _rankRow('7', 'F', '회원님 (나)', '이번 주 운동 5일 · 640pt', '640', gold: true),
        ),
        const SectHead('이번 주 랭킹 · 강남구', more: '전체'),
        for (final r in rankList)
          Divided(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: _rankRow(r[0], r[1].substring(0, 1), r[1], r[2], r[3], gold: r[4] == 'top1'),
          ),
      ];

  Widget _rankRow(String rk, String av, String name, String meta, String sc, {bool gold = false}) => Row(children: [
        SizedBox(width: 26, child: Text(rk, textAlign: TextAlign.center, style: F.serif(size: 16, color: gold ? C.goldBright : C.textDim))),
        const SizedBox(width: 14),
        Avatar(av, size: 34),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: F.inter(size: 12.5, w: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(meta, style: F.inter(size: 9.5, color: C.textFaint, w: FontWeight.w300)),
          ]),
        ),
        Text(sc, style: F.gnum(size: 15)),
      ]);
}
