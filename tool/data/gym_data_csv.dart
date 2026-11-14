// data/*.csv(기구 카탈로그 · 헬스장 · 헬스장별 보유 기구)를 읽고 검사해서
// 앱 코드 lib/data/gym_data.dart 를 만든다. 사용법은 data/README.md.
//
// 순수 Dart라 `dart run tool/data/import_gym_data.dart`로 돌고,
// test/gym_data_test.dart 가 같은 함수로 "CSV와 앱 코드가 일치하는지"를 확인한다.
import 'package:fit_link/data/equipment.dart';

/// CSV 파일 이름 (data/ 아래)
const catalogFile = 'gear_catalog.csv', gymsFile = 'gyms.csv', gymGearFile = 'gym_gear.csv';

/// 각 파일의 열 이름 (순서는 자유, 이름은 정확히)
const catalogCols = ['기구ID', '브랜드', '제품라인', '이름(한글)', '이름(영문)', '종류', '구동방식', '타겟부위'];
const gymsCols = ['헬스장', '위도', '경도', '면적(평)', '평점', '운영시간', '대표편의', '현재인원(데모)'];
const gymGearCols = ['헬스장', '기구ID'];

typedef CatalogRow = ({String id, String brand, String line, String nameKo, String nameEn, GearCategory category, DriveType drive, String target});
typedef GymRow = ({String name, double lat, double lng, int area, double rating, String hours, String perk, int now});

/// 검사를 통과한 데이터 (CSV 순서 그대로)
typedef GymDataSet = ({List<CatalogRow> catalog, List<GymRow> gyms, Map<String, List<String>> gymGear});

/// 검사 결과: 데이터 또는 오류 목록 ('gyms.csv 3행: …')
typedef ImportResult = ({GymDataSet? data, List<String> errors});

/* ---------------- CSV 읽기 ---------------- */

/// RFC 4180 CSV: 큰따옴표로 감싼 칸(쉼표·줄바꿈 포함 가능, "" = "), CRLF/LF, 맨 앞 BOM 무시.
/// 행마다 (원본 줄 번호, 칸들). 완전히 빈 줄은 건너뛴다.
List<({int line, List<String> cells})> parseCsv(String text) {
  if (text.startsWith('﻿')) text = text.substring(1);
  final rows = <({int line, List<String> cells})>[];
  var cells = <String>[];
  final cell = StringBuffer();
  var quoted = false, line = 1, rowLine = 1;

  void endCell() {
    cells.add(cell.toString().trim());
    cell.clear();
  }

  void endRow() {
    endCell();
    if (cells.any((c) => c.isNotEmpty)) rows.add((line: rowLine, cells: cells));
    cells = [];
  }

  for (var i = 0; i < text.length; i++) {
    final ch = text[i];
    if (quoted) {
      if (ch == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        if (ch == '\n') line++;
        cell.write(ch);
      }
    } else if (ch == '"') {
      quoted = true;
    } else if (ch == ',') {
      endCell();
    } else if (ch == '\r') {
      // \r\n 의 \r 은 무시
    } else if (ch == '\n') {
      endRow();
      line++;
      rowLine = line;
    } else {
      cell.write(ch);
    }
  }
  if (cell.isNotEmpty || cells.isNotEmpty) endRow();
  return rows;
}

/// 머리글 행으로 열 위치를 찾아, 데이터 행마다 {열 이름: 값}을 돌려준다.
List<({int line, Map<String, String> v})> _table(String file, String text, List<String> cols, List<String> errors) {
  final rows = parseCsv(text);
  if (rows.isEmpty) {
    errors.add('$file: 내용이 없어요 (첫 줄은 머리글: ${cols.join(',')})');
    return const [];
  }
  final head = rows.first.cells;
  final missing = [for (final c in cols) if (!head.contains(c)) c];
  if (missing.isNotEmpty) {
    errors.add('$file 1행: 머리글에 ${missing.map((c) => '"$c"').join(', ')} 열이 없어요 (필요한 열: ${cols.join(',')})');
    return const [];
  }
  return [
    for (final r in rows.skip(1))
      (line: r.line, v: {for (final c in cols) c: head.indexOf(c) < r.cells.length ? r.cells[head.indexOf(c)] : ''}),
  ];
}

