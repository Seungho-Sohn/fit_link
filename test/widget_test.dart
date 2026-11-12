// FIT LINK 기본 테스트.
// flutter create 가 만든 카운터 예제(MyApp)를 대체합니다.
// 화면을 실제로 띄우는 테스트는 google_fonts 가 실행 중 글꼴을 내려받으려 해서
// 테스트 환경에서 실패할 수 있으므로, 지금은 앱 진입 위젯이 만들어지는지만 확인합니다.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/main.dart';

void main() {
  test('FitLinkApp 진입 위젯 생성', () {
    const app = FitLinkApp();
    expect(app, isA<StatelessWidget>());
  });
}
