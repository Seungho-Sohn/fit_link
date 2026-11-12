import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';

/// 테두리 박스 (HTML의 border:1px solid var(--hairline-soft) 패턴)
class Box extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final Color border;
  final Gradient? gradient;
  final Color? color;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final double? width, height;
  const Box({super.key, required this.child, this.padding = const EdgeInsets.all(14), this.border = C.hairlineSoft, this.gradient, this.color, this.margin = EdgeInsets.zero, this.onTap, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    final w = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(border: Border.all(color: border), gradient: gradient, color: color),
      child: child,
    );
    return onTap == null ? w : GestureDetector(behavior: HitTestBehavior.opaque, onTap: onTap, child: w);
  }
}

/// 금색 그라데이션 기본 버튼 / 고스트 버튼
class GoldButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool ghost;
  final bool upper;
  final EdgeInsets margin;
  const GoldButton(this.text, {super.key, this.onTap, this.ghost = false, this.upper = true, this.margin = EdgeInsets.zero});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: ghost ? null : goldGradient,
            border: Border.all(color: ghost ? C.hairline : Colors.transparent),
          ),
          child: Text(upper ? text.toUpperCase() : text,
              textAlign: TextAlign.center,
              style: F.inter(size: 12.5, w: FontWeight.w500, ls: upper ? .14 : .01, color: ghost ? C.textDim : C.ink)),
        ),
      ),
    );
  }
}

/// 작은 외곽선 버튼 (메이트 신청, 적용하기, 견적담기 등)
class LineButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool done;
  final double size;
  final EdgeInsets padding;
  final bool expand;
  const LineButton(this.text, {super.key, this.onTap, this.done = false, this.size = 10, this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 7), this.expand = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: expand ? double.infinity : null,
        alignment: expand ? Alignment.center : null,
        padding: padding,
        decoration: BoxDecoration(border: Border.all(color: done ? C.hairlineSoft : C.gold)),
        child: Text(text, style: F.inter(size: size, color: done ? C.textFaint : C.goldBright)),
      ),
    );
  }
}

/// 선택형 칩 (필터·정렬·카테고리)
class SelChip extends StatelessWidget {
  final String text;
  final bool on;
  final VoidCallback onTap;
  final bool solid; // true: 금색 채움(마켓 카테고리), false: 금색 테두리+그라데이션
  const SelChip(this.text, {super.key, required this.on, required this.onTap, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 7),
        padding: EdgeInsets.symmetric(horizontal: solid ? 14 : 13, vertical: solid ? 8 : 7),
        decoration: BoxDecoration(
          color: on && solid ? C.gold : null,
          gradient: on && !solid ? softGold(.13) : null,
          border: Border.all(color: on ? C.gold : (solid ? C.hairline : C.hairlineSoft)),
        ),
        child: Text(text,
            style: F.inter(size: 10.5, w: on && solid ? FontWeight.w600 : FontWeight.w400, color: on ? (solid ? C.ink : C.ivory) : C.textDim)),
      ),
    );
  }
}

class ChipRow extends StatelessWidget {
  final List<String> items;
  final String selected;
  final ValueChanged<String> onSelect;
  final bool solid;
  const ChipRow({super.key, required this.items, required this.selected, required this.onSelect, this.solid = false});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [for (final c in items) SelChip(c, on: c == selected, solid: solid, onTap: () => onSelect(c))]),
    );
  }
}

/// 섹션 헤더: 왼쪽 제목, 오른쪽 '더보기'
class SectHead extends StatelessWidget {
  final String title;
  final String? more;
  final double top;
  final VoidCallback? onMore;
  const SectHead(this.title, {super.key, this.more, this.top = 6, this.onMore});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: 12),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(child: Text(title, style: F.inter(size: 12.5, w: FontWeight.w500, ls: .04))),
        if (more != null) GestureDetector(onTap: onMore, child: Text(more!, style: F.inter(size: 10, color: C.gold, ls: .06))),
      ]),
    );
  }
}

/// 홈 화면의 '📈 내 운동 기록  MY PROGRESS' 형식 헤더 + 부제
class ProgHead extends StatelessWidget {
  final String title, eyebrow, sub;
  const ProgHead(this.title, this.eyebrow, this.sub, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title, style: F.inter(size: 12, w: FontWeight.w500))),
          Text(eyebrow.toUpperCase(), style: F.inter(size: 8.5, color: C.gold, ls: .34)),
        ]),
        const SizedBox(height: 5),
        Text(sub, style: F.inter(size: 10.5, color: C.textDim, w: FontWeight.w300)),
        const SizedBox(height: 13),
      ]),
    );
  }
}

