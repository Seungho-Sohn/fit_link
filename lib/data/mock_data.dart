// HTML <script> 안의 하드코딩 데이터를 그대로 옮긴 목업 데이터
import 'package:latlong2/latlong.dart';

String won(num n) {
  final s = n.round().toString();
  final b = StringBuffer();
  for (int i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return '${b.toString()}원';
}

String comma(num n) => won(n).replaceAll('원', '');

String starStr(double r) {
  final f = r.round();
  return '★' * f + '☆' * (5 - f);
}

/* ===== 온보딩 ===== */
class ObOption {
  final String icon, title, sub;
  const ObOption(this.icon, this.title, this.sub);
}

class ObPreview {
  final String title;
  final List<({String icon, String text})> items;
  const ObPreview(this.title, this.items);
}

class ObStep {
  final String eye, h, p;
  final List<ObOption> opts;
  final List<String>? social;
  final List<ObPreview> preview;
  const ObStep({required this.eye, required this.h, required this.p, required this.opts, this.social, required this.preview});
}

const obSteps = [
  ObStep(
    eye: 'Step 1 · 목표',
    h: '오늘은 어떤 목표로\n운동하세요??',
    p: '목표에 맞춰 루틴과 칼로리 기준을 세팅해요.',
    opts: [ObOption('💪', '근육량 증가', '벌크업 · 근력 향상'), ObOption('🔥', '체지방 감량', '다이어트 · 커팅'), ObOption('⚖️', '체형 유지', '컨디션 · 건강관리')],
    social: ['회원의 58%가 근육량 증가를 선택했어요', '최근 감량 목표 회원 +23% 증가 중', '꾸준한 유지가 가장 오래 가는 목표예요'],
    preview: [
      ObPreview('근육량 증가 맞춤 설정', [(icon: '🍽', text: '고단백 식단 · 체중 1kg당 2g'), (icon: '🗓', text: 'PPL 분할 루틴 자동 구성'), (icon: '🔥', text: '벌크업 칼로리 +300kcal')]),
      ObPreview('체지방 감량 맞춤 설정', [(icon: '🥗', text: '고단백·저탄수 커팅 식단'), (icon: '🏃', text: '근력 + 유산소 병행 루틴'), (icon: '🔥', text: '커팅 칼로리 −400kcal')]),
      ObPreview('체형 유지 맞춤 설정', [(icon: '🍚', text: '균형 잡힌 유지 식단'), (icon: '🗓', text: '상·하체 2분할 루틴'), (icon: '⚖️', text: '컨디션·회복 중심 관리')]),
    ],
  ),
  ObStep(
    eye: 'Step 2 · 빈도',
    h: '일주일에\n몇 번 운동하세요?',
    p: '현실적인 목표가 지속률을 높여요.',
    opts: [ObOption('🌱', '주 1–2회', '이제 시작해요'), ObOption('🏃', '주 3–4회', '꾸준히 하는 편'), ObOption('🔥', '주 5회 이상', '거의 매일')],
    preview: [
      ObPreview('주 1–2회 플랜', [(icon: '🌱', text: '전신(무분할) 루틴'), (icon: '⏱', text: '40분 압축 프로그램'), (icon: '🔔', text: '부담 없는 리마인더')]),
      ObPreview('주 3–4회 플랜', [(icon: '🗓', text: '상·하체 또는 3분할'), (icon: '🔁', text: '부위별 회복일 자동 배치'), (icon: '📈', text: '주간 볼륨 밸런싱')]),
      ObPreview('주 5회+ 플랜', [(icon: '🔥', text: '5분할 부위 집중'), (icon: '📈', text: '고빈도 볼륨 관리'), (icon: '🛌', text: '회복도 기반 강도 조절')]),
    ],
  ),
  ObStep(
    eye: 'Step 3 · 관심',
    h: '주로 어떤 운동을\n하고 싶으세요?',
    p: '관심 부위 위주로 추천해 드릴게요.',
    opts: [ObOption('🏋️', '웨이트 트레이닝', '헬스장 머신·프리웨이트'), ObOption('🧘', '홈트·맨몸', '집에서 가볍게'), ObOption('🏃', '유산소·러닝', '체력·심폐')],
    preview: [
      ObPreview('웨이트 트레이닝 맞춤', [(icon: '🏋️', text: '머신·프리웨이트 루틴'), (icon: '📍', text: '기구 보유 헬스장 추천'), (icon: '📷', text: '기구 스캔 매칭')]),
      ObPreview('홈트·맨몸 맞춤', [(icon: '🧘', text: '집에서 하는 맨몸 루틴'), (icon: '🪑', text: '최소 장비 대체 운동'), (icon: '⏱', text: '시간대별 홈트 코스')]),
      ObPreview('유산소·러닝 맞춤', [(icon: '🏃', text: '심폐 지구력 프로그램'), (icon: '⌚', text: '심박 존 트레이닝'), (icon: '🗺', text: '러닝 코스 추천')]),
    ],
  ),
];

/* ===== AI 코치 ===== */
class CoachQuestion {
  final String key, question, answer;
  const CoachQuestion(this.key, this.question, this.answer);
}

const coachQ = [
  CoachQuestion('today', '오늘 뭐 운동할까?', '이번 주 근육 밸런스를 보니 하체가 4세트로 부족해요. 오늘은 하체 집중을 추천해요 — 스쿼트 4×8, 레그프레스 4×12, 루마니안 데드리프트 3×10. 마침 스틸핏 강남이 지금 37명으로 한산하니 바로 가기 좋아요 💪'),
  CoachQuestion('legs', '하체 어떻게 채워?', '주간 권장 대비 절반 수준이에요. 이번 주에 하체 세션을 한 번 더 넣어 12~16세트로 올려보세요. 스쿼트·레그프레스·레그컬 위주면 충분해요.'),
  CoachQuestion('gym', '지금 헬스장 가도 돼?', '가까운 스틸핏 강남이 37명 · 1인당 4.1평으로 여유예요. 한산한 곳을 선호하시니 지금이 딱이에요. 대기 없이 스쿼트랙 바로 쓸 수 있어요.'),
  CoachQuestion('protein', '단백질 얼마나 먹어?', '체중 72.3kg 기준 근성장엔 하루 약 116~145g(1.6~2.0g/kg)을 권장해요. 오늘 칼로리 기록엔 아직 여유가 있으니 저녁에 닭가슴살이나 프로틴으로 채워주세요.'),
  CoachQuestion('pr', '1RM 더 올리려면?', '데드리프트 185kg로 최근 신기록을 세웠어요 🎉. 다음 4주는 90%(약 166kg) 3×3 위주로 신경계 자극을 늘리고, 주간 볼륨을 5%씩 점진적으로 올려보세요.'),
];

class LiveStep {
  final int bpm;
  final String zone, cue;
  const LiveStep(this.bpm, this.zone, this.cue);
}

const liveSteps = [
  LiveStep(118, 'Zone 3 · 유산소', '첫 세트예요. 발은 어깨너비, 코어 단단히 잡고 천천히 앉았다 일어나세요.'),
  LiveStep(132, 'Zone 3 · 유산소', '좋아요! 무릎이 발끝 방향으로 잘 나가고 있어요. 호흡 리듬 유지하세요.'),
  LiveStep(145, 'Zone 4 · 무산소', '심박이 Zone 4로 올라왔어요. 세트 간 90초 휴식으로 회복하며 가세요.'),
  LiveStep(151, 'Zone 4 · 무산소', '후반부예요. 마지막 2회는 천천히 내려가며 자극을 끝까지 유지하세요.'),
  LiveStep(158, 'Zone 5 · 최대', '마지막 세트! 폼 무너지지 않게, 3회만 남기고 힘내세요 💪'),
];

/* ===== 커뮤니티 ===== */
class Post {
  final String av, name, tier, time, tag, txt, img;
  int likes, comments;
  bool liked;
  Post(this.av, this.name, this.tier, this.time, this.tag, this.txt, this.img, this.likes, this.comments, this.liked);
}

class Comment {
  final String av, name, text, time;
  const Comment(this.av, this.name, this.text, this.time);
}

List<Post> seedPosts() => [
      Post('K', '김철봉', 'Gold', '12분 전', '운동 인증', '오늘 스틸핏 강남에서 등 운동 완료 🔥 랫풀다운 60kg 성공! 기구 매칭으로 찾은 곳인데 진짜 딱 맞아요.', '🏋️', 42, 8, false),
      Post('S', '수진트레이닝', 'PT', '40분 전', '꿀팁', '초보자분들 데드리프트 허리 안 아프게 하는 법 3가지 정리해봤어요. 궁금하면 댓글 남겨주세요!', '', 118, 23, true),
      Post('J', '정다이어터', 'Silver', '1시간 전', '식단 인증', '점심 제육덮밥 642kcal 기록 완료. 칼로리 자동 계산 너무 편하다… 오늘 목표 안에서 클리어 ✅', '🍚', 67, 11, false),
      Post('H', '헬린이탈출', 'Bronze', '2시간 전', '질문', '3대 500 목표로 하는데 주 4일 분할 어떻게 짜는 게 좋을까요? 선배님들 조언 부탁드려요 🙏', '', 15, 19, false),
    ];

Map<Post, List<Comment>> seedComments(List<Post> posts) => {
      posts[0]: [
        Comment('J', '정다이어터', '폼 미쳤네요 👏 저도 스틸핏 가봐야겠어요', '5분 전'),
        Comment('H', '헬린이탈출', '랫풀다운 60kg 대단하십니다!', '2분 전')
      ],
      posts[1]: [
        Comment('K', '김철봉', '오 이거 진짜 도움됐어요 감사합니다 🙏', '30분 전')
      ],
      posts[2]: [],
      posts[3]: [
        Comment('S', '수진트레이닝', '주 4일이면 상·하체 2분할 추천해요! 회복 잘 됩니다', '20분 전')
      ],
    };

class Group {
  final String em, name, desc;
  int members;
  bool joined;
  Group(this.em, this.name, this.desc, this.members, this.joined);
}

List<Group> seedGroups() => [
      Group('🌅', '강남 아침 헬스 모임', '오전 6–8시 함께 운동 · 인증 필수', 128, false),
      Group('🏋️', '3대 500 클럽', '스쿼트·벤치·데드 총합 500kg 목표', 342, true),
      Group('🥗', '다이어트 식단 공유방', '매일 식단 인증 & 레시피 공유', 891, false),
      Group('🏃', '러닝 크루 강남', '주말 한강 러닝 · 페이스 그룹별 모집', 205, false),
      Group('💪', '헬린이 첫걸음', '초보자 환영 · 운동 질문 자유롭게', 1540, false),
    ];

class Challenge {
  final String em, title, desc, badge;
  final bool live;
  int prog;
  String meta;
  bool joined;
  Challenge(this.em, this.title, this.desc, this.badge, this.live, this.prog, this.meta, this.joined);
}

List<Challenge> seedChallenges() => [
      Challenge('🦵', '30일 스쿼트 챌린지', '매일 스쿼트 인증 · 3,204명 참여중', 'D-18', true, 40, '12 / 30일 완료', true),
      Challenge('🌅', '7일 아침 운동 인증', '오전 9시 전 운동 인증 · 892명 참여중', 'HOT', true, 57, '4 / 7일 완료', true),
      Challenge('📉', '10kg 감량 프로젝트', '12주 그룹 챌린지 · 상금 100만원', '모집중', false, 0, '다음 기수 8/15 시작', false),
      Challenge('🥩', '단백질 150g 30일', '매일 단백질 목표 달성 · 1,540명', 'D-25', true, 17, '5 / 30일 완료', false),
    ];

const rankList = [
  (rank: '🥇', name: '철봉의신', meta: '운동 7일 · 1,240pt', score: '1240', top: true),
  (rank: '🥈', name: '수진트레이닝', meta: '운동 7일 · 1,180pt', score: '1180', top: false),
  (rank: '🥉', name: '벤치프레서', meta: '운동 6일 · 1,020pt', score: '1020', top: false),
  (rank: '4', name: '아침운동러', meta: '운동 6일 · 940pt', score: '940', top: false),
  (rank: '5', name: '단백질요정', meta: '운동 5일 · 820pt', score: '820', top: false),
  (rank: '6', name: '헬창라이프', meta: '운동 5일 · 720pt', score: '720', top: false),
];

/* ===== 마켓 ===== */
class Seller {
  final String name, emoji, meta, desc;
  final bool official;
  const Seller(this.name, this.emoji, this.official, this.meta, this.desc);
}

const sellers = <String, Seller>{
  'wildwear': Seller('WILD WEAR', '🏔️', true, '공식 스토어 · 만족도 98% · 4.9★', 'FIT LINK 자체 브랜드 공식 스토어'),
  'hammer': Seller('Hammer Strength Korea', '🏋️', true, '공식 총판 · 만족도 97% · 4.8★', '해머스트렝스 공식 수입·총판'),
  'onlab': Seller('옵티멈뉴트리션 정품관', '🥤', true, '브랜드관 · 만족도 96% · 4.8★', '옵티멈뉴트리션 정품 인증 판매자'),
  'healthlab': Seller('헬스랩 스토어', '💊', false, '파워셀러 · 만족도 95% · 4.7★', '건강기능식품 전문 셀러'),
  'corefit': Seller('코어핏 기어', '🔩', false, '우수셀러 · 만족도 94% · 4.6★', '홈트·소도구 전문 판매자'),
  'ptlink': Seller('FIT LINK 파트너 짐', '🎟️', true, '제휴 헬스장 · 만족도 96% · 4.8★', '제휴 헬스장 이용권·PT 판매'),
};

class Product {
  final String id, seller, cat, name, emoji, ship, desc;
  final String? img, flag;
  final int price, reviews;
  final double rating;
  const Product(this.id, this.seller, this.cat, this.name, this.price, this.emoji, this.rating, this.reviews, this.ship, this.desc, {this.img, this.flag});
}

const imgStraps = 'assets/images/prod_straps.jpg';
const imgShorts = 'assets/images/prod_shorts.jpg';

const products = [
  Product('p1', 'wildwear', '운동복', '시그니처 리프팅 스트랩', 38000, '🎗️', 4.9, 214, '무료배송 · 오늘출발', '손목 보호와 그립력 강화를 위한 자체 제작 리프팅 스트랩. 이중 스티치로 내구성을 높였습니다.', img: imgStraps, flag: 'BEST'),
  Product('p2', 'wildwear', '운동복', '컴프레션 반팔', 52000, '👕', 4.7, 98, '무료배송', '흡한속건 원단의 컴프레션 반팔. 매칭된 헬스장에서 바로 착용하기 좋은 슬림 핏입니다.'),
  Product('p3', 'wildwear', '운동복', '트레이닝 조거팬츠', 74000, '🩳', 4.8, 156, '무료배송', '테이퍼드 핏의 트레이닝 조거팬츠. 스쿼트 동작에도 밑위가 편안합니다.', img: imgShorts),
  Product('p4', 'hammer', '운동장비', '조절식 웨이트 벤치', 1290000, '🪑', 4.8, 42, '설치배송 · 3~5일', '인식하신 브랜드와 동일 라인의 가정용 조절식 벤치. 헬스장 기구와 같은 각도 세팅이 가능합니다.', flag: '인증'),
  Product('p5', 'hammer', '운동장비', '올림픽 바벨 20kg', 340000, '🏋️', 4.9, 73, '무료배송 · 2~3일', 'IWF 규격 올림픽 바벨. 널링 가공으로 그립감이 우수합니다.'),
  Product('p6', 'onlab', '보충제·건기식', '골드 스탠다드 웨이', 68000, '🥤', 4.8, 1204, '무료배송 · 오늘출발', '회원님이 자주 찾는 벌크업 목적에 맞춘 고단백 웨이 프로틴, 2.27kg.', flag: 'BEST'),
  Product('p7', 'onlab', '보충제·건기식', '마이크로나이즈드 크레아틴', 32000, '⚗️', 4.7, 521, '무료배송', '순도 높은 크레아틴 모노하이드레이트 300g. 무맛으로 쉐이크에 타 먹기 좋습니다.'),
  Product('p8', 'healthlab', '보충제·건기식', '알티지 오메가3', 29000, '💊', 4.6, 340, '무료배송', '관절 및 혈행 개선에 도움을 줄 수 있는 건강기능식품. 원료 함량 표준화 제품.'),
  Product('p9', 'healthlab', '헬스케어기기', '스마트 체성분 체중계', 59000, '⚖️', 4.5, 187, '무료배송', '앱 연동 체성분 측정 체중계. 체지방·근육량을 FIT LINK 식단 기록과 함께 관리할 수 있습니다.', flag: '신상'),
  Product('p10', 'corefit', '운동장비', '프리미엄 저항밴드 세트', 24000, '🔗', 4.6, 265, '무료배송 · 오늘출발', '5단계 강도 저항밴드 세트. 홈트와 워밍업에 두루 활용 가능합니다.'),
  Product('p11', 'corefit', '헬스케어기기', '마사지건 프로', 89000, '🔫', 4.7, 412, '무료배송', '운동 후 근육 이완용 마사지건. 6단계 강도와 4종 헤드를 제공합니다.'),
  Product('p12', 'ptlink', 'PT·이용권', '스틸핏 강남 · 1개월 이용권', 99000, '🎟️', 4.8, 88, '모바일 즉시발급', '기구 매칭으로 찾은 스틸핏 강남점 1개월 이용권. 앱에서 바로 발급되는 모바일 이용권입니다.', flag: '제휴'),
  Product('p13', 'ptlink', 'PT·이용권', 'PT 10회 패키지', 650000, '💪', 4.9, 34, '모바일 즉시발급', '제휴 헬스장 전문 트레이너 1:1 PT 10회권. 유효기간 6개월.'),
];

Product productById(String id) => products.firstWhere((p) => p.id == id);

class Review {
  final String author, stars, text;
  const Review(this.author, this.stars, this.text);
}

const reviews = <String, List<Review>>{
  'p1': [
    Review('김O훈', '★★★★★', '손목 아팠는데 이거 쓰고 데드리프트 무게 늘었어요. 재질도 튼튼합니다.'),
    Review('이O연', '★★★★☆', '그립감 좋아요. 다만 처음엔 좀 뻣뻣해서 길들이는 시간이 필요해요.')
  ],
  'p6': [
    Review('박O성', '★★★★★', '벌크업 시즌마다 재구매합니다. 초코맛 물에도 잘 녹아요.'),
    Review('정O우', '★★★★★', '정품관이라 믿고 삽니다. 배송도 빨라요.'),
    Review('최O진', '★★★★☆', '가성비 좋은데 스쿱이 가끔 안 들어있을 때가 있네요.')
  ],
  'p12': [
    Review('한O규', '★★★★★', '앱에서 바로 발급돼서 편했어요. 기구 매칭으로 찾은 곳이라 딱 맞았습니다.'),
    Review('서O민', '★★★★☆', '시설 좋아요. 피크타임엔 좀 붐빕니다.')
  ],
};
const defaultReviews = [
  Review('구매자', '★★★★★', '만족스러운 상품이에요. 추천합니다.'),
  Review('구매자', '★★★★☆', '배송 빠르고 품질 좋습니다.')
];

const marketCats = ['전체', '운동장비', '운동복', '보충제·건기식', '헬스케어기기', 'PT·이용권'];

/// 타임특가: 상품 id · 할인율(%)
const deals = [
  (productId: 'p6', off: 40), (productId: 'p1', off: 30), (productId: 'p11', off: 35), (productId: 'p10', off: 45), (productId: 'p9', off: 25), (productId: 'p5', off: 20),
];

/* ===== B2B ===== */
class B2BItem {
  final String em, cat, brand, name, spec, moq;
  final int price;
  const B2BItem(this.em, this.cat, this.brand, this.name, this.spec, this.price, this.moq);
}

const b2bItems = [
  B2BItem('🏗️', '파워랙·프레임', 'Hammer Strength', '컴바인드 파워 랙', '헤비듀티 · 풀업바·세이프티 포함 · 상업용', 2400000, '1대~'),
  B2BItem('🏋️', '파워랙·프레임', 'Rogue', '스미스 머신', '리니어 베어링 · 카운터밸런스', 1850000, '1대~'),
  B2BItem('🔩', '셀렉토라이즈드', 'Life Fitness', '케이블 크로스오버', '듀얼 90kg 웨이트 스택 · 상업용', 3200000, '1대~'),
  B2BItem('🦵', '셀렉토라이즈드', 'Hammer Strength', '레그 프레스 45°', '플레이트 로디드 · 최대 400kg', 2100000, '1대~'),
  B2BItem('🏃', '유산소', 'Life Fitness', '상업용 트레드밀', 'AC 모터 · 22인치 터치 디스플레이', 5500000, '2대~'),
  B2BItem('🚣', '유산소', 'Concept2', '로잉 머신 (10대 패키지)', '상업용 · PM5 모니터', 4200000, '10대'),
  B2BItem('💪', '프리웨이트', 'Eleiko', '우레탄 덤벨 5~50kg', '2.5kg 단위 · 10조 + 거치대', 3800000, '세트'),
  B2BItem('🏋️', '프리웨이트', 'Rogue', '올림픽 바벨+원판 세트', '20kg 바 5개 + 범퍼플레이트 500kg', 1200000, '세트'),
  B2BItem('🪑', '프리웨이트', 'Hammer Strength', '멀티 벤치 (5대)', '플랫·인클라인·디클라인 겸용', 950000, '5대'),
];
const b2bCats = ['전체', '파워랙·프레임', '셀렉토라이즈드', '프리웨이트', '유산소'];

class UsedItem {
  final String em, cat, name, cond, grade, loc, st;
  final int price, was;
  const UsedItem(this.em, this.cat, this.name, this.cond, this.grade, this.price, this.was, this.loc, this.st);
}

const usedItems = [
  UsedItem('🏗️', '파워랙·프레임', '컴바인드 파워 랙 (Hammer)', '스크래치 소량 · 작동 이상無', 'A급', 1280000, 2400000, '서울 강남 · 2023년식', 'sale'),
  UsedItem('🏋️', '파워랙·프레임', '스미스 머신', '베어링 교체 완료 · 상태 우수', 'A급', 920000, 1850000, '경기 분당 · 직거래', 'hold'),
  UsedItem('🏃', '유산소', '상업용 트레드밀 (Life Fitness)', '구동벨트 신품 교체', 'B급', 2350000, 5500000, '인천 · 배송협의', 'sale'),
  UsedItem('🔩', '셀렉토라이즈드', '케이블 크로스오버', '케이블 신품 · 스택 정상', 'A급', 1650000, 3200000, '대전 · 설치도움', 'sale'),
  UsedItem('💪', '프리웨이트', '우레탄 덤벨 5~40kg 세트', '거치대 포함 · 코팅 양호', 'A급', 1450000, 3200000, '경기 수원', 'sale'),
  UsedItem('🦵', '셀렉토라이즈드', '레그 프레스 45°', '용접부 이상無 · 롤러 교체', 'B급', 980000, 2100000, '부산 · 직거래', 'sale'),
];
const usedCats = ['전체', '파워랙·프레임', '셀렉토라이즈드', '유산소', '프리웨이트'];

/* ===== 뉴스 ===== */
class NewsItem {
  final String category, emoji, title, body;
  const NewsItem(this.category, this.emoji, this.title, this.body);
}

const news = [
  NewsItem('연구', '🧬', '"주 2회 근력운동, 사망 위험 최대 20%↓"', '대규모 코호트 분석에서 유산소와 별개로 근력운동 자체가 사망률을 유의하게 낮췄습니다.'),
  NewsItem('영양', '🥩', '운동 후 단백질, 30분 안에 vs 하루 총량?', '"단백질 타이밍보다 하루 총 섭취량이 더 중요"라는 게 최근 연구들의 정설로 모이고 있어요.'),
  NewsItem('트렌드', '🔥', '2026 헬스 키워드는 "하이브리드 트레이닝"', '근력과 유산소를 한 세션에 섞는 방식이 시간 대비 효율로 주목받고 있습니다.'),
  NewsItem('운동팁', '🦵', '스쿼트 무릎 통증, 발 각도만 바꿔도 준다', '발끝을 약 15~30도 바깥으로 벌리면 무릎 부담이 줄어든다는 코칭 가이드가 확산 중.'),
  NewsItem('연구', '😴', '"수면 6시간 미만이면 근성장 최대 40%↓"', '수면 부족이 근단백 합성과 회복을 방해한다는 결과. 잘 자는 것도 훈련의 일부예요.'),
  NewsItem('영양', '⚗️', '크레아틴, 근육 넘어 인지기능에도 효과 연구', '전통적 운동 보조제인 크레아틴이 집중력·기억 등에 도움될 수 있다는 연구가 이어집니다.'),
  NewsItem('트렌드', '💪', '여성 웨이트 인구 급증… 3대 운동 관심 최고', '국내외 헬스장에서 여성 근력운동 참여가 빠르게 늘며 관련 콘텐츠 수요도 커지고 있어요.'),
  NewsItem('운동팁', '🏋️', '"주동근보다 자세" 초보 3대 운동 체크리스트', '무게를 올리기 전 가동범위와 코어 고정을 먼저 잡으라는 전문가 조언이 정리됐습니다.'),
  NewsItem('연구', '❤️', '가벼운 걷기도 심혈관 위험 낮춘다', '하루 7천 보 안팎부터 사망·심질환 위험이 뚜렷하게 감소한다는 메타분석 결과.'),
  NewsItem('영양', '🥗', '"고단백 다이어트, 근손실 줄이며 감량"', '체중 감량기에 단백질을 넉넉히 먹으면 근육 손실을 줄일 수 있다는 점이 재확인됐어요.'),
];

/* ===== 헬스장 혼잡도 ===== */
class Gym {
  final String name;
  final int now, area;
  final LatLng pos;
  const Gym(this.name, this.now, this.area, this.pos);
  double get spp => area / now; // 1인당 평수
  int get dens {
    final d = (130 / spp).round();
    return d > 100 ? 100 : d;
  }
}

/// 목업 헬스장 (좌표는 강남 일대 실제 지역 기준의 가상 위치)
const gyms = [
  Gym('스틸핏 강남점', 37, 150, LatLng(37.4997, 127.0300)),
  Gym('코어짐24 역삼', 90, 120, LatLng(37.5009, 127.0368)),
  Gym('바디스퀘어 논현', 62, 200, LatLng(37.5085, 127.0236)),
  Gym('아이언짐 삼성', 128, 140, LatLng(37.5088, 127.0631)),
  Gym('머슬팩토리 선릉', 200, 320, LatLng(37.5045, 127.0490)),
];

Gym gymByName(String name) => gyms.firstWhere((g) => g.name == name);

/* ===== PT 트레이너 ===== */
class Trainer {
  final String av, nm, gym, price;
  final List<String> spec;
  final double rate;
  final int rev;
  final bool match;
  const Trainer(this.av, this.nm, this.spec, this.gym, this.rate, this.rev, this.price, {this.match = false});
}

const trainers = [
  Trainer('🧑‍🦱', '박강현', ['웨이트', '근비대'], '스틸핏 강남', 4.9, 212, '55,000', match: true),
  Trainer('🧑‍🦰', '이수민', ['다이어트', '체형교정'], '파워짐 역삼', 4.8, 168, '50,000'),
  Trainer('👨', '정태우', ['파워리프팅', '3대 중량'], '아이언웍스 선릉', 5.0, 94, '60,000'),
  Trainer('👩', '김하늘', ['재활', '코어'], '헬스킹 논현', 4.7, 131, '45,000'),
];
const bkDays = [
  (label: '오늘', date: '10'), (label: '목', date: '11'), (label: '금', date: '12'),
  (label: '토', date: '13'), (label: '일', date: '14'), (label: '월', date: '15'),
];
const bkTimes = ['07:00', '09:00', '11:00', '14:00', '18:00', '20:00'];

/* ===== 배달 ===== */
class DShop {
  final String id, name, em, tags, menu;
  final double rating, dist;
  final int time, tip, cheap, price, was;
  final bool fast;
  const DShop(this.id, this.name, this.em, this.tags, this.rating, this.dist, this.time, this.tip, this.cheap, this.menu, this.price, this.was, this.fast);
}

const dshops = [
  DShop('s1', '그린테이블 샐러드', '🥗', '샐러드·포케', 4.9, 1.2, 15, 0, 12, '시그니처 닭가슴살 샐러드', 8900, 10900, true),
  DShop('s2', '프로틴키친', '🍱', '닭가슴살·도시락', 4.8, 0.8, 12, 0, 15, '저염 닭가슴살 도시락', 7500, 8900, true),
  DShop('s3', '포케볼 클린', '🥙', '포케·저당식', 4.7, 1.5, 20, 900, 10, '연어 포케볼', 11000, 12500, false),
  DShop('s4', '클린박스 도시락', '🍚', '도시락·저염', 4.6, 0.5, 10, 0, 14, '닭가슴살 현미 도시락', 6900, 7900, true),
  DShop('s5', '브로콜리마켓', '🥦', '샐러드·저당', 4.8, 2.1, 22, 1200, 8, '그릴 치킨 콥샐러드', 9500, 10500, false),
  DShop('s6', '닭신 닭가슴살', '🍗', '닭가슴살·구이', 4.5, 1.8, 18, 500, 18, '수비드 닭가슴살 도시락', 7200, 8500, false),
];

class DMenu {
  final String id, cat, em, name, desc;
  final int price;
  final bool best;
  const DMenu(this.id, this.cat, this.em, this.name, this.desc, this.price, {this.best = false});
}

const dmenu = [
  DMenu('d1', '베스트', '🍱', '저염 닭가슴살 도시락', '현미밥·닭가슴살·채소 · 단백질 42g', 7500, best: true),
  DMenu('d2', '베스트', '🥗', '그릴드 치킨 샐러드', '닭가슴살·로메인·발사믹 · 단백질 38g', 8900, best: true),
  DMenu('d3', '도시락', '🍚', '소불고기 현미 도시락', '저지방 소불고기·현미밥 · 단백질 35g', 8500),
  DMenu('d4', '도시락', '🐟', '연어 스테이크 도시락', '구운 연어·퀴노아 · 단백질 40g', 10500),
  DMenu('d5', '샐러드', '🥙', '연어 포케 볼', '연어·아보카도·현미 · 단백질 30g', 9900),
  DMenu('d6', '음료', '🥤', '프로틴 쉐이크 (초코)', '단백질 25g · 무설탕', 3500),
];

DMenu menuById(String id) => dmenu.firstWhere((m) => m.id == id);

/* ===== 포인트 ===== */
class Tier {
  final String en, name;
  final double rate;
  final int min;
  const Tier(this.en, this.name, this.rate, this.min);
  String get rateStr => rate == rate.roundToDouble() ? rate.toInt().toString() : rate.toString();
}

const tiers = [Tier('Bronze', '브론즈', 1, 0), Tier('Silver', '실버', 1.5, 1000), Tier('Gold', '골드', 2, 3000), Tier('Platinum', '플래티넘', 3, 5000)];

class PtDeal {
  final String em, name;
  final int was, pts;
  int left;
  PtDeal(this.em, this.name, this.was, this.pts, this.left);
}

/// 주간 미션
class Mission {
  final String name;
  int progress;
  final int goal;
  Mission(this.name, this.progress, this.goal);
  bool get isDone => progress >= goal;
}

List<Mission> seedMissions() => [
      Mission('출석 3일', 3, 3),
      Mission('운동 인증 2회', 1, 2),
      Mission('배달 주문 1회', 0, 1),
      Mission('리뷰 작성 1개', 1, 1),
      Mission('3대 기록 갱신', 0, 1),
    ];

/// 포인트 적립(+)·사용(−) 내역
class PointLog {
  final String reason;
  final int amount; // 적립은 양수, 사용은 음수
  final String when; // 목업 내역의 표시용 날짜 ('8월 9일')
  final DateTime? time; // 앱에서 생긴 내역의 실제 시각

  const PointLog(this.reason, this.amount, this.when) : time = null;
  const PointLog.timed(this.reason, this.amount, DateTime this.time) : when = '';

  bool get isSpend => amount < 0;

  /// '+2,000' / '-3,900'
  String get signed => '${isSpend ? '-' : '+'}${comma(amount.abs())}';

  /// 내역에 표시할 시각: 1분 이내 '방금', 같은 날 '오늘', 그 외 'M월 D일'
  String label(DateTime now) {
    final t = time;
    if (t == null) return when;
    if (now.difference(t).inMinutes < 1) return '방금';
    if (t.year == now.year && t.month == now.month && t.day == now.day) return '오늘';
    return '${t.month}월 ${t.day}일';
  }

  Map<String, Object?> toJson() => {'reason': reason, 'amount': amount, if (time == null) 'when': when, if (time != null) 'time': time!.toIso8601String()};

  factory PointLog.fromJson(Map<String, dynamic> j) {
    final t = j['time'] as String?;
    return t != null ? PointLog.timed(j['reason'] as String, j['amount'] as int, DateTime.parse(t)) : PointLog(j['reason'] as String, j['amount'] as int, j['when'] as String);
  }
}
