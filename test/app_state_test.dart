import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/data/mock_data.dart';
import 'package:fit_link/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // toast()가 GlobalKey에 접근
  late AppState s;
  setUp(() => s = AppState.fresh());

  group('화면 전환', () {
    test('go()는 pageSeq를 올리고 마켓·배달 내부 화면을 홈으로 되돌린다', () {
      s.goMarket(MarketView.cart);
      s.goDeliv(DelivView.pay);
      final seq = s.pageSeq;
      s.go(AppPage.market);
      expect(s.pageSeq, seq + 1);
      expect(s.marketView, MarketView.home);
      s.go(AppPage.delivery);
      expect(s.delivView, DelivView.home);
    });

    test('하위 화면의 강조 탭과 뒤로가기 대상', () {
      expect(AppPage.coach.tab, AppPage.home);
      expect(AppPage.points.tab, AppPage.my);
      expect(AppPage.market.tab, AppPage.market);
      expect(AppPage.live.parent, AppPage.coach);
      expect(AppPage.points.parent, AppPage.my);
      expect(AppPage.cal.parent, AppPage.home);
    });

    test('openProduct / openShop은 해당 탭의 상세 화면으로 이동한다', () {
      s.openProduct('p1');
      expect((s.page, s.marketView, s.curProductId), (AppPage.market, MarketView.detail, 'p1'));
      s.openShop('s2');
      expect((s.page, s.delivView, s.curShopId), (AppPage.delivery, DelivView.store, 's2'));
    });
  });

  group('포인트', () {
    test('적립은 잔액과 누적을 올리고 내역 맨 앞에 기록한다', () {
      final p = s.points, e = s.earned;
      s.earnPoints(800, '테스트');
      expect(s.points, p + 800);
      expect(s.earned, e + 800);
      expect(s.ptHistory.first.reason, '테스트');
      expect(s.ptHistory.first.signed, '+800');
    });

    test('사용은 누적에 영향이 없고 잔액은 0 아래로 내려가지 않는다', () {
      final e = s.earned;
      s.spendPoints(s.points + 5000, '과다 사용');
      expect(s.points, 0);
      expect(s.earned, e);
      expect(s.ptHistory.first.isSpend, isTrue);
      expect(s.ptHistory.first.signed, startsWith('-'));
    });

    test('등급은 누적 적립 기준으로 정해진다', () {
      s.earned = 0;
      expect(s.tier.en, 'Bronze');
      s.earned = tiers[2].min;
      expect(s.tier.en, tiers[2].en);
      s.earned = 999999;
      expect(s.tier, tiers.last);
    });

    test('출석은 하루 한 번만 적립된다', () {
      final p = s.points;
      s.attend();
      s.attend();
      expect(s.points, p + 10);
    });

    test('포인트가 부족하면 특가 교환이 되지 않는다', () {
      final d = s.ptDeals.first;
      final left = d.left;
      s.points = d.pts - 1;
      s.redeemDeal(d);
      expect((s.points, d.left), (d.pts - 1, left));

      s.points = d.pts;
      s.redeemDeal(d);
      expect((s.points, d.left), (0, left - 1));
    });

    test('주간 미션을 모두 채워야 스탬프 보너스를 한 번 받을 수 있다', () {
      final p = s.points;
      s.claimStamp();
      expect(s.points, p);
      expect(s.missionsAllDone, isFalse);

      for (final m in s.missions) {
        m.progress = m.goal;
      }
      expect(s.missionsDone, s.missions.length);
      s.claimStamp();
      s.claimStamp();
      expect(s.points, p + 500);
      expect(s.stampClaimed, isTrue);
    });
  });

  group('마켓 장바구니', () {
    test('담기 · 합계 · 주문', () {
      final p1 = productById('p1').price, p6 = productById('p6').price;
      s.addToCart('p1', 2);
      s.addToCart('p6', 1);
      s.addToCart('p1', 1);
      expect(s.cartCount, 4);
      expect(s.cartTotal, p1 * 3 + p6);

      s.checkout();
      expect(s.cart, isEmpty);
      expect(s.lastOrderTotal, p1 * 3 + p6);
      expect(s.marketView, MarketView.done);
    });

    test('빈 장바구니는 주문되지 않는다', () {
      s.checkout();
      expect(s.marketView, MarketView.home);
    });
  });

  group('배달 결제', () {
    test('수량이 0이 되면 장바구니에서 빠진다', () {
      s.dAdd('d1');
      s.dQty('d1', 1);
      expect(s.dCount, 2);
      s.dQty('d1', -2);
      expect(s.dcart.containsKey('d1'), isFalse);
    });

    test('클럽 할인은 상품금액을 넘지 않는다', () {
      s.dcart['d1'] = 1;
      expect(s.payCalc().clubDiscount, 1000);
      // 1,000원 미만 주문을 흉내 내기 위해 빈 장바구니로 계산
      s.dcart.clear();
      final c = s.payCalc();
      expect((c.subtotal, c.clubDiscount, c.total), (0, 0, 0));
    });

    test('포인트 사용은 할인 후 금액까지만, 적립은 최종 금액 × 등급 적립률', () {
      final price = menuById('d1').price;
      s.dcart['d1'] = 1;
      s.points = 1000000;
      s.dUsePts = true;
      var c = s.payCalc();
      expect(c.pointsUsed, price - 1000);
      expect(c.total, 0);

      s.points = 500;
      c = s.payCalc();
      expect(c.subtotal, price);
      expect(c.pointsUsed, 500);
      expect(c.total, price - 1000 - 500);
      expect(c.pointsEarned, (c.total * s.tier.rate / 100).round());
    });

    test('주문하면 포인트를 차감하고, 잠시 후 결제액 적립', () async {
      s.dcart['d1'] = 2;
      s.points = 500;
      s.toggleDPts();
      final c = s.payCalc();

      s.placeDOrder();
      expect(s.points, 0);
      expect(s.lastDelivTotal, c.total);
      expect(s.dcart, isEmpty);
      expect(s.dUsePts, isFalse);
      expect(s.delivView, DelivView.done);

      await Future<void>.delayed(const Duration(milliseconds: 800));
      expect(s.points, c.pointsEarned);
      expect(s.ptHistory.first.reason, '배달 주문 적립');
    });
  });

  test('PointLog 부호 표기', () {
    expect(const PointLog('a', 2000, '').signed, '+2,000');
    expect(const PointLog('a', -3900, '').signed, '-3,900');
  });

  group('주간 미션 · 실제 행동', () {
    int prog(AppState s, MissionKind k) => s.missions.firstWhere((m) => m.kind == k).progress;

    test('새로 시작하면 모든 미션이 0', () {
      expect(AppState.fresh().missions.map((m) => m.progress), everyElement(0));
    });

    test('출석 · 운동 인증 글 · 배달 주문 · 리뷰 · 신기록이 각 미션을 올린다', () {
      s.attend();
      s.addPost('운동 인증', 'a');
      s.addPost('식단 인증', 'b'); // 운동 인증만 센다
      s.dAdd('d1');
      s.placeDOrder();
      s.writeReview();
      s.recordPersonalRecord();
      expect(prog(s, MissionKind.attend), 1);
      expect(prog(s, MissionKind.workoutPost), 1);
      expect(prog(s, MissionKind.delivery), 1);
      expect(prog(s, MissionKind.review), 1);
      expect(prog(s, MissionKind.personalRecord), 1);
    });

    test('목표를 넘어 올라가지 않는다', () {
      for (var i = 0; i < 5; i++) {
        s.addPost('운동 인증', '$i');
        s.writeReview();
      }
      expect(prog(s, MissionKind.workoutPost), MissionKind.workoutPost.goal);
      expect(prog(s, MissionKind.review), MissionKind.review.goal);
    });

    test('리뷰 쓰기는 +100P', () {
      final p = s.points;
      s.writeReview();
      expect(s.points, p + 100);
    });
  });
}