/// 화면 상단 제목 영역 (eyebrow · h1 · p). eyebrow를 누르면 뒤로가기.
class StepTitle extends StatelessWidget {
  final String eyebrow;
  final String? title, desc;
  final VoidCallback? onBack;
  final double titleSize;
  const StepTitle({super.key, required this.eyebrow, this.title, this.desc, this.onBack, this.titleSize = 27});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(onTap: onBack, child: Text(eyebrow.toUpperCase(), style: F.inter(size: 10, color: C.gold, ls: .28, w: FontWeight.w500))),
        if (title != null) ...[
          const SizedBox(height: 9),
          Text(title!, style: F.serif(size: titleSize, h: 1.2)),
        ],
        if (desc != null) ...[
          const SizedBox(height: 7),
          Text(desc!, style: F.inter(size: 12, color: C.textDim, w: FontWeight.w300, h: 1.6)),
        ],
      ]),
    );
  }
}

/// 상단 Title + 스크롤 콘텐츠 + 하단 Footer 로 구성되는 공통 화면 틀
class ScreenFrame extends StatelessWidget {
  final Widget? header;
  final List<Widget> children;
  final List<Widget>? footer;
  final EdgeInsets padding;
  const ScreenFrame({super.key, this.header, required this.children, this.footer, this.padding = const EdgeInsets.fromLTRB(22, 0, 22, 20)});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      if (header != null) header!,
      Expanded(
        child: ListView(padding: padding, children: children),
      ),
      if (footer != null && footer!.isNotEmpty)
        Container(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 20),
          decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
          child: Column(mainAxisSize: MainAxisSize.min, children: footer!),
        ),
    ]);
  }
}

/// 굵은 금색 강조 + 일반 문장 형태의 안내 카드
class HintCard extends StatelessWidget {
  final String bold, rest;
  final double top;
  const HintCard(this.bold, this.rest, {super.key, this.top = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: top),
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
      decoration: const BoxDecoration(border: Border.symmetric(horizontal: BorderSide(color: C.hairlineSoft))),
      child: Text.rich(TextSpan(children: [
        TextSpan(text: bold, style: F.inter(size: 11.5, color: C.goldBright, w: FontWeight.w500)),
        TextSpan(text: ' $rest', style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300, h: 1.7)),
      ])),
    );
  }
}

/// 진행 막대
class Bar extends StatelessWidget {
  final double value; // 0~1
  final double height;
  final Color? color;
  final Gradient? gradient;
  final Color track;
  const Bar(this.value, {super.key, this.height = 5, this.color, this.gradient, this.track = const Color(0x0FFFFFFF)});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: track,
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: value.clamp(0.0, 1.0).toDouble(),
        child: Container(decoration: BoxDecoration(color: color, gradient: gradient ?? (color == null ? const LinearGradient(colors: [C.goldDim, C.goldBright]) : null))),
      ),
    );
  }
}

/// 원형 진행 링 (CSS conic-gradient + mask 대체)
class Ring extends StatelessWidget {
  final double size, stroke;
  final List<MapEntry<double, Color>> segments; // (비율, 색)
  final Color track;
  final Widget child;
  final bool border;
  const Ring({super.key, required this.size, required this.segments, required this.child, this.stroke = 2, this.track = Colors.transparent, this.border = true});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(segments, stroke, track, border),
        child: Center(child: child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final List<MapEntry<double, Color>> segs;
  final double stroke;
  final Color track;
  final bool border;
  _RingPainter(this.segs, this.stroke, this.track, this.border);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    if (border) {
      canvas.drawCircle(size.center(Offset.zero), size.width / 2 - .5, Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = C.hairline);
    }
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    double start = -math.pi / 2;
    double used = 0;
    for (final s in segs) {
      p.color = s.value;
      canvas.drawArc(rect, start, s.key * 2 * math.pi, false, p);
      start += s.key * 2 * math.pi;
      used += s.key;
    }
    if (used < 1 && track != Colors.transparent) {
      p.color = track;
      canvas.drawArc(rect, start, (1 - used) * 2 * math.pi, false, p);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) => true;
}

/// 맥박처럼 깜빡이는 점 (CSS @keyframes pulse)
class LiveDot extends StatefulWidget {
  final Color color;
  final double size;
  const LiveDot({super.key, this.color = C.live, this.size = 5});
  @override
  State<LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<LiveDot> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = (_c.value / .7).clamp(0.0, 1.0).toDouble();
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: widget.color, boxShadow: [
            BoxShadow(color: widget.color.op(.45 * (1 - t)), spreadRadius: 7 * t),
          ]),
        );
      },
    );
  }
}

