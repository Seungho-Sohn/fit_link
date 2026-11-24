import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:fit_link/data/equipment.dart';

import '../tool/data/gym_data_csv.dart';

void main() {
  String read(String name) => File('data/$name').readAsStringSync();
  ImportResult importWith({String? catalog, String? gyms, String? gymGear, String? exercises}) => importGymData(
      catalog: catalog ?? read(catalogFile), gyms: gyms ?? read(gymsFile), gymGear: gymGear ?? read(gymGearFile), exercises: exercises ?? read(exercisesFile));

  test('data/*.csv 에 오류가 없고, lib/data/gym_data.dart 가 CSV와 일치한다', () {
    final r = importWith();
    expect(r.errors, isEmpty);
    final code = File('lib/data/gym_data.dart').readAsStringSync().replaceAll('\r\n', '\n');
    expect(code, generateGymData(r.data!), reason: 'CSV를 고친 뒤 dart run tool/data/import_gym_data.dart 를 실행하세요');
    expect(gearCatalog.length, r.data!.catalog.length);
    expect(exercises.length, r.data!.exercises.length);
  });

  group('CSV 읽기', () {
    test('큰따옴표 칸(쉼표·따옴표 포함), CRLF, BOM, 빈 줄', () {
      final rows = parseCsv('﻿a,b\r\n"x, y","say ""hi"""\r\n\r\n c ,\n');
      expect([for (final r in rows) r.cells], [
        ['a', 'b'],
        ['x, y', 'say "hi"'],
        ['c', ''],
      ]);
      expect([for (final r in rows) r.line], [1, 2, 4]); // 오류 메시지의 행 번호 = 엑셀 행 번호
    });

    test('열 순서가 달라도 이름으로 찾는다', () {
      final swapped = [
        for (final r in parseCsv(read(gymGearFile))) r.cells.reversed.join(','), // 헬스장,기구ID → 기구ID,헬스장
      ].join('\n');
      final r = importWith(gymGear: swapped);
      expect(r.errors, isEmpty);
      expect(r.data!.gymGear['스틸핏 강남점']!.first, 'hs-pl-pulldown');
    });
  });

  group('잘못된 데이터는 행 번호와 함께 알려 준다', () {
    List<String> errorsOf({String? catalog, String? gyms, String? gymGear, String? exercises}) =>
        importWith(catalog: catalog, gyms: gyms, gymGear: gymGear, exercises: exercises).errors;

    test('기구 카탈로그: 중복 id, 잘못된 id, 모르는 종류, 빈 칸', () {
      final head = catalogCols.join(',');
      final e = errorsOf(catalog: [
        head,
        'a-1,B,L,랫 풀다운,Lat Pulldown,랫풀다운,셀렉토라이즈드,광배근',
        'a-1,B,L,랫 풀다운,Lat Pulldown,랫풀다운,셀렉토라이즈드,광배근',
        'Bad ID,B,L,x,x,로우,셀렉토라이즈드,x',
        'c-1,B,L,x,x,스쿼트,셀렉토라이즈드,x',
        'd-1,,L,x,x,로우,셀렉토라이즈드,x',
      ].join('\n'), gymGear: '헬스장,기구ID\n');
      expect(e, contains(startsWith('gear_catalog.csv 3행: 기구ID "a-1"가 이미')));
      expect(e, contains(startsWith('gear_catalog.csv 4행: 기구ID "Bad ID"')));
      expect(e, contains(startsWith('gear_catalog.csv 5행: 종류 "스쿼트"')));
      expect(e, contains(startsWith('gear_catalog.csv 6행: "브랜드"이(가) 비어')));
      expect(e, contains(contains('종류 "체스트 프레스" 기구가 하나도 없어요')));
    });

    test('헬스장: 숫자가 아닌 좌표, 한국 밖 좌표, 평점 범위, 이름 중복', () {
      final lines = read(gymsFile).trim().split('\n');
      final e = errorsOf(gyms: [
        ...lines,
        '새 헬스장,abc,127.0,100,4.5,24시간,샤워실,10,',
        '먼 헬스장,40.7,-74.0,100,4.5,24시간,샤워실,10,',
        '별점 헬스장,37.5,127.0,100,5.5,24시간,샤워실,10,',
        '스틸핏 강남점,37.5,127.0,100,4.5,24시간,샤워실,10,',
      ].join('\n'));
      final n = lines.length; // 머리글 포함 줄 수 → 추가한 줄은 n+1행부터
      expect(e, contains(startsWith('gyms.csv ${n + 1}행: 위도 "abc"')));
      expect(e, contains(startsWith('gyms.csv ${n + 2}행: 위도 "40.7"')));
      expect(e, contains(startsWith('gyms.csv ${n + 2}행: 경도 "-74.0"')));
      expect(e, contains(startsWith('gyms.csv ${n + 3}행: 평점 "5.5"')));
      expect(e, contains(startsWith('gyms.csv ${n + 4}행: 헬스장 "스틸핏 강남점"이(가) 이미')));
    });

    test('보유 기구: 없는 헬스장·기구, 중복, 보유 기구 없는 헬스장', () {
      final e = errorsOf(gymGear: [
        '헬스장,기구ID',
        '스틸핏 강남점,hs-pl-pulldown',
        '스틸핏 강남점,hs-pl-pulldown',
        '없는짐,hs-pl-pulldown',
        '코어짐24 역삼,no-such-gear',
      ].join('\n'));
      expect(e, contains(startsWith('gym_gear.csv 3행: "스틸핏 강남점"의 "hs-pl-pulldown"가 이미')));
      expect(e, contains(startsWith('gym_gear.csv 4행: 헬스장 "없는짐"')));
      expect(e, contains(startsWith('gym_gear.csv 5행: 기구ID "no-such-gear"')));
      expect(e, contains('gym_gear.csv: "바디스퀘어 논현"의 보유 기구가 하나도 없어요'));
    });

    test('체인은 비워도 되고(단독 헬스장), 다른 칸은 비우면 안 된다', () {
      final r = importWith();
      expect(r.data!.gyms.firstWhere((g) => g.name == '바디스퀘어 논현').chain, '');
      expect(r.data!.gyms.where((g) => g.chain == '스틸핏').map((g) => g.name), ['스틸핏 강남점', '스틸핏 역삼점']);
      final e = errorsOf(gyms: '${gymsCols.join(',')}\n이름없는짐,37.5,127.0,100,4.5,,샤워실,10,\n');
      expect(e, contains(startsWith('gyms.csv 2행: "운영시간"이(가) 비어')));
    });

    test('운동: 중복·잘못된 id, 모르는 기구 종류, 빈 칸, 여러 종류는 / 로', () {
      final e = errorsOf(exercises: [
        exercisesCols.join(','),
        'a,A,등,랫풀다운/로우',
        'a,A,등,로우',
        'Bad,B,등,로우',
        'c,C,하체,스쿼트 랙',
        'd,,하체,레그 프레스',
      ].join('\n'));
      expect(e, contains(startsWith('exercises.csv 3행: 운동ID "a"가 이미')));
      expect(e, contains(startsWith('exercises.csv 4행: 운동ID "Bad"')));
      expect(e, contains(startsWith('exercises.csv 5행: 필요기구종류 "스쿼트 랙"')));
      expect(e, contains(startsWith('exercises.csv 6행: "운동"이(가) 비어')));
      final ok = importWith(exercises: '${exercisesCols.join(',')}\nx,X,등,랫풀다운 / 로우\n');
      expect(ok.data!.exercises.single.needs, [GearCategory.pulldown, GearCategory.row]);
    });

    test('머리글에 필요한 열이 없으면 알려 준다', () {
      final e = errorsOf(gyms: '헬스장,위도\n스틸핏 강남점,37.5\n');
      expect(e, contains(startsWith('gyms.csv 1행: 머리글에 "경도"')));
    });
  });

  test('만든 코드의 문자열은 따옴표·\$·\\ 를 이스케이프한다', () {
    final r = importWith();
    final d = r.data!;
    final tricky = (
      catalog: d.catalog,
      gyms: [(name: "O'Neil \$gym \\ 1", lat: 37.5, lng: 127.0, area: 10, rating: 4.0, hours: '24시간', perk: 'x', now: 1, chain: "O'Chain")],
      gymGear: {"O'Neil \$gym \\ 1": ['hs-pl-pulldown']},
      exercises: d.exercises,
    );
    expect(generateGymData(tricky), contains(r"Gym('O\'Neil \$gym \\ 1'"));
    expect(generateGymData(tricky), contains(r"chain: 'O\'Chain'"));
  });
}
