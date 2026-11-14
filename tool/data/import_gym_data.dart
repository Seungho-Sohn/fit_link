// data/*.csv 를 검사하고 lib/data/gym_data.dart 를 다시 만든다.
//
//   dart run tool/data/import_gym_data.dart
//
// 오류가 있으면 파일 이름·행 번호와 함께 알려 주고, 앱 코드는 바꾸지 않는다.
import 'dart:io';

import 'gym_data_csv.dart';

const outFile = 'lib/data/gym_data.dart';

void main() {
  String read(String name) {
    final f = File('data/$name');
    if (!f.existsSync()) {
      stderr.writeln('data/$name 파일이 없어요. 프로젝트 폴더에서 실행했는지 확인해 주세요.');
      exit(2);
    }
    return f.readAsStringSync();
  }

  final r = importGymData(catalog: read(catalogFile), gyms: read(gymsFile), gymGear: read(gymGearFile));
  final d = r.data;
  if (d == null) {
    stderr.writeln('데이터에 고칠 곳이 ${r.errors.length}개 있어요. 앱 코드는 바꾸지 않았어요.\n');
    for (final e in r.errors) {
      stderr.writeln('  • $e');
    }
    exit(1);
  }

  final code = generateGymData(d);
  final out = File(outFile);
  final changed = !out.existsSync() || out.readAsStringSync() != code;
  if (changed) out.writeAsStringSync(code);
  final pairs = d.gymGear.values.fold<int>(0, (n, l) => n + l.length);
  stdout.writeln('${changed ? '$outFile 를 새로 만들었어요' : '바뀐 내용이 없어요'} — 기구 ${d.catalog.length}종 · 헬스장 ${d.gyms.length}곳 · 보유 기록 $pairs건');
}