/// WILD WEAR 홀로그램 금색 로고: 마스크 PNG 위에 흐르는 그라데이션
class WwHolo extends StatefulWidget {
  final double width, height;
  final bool deep;
  const WwHolo({super.key, required this.width, required this.height, this.deep = true});
  @override
  State<WwHolo> createState() => _WwHoloState();
}

class _WwHoloState extends State<WwHolo> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.deep
        ? const [Color(0xFF4E2E14), Color(0xFF8B5A2B), Color(0xFFB8823C), Color(0xFFD9A94E), Color(0xFFF0D48A), Color(0xFFFBEFC0), Color(0xFFF0D48A), Color(0xFFD9A94E), Color(0xFFB8823C), Color(0xFF8B5A2B), Color(0xFF4E2E14)]
        : const [Color(0xFF8B5A2B), Color(0xFFC99A46), Color(0xFFE6C46E), Color(0xFFF5E3A8), Color(0xFFFFF6D8), Color(0xFFF5E3A8), Color(0xFFE6C46E), Color(0xFFC99A46), Color(0xFF8B5A2B)];
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) {
          final shift = _c.value * 2.8 * r.width;
          return LinearGradient(colors: colors, tileMode: TileMode.repeated, transform: GradientRotation(.35))
              .createShader(Rect.fromLTWH(-shift, 0, r.width * 2.8, r.height));
        },
        child: child,
      ),
      child: Image.asset('assets/images/ww_mask.png', width: widget.width, height: widget.height, fit: BoxFit.contain),
    );
  }
}

/// 간단한 SVG path("M x y L x y … Z") 를 그리는 페인터 (실루엣 등)
Path parseSimplePath(String d, double sx, double sy) {
  final path = Path();
  final tokens = RegExp(r'[MLZ]|-?\d+(\.\d+)?').allMatches(d).map((m) => m.group(0)!).toList();
  String cmd = 'M';
  int i = 0;
  while (i < tokens.length) {
    final t = tokens[i];
    if (t == 'M' || t == 'L' || t == 'Z') {
      cmd = t;
      i++;
      if (t == 'Z') path.close();
      continue;
    }
    final x = double.parse(tokens[i]) * sx;
    final y = double.parse(tokens[i + 1]) * sy;
    if (cmd == 'M') {
      path.moveTo(x, y);
      cmd = 'L';
    } else {
      path.lineTo(x, y);
    }
    i += 2;
  }
  return path;
}

/// 눈바디 실루엣 (원본 viewBox 0 0 64 150)
class BodySilhouette extends StatelessWidget {
  final bool after;
  final double height;
  const BodySilhouette({super.key, required this.after, this.height = 132});

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: height * 64 / 150, height: height, child: CustomPaint(painter: _BodyPainter(after)));
  }
}

