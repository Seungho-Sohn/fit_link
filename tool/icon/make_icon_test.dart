// 앱 아이콘 원본 이미지를 만든다 (앱 테마 색 + 내장 Cormorant 글꼴).
//
//   flutter test tool/icon/make_icon_test.dart     # assets/icon/*.png 생성
//   dart run flutter_launcher_icons                 # 각 플랫폼 아이콘으로 변환 (pubspec.yaml 설정)
//
// 색이나 모양을 바꾸려면 아래 값을 고친 뒤 두 명령을 다시 실행한다.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _onyx = Color(0xFF0A0A0B), _charcoal = Color(0xFF1B1A14);
const _gold = Color(0xFFC9A24B), _goldBright = Color(0xFFF0DA92), _goldDim = Color(0xFF8A6F35);

/// FL 모노그램 + 금색 링. [scale]은 1024 캔버스 대비 크기(적응형 아이콘 전경은 안전 영역에 맞춰 작게).
class _Mark extends StatelessWidget {
  final double scale;
  final bool background;
  const _Mark({required this.scale, required this.background});

  @override
  Widget build(BuildContext context) {
    final ring = 640 * scale, stroke = 14 * scale;
    return Container(
      width: _size,
      height: _size,
      decoration: background
          ? const BoxDecoration(
              gradient: RadialGradient(center: Alignment(-.3, -.4), radius: 1.1, colors: [_charcoal, _onyx]),
            )
          : null,
      alignment: Alignment.center,
      child: SizedBox(
        width: ring,
        height: ring,
        child: CustomPaint(
          painter: _RingPainter(stroke),
          child: Center(
            child: ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (r) => const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_goldBright, _gold]).createShader(r),
              child: Transform.translate(
                offset: Offset(0, 16 * scale), // 글꼴 위아래 여백 차이 보정 — 글자를 링 중심에 맞춤
                child: Text(
                  'FL',
                  style: TextStyle(fontFamily: 'IconCormorant', fontSize: 330 * scale, fontWeight: FontWeight.w600, letterSpacing: 6 * scale, height: 1, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double stroke;
  const _RingPainter(this.stroke);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..shader = const SweepGradient(colors: [_goldBright, _gold, _goldDim, _gold, _goldBright], transform: GradientRotation(-math.pi / 2)).createShader(rect);
    canvas.drawCircle(rect.center, size.width / 2 - stroke / 2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Future<void> _render(WidgetTester t, Widget w, String path) async {
  final key = GlobalKey();
  await t.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: RepaintBoundary(key: key, child: w)),
  ));
  await t.runAsync(() async {
    final img = await (key.currentContext!.findRenderObject() as RenderRepaintBoundary).toImage(pixelRatio: 1);
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

void main() {
  testWidgets('앱 아이콘 생성', (t) async {
    t.view.physicalSize = const Size(_size, _size);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(() async {
      final loader = FontLoader('IconCormorant')..addFont(rootBundle.load('assets/google_fonts/CormorantGaramond-SemiBold.ttf'));
      await loader.load();
    });

    // 꽉 찬 아이콘 (iOS · 웹 · Windows · macOS)
    await _render(t, const _Mark(scale: 1, background: true), 'assets/icon/icon.png');
    // Android 적응형 아이콘 전경: 투명 배경, 가운데 안전 영역(지름 약 61%) 안에 들어가도록 축소
    await _render(t, const _Mark(scale: .9, background: false), 'assets/icon/icon_foreground.png');
  });
}
