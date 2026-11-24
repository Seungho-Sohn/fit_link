import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/data/mock_data.dart';
import 'package:fit_link/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // toast()가 GlobalKey에 접근
  late AppState s;
  setUp(() => s = AppState.fresh());

  group('화면 전환', () {
    test('go()는 pageSeq를 올리고 운영자 전용관 내부 화면을 첫 화면으로 되돌린다', () {
      s.goB2B(B2BPage.quote);
      final seq = s.pageSeq;
      s.go(AppPage.b2b);
      expect(s.pageSeq, seq + 1);
      expect(s.b2bPage, B2BPage.home);
    });

    test('goB2B: 다른 화면에서 오면 전용관을 새로 시작하고, 안에서 이동할 때는 그대로', () {
      final seq = s.pageSeq;
      s.goB2B(B2BPage.gear);
      expect((s.page, s.b2bPage, s.pageSeq), (AppPage.b2b, B2BPage.gear, seq + 1));
      s.goB2B(B2BPage.dash);
      expect((s.b2bPage, s.pageSeq), (B2BPage.dash, seq + 1));
    });

    test('하단 탭은 홈 · 헬스장 찾기 · 커뮤니티 · 칼로리 · 마이', () {
      expect([for (final p in AppPage.values) if (p.tab == p) p], [AppPage.home, AppPage.gear, AppPage.comm, AppPage.cal, AppPage.my]);
    });

    test('하위 화면의 강조 탭과 뒤로가기 대상', () {
      expect(AppPage.coach.tab, AppPage.home);
      expect(AppPage.b2b.tab, AppPage.my);
      expect(AppPage.gear.tab, AppPage.gear);
      expect(AppPage.live.parent, AppPage.coach);
      expect(AppPage.b2b.parent, AppPage.my);
      expect(AppPage.cal.parent, AppPage.home);
    });
  });

  group('커뮤니티', () {
    test('내 글은 피드 맨 앞, 이름 옆 배지 없이', () {
      final p = s.addPost('운동 인증', '오늘 하체');
      expect(s.feed.first, same(p));
      expect(p.tier, isEmpty);
      expect(p.img, '🔥');
    });

    test('포인트 등급 배지는 없고 트레이너(PT) 표시만 남는다', () {
      expect({for (final p in seedPosts) p.tier}.where((t) => t.isNotEmpty), {'PT'});
    });
  });
}