class _BodyPainter extends CustomPainter {
  final bool after;
  _BodyPainter(this.after);
  static const before =
      'M24 22 L18 27 L15 52 L14 74 L19 74 L22 42 L24 60 L23 82 L21 146 L28 146 L31 94 L33 94 L36 146 L43 146 L41 82 L40 60 L42 42 L45 52 L50 74 L49 52 L46 27 L40 22 Z';
  static const aft =
      'M24 22 L16 27 L13 52 L12 74 L18 74 L21 43 L27 60 L26 82 L21 146 L28 146 L31 94 L33 94 L36 146 L43 146 L38 82 L37 60 L43 43 L46 52 L52 74 L51 52 L48 27 L40 22 Z';

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 64, sy = size.height / 150;
    final fill = Paint()..color = after ? const Color(0xFFCBA24E) : const Color(0xFF6B6457);
    canvas.drawCircle(Offset(32 * sx, 12 * sy), 8 * sx, fill);
    canvas.drawPath(parseSimplePath(after ? aft : before, sx, sy), fill);
    if (after) {
      final line = Paint()
        ..color = C.goldDim
        ..strokeWidth = 1.1
        ..style = PaintingStyle.stroke;
      for (final l in const [
        [28.0, 40.0, 36.0],
        [27.0, 50.0, 37.0],
        [29.0, 60.0, 35.0]
      ]) {
        canvas.drawLine(Offset(l[0] * sx, l[1] * sy), Offset(l[2] * sx, l[1] * sy), line);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 사각 이모지 썸네일
class EmojiTile extends StatelessWidget {
  final String emoji;
  final double size, font;
  final String? badge;
  final Color badgeColor;
  final String? image;
  const EmojiTile(this.emoji, {super.key, this.size = 52, this.font = 22, this.badge, this.badgeColor = C.gold, this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: C.panel,
        border: Border.all(color: C.hairlineSoft),
        image: image != null ? DecorationImage(image: AssetImage(image!), fit: BoxFit.cover) : null,
      ),
      child: Stack(children: [
        if (image == null) Center(child: Text(emoji, style: TextStyle(fontSize: font))),
        if (badge != null)
          Positioned(
            top: 0,
            left: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              color: badgeColor,
              child: Text(badge!, style: F.inter(size: 7.5, w: FontWeight.w700, color: const Color(0xFF1A1207))),
            ),
          ),
      ]),
    );
  }
}

/// 원형 아바타
class Avatar extends StatelessWidget {
  final String text;
  final double size;
  final Color border;
  final bool serif;
  const Avatar(this.text, {super.key, this.size = 36, this.border = C.hairline, this.serif = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, color: C.panel, border: Border.all(color: border)),
      child: Text(text, style: serif ? F.gnum(size: size * .4) : TextStyle(fontSize: size * .42)),
    );
  }
}

/// 금색 원형 체크 (완료 화면)
class ConfirmHero extends StatelessWidget {
  final String title, desc;
  const ConfirmHero(this.title, this.desc, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 28, 10, 8),
      child: Column(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: C.gold)),
          child: const Icon(Icons.check, color: C.goldBright, size: 22),
        ),
        const SizedBox(height: 16),
        Text(title, style: F.serif(size: 22)),
        const SizedBox(height: 8),
        Text(desc, textAlign: TextAlign.center, style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300, h: 1.7)),
      ]),
    );
  }
}

/// 키-값 상세 행 목록
class DetailList extends StatelessWidget {
  final List<List<String>> rows;
  const DetailList(this.rows, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(children: [
        for (final r in rows)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
            child: Row(children: [
              Expanded(child: Text(r[0], style: F.inter(size: 12.5, color: C.textDim, w: FontWeight.w300))),
              Text(r[1], style: F.inter(size: 12.5, color: C.goldBright, w: FontWeight.w500)),
            ]),
          ),
      ]),
    );
  }
}

/// 업로드 박스 (사진 선택 또는 촬영)
class DropZone extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  const DropZone(this.title, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 224,
        margin: const EdgeInsets.only(top: 6),
        decoration: BoxDecoration(border: Border.all(color: C.hairline)),
        child: Stack(children: [
          Positioned(top: 0, left: 0, child: _corner(true)),
          Positioned(bottom: 0, right: 0, child: _corner(false)),
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.upload_outlined, color: C.gold, size: 30),
              const SizedBox(height: 12),
              Text(title, style: F.inter(size: 12.5, w: FontWeight.w500, ls: .08)),
              const SizedBox(height: 12),
              Text('JPG · PNG · HEIC', style: F.inter(size: 10.5, color: C.textFaint, ls: .06)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _corner(bool tl) => Container(
        width: 14,
        height: 14,
        decoration: BoxDecoration(
            border: Border(
          top: tl ? const BorderSide(color: C.gold) : BorderSide.none,
          left: tl ? const BorderSide(color: C.gold) : BorderSide.none,
          bottom: tl ? BorderSide.none : const BorderSide(color: C.gold),
          right: tl ? BorderSide.none : const BorderSide(color: C.gold),
        )),
      );
}

/// 스캔 뷰파인더 (코너 + 위아래로 움직이는 스캔라인)
class Viewfinder extends StatefulWidget {
  final Widget child;
  const Viewfinder({super.key, required this.child});
  @override
  State<Viewfinder> createState() => _ViewfinderState();
}

class _ViewfinderState extends State<Viewfinder> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        border: Border.all(color: C.hairlineSoft),
        gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1C1810), Color(0xFF100E0A)]),
      ),
      child: LayoutBuilder(builder: (_, cons) {
        return Stack(children: [
          Center(child: widget.child),
          for (final a in const [Alignment.topLeft, Alignment.topRight, Alignment.bottomLeft, Alignment.bottomRight])
            Align(alignment: a, child: Padding(padding: const EdgeInsets.all(16), child: _Corner(a))),
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) {
              final v = _c.value < .5 ? _c.value * 2 : (1 - _c.value) * 2;
              return Positioned(
                left: 16,
                right: 16,
                top: 16 + v * (cons.maxHeight - 34),
                child: Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.transparent, C.goldBright, Colors.transparent]),
                    boxShadow: [BoxShadow(color: Color(0x80F0DA92), blurRadius: 10, spreadRadius: 1)],
                  ),
                ),
              );
            },
          ),
        ]);
      }),
    );
  }
}

