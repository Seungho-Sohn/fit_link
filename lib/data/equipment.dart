// 시그니처 기능(기구 → 같은 기구가 있는 헬스장)의 데이터와 매칭 규칙.
//
// 데이터([gearCatalog] · [gymGear] · 헬스장 목록)는 data/*.csv 에서 만든 gym_data.dart 에 있다
// (지금은 목업, 제휴 헬스장 데이터가 오면 CSV만 바꾼다 — data/README.md).
// 매칭 규칙([matchLevel] · [matchGyms])은 데이터가 바뀌어도 그대로 쓴다.
import 'gym_data.dart';
import 'mock_data.dart';

export 'gym_data.dart' show gearCatalog, gymGear;

/// 기구 종류
enum GearCategory {
  pulldown('랫풀다운'),
  row('로우'),
  chestPress('체스트 프레스'),
  legPress('레그 프레스');

  const GearCategory(this.label);
  final String label;
}

/// 구동 방식
enum DriveType {
  plateLoaded('플레이트 로디드'),
  selectorized('셀렉토라이즈드');

  const DriveType(this.label);
  final String label;
}

/// 기구 모델 (브랜드 · 제품 라인 · 모델)
class GearModel {
  final String id, brand, line, nameKo, nameEn, targetMuscle;
  final GearCategory category;
  final DriveType drive;
  const GearModel(this.id, this.brand, this.line, this.nameKo, this.nameEn, this.category, this.drive, this.targetMuscle);

  /// 'Hammer Strength · Plate-Loaded'
  String get brandLine => '$brand · $line';
}

GearModel gearById(String id) => gearCatalog.firstWhere((g) => g.id == id);

/// 헬스장 보유 기구 정보가 어디서 왔는지 (회원에게 신뢰도로 보여준다).
/// 매칭에 쓰는 실제 목록은 [gymGear]에 운영자 등록·이용자 제보를 합친 `AppState.gymGearNow`.
enum GearSource {
  listed('등록 정보'), // 기본(제휴) 데이터, 아직 아무도 확인하지 않음
  operator('운영자 등록'), // 헬스장 운영자가 B2B 화면에서 직접 등록
  member('이용자 확인'); // 회원이 "있어요"로 확인

  const GearSource(this.label);
  final String label;
}

/// 찾는 기구와 헬스장 보유 기구의 일치 정도 (위쪽일수록 좋음)
enum MatchLevel {
  exact('동일 모델', 100),
  sameBrand('같은 브랜드', 85),
  alternative('같은 종류 대체 기구', 60);

  const MatchLevel(this.label, this.score);
  final String label;

  /// 목록에 보여주는 매칭 점수
  final int score;
}

/// [target]을 찾을 때 [other]가 얼마나 맞는지. 종류가 다르면 null.
MatchLevel? matchLevel(GearModel target, GearModel other) {
  if (other.id == target.id) return MatchLevel.exact;
  if (other.category != target.category) return null;
  return other.brand == target.brand ? MatchLevel.sameBrand : MatchLevel.alternative;
}

/// 헬스장 한 곳의 매칭 결과: 가장 잘 맞는 보유 기구와 그 정도
typedef GymMatch = ({Gym gym, MatchLevel level, GearModel gear});

/// [target]을 보유했거나 비슷한 기구가 있는 헬스장들 (일치 정도가 높은 순, 같으면 [gyms] 순서)
List<GymMatch> matchGyms(GearModel target, {List<Gym> from = gyms, Map<String, List<String>> gear = gymGear}) {
  final result = <GymMatch>[];
  for (final gym in from) {
    GymMatch? best;
    for (final id in gear[gym.name] ?? const <String>[]) {
      final g = gearById(id);
      final level = matchLevel(target, g);
      if (level != null && (best == null || level.index < best.level.index)) best = (gym: gym, level: level, gear: g);
    }
    if (best != null) result.add(best);
  }
  result.sort((a, b) => a.level.index.compareTo(b.level.index));
  return result;
}

/// 목적격 조사: 마지막 글자에 받침이 있으면 '을', 없으면 '를' ('풀다운을', '프레스를').
/// 마지막 글자가 한글이 아니면 '을(를)'.
String objectParticle(String word) {
  if (word.isEmpty) return '을(를)';
  final c = word.runes.last;
  if (c < 0xAC00 || c > 0xD7A3) return '을(를)';
  return (c - 0xAC00) % 28 == 0 ? '를' : '을';
}
