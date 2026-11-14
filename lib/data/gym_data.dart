// 자동 생성 파일 — 직접 고치지 마세요.
// 원본: data/gear_catalog.csv · data/gyms.csv · data/gym_gear.csv
// 다시 만들기: dart run tool/data/import_gym_data.dart (data/README.md)
import 'package:latlong2/latlong.dart';

import 'equipment.dart';
import 'mock_data.dart';

/// 기구 카탈로그 (브랜드 · 제품 라인 · 모델)
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

/// 헬스장 (이름 · 현재 인원(데모) · 면적(평) · 좌표)
const gyms = [
  Gym('스틸핏 강남점', 37, 150, LatLng(37.4997, 127.03), rating: 4.8, hours: '06:00–24:00', perk: 'PT 가능'),
  Gym('코어짐24 역삼', 90, 120, LatLng(37.5009, 127.0368), rating: 4.6, hours: '24시간', perk: '24시간'),
  Gym('바디스퀘어 논현', 62, 200, LatLng(37.5085, 127.0236), rating: 4.4, hours: '06:00–23:00', perk: '주차 가능'),
  Gym('아이언짐 삼성', 128, 140, LatLng(37.5088, 127.0631), rating: 4.5, hours: '05:00–24:00', perk: '샤워실'),
  Gym('머슬팩토리 선릉', 200, 320, LatLng(37.5045, 127.049), rating: 4.7, hours: '24시간', perk: '프리웨이트 존'),
];

/// 헬스장별 보유 기구. 키는 [Gym.name].
const gymGear = <String, List<String>>{
  '스틸핏 강남점': ['hs-pl-pulldown', 'hs-pl-low-row', 'hs-pl-chest', 'hs-pl-leg-press', 'lf-ins-row'],
  '코어짐24 역삼': ['hs-sel-pulldown', 'hs-pl-low-row', 'cybex-leg-press', 'tg-sel-chest'],
  '바디스퀘어 논현': ['lf-ins-pulldown', 'lf-ins-row', 'matrix-leg-press', 'tg-sel-chest'],
  '아이언짐 삼성': ['newtech-pulldown', 'hs-pl-chest', 'cybex-leg-press'],
  '머슬팩토리 선릉': ['cybex-pulldown', 'hs-pl-pulldown', 'hs-pl-leg-press', 'lf-ins-row'],
};