class _Corner extends StatelessWidget {
  final Alignment a;
  const _Corner(this.a);
  @override
  Widget build(BuildContext context) {
    const s = BorderSide(color: C.gold);
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
          border: Border(
        top: a.y < 0 ? s : BorderSide.none,
        bottom: a.y > 0 ? s : BorderSide.none,
        left: a.x < 0 ? s : BorderSide.none,
        right: a.x > 0 ? s : BorderSide.none,
      )),
    );
  }
}

/// 순차적으로 떠오르는 분석 로그 (CSS animation-delay 대체)
class AnalyzeLog extends StatefulWidget {
  final List<String> rows;
  const AnalyzeLog(this.rows, {super.key});
  @override
  State<AnalyzeLog> createState() => _AnalyzeLogState();
}

class _AnalyzeLogState extends State<AnalyzeLog> {
  int shown = 0;

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.rows.length; i++) {
      Future.delayed(Duration(milliseconds: 200 + i * 800), () {
        if (mounted) setState(() => shown = i + 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: Column(children: [
        for (int i = 0; i < widget.rows.length; i++)
          AnimatedOpacity(
            opacity: i < shown ? 1 : 0,
            duration: const Duration(milliseconds: 400),
            child: Container(
              margin: const EdgeInsets.only(bottom: 11),
              padding: const EdgeInsets.only(bottom: 9),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
              child: Row(children: [
                Expanded(child: Text(widget.rows[i], style: F.inter(size: 11.5, color: C.textDim, w: FontWeight.w300))),
                Text('완료', style: F.inter(size: 11.5, color: C.goldBright, ls: .05)),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// 하단 시트 공통 틀
Future<T?> showGoldSheet<T>(BuildContext context, {required String title, required Widget Function(BuildContext, StateSetter) body, Widget Function(BuildContext, StateSetter)? foot}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: C.charcoal,
    barrierColor: const Color(0x9E000000),
    shape: const RoundedRectangleBorder(side: BorderSide(color: C.goldDim)),
    builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * .86),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.fromLTRB(18, 16, 10, 14),
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: C.hairlineSoft))),
              child: Row(children: [
                Expanded(child: Text(title, style: F.kr(size: 15))),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: C.textDim, size: 18)),
              ]),
            ),
            Flexible(child: SingleChildScrollView(padding: const EdgeInsets.fromLTRB(18, 16, 18, 16), child: body(ctx, setS))),
            if (foot != null)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                decoration: const BoxDecoration(border: Border(top: BorderSide(color: C.hairlineSoft))),
                child: foot(ctx, setS),
              ),
          ]),
        ),
      );
    }),
  );
}

/// 작은 테두리 태그
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color border;
  final double size;
  const Tag(this.text, {super.key, this.color = C.textFaint, this.border = C.hairlineSoft, this.size = 9.5});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(border: Border.all(color: border)),
      child: Text(text, style: F.inter(size: size, color: color)),
    );
  }
}

/// 수평 구분선 리스트 행
class Divided extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final bool top;
  const Divided({super.key, required this.child, this.padding = const EdgeInsets.symmetric(vertical: 12), this.top = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(border: Border(top: top ? const BorderSide(color: C.hairlineSoft) : BorderSide.none, bottom: top ? BorderSide.none : const BorderSide(color: C.hairlineSoft))),
      child: child,
    );
  }
}
