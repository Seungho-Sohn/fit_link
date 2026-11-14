// 시그니처 기능(기구 → 같은 기구가 있는 헬스장)의 데이터와 매칭 규칙.
//
// 지금은 목업 데이터다. 제휴 헬스장·운영자 등록 데이터가 생기면 [gearCatalog]와 [gymGear]를
// 서버 데이터로 바꾸면 되고, 매칭 규칙([matchLevel] · [matchGyms])은 그대로 쓴다.
import 'mock_data.dart';

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

/// 기구 카탈로그 (목업). 브랜드명은 실제 제조사, 모델 구성은 예시.
const gearCatalog = [
  GearModel('hs-pl-pulldown', 'Hammer Strength', 'Plate-Loaded', '프론트 풀다운', 'Front Pulldown', GearCategory.pulldown, DriveType.plateLoaded, '광배근'),
  GearModel('hs-sel-pulldown', 'Hammer Strength', 'Select', '랫 풀다운', 'Lat Pulldown', GearCategory.pulldown, DriveType.selectorized, '광배근'),
  GearModel('lf-ins-pulldown', 'Life Fitness', 'Insignia', '랫 풀다운', 'Lat Pulldown', GearCategory.pulldown, DriveType.selectorized, '광배근'),
  GearModel('cybex-pulldown', 'Cybex', 'Prestige', '랫 풀다운', 'Lat Pulldown', GearCategory.pulldown, DriveType.selectorized, '광배근'),
  GearModel('newtech-pulldown', '뉴텍', 'Plate', '프론트 풀다운', 'Front Pulldown', GearCategory.pulldown, DriveType.plateLoaded, '광배근'),
  GearModel('hs-pl-low-row', 'Hammer Strength', 'Plate-Loaded', '로우 로우', 'Low Row', GearCategory.row, DriveType.plateLoaded, '광배근 · 능형근'),
  GearModel('lf-ins-row', 'Life Fitness', 'Insignia', '시티드 로우', 'Seated Row', GearCategory.row, DriveType.selectorized, '능형근 · 승모근'),
  GearModel('hs-pl-chest', 'Hammer Strength', 'Plate-Loaded', '아이소 래터럴 체스트 프레스', 'Iso-Lateral Chest Press', GearCategory.chestPress, DriveType.plateLoaded, '대흉근'),
  GearModel('tg-sel-chest', 'Technogym', 'Selection', '체스트 프레스', 'Chest Press', GearCategory.chestPress, DriveType.selectorized, '대흉근'),
  GearModel('hs-pl-leg-press', 'Hammer Strength', 'Plate-Loaded', '레그 프레스', 'Leg Press', GearCategory.legPress, DriveType.plateLoaded, '대퇴사두 · 둔근'),
  GearModel('cybex-leg-press', 'Cybex', 'Plate', '레그 프레스', 'Leg Press', GearCategory.legPress, DriveType.plateLoaded, '대퇴사두 · 둔근'),
  GearModel('matrix-leg-press', 'Matrix', 'Aura', '레그 프레스', 'Leg Press', GearCategory.legPress, DriveType.selectorized, '대퇴사두 · 둔근'),
];

GearModel gearById(String id) => gearCatalog.firstWhere((g) => g.id == id);

/// 헬스장별 보유 기구 (목업). 키는 [Gym.name].
const gymGear = <String, List<String>>{
  '스틸핏 강남점': ['hs-pl-pulldown', 'hs-pl-low-row', 'hs-pl-chest', 'hs-pl-leg-press', 'lf-ins-row'],
  '코어짐24 역삼': ['hs-sel-pulldown', 'hs-pl-low-row', 'cybex-leg-press', 'tg-sel-chest'],
  '바디스퀘어 논현': ['lf-ins-pulldown', 'lf-ins-row', 'matrix-leg-press', 'tg-sel-chest'],
  '아이언짐 삼성': ['newtech-pulldown', 'hs-pl-chest', 'cybex-leg-press'],
  '머슬팩토리 선릉': ['cybex-pulldown', 'hs-pl-pulldown', 'hs-pl-leg-press', 'lf-ins-row'],
};

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
