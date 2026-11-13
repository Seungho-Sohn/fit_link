import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/data/equipment.dart';
import 'package:fit_link/data/mock_data.dart';
import 'package:fit_link/services/gear_recognizer.dart';

void main() {
  group('데이터 무결성', () {
    test('기구 id가 겹치지 않는다', () {
      final ids = gearCatalog.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('헬스장 보유 기구는 모두 카탈로그에 있고, 모든 헬스장에 보유 목록이 있다', () {
      for (final e in gymGear.entries) {
        expect(gyms.any((g) => g.name == e.key), isTrue, reason: '없는 헬스장: ${e.key}');
        for (final id in e.value) {
          expect(gearCatalog.any((g) => g.id == id), isTrue, reason: '${e.key}: 없는 기구 $id');
        }
      }
      for (final g in gyms) {
        expect(gymGear.containsKey(g.name), isTrue, reason: '보유 목록 없음: ${g.name}');
      }
    });

    test('모든 기구 종류에 고를 수 있는 기구가 있다', () {
      for (final c in GearCategory.values) {
        expect(gearCatalog.where((g) => g.category == c), isNotEmpty, reason: c.label);
      }
    });
  });

  group('매칭 규칙', () {
    final hsPulldown = gearById('hs-pl-pulldown');

    test('같은 모델 > 같은 브랜드 같은 종류 > 다른 브랜드 같은 종류, 종류가 다르면 매칭 안 됨', () {
      expect(matchLevel(hsPulldown, hsPulldown), MatchLevel.exact);
      expect(matchLevel(hsPulldown, gearById('hs-sel-pulldown')), MatchLevel.sameBrand);
      expect(matchLevel(hsPulldown, gearById('lf-ins-pulldown')), MatchLevel.alternative);
      expect(matchLevel(hsPulldown, gearById('hs-pl-leg-press')), isNull);
    });

    test('헬스장마다 가장 잘 맞는 기구로 판정하고, 일치 정도 순으로 정렬한다', () {
      final r = matchGyms(hsPulldown);
      String levelOf(String gym) => r.firstWhere((m) => m.gym.name == gym).level.label;
      expect(levelOf('스틸핏 강남점'), MatchLevel.exact.label);
      expect(levelOf('머슬팩토리 선릉'), MatchLevel.exact.label); // Cybex도 있지만 동일 모델이 우선
      expect(levelOf('코어짐24 역삼'), MatchLevel.sameBrand.label);
      expect(levelOf('바디스퀘어 논현'), MatchLevel.alternative.label);
      expect([for (final m in r) m.level.index], orderedEquals([...r.map((m) => m.level.index)]..sort()));
    });

    test('같은 종류 기구가 하나도 없는 헬스장은 빠진다', () {
      final r = matchGyms(gearById('hs-pl-pulldown'), gear: {'스틸핏 강남점': ['hs-pl-leg-press']});
      expect(r, isEmpty);
    });
  });

  test('을/를은 받침에 따라', () {
    expect(objectParticle('랫 풀다운'), '을');
    expect(objectParticle('레그 프레스'), '를');
    expect(objectParticle('Low Row'), '을(를)');
  });

  test('데모 인식기는 카탈로그 기구를 확신도 높은 순으로 돌려준다', () async {
    const r = DemoGearRecognizer(delay: Duration.zero);
    final c = await r.recognize(Uint8List(0), 'image/png');
    expect(r.isDemo, isTrue);
    expect(c, isNotEmpty);
    expect([for (final x in c) x.confidence], orderedEquals([...c.map((x) => x.confidence)]..sort((a, b) => b.compareTo(a))));
  });
}
