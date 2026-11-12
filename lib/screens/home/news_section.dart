import 'package:flutter/material.dart';
import '../../data/mock_data.dart';
import '../../state/app_state.dart';
import '../../theme.dart';
import '../../widgets/common.dart';

AppState get _s => AppState.I;

/* ================= 오늘의 헬스 소식 (날짜별 로테이션) ================= */
class NewsSection extends StatelessWidget {
  const NewsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final doy = now.difference(DateTime(now.year, 1, 1)).inDays + 1;
    final idx = doy % news.length;
    final feat = news[idx];
    String fmt(DateTime d) => '${d.month}월 ${d.day}일';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 12),
        child: Row(children: [
          const LiveDot(size: 6),
          const SizedBox(width: 7),
          Expanded(child: Text('오늘의 헬스 소식', style: F.inter(size: 12, w: FontWeight.w500))),
          Text('${fmt(now)} · 매일 업데이트', style: F.inter(size: 9.5, color: C.textFaint)),
        ]),
      ),
      GestureDetector(
        onTap: () => _s.toast('전체 기사는 개발 버전에서 연결돼요'),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: C.goldDim), gradient: softGold(.10)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              height: 120,
              decoration: const BoxDecoration(color: C.panel, border: Border(bottom: BorderSide(color: C.hairlineSoft))),
              child: Stack(children: [
                Center(child: Text(feat.emoji, style: const TextStyle(fontSize: 44))),
                Positioned(top: 0, left: 0, child: Container(color: C.gold, padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4), child: Text(feat.category, style: F.inter(size: 8.5, w: FontWeight.w700, color: C.ink, ls: .08)))),
                Positioned(top: 9, right: 11, child: Text('TODAY', style: F.inter(size: 9, color: C.textDim, ls: .05))),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(feat.title, style: F.inter(size: 14.5, w: FontWeight.w500, h: 1.4)),
                const SizedBox(height: 8),
                Text(feat.body, style: F.inter(size: 11, color: C.textDim, w: FontWeight.w300, h: 1.6)),
                const SizedBox(height: 11),
                Text('자세히 보기 ›', style: F.inter(size: 10, color: C.goldBright, ls: .06)),
              ]),
            ),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      for (int k = 1; k <= 3; k++) _pastRow(now.subtract(Duration(days: k)), news[((idx - k) % news.length + news.length) % news.length], fmt),
    ]);
  }

  Widget _pastRow(DateTime d, NewsItem n, String Function(DateTime) fmt) => GestureDetector(
        onTap: () => _s.toast('지난 소식도 다시 볼 수 있어요'),
        child: Divided(
          top: true,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 2),
          child: Row(children: [
            EmojiTile(n.emoji, size: 38, font: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(n.category, style: F.inter(size: 8.5, color: C.gold, ls: .1)),
                const SizedBox(height: 3),
                Text(n.title, style: F.inter(size: 11.5, h: 1.4)),
              ]),
            ),
            Text(fmt(d), style: F.inter(size: 9, color: C.textFaint)),
          ]),
        ),
      );
}