/* ---------------- 검사 ---------------- */

final _idPattern = RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$');

T? _enumByLabel<T extends Enum>(List<T> values, String s, String Function(T) label) {
  for (final v in values) {
    if (label(v) == s || v.name == s) return v;
  }
  return null;
}

/// 세 CSV의 내용을 검사한다. 오류가 하나라도 있으면 data는 null.
ImportResult importGymData({required String catalog, required String gyms, required String gymGear}) {
  final errors = <String>[];
  void err(String file, int line, String msg) => errors.add('$file $line행: $msg');

  // 기구 카탈로그
  final cat = <CatalogRow>[];
  final ids = <String>{};
  for (final r in _table(catalogFile, catalog, catalogCols, errors)) {
    final v = r.v, at = r.line;
    final id = v['기구ID']!;
    var ok = true;
    for (final c in catalogCols) {
      if (v[c]!.isEmpty) {
        err(catalogFile, at, '"$c"이(가) 비어 있어요');
        ok = false;
      }
    }
    if (!ok) continue;
    if (!_idPattern.hasMatch(id)) {
      err(catalogFile, at, '기구ID "$id"는 영문 소문자·숫자·하이픈(-)만 쓸 수 있어요 (예: hs-pl-pulldown)');
      continue;
    }
    if (!ids.add(id)) {
      err(catalogFile, at, '기구ID "$id"가 이미 위에 있어요');
      continue;
    }
    final category = _enumByLabel(GearCategory.values, v['종류']!, (c) => c.label);
    final drive = _enumByLabel(DriveType.values, v['구동방식']!, (d) => d.label);
    if (category == null) err(catalogFile, at, '종류 "${v['종류']}"를 모르겠어요 (${GearCategory.values.map((c) => c.label).join(' / ')})');
    if (drive == null) err(catalogFile, at, '구동방식 "${v['구동방식']}"를 모르겠어요 (${DriveType.values.map((d) => d.label).join(' / ')})');
    if (category == null || drive == null) continue;
    cat.add((id: id, brand: v['브랜드']!, line: v['제품라인']!, nameKo: v['이름(한글)']!, nameEn: v['이름(영문)']!, category: category, drive: drive, target: v['타겟부위']!));
  }
  for (final c in GearCategory.values) {
    if (ids.isNotEmpty && !cat.any((g) => g.category == c)) errors.add('$catalogFile: 종류 "${c.label}" 기구가 하나도 없어요 (직접 찾기 화면에서 고를 게 없어져요)');
  }

  // 헬스장
  final gymRows = <GymRow>[];
  final names = <String>{};
  for (final r in _table(gymsFile, gyms, gymsCols, errors)) {
    final v = r.v, at = r.line;
    final name = v['헬스장']!;
    var ok = true;
    for (final c in gymsCols) {
      if (v[c]!.isEmpty) {
        err(gymsFile, at, '"$c"이(가) 비어 있어요');
        ok = false;
      }
    }
    if (!ok) continue;
    if (!names.add(name)) {
      err(gymsFile, at, '헬스장 "$name"이(가) 이미 위에 있어요 (이름이 같으면 구분할 수 없어요)');
      continue;
    }
    double? num(String col, double min, double max, String hint) {
      final x = double.tryParse(v[col]!);
      if (x == null || x < min || x > max) {
        err(gymsFile, at, '$col "${v[col]}"이(가) 올바르지 않아요 ($hint)');
        return null;
      }
      return x;
    }

    int? whole(String col, int min) {
      final x = int.tryParse(v[col]!);
      if (x == null || x < min) {
        err(gymsFile, at, '$col "${v[col]}"은(는) $min 이상의 정수여야 해요');
        return null;
      }
      return x;
    }

    final lat = num('위도', 33, 39, '한국 안: 33~39, 예 37.4997');
    final lng = num('경도', 124, 132, '한국 안: 124~132, 예 127.0300');
    final rating = num('평점', 0, 5, '0~5');
    final area = whole('면적(평)', 1), now = whole('현재인원(데모)', 0);
    if (lat == null || lng == null || rating == null || area == null || now == null) continue;
    gymRows.add((name: name, lat: lat, lng: lng, area: area, rating: rating, hours: v['운영시간']!, perk: v['대표편의']!, now: now));
  }

  // 헬스장별 보유 기구
  final owned = <String, List<String>>{for (final g in gymRows) g.name: []};
  for (final r in _table(gymGearFile, gymGear, gymGearCols, errors)) {
    final gym = r.v['헬스장']!, id = r.v['기구ID']!, at = r.line;
    if (gym.isEmpty || id.isEmpty) {
      err(gymGearFile, at, '헬스장과 기구ID를 모두 적어 주세요');
    } else if (!names.contains(gym)) {
      err(gymGearFile, at, '헬스장 "$gym"이(가) $gymsFile에 없어요');
    } else if (!ids.contains(id)) {
      err(gymGearFile, at, '기구ID "$id"가 $catalogFile에 없어요');
    } else if (owned[gym]!.contains(id)) {
      err(gymGearFile, at, '"$gym"의 "$id"가 이미 위에 있어요');
    } else {
      owned[gym]!.add(id);
    }
  }
  for (final g in gymRows) {
    if (owned[g.name]!.isEmpty) errors.add('$gymGearFile: "${g.name}"의 보유 기구가 하나도 없어요');
  }

  if (cat.isEmpty && errors.isEmpty) errors.add('$catalogFile: 기구가 하나도 없어요');
  if (gymRows.isEmpty && errors.isEmpty) errors.add('$gymsFile: 헬스장이 하나도 없어요');
  return errors.isEmpty ? (data: (catalog: cat, gyms: gymRows, gymGear: owned), errors: const <String>[]) : (data: null, errors: errors);
}

