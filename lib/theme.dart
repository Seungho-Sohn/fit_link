import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// HTML :root CSS 변수와 1:1 대응되는 색상 팔레트
class C {
  static const onyx = Color(0xFF0A0A0B);
  static const charcoal = Color(0xFF15140F);
  static const panel = Color(0xFF1B1A14);
  static const panel2 = Color(0xFF242219);
  static const hairline = Color(0xFF4A3F27);
  static const hairlineSoft = Color(0x2EC9A24B); // rgba(201,162,75,.18)
  static const gold = Color(0xFFC9A24B);
  static const goldBright = Color(0xFFF0DA92);
  static const goldDim = Color(0xFF8A6F35);
  static const ivory = Color(0xFFF1E9D6);
  static const textDim = Color(0xFFA79A7C);
  static const textFaint = Color(0xFF6E6550);
  static const good = Color(0xFFB9C79A);
  static const carb = Color(0xFFD8B25A);
  static const protein = Color(0xFFC98F5A);
  static const fat = Color(0xFF8A9BC7);
  static const live = Color(0xFFE0864F);
  static const cLow = Color(0xFF79B487);
  static const cMid = Color(0xFFD8B25A);
  static const cHigh = Color(0xFFD07C63);
  static const ink = Color(0xFF1A1408); // 금색 버튼 위 글자색

  static Color goldA(double o) => gold.op(o);
}

/// withOpacity(deprecated) 대체: 0~1 불투명도를 알파값으로 변환
extension ColorOp on Color {
  Color op(double o) => withAlpha((o * 255).round());
}

/// 한글 대체 글꼴. Inter·Cormorant·Bodoni에는 한글 글리프가 없어서,
/// 지정하지 않으면 기기마다 다른 시스템 글꼴로 보인다. 앱에 내장한 Pretendard로 통일.
const kKoreanFallback = ['Pretendard'];

/// 폰트 헬퍼 (라틴 글꼴은 Google Fonts 런타임 다운로드, 한글은 내장 Pretendard)
class F {
  static TextStyle inter({double size = 12, FontWeight w = FontWeight.w400, Color color = C.ivory, double ls = 0, double? h}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: w, color: color, letterSpacing: ls * size, height: h)
          .copyWith(fontFamilyFallback: kKoreanFallback);

  static TextStyle serif({double size = 16, FontWeight w = FontWeight.w500, Color color = C.ivory, double ls = 0, FontStyle? style, double? h}) =>
      GoogleFonts.cormorantGaramond(fontSize: size, fontWeight: w, color: color, letterSpacing: ls * size, fontStyle: style, height: h)
          .copyWith(fontFamilyFallback: kKoreanFallback);

  static TextStyle bodoni({double size = 16, FontWeight w = FontWeight.w500, Color color = C.ivory, double ls = 0}) =>
      GoogleFonts.bodoniModa(fontSize: size, fontWeight: w, color: color, letterSpacing: ls * size)
          .copyWith(fontFamilyFallback: kKoreanFallback);

  static TextStyle kr({double size = 14, FontWeight w = FontWeight.w600, Color color = C.ivory, double? h}) =>
      GoogleFonts.notoSerifKr(fontSize: size, fontWeight: w, color: color, height: h);

  /// 금색 숫자 (Cormorant 600)
  static TextStyle gnum({double size = 16, Color color = C.goldBright}) => serif(size: size, w: FontWeight.w600, color: color);
}

ThemeData buildTheme() {
  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: C.charcoal,
    colorScheme: const ColorScheme.dark(primary: C.gold, secondary: C.goldBright, surface: C.charcoal),
    textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(bodyColor: C.ivory, displayColor: C.ivory, fontFamilyFallback: kKoreanFallback),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

const goldGradient = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [C.goldBright, C.gold]);

LinearGradient softGold([double a = .15]) => LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [C.goldA(a), C.goldA(.02)],
    );