/* ---------------- 코드 만들기 ---------------- */

String _str(String s) => "'${s.replaceAll(r'\', r'\\').replaceAll("'", r"\'").replaceAll(r'$', r'\$')}'";

/// lib/data/gym_data.dart 내용
String generateGymData(GymDataSet d) {
  final b = StringBuffer()
    ..writeln('// 자동 생성 파일 — 직접 고치지 마세요.')
    ..writeln('// 원본: data/$catalogFile · data/$gymsFile · data/$gymGearFile')
    ..writeln('// 다시 만들기: dart run tool/data/import_gym_data.dart (data/README.md)')
    ..writeln("import 'package:latlong2/latlong.dart';")
    ..writeln()
    ..writeln("import 'equipment.dart';")
    ..writeln("import 'mock_data.dart';")
    ..writeln()
    ..writeln('/// 기구 카탈로그 (브랜드 · 제품 라인 · 모델)')
    ..writeln('const gearCatalog = [');
  for (final g in d.catalog) {
    b.writeln('  GearModel(${[g.id, g.brand, g.line, g.nameKo, g.nameEn].map(_str).join(', ')}, GearCategory.${g.category.name}, DriveType.${g.drive.name}, ${_str(g.target)}),');
  }
  b
    ..writeln('];')
    ..writeln()
    ..writeln('/// 헬스장 (이름 · 현재 인원(데모) · 면적(평) · 좌표)')
    ..writeln('const gyms = [');
  for (final g in d.gyms) {
    b.writeln('  Gym(${_str(g.name)}, ${g.now}, ${g.area}, LatLng(${g.lat}, ${g.lng}), rating: ${g.rating}, hours: ${_str(g.hours)}, perk: ${_str(g.perk)}),');
  }
  b
    ..writeln('];')
    ..writeln()
    ..writeln('/// 헬스장별 보유 기구. 키는 [Gym.name].')
    ..writeln('const gymGear = <String, List<String>>{');
  for (final e in d.gymGear.entries) {
    b.writeln('  ${_str(e.key)}: [${e.value.map(_str).join(', ')}],');
  }
  b.writeln('};');
  return b.toString();
}
