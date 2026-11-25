# GYMVIA-3 시스템 설계서 r2 (개조식, 짐비아 2.0.0 기준) — 1 개요 · 2 앱 · 3 서버 · 4 DB · 5 인터페이스 · 6 보안 · 7 운영 · 8 처리 흐름
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DOCS = os.path.join(ROOT, 'docs')
FIG = os.path.join(DOCS, '_그림')
sys.path.insert(0, HERE)
from docx.enum.section import WD_ORIENT, WD_SECTION
from docx.shared import Cm
import report_lib
from report_lib import Report

OUT = os.path.join(DOCS, 'GYMVIA-3_시스템설계서_r2.docx')
R = Report()
R.doc.sections[0].footer.paragraphs[0].runs[0].text = 'GYMVIA-3 시스템 설계서 r2 · '
B = R.bullets


def T(h, rows, *a, **k):
    t = R.table(h, [[v if isinstance(v, list) else str(v) for v in r] for r in rows], *a, **k)
    if len(t.rows) <= 9:
        for row in t.rows[:-1]:
            for c in row.cells:
                for p in c.paragraphs:
                    p.paragraph_format.keep_with_next = True
    return t


def flow(title, ids, steps):
    R.h3(title)
    B(['관련 기능: ' + ids], size=8.5)
    R.numbered(steps, size=9.5)


R.title('짐비아(GYMVIA) 시스템 설계서', '앱 · 서버 · 데이터베이스 · 인터페이스 · 보안 · 운영')
R.meta([
    ['문서 번호 · 판', 'GYMVIA-3 · r2 — 이전 판: FITLINK-3 r1 (docs/_보관/)'],
    ['작성일', '2026-11-25'],
    ['기준 버전', '짐비아 2.0.0 (2026-11-24 배포) — [현재] 구조와 [목표] 구조를 함께 기록'],
    ['시점 표시', '[현재] = 2.0.0에 있음 · [2.0.1] = 개발 완료·배포 전 · [목표] = 4번 로드맵 단계에서 만들 것 (단계 번호 병기) · [보류] = 마켓·배달·포인트 재개 시 (D-010)'],
    ['참조 표기', '"→ 4-2" = 4번 구축 계획서 2장 · "D-004" = 결정 · "Q-01" = 미결정 · "C-2" = 비용 항목 · "F-SIG-6.4" = 기능 ID'],
    ['문서 체계', ['1 서비스·기능 정의서 r2', '2 버전 보고서 v2.0.0', '**3 시스템 설계서 r2 (이 문서)**', '4 구축 계획서 r2', '5 기능 추적표 r2']],
    ['코드와의 관계', '클래스·필드의 세부는 코드가 원천 — 이 문서는 구조·규칙과 파일 경로만 기록'],
])
R.toc()
R.h3('개정 이력')
T(['판', '날짜', '내용'], [
    ['r1', '2026-11-18', ['첫 판 — FIT_LINK_시스템_아키텍처_설계서 1~9장을 장 번호 체계(3-1~3-8)로 재구성',
                         '[현재] 코드 구조·데이터·보안 규칙·주소 목록 보강, 기능 ID·결정·단계 연결',
                         '기능별 매핑(구 10장) → 5번 추적표, 단계 계획(구 11장) → 4번 2장, 미결정(구 12장) → 4번 3장']],
    ['r2', '2026-11-25', ['짐비아 2.0.0 기준 — 5개 탭, 운영자 전용관 #/b2b, 운동·체인 데이터(CSV 4종), 개인정보 처리방침 반영',
                         '마켓·배달·포인트 관련 서버 함수·컬렉션은 [보류] 표시 (설계는 유지)', '길찾기 네이버 지도 앱(2.0.1), 지도 화면 NCP Maps(목표) 반영']],
], [1.6, 2.2, 13.2], size=9)
R.page_break()

# =====================================================================
R.h1('1. 아키텍처 개요')
R.h2('1-1. 목적 · 범위')
B(['2.0.0(앱 중심, 서버는 제보 공유만) → 실제 회원이 쓰는 서비스로 확장하기 위한 전체 구조',
   '대상: 앱(Android·웹, iOS 예정), 서버, 데이터베이스, 외부 서비스, 개발·운영 체계',
   '제외: 비용 금액·일정·결정 과정 → 4번 구축 계획서, 기능별 상태 → 5번 기능 추적표'])
R.h2('1-2. 설계 원칙')
T(['원칙', '내용', '근거'], [
    ['서버리스 우선', '서버 컴퓨터 직접 운영 없이 Firebase(Google Cloud) 관리형 서비스 조합', 'D-004'],
    ['권한·돈은 서버만', '운영자 권한, 보상 지급, 결제 승인·주문 확정은 서버에서만 처리 (앱 조작 방지) — 결제·포인트는 현재 보류', 'D-010'],
    ['비밀키는 서버에만', 'AI·결제 키를 앱에 넣지 않음 → Secret Manager 보관, 서버 함수가 대신 호출', '—'],
    ['휴대폰 안 처리 우선', '사진·건강 정보는 기기 안 AI(ML Kit 등)로 처리 → 비용·개인정보 최소화', 'D-008'],
    ['사람 확인 유지', 'AI 인식 결과는 항상 사용자가 확인·선택 (단정하지 않음)', 'F-SIG-3'],
    ['오프라인 우선', '인터넷 없이 핵심 화면 동작, 연결되면 동기화 ([현재] 제보 업로드 방식 확장)', 'F-SYS-5'],
    ['최소 권한', '회원은 자기 데이터만 쓰기, 운영자·관리자 권한은 서버가 부여', 'D-005'],
    ['개발·운영 분리', 'Firebase 프로젝트 2개(개발용·운영용) — 테스트 데이터가 실제 데이터에 섞이지 않게', '1단계'],
    ['자동화', '테스트·배포를 GitHub Actions로 자동화', 'F-SYS-1, F-SYS-2'],
], [3.2, 11.0, 2.8], first_col_bold=True, size=8.5)
R.h2('1-3. [현재] 2.0.0 구조')
T(['영역', '현재 상태'], [
    ['모바일 앱', ['Flutter 단일 코드 → Android APK(kr.gymvia.app) + 웹(GitHub Pages)', '하단 5개 탭(홈 · 헬스장 찾기 · 커뮤니티 · 칼로리 · 마이), 운영자 전용관은 마이에서 진입',
                  '마켓·배달·포인트 코드 삭제 (태그 archive/store-delivery-points 보관)', '데이터는 대부분 목업, 사용자 데이터는 기기 안 저장(shared_preferences)']],
    ['서버', ['자체 서버 코드 없음', 'Firebase 일부: 익명 로그인 + Firestore(회원 기구 제보 공유) + 보안 규칙']],
    ['데이터', ['헬스장·기구·운동: CSV 4종 → 앱 코드로 생성(빌드에 포함), 헬스장에 체인 열', '글·트레이너 등: 앱 안 목업']],
    ['외부 연동', ['OpenStreetMap 지도, 카카오맵 길찾기 링크(2.0.1부터 네이버 지도 앱), 기기 위치·카메라']],
    ['개발·배포', ['GitHub + GitHub Actions(분석·테스트·웹 배포·서명 APK 릴리스)']],
], [3.0, 14.0], first_col_bold=True, size=9)
R.h2('1-4. [목표] 구성도')
B(['다음 쪽 그림 (가로 페이지) · 화살표 = 데이터·호출 방향 · 외부 서비스는 모두 서버(Cloud Functions)를 거쳐 호출'], size=9.5)
sec = R.doc.add_section(WD_SECTION.NEW_PAGE)
sec.orientation = WD_ORIENT.LANDSCAPE
sec.page_width, sec.page_height = Cm(29.7), Cm(21.0)
sec.left_margin = sec.right_margin = Cm(1.5)
sec.top_margin = sec.bottom_margin = Cm(1.3)
R.doc.add_picture(os.path.join(FIG, 'arch.png'), width=Cm(26.5))
sec2 = R.doc.add_section(WD_SECTION.NEW_PAGE)
sec2.orientation = WD_ORIENT.PORTRAIT
sec2.page_width, sec2.page_height = Cm(21.0), Cm(29.7)
sec2.left_margin = sec2.right_margin = Cm(2.0)
sec2.top_margin, sec2.bottom_margin = Cm(2.0), Cm(1.8)
R.h2('1-5. 구성 요소')
T(['계층', '구성 요소', '역할', '상세'], [
    ['사용자 기기', 'Flutter 앱 (Android · 웹 · iOS 예정)', '화면, 로컬 저장, 휴대폰 안 AI, 기기 기능', '2장'],
    ['인증', 'Firebase Authentication', '익명 [현재] → 카카오·이메일 연결 [1단계], 운영자·관리자 권한', '3장, 6장'],
    ['데이터베이스', 'Cloud Firestore (서울 리전)', 'gear_reports [현재] → 회원·글·헬스장·기구·예약 요청 (주문·포인트는 보류)', '4장'],
    ['서버 코드', 'Cloud Functions (2세대, TypeScript)', 'AI 중계, 사업자 인증, 집계, 예약 작업 (결제·포인트는 보류)', '3장'],
    ['파일 저장', 'Cloud Storage', '커뮤니티·중고 매물 사진, 썸네일', '4장'],
    ['알림', 'Firebase Cloud Messaging (FCM)', '리마인더, 메이트 신청, PT 예약 요청 푸시', '5장'],
    ['보안', 'App Check · 보안 규칙 · Secret Manager', '우리 앱만 접근, 데이터별 권한, 비밀키 보관', '6장'],
    ['외부', 'Claude API · 국세청 · 식약처 · 카카오 로그인 · 네이버 지도 (토스·택배·배달은 보류)', 'AI, 사업자 인증, 영양 정보, 로그인, 지도·길찾기', '5장'],
    ['운영', 'GitHub Actions · Pages · Releases · Cloud Logging · Crashlytics', '자동 테스트·배포, 웹 호스팅, 오류·비용 감시', '7장'],
], [2.4, 5.0, 7.8, 1.8], size=8.5)
R.h2('1-6. 데이터가 흐르는 세 가지 길')
B(['**① 앱 → Firestore 직접:** 단순 읽기·쓰기(글, 댓글, 좋아요, 제보, 찜) — 보안 규칙으로 권한 검사 ([현재] 제보)',
   '**② 앱 → Cloud Functions → (Firestore·외부):** 검증·비밀키가 필요한 일(AI, 사업자 인증, 보상 · 결제는 보류) [목표]',
   '**③ 서버 → 앱:** 푸시 알림(FCM), Firestore 실시간 구독(제보·글 변경 즉시 반영 — [현재] 제보 구독)'])
R.h2('1-7. 기술 선택 근거')
T(['영역', '선택', '대안', '근거'], [
    ['앱', 'Flutter', '네이티브 2벌, PWA', 'D-001'],
    ['지도 · 길찾기', '네이버 지도 — 길찾기 앱 URL Scheme [2.0.1], 지도 화면 NCP Maps [1단계]', 'OpenStreetMap 유지, 카카오맵, Google Maps, Mapbox', 'D-002, D-016, C-8'],
    ['헬스장·기구 데이터', 'CSV + 생성 도구 → Firestore [2단계]', '코드 직접 작성, 처음부터 서버 DB', 'D-003'],
    ['서버·DB', 'Firebase (Auth · Firestore · Functions)', '자체 서버, Supabase', 'D-004'],
    ['AI', '휴대폰 안 AI + Claude Haiku 최소', 'Claude Sonnet 전부', 'D-008, C-1'],
    ['결제 [보류]', '토스페이먼츠 (기준) — 마켓·배달 재개 시', '다른 PG', 'D-010, C-3'],
    ['로그인', '카카오 + 이메일 (권장)', '카카오만, 애플 추가', 'Q-01'],
], [3.0, 5.6, 5.0, 3.4], size=8.5)
R.h2('1-8. 비기능 요구')
T(['구분', '요구', '확인 방법'], [
    ['성능', '첫 화면 3초 이내(중급 Android), 목록 스크롤 끊김 없음, 서버 함수 응답 2초 이내(AI 제외)', 'Firebase Performance, 수동 측정'],
    ['가용성', 'Firebase 관리형 서비스 가용성 따름, 서버 장애 시 기기 저장·캐시로 핵심 화면 유지', '오프라인 테스트'],
    ['보안', '돈·포인트·역할은 서버만 변경, 비밀키 앱 포함 금지, 보안 규칙 자동 테스트', '에뮬레이터 테스트, 코드 검색'],
    ['개인정보', '건강 정보 기기 안 보관 원칙, 삭제 요청 처리([현재] 내 기구 제보 지우기)', '6-2'],
    ['비용', 'B안 월 비용 이내, 예산 알림(Q-10)', '4-1, 예산 알림'],
    ['접근성', 'WCAG 2.2 AA — 화면 낭독 이름, 터치 영역 24×24 이상, 대비 4.5:1, 글자 150%까지 깨짐 없음 [현재]', 'test/a11y_test.dart'],
    ['호환성', 'Android 최신 3개 주요 버전, 최신 Chrome·Safari·Edge 웹', '기기 테스트'],
], [2.2, 10.4, 4.4], size=8.5)

# =====================================================================
R.page_break()
R.h1('2. 앱')
R.h2('2-1. 기술 구성')
T(['항목', '내용'], [
    ['프레임워크', 'Flutter (Dart) — 단일 코드로 Android · 웹 · iOS [현재: Android·웹]'],
    ['상태 관리', '[현재] AppState(ChangeNotifier) 단일 상태 → [목표 1단계] 기능별 상태 분리(회원·헬스장 찾기·커뮤니티 등)'],
    ['화면 이동', '[현재] go_router — 화면 ↔ 웹 주소 동기화, 딥링크, Android 뒤로 가기 (5-5 주소 목록)'],
    ['로컬 저장', '[현재] shared_preferences(JSON 한 덩어리) → [목표] 로컬 DB(캐시·오프라인 대기열) + 보안 저장소(토큰)'],
    ['서버 연동', '[현재] Firebase Auth(익명)·Firestore(제보) → [목표] Functions 호출, Storage, FCM, App Check'],
    ['휴대폰 안 AI', '[목표 3단계] ML Kit 글자 인식·포즈 감지, 음식 분류 모델(TFLite), Gemini Nano(지원 기기)'],
    ['기기 기능', '[현재] 카메라·앨범(image_picker), 위치(geolocator), 외부 링크(url_launcher — 2.0.1 네이버 지도 앱) → [목표 3단계] Health Connect'],
    ['지도', '[현재] flutter_map + OpenStreetMap (어두운 색 반전) → [목표 1단계] 네이버 지도 NCP Maps (D-016)'],
    ['글꼴', '[현재] 모든 글꼴 앱 내장(실행 중 내려받기 없음), 한글은 Pretendard·Noto Serif KR'],
    ['품질', '[현재] 자동 테스트(위젯·상태·저장·접근성·라우팅·지도·제보 공유), 글자 150% 대응'],
], [3.0, 14.0], first_col_bold=True, size=8.5)
R.h2('2-2. [현재] 코드 구조')
T(['위치', '내용'], [
    ['lib/main.dart', '앱 시작, 글꼴·라이선스 등록, 저장소 연결, Firebase 연결(_connectCloud — 화면 표시 후 비동기), Shell(화면 선택)'],
    ['lib/state/', 'app_state.dart(전체 상태·화면 이동·제보·운영자 등록·내 이용권), routes.dart(화면 ↔ 주소), router.dart(go_router), persistence.dart(저장)'],
    ['lib/screens/', '탭·흐름별 화면 — home_screen + home/(섹션), gear_flow(헬스장 찾기 탭: 6단계·운동으로 찾기·내 이용권), coach, inbody, community, b2b_screen(운영자 전용관), calorie, my, onboarding'],
    ['lib/services/', 'gear_recognizer(인식 인터페이스·데모), gear_cloud(제보 공유 인터페이스·Firestore), location(위치·거리), photo_picker(사진), directions(네이버 지도 길찾기 — 2.0.1)'],
    ['lib/data/', 'equipment.dart(기구·매칭·운동 찾기 규칙), gym_data.dart(헬스장·기구·운동 CSV에서 생성 — 직접 수정 금지), mock_data.dart(원본 목업 데이터·모델)'],
    ['lib/widgets/', 'common.dart(공통 UI·TapArea 등), gym_map.dart(지도)'],
    ['lib/theme.dart', '색(C)·글꼴(F) — 원본 CSS 변수 1:1'],
], [3.2, 13.8], first_col_bold=True, size=8.5)
R.h2('2-3. 앱 내부 계층 [목표]')
B(['**화면 계층:** 5개 탭 + 하위 화면 — 상태를 보여 주고 사용자 입력 전달만 담당',
   '**상태 계층:** 기능별 상태 객체 — 화면에 필요한 값 계산, 로딩·오류 상태 관리',
   '**저장소(Repository) 계층:** 데이터 출처 숨김 — "로컬 캐시 먼저 보여 주고 서버 값으로 갱신"',
   '**서비스 계층:** 서버 함수 호출, 기기 기능(카메라·위치·Health Connect), 휴대폰 안 AI',
   '**교체 가능한 인터페이스:** [현재] GearRecognizer(기구 인식), GearCloud(제보 공유) — 같은 방식으로 AI·결제·로그인도 인터페이스화(테스트 시 가짜 구현)'])
R.h2('2-4. 앱 모듈')
T(['모듈', '포함 화면·기능', '기능 ID', '주요 연동'], [
    ['시작·계정', '온보딩, 저장 복원, 로그인(익명→카카오·이메일), 계정 삭제', 'F-APP, F-SYS-7', 'Auth, kakaoSignIn, deleteAccount'],
    ['홈', '목표 카드, 헬스장 추천, 메이트, 챌린지, 소식, 루틴, 운동 기록, 계산기, PT, 근육 밸런스, 프로그램, 워치', 'F-HOME', 'Firestore, Health Connect, 템플릿'],
    ['헬스장 찾기', '사진 → 인식 → 기구 확인 → 헬스장 매칭 → 지도 → 확정 → 제보, 오늘 할 운동으로 찾기, 내 이용권', 'F-SIG', 'ML Kit, recognizeGear, Firestore, 네이버 지도'],
    ['AI 코치', '추천 질문, 자유 질문, 주간 리포트, 실시간 코칭', 'F-COACH', 'askCoach, Health Connect, ML Kit 포즈'],
    ['인바디·눈바디', '체성분 리포트, 사진 비교', 'F-INB, F-HOME-14', 'Health Connect, ML Kit(글자·포즈)'],
    ['커뮤니티', '피드·글쓰기·사진·댓글·좋아요, 챌린지, 그룹, 랭킹, 신고', 'F-COMM', 'Firestore, Storage, reportContent'],
    ['마켓 [보류]', '검색·특가·스토어·상세·장바구니·주문·결제·배송', 'F-MKT', 'createOrder, 토스 결제창, confirmPayment'],
    ['운영자(B2B)', '전용관(마이·확정 화면에서 진입), 견적, 중고, 대시보드, 사업자 인증, 보유 기구 등록', 'F-B2B', 'verifyBusiness, gym_gear, submitQuote'],
    ['배달 [보류]', '매장·메뉴·장바구니·결제·주문 추적, FIT 클럽', 'F-DLV', 'createOrder, confirmPayment, FCM'],
    ['칼로리', '음식 사진·검색 → 결과 → 오늘의 식단, 물 섭취', 'F-CAL', 'ML Kit/음식 분류, recognizeFood, 식약처 DB'],
    ['마이', '프로필·배지, 메뉴, 운영자 전용관 진입, 개인정보 처리방침·제보 삭제 (포인트 허브는 보류)', 'F-MY-1, F-MY-2, F-SIG-6.5', 'deleteAccount, gear_reports'],
], [2.4, 7.0, 2.4, 5.2], size=8)
R.h2('2-5. 앱 동작 원칙')
B(['**오프라인:** 읽기는 캐시 우선, 쓰기는 대기열 → 연결되면 전송·재시도 ([현재] 제보는 연결 시 1회 업로드, 성공해야 완료 표시)',
   '**낙관적 표시:** 좋아요·제보는 화면에 바로 반영 → 서버 실패 시 되돌림',
   '**서버 값이 최종:** 권한·제보 집계(재개 시 포인트·주문 상태)는 서버 값만 신뢰, 앱 계산은 미리보기',
   '**권한 요청 시점:** 카메라·위치·건강 데이터·알림 권한은 해당 기능을 처음 쓸 때',
   '**버전 관리:** 서버의 "최소 지원 앱 버전" 확인 → 오래된 앱은 업데이트 안내 [목표]',
   '**접근성 (현재 규칙):** 누를 수 있는 요소는 이름·24×24 이상, 글자 들어간 상자는 고정 높이 금지, 글자 대비 4.5:1'])

# =====================================================================
R.page_break()
R.h1('3. 서버')
R.h2('3-1. Firebase 프로젝트')
T(['항목', '내용'], [
    ['프로젝트', ['fit-link-6922f (운영용) [현재] — 웹·Android 앱 등록', 'fit-link-dev (개발·테스트용) [목표 1단계]']],
    ['요금제', '[현재] Spark(무료) → [목표 1단계] Blaze(종량제) — Functions·Storage에 필요, 소규모는 무료 한도 안 (C-2)'],
    ['리전', '서울(asia-northeast3) — Firestore [현재], Functions·Storage [목표]'],
    ['서버 코드 언어', 'TypeScript (Node.js) — 저장소의 functions/ 폴더 [목표]'],
    ['비밀키', 'Secret Manager — CLAUDE_API_KEY, NTS_SERVICE_KEY, KAKAO_REST_KEY [목표] (TOSS_SECRET_KEY는 결제 재개 시)'],
    ['권한 표시', 'Auth 사용자 정보의 역할(role): member · operator(사업자 인증 완료) · admin [목표]'],
], [3.0, 14.0], first_col_bold=True, size=8.5)
R.h2('3-2. 서버 함수 목록 [목표]')
B(['종류: 호출형(앱이 직접 호출) · 트리거(데이터 변경 시 자동) · 예약(정해진 시간) · 입력·출력 → 5-1'], size=9)
T(['함수', '종류', '하는 일', '단계', '기능 ID'], [
    ['kakaoSignIn', '호출형', '카카오 토큰 확인 → Firebase 계정 발급·익명 계정 연결', '1', 'F-SYS-7, F-APP-3'],
    ['deleteAccount', '호출형', '회원 데이터·사진·제보 삭제', '1', 'F-SYS-7'],
    ['attend · claimMissionBonus · redeemDeal', '호출형', '출석·주간 보너스·포인트 특가 교환', '보류', 'F-MY-3.x'],
    ['askCoach', '호출형', 'AI 코치 자유 질문 — 기록 요약 첨부 → Claude Haiku, 하루 횟수 제한(Q-06)', '3', 'F-COACH-2'],
    ['recognizeGear · recognizeFood', '호출형', '휴대폰 안 인식 실패 시 보조 인식(Claude Haiku)', '3', 'F-SIG-2.1, F-CAL-2'],
    ['verifyBusiness', '호출형', '국세청 진위확인 → 운영자 권한 부여', '2', 'F-B2B-2.1'],
    ['submitQuote', '호출형', 'B2B 견적 요청 접수·담당자 알림', '2', 'F-B2B-3.2'],
    ['createOrder · confirmPayment · cancelOrder', '호출형', '주문 생성(가격은 서버 계산) → 토스 결제 승인 → 확정 / 취소·환불', '보류', 'F-MKT-7.1, F-DLV-5.3'],
    ['createBooking', '호출형', 'PT 예약 요청 저장·트레이너 알림 (결제는 현장, D-017)', '2', 'F-HOME-16.2'],
    ['sendMateRequest · respondMateRequest', '호출형', '메이트 신청·수락, 상대에게 푸시', '2', 'F-HOME-7.1'],
    ['reportContent', '호출형', '글·댓글·매물 신고, 누적 시 자동 숨김', '2', 'F-COMM-1.6'],
    ['onPostCreated', '트리거', '인증 글 집계, 챌린지 진행·랭킹 점수 (포인트 없음, D-015)', '2', 'F-COMM-1.1'],
    ['onLikeChanged · onCommentChanged', '트리거', '좋아요·댓글 수 집계', '2', 'F-COMM-1.3, 1.4'],
    ['onPhotoUploaded', '트리거', '사진 형식·크기 검사, 썸네일 생성', '2', 'F-COMM-1.2'],
    ['onOrderPaid', '트리거', '판매자·매장 알림, 적립', '보류', 'F-DLV-5.2'],
    ['weeklyReset', '예약 (매주 월 00:00)', '지난주 랭킹 확정, 챌린지 주차 정리', '2', 'F-COMM-4'],
    ['dailyRanking', '예약 (매일)', '지역별 랭킹 집계', '2', 'F-COMM-4'],
    ['reminderPush', '예약 (매시)', '회원별 운동 시간에 리마인더 푸시', '2', 'F-HOME-9'],
    ['weeklyReport', '예약 (매주 일)', '주간 리포트(템플릿 + 선택적 Batch AI)', '3', 'F-COACH-3'],
    ['dailyBackup', '예약 (매일)', 'Firestore 전체 내보내기 백업', '1', 'F-SYS'],
], [4.4, 2.2, 6.6, 1.2, 2.6], size=7.5)
R.h2('3-3. 서버 공통 처리')
B(['**입력 검증:** 모든 호출형 함수에서 로그인·App Check·입력 형식 검사',
   '**중복 방지:** 같은 요청 두 번 처리 안 함(멱등 키 — 예: 제보는 회원+헬스장+기구 문서 하나)',
   '**트랜잭션:** 권한·집계 변경(재개 시 재고·주문 상태)은 한 번에 성공 또는 실패',
   '**사용량 제한:** AI 질문 회원당 하루 N회(Q-06), 같은 기기 과다 호출 차단',
   '**기록:** 권한 부여·운영자 변경 내역(재개 시 금전 변경 포함) — 감사 추적',
   '**오류 응답:** 사용자용 한국어 메시지 + 내부 오류 코드',
   '**시간:** 서버 시각 기준, 주 단위는 한국 시간 월요일 ([현재] 앱의 weekKey와 같은 규칙)'])

# =====================================================================
R.page_break()
R.h1('4. 데이터베이스')
R.h2('4-1. 저장 위치')
T(['위치', '저장하는 것', '이유'], [
    ['기기 안 (앱)', '[현재] 앱 상태 전체 / [목표] 설정·캐시·오프라인 대기열·체성분·눈바디 사진·물 섭취', '건강 정보 최소 수집, 오프라인 동작'],
    ['Cloud Firestore', '[현재] gear_reports / [목표] 회원·글·헬스장·기구·예약 요청 등 (주문·포인트는 보류)', '여러 기기·회원 간 공유, 서버 검증'],
    ['Cloud Storage', '[목표 2단계] 커뮤니티·중고 매물 사진, 썸네일', '큰 파일 전용'],
    ['앱에 포함(빌드)', '[현재] 헬스장·기구 카탈로그(CSV 생성) → [목표 2단계] Firestore 이전, 앱에는 초기값만', '데이터 수정 시 앱 재배포 불필요'],
], [3.0, 8.4, 5.6], size=8.5)
R.h2('4-2. [현재] 기기 저장 형식')
B(['저장소: shared_preferences, 키 fit_link.app_state 하나에 JSON 한 덩어리 (lib/state/persistence.dart)',
   '저장 시점: 상태가 바뀔 때마다 직렬화 → 바뀐 경우에만 기록',
   '저장 항목: 내 글·댓글·좋아요, 온보딩·목표, 운영자 등록(operatorGear), 내 제보(gearReports), 업로드 완료 표시(uploadedLocal), 내 이용권(myChains)',
   '저장 안 함: 화면 이동 상태, 운동 기록 세트, 챌린지·그룹 참여, 물 섭취',
   '예전(1.0.3) 저장본의 포인트·미션·장바구니·찜 항목은 읽지 않고 버림 — 다음 저장 때 사라짐',
   '호환 규칙: 스키마 번호(_schema) — 호환 안 되는 변경 시 증가, 새 필드는 없어도 복원되게 선택값으로 처리 (이전 버전 저장분 유지)',
   '날짜 판단: AppState.now() 사용 (시계는 교체 가능 — 테스트용)'], size=9)
R.h2('4-3. [현재] 헬스장 · 기구 · 운동 데이터 (CSV)')
T(['파일', '한 줄', '주요 열', '규칙'], [
    ['data/gear_catalog.csv', '기구 모델 하나', '기구ID, 브랜드, 제품라인, 이름(한글·영문), 종류, 구동방식, 타겟부위', '기구ID는 영문 소문자·숫자·하이픈, 변경 금지(제보·등록의 키)'],
    ['data/gyms.csv', '헬스장 하나', '헬스장, 위도·경도, 면적(평), 평점, 운영시간, 대표편의, 현재인원(데모), 체인', '이름 중복 금지, 한국 좌표 범위, 체인 비우면 독립 헬스장'],
    ['data/gym_gear.csv', '"이 헬스장에 이 기구" 한 건', '헬스장, 기구ID', '헬스장마다 1개 이상, 중복 금지'],
    ['data/exercises.csv', '운동 하나', '운동ID, 운동, 부위, 필요기구종류(/로 여러 개 — 하나만 있으면 됨)', '오늘 할 운동으로 찾기(F-SIG-7)에 사용'],
], [3.4, 2.6, 6.4, 4.6], size=8)
B(['변환: dart run tool/data/import_gym_data.dart → 검사(오류는 파일·엑셀 행 번호) → lib/data/gym_data.dart 생성 (D-003)',
   '일치 검사: test/gym_data_test.dart — CSV와 생성 파일이 다르면 테스트 실패',
   '매칭 규칙: 동일 모델 100 > 같은 브랜드·종류 85 > 같은 종류 60 (lib/data/equipment.dart, F-SIG-4.1)',
   '덧붙는 데이터: 운영자 등록(기기)이 해당 헬스장 목록을 대체, 회원 제보가 "없어요" 제외 (D-005, D-006)'], size=9)
R.h2('4-4. Firestore 컬렉션')
B(['쓰기 권한: 본인 = 앱에서 직접, 서버 = Cloud Functions만, 관리자 = 관리 도구 · 공통 필드: createdAt, updatedAt'], size=9)
T(['컬렉션', '주요 필드', '읽기', '쓰기', '단계'], [
    ['gear_reports/{uid__gym__gear}', 'uid, gym, gear, present, at', '모두', '본인(자기 제보만, 삭제 포함)', '현재'],
    ['users/{uid}', 'nickname, goal, frequency, interest, chains[], badges[], role, kakaoLinked', '본인', '본인(일부) · 서버(배지·역할)', '1'],
    ['users/{uid}/points/{id}', 'amount(+/−), reason, refType, refId, balanceAfter', '본인', '서버만', '보류'],
    ['users/{uid}/missions/{week}', 'attend, workoutPost, delivery, review, personalRecord, bonusClaimed', '본인', '서버만', '보류'],
    ['users/{uid}/devices/{token}', 'platform, appVersion, lastSeen', '본인', '본인', '2'],
    ['users/{uid}/favorites/{id}', 'type(gym), targetId', '본인', '본인', '1'],
    ['users/{uid}/workouts/{id}', '날짜, 종목, 세트(무게·횟수), PR 여부', '본인', '본인', '1'],
    ['gyms/{gymId}', 'name, lat, lng, area, rating, hours, perk, chain, partner', '모두', '관리자', '2'],
    ['exercises/{id}', 'name, part, needs[] (기구 종류)', '모두', '관리자', '2'],
    ['gear_catalog/{gearId}', 'brand, line, nameKo, nameEn, category, drive, target', '모두', '관리자', '2'],
    ['gym_gear/{gymId}', 'gearIds[], ownerUid, verified, updatedAt', '모두', '인증된 운영자(본인 헬스장) · 서버', '2'],
    ['businesses/{uid}', 'bizNoMasked, ownerName, gymId, verifiedAt', '본인 · 관리자', '서버만', '2'],
    ['posts/{postId} · /comments/{id}', 'uid, author, tier, tag, text, photoPaths[], likeCount, commentCount, hidden', '모두', '본인 · 서버(수·숨김)', '2'],
    ['likes/{postId__uid}', 'postId, uid', '모두', '본인', '2'],
    ['challenges · groups (/members)', '제목·기간·보상 / 진행도·가입일', '모두', '관리자 · 서버 · 본인(가입)', '2'],
    ['rankings/{region__week}', 'entries[{uid, name, score}]', '모두', '서버만', '2'],
    ['mate_profiles · mate_requests', 'gymId, timeSlot, goal / from, to, status', '공개 설정 · 당사자', '본인 / 서버', '2'],
    ['news/{id}', '제목, 본문, 출처, 게시일', '모두', '관리자', '2'],
    ['quotes · used_listings · as_requests', 'B2B 견적 / 중고 매물 / A/S 접수', '본인 · 관리자 (매물은 모두)', '본인 · 서버', '2'],
    ['meals/{uid__date}', '식사 기록, 칼로리·탄단지 합계', '본인', '본인', '3'],
    ['weekly_reports · ai_usage', '주간 요약 / 하루 AI 사용 횟수', '본인', '서버만', '3'],
    ['trainers · bookings', '트레이너·예약 가능 시간 / 예약 요청(uid, trainerId, slot, status)', '모두 / 당사자', '관리자 / 서버', '2'],
    ['sellers · products · deals · reviews', '판매자, 상품(가격·재고), 타임특가, 리뷰', '모두', '관리자 · 본인(리뷰)', '보류'],
    ['shops · menus', '배달 매장, 메뉴(가격·영양)', '모두', '관리자', '보류'],
    ['orders/{orderId}', 'uid, type(market·delivery·club·pt), items, total, pointsUsed, earn, status, payment{…}', '본인', '서버만', '보류'],
    ['subscriptions/{uid}', 'FIT 클럽 상태, 다음 결제일', '본인', '서버만', '보류'],
    ['content_reports · app_config', '신고 / 최소 앱 버전·공지·기능 끄기', '관리자 / 모두', '서버 / 관리자', '2'],
], [3.8, 6.4, 2.2, 3.6, 1.0], size=7.5)
R.h2('4-5. Cloud Storage 경로 [목표 2단계]')
T(['경로', '내용', '규칙'], [
    ['posts/{uid}/{postId}/{n}.jpg', '커뮤니티 인증 사진', '본인만 올리기, 이미지·10MB 이하, 모두 읽기'],
    ['used/{uid}/{listingId}/{n}.jpg', '중고 매물 사진', '본인만 올리기, 모두 읽기'],
    ['avatars/{uid}.jpg', '프로필 사진', '본인만 올리기, 모두 읽기'],
    ['thumbs/...', '자동 생성 썸네일', '서버만 쓰기'],
], [5.2, 4.0, 7.8], size=8.5)
R.h2('4-6. 데이터 관리 규칙')
B(['**식별자:** 회원 = Firebase uid, 헬스장·기구 = 고정 ID ([현재] 헬스장은 이름 사용 → 2단계 이전 시 고정 ID로 전환)',
   '**금액(결제 재개 시):** 정수(원), 계산은 서버만',
   '**개인정보 최소화:** 사업자번호는 가려서 저장, 체성분·사진은 기기 안 보관 원칙 (Q-07)',
   '**보존·삭제:** 계정 삭제 시 회원 문서·하위 데이터·사진·제보 삭제, 주문 기록은 법정 보존 기간만',
   '**색인:** 정렬·필터별 복합 색인은 firestore.indexes.json으로 관리',
   '**이전(1단계):** 2.0.0 기기 데이터(글·제보·운영자 등록·이용권) → 첫 로그인 시 서버로 1회 업로드',
   '**이전(2단계):** CSV 4종 → Firestore 가져오기 도구 (같은 검사 규칙 재사용)'], size=9)

# =====================================================================
R.page_break()
R.h1('5. 인터페이스')
R.h2('5-1. 앱 ↔ 서버 함수 (호출형) [목표]')
B(['공통: 로그인 필수, App Check 토큰 필수, 오류는 code + 한국어 message 반환'], size=9)
T(['함수', '입력', '출력', '주요 오류'], [
    ['kakaoSignIn', 'kakaoAccessToken', 'firebaseCustomToken, isNewUser', 'invalid-token'],
    ['deleteAccount', '없음 (본인)', 'deletedCounts', '—'],
    ['attend [보류]', '없음', 'pointsAdded, balance, alreadyToday', 'already-exists'],
    ['claimMissionBonus [보류]', 'weekKey', 'pointsAdded, balance', 'failed-precondition(미션 미완료)'],
    ['redeemDeal [보류]', 'dealId', 'balance, remaining', 'insufficient-points, sold-out'],
    ['askCoach', 'question, contextFlags', 'answer, remainingToday', 'resource-exhausted(횟수 초과)'],
    ['recognizeGear', '이미지 경로 또는 이미지, ocrText', 'candidates[{gearId, confidence}]', 'not-found'],
    ['recognizeFood', '이미지 경로 또는 이미지', 'candidates[{foodCode, name, portion}]', 'not-found'],
    ['verifyBusiness', 'bizNo, ownerName, openDate, gymId', 'verified, role', 'not-matched, closed-business'],
    ['submitQuote', '상호·연락처·오픈 유형·규모·품목·요청 사항', 'quoteId', 'invalid-argument'],
    ['createOrder [보류]', 'type, items[{id, qty}], usePoints, options', 'orderId, amount, orderName', 'out-of-stock, price-changed'],
    ['confirmPayment [보류]', 'paymentKey, orderId, amount', 'status, pointsEarned', 'amount-mismatch, payment-failed'],
    ['cancelOrder [보류]', 'orderId, reason', 'status, refundAmount', 'not-cancelable'],
    ['createBooking', 'trainerId, slot', 'bookingId, status(요청됨)', 'slot-taken'],
    ['sendMateRequest · respondMateRequest', 'targetUid / requestId, accept', 'requestId, status', 'blocked, not-found'],
    ['reportContent', 'targetType, targetId, reason', 'reportId', 'duplicate'],
], [3.8, 5.0, 4.4, 3.8], size=7.5)
R.h2('5-2. 앱 ↔ Firestore · Storage (직접 접근)')
T(['구분', '[현재]', '[목표]'], [
    ['읽기', 'gear_reports 전체 실시간 구독 (watch)', '+ 헬스장·기구·운동 카탈로그, 글·댓글, 챌린지·그룹·랭킹, 내 예약 요청'],
    ['쓰기 (본인 것만)', 'gear_reports 작성·수정 (report), 삭제 (deleteMine)', '+ 프로필 일부, 글·댓글·좋아요, 찜, 운동 기록, 메이트 프로필, 기기 토큰, 사진'],
    ['코드 인터페이스', 'GearCloud { uid, watch(), report(gym, gear, present), deleteMine() } — lib/services/gear_cloud.dart', '같은 방식으로 기능별 저장소 인터페이스'],
    ['검사', 'firestore.rules (6-1)', '+ storage.rules'],
], [2.6, 7.0, 7.4], size=8.5)
R.h2('5-3. 서버 ↔ 외부 서비스 [목표]')
T(['외부 서비스', '호출 주체·시점', '인터페이스', '주고받는 데이터', '비용'], [
    ['Anthropic Claude API', 'askCoach, recognize*, weeklyReport', 'Messages API (API 키), Batch API', '질문·요약된 기록·사진 → 답변·후보', 'C-1'],
    ['토스페이먼츠 [보류]', '앱: 결제창 / 서버: confirmPayment·cancelOrder', '결제창 SDK + 승인·취소 API(비밀키)', 'orderId·금액 → 승인 결과', 'C-3, C-4'],
    ['국세청 사업자 진위확인', 'verifyBusiness', '공공데이터포털 API (서비스 키)', '사업자번호·대표자·개업일 → 일치·상태', 'C-12'],
    ['식약처 식품영양성분 DB', 'recognizeFood, 음식 검색', '공공데이터포털 API', '음식명 → 칼로리·탄단지', 'C-12'],
    ['카카오 로그인', 'kakaoSignIn', '사용자 정보 조회 API (토큰 확인)', '토큰 → 카카오 회원 번호', 'C-12'],
    ['FCM', '트리거·예약 함수', 'Firebase Admin SDK', '기기 토큰·제목·내용', 'C-12'],
    ['택배 조회 · 배달 대행 [보류]', '주문 상태 갱신', '업체별 API (제휴 후)', '운송장·배달 상태', 'C-11'],
], [3.2, 3.6, 4.0, 4.6, 1.6], size=7.5)
R.h2('5-4. 앱 ↔ 기기 · 외부 앱')
T(['대상', '용도', '방식'], [
    ['카메라·앨범', '기구·음식·인증 사진', 'image_picker [현재 — 기구], 음식·인증 [목표]'],
    ['위치(GPS)', '헬스장 거리', 'geolocator, 거부·15초 무응답 시 강남역 기준 [현재]'],
    ['ML Kit', '로고·결과지 글자 인식, 자세·포즈 감지', '휴대폰 안 실행, 서버 전송 없음 [목표 3단계]'],
    ['Health Connect', '심박·체중·체지방·근육량 읽기', '사용자 허용 후 읽기 전용 [목표 3단계]'],
    ['네이버 지도 앱', '길찾기', 'nmap://route/walk URL Scheme (키 없음), 앱이 없으면 스토어 [2.0.1] — 2.0.0은 카카오맵 공개 링크'],
    ['지도 화면', '지도 그림', 'OpenStreetMap [현재] → 네이버 지도 NCP Maps [목표 1단계]'],
], [3.2, 5.4, 8.4], size=8.5)
R.h2('5-5. [현재] 웹 주소 (딥링크)')
B(['웹은 해시 주소(#/…) — GitHub Pages에서 바로 열기 가능 · 주소 ↔ 화면 변환은 lib/state/routes.dart, 왕복 일치는 test/routes_test.dart'], size=9)
T(['주소', '화면', '주소', '화면'], [
    ['#/', '홈', '#/b2b', '운영자 전용관'],
    ['#/gear', '헬스장 찾기', '#/b2b/gear', '보유 기구 등록'],
    ['#/coach · #/coach/live', 'AI 코치 · 실시간 코칭', '#/b2b/quote(/done)', '견적 요청 (완료)'],
    ['#/inbody', '인바디 리포트', '#/b2b/used · #/b2b/dashboard', '중고 · 대시보드'],
    ['#/comm', '커뮤니티', '#/cal', '칼로리'],
    ['#/my', '마이', '그 밖의 주소', '홈으로 (예전 #/market · #/delivery · #/my/points 포함)'],
], [4.2, 4.3, 4.6, 3.9], size=8)
R.h2('5-6. 데이터 파일 형식')
B(['CSV 4종: UTF-8(BOM 포함 — 엑셀에서 바로 열림), 첫 줄 한글 머리글(이름 변경 금지, 순서 변경 가능) — 열 정의는 4-3, 상세 안내는 data/README.md',
   '[목표] 같은 CSV를 관리 도구에서 Firestore로 가져오기 — 형식 유지'], size=9)

# =====================================================================
R.page_break()
R.h1('6. 보안 · 개인정보')
R.h2('6-1. [현재] 보안 규칙 (firestore.rules)')
B(['gear_reports만 허용, 그 밖의 모든 문서는 읽기·쓰기 차단',
   '읽기: 누구나',
   '쓰기: 익명 로그인한 앱이 자기 uid 문서만 — 문서 ID는 "uid__헬스장__기구ID", 필드는 uid·gym·gear·present·at만, 문자열 1~60자, at = 서버 시각',
   '삭제: 본인 문서만 ([현재] 마이 → 내 기구 제보 지우기 — 규칙은 콘솔에 게시 완료)',
   '운영자 등록은 서버 경로 없음 — 사업자 인증 전 공유 금지 (D-005)',
   '원본: 저장소의 firestore.rules → 콘솔에 붙여 넣어 게시 (목표: firebase deploy 자동화, 7-3)'], size=9)
R.h2('6-2. 권한 모델 [목표]')
T(['역할', '부여', '할 수 있는 일'], [
    ['익명 회원', '앱 첫 실행 [현재]', '제보, 기기 저장 기능'],
    ['회원 (member)', '카카오·이메일 연결 [1단계]', '글·댓글·좋아요, 메이트, PT 예약 요청'],
    ['운영자 (operator)', 'verifyBusiness 성공 [2단계]', '본인 헬스장 gym_gear 쓰기, 견적·대시보드'],
    ['관리자 (admin)', '수동 지정', '상품·헬스장·공지·신고 관리, 관리 도구'],
], [3.0, 4.6, 9.4], size=8.5)
R.h2('6-3. 보안 대책 [목표]')
B(['**인증:** 모든 서버 기능은 로그인 필수, 관리자 기능은 admin만',
   '**App Check:** Play Integrity(Android) · App Attest(iOS) · reCAPTCHA(웹) — Play 출시 후 적용 (F-SYS-6, C-6)',
   '**보안 규칙:** 기본 전부 차단 → 필요한 것만 허용 ([현재] 방식 유지), 역할·집계 필드는 서버만',
   '**비밀키:** Secret Manager 보관, 앱·저장소에 키 없음 ([현재] 서명 키도 저장소 밖·GitHub Secrets)',
   '**악용 방지:** 호출 횟수 제한, 제보 2명 이상 규칙(D-006), 신고·자동 숨김',
   '**결제 위변조 방지 [보류]:** 금액은 서버 계산, 승인 전 금액 대조, 결과는 서버 승인으로만 확정',
   '**테스트:** 에뮬레이터로 보안 규칙 자동 테스트(허용·차단 사례)'], size=9)
R.h2('6-4. 개인정보')
T(['항목', '[현재]', '[목표]'], [
    ['수집 항목', '익명 uid, 기구 제보(헬스장·기구·있음/없음·시각)', '+ 카카오 회원 번호, 닉네임 (주문·배송 정보는 결제 재개 시)'],
    ['위치', '기기 안에서 거리 계산, 서버 전송 없음', '같음'],
    ['건강 정보', '서버 전송 없음', '기기 안 보관 원칙, 서버 보관은 별도 동의 (Q-07)'],
    ['AI 전송', '없음', '자유 질문에 요약 기록만, 사진은 인식 실패 시에만'],
    ['공개 범위', '제보는 익명 ID로 공개', '글은 닉네임, 메이트 프로필은 본인 공개 설정 시'],
    ['삭제 권리', '[현재] 마이 → 내 기구 제보 지우기', '계정 삭제(deleteAccount)·데이터 내려받기'],
    ['처리방침', '[현재] web/privacy.html + 마이 메뉴 — 문의처 짐비아 운영팀 · gymvia.cs@gmail.com (D-009), 길찾기 네이버 지도 명시(2.0.1)', '처리 위탁(Google·Anthropic·네이버)·국외 이전 명시, 확장 시 갱신'],
    ['만 14세 미만', '—', '결제·커뮤니티 제한 또는 법정대리인 동의'],
], [2.6, 6.4, 8.0], size=8.5)

# =====================================================================
R.page_break()
R.h1('7. 운영 · 배포')
R.h2('7-1. 저장소 구성')
T(['폴더', '내용'], [
    ['lib/ · test/', 'Flutter 앱과 테스트 [현재]'],
    ['data/ · tool/data/', '헬스장·기구 CSV와 검사·생성 도구 [현재] → Firestore 가져오기 [2단계]'],
    ['firestore.rules', '보안 규칙 [현재] (+ storage.rules, firestore.indexes.json [목표])'],
    ['web/', '웹 앱 껍데기, privacy.html [현재]'],
    ['android/ · ios/ · …', '플랫폼 폴더 (flutter create 생성), Android 서명 설정'],
    ['.github/workflows/', 'ci.yml · release.yml [현재] + 서버 배포 [목표]'],
    ['functions/', '서버 함수(TypeScript) [목표 1단계]'],
    ['admin/', '간단한 관리 웹 [목표]'],
    ['docs/ · tool/docs/', '문서 5종과 생성 스크립트 [현재] (이전 판은 docs/_보관/)'],
], [4.4, 12.6], first_col_bold=True, size=8.5)
R.h2('7-2. 환경')
T(['환경', '[현재]', '[목표]'], [
    ['개발', '개발자 PC (flutter run -d chrome 등)', '+ Firebase 에뮬레이터, fit-link-dev 프로젝트'],
    ['검수', '—', 'fit-link-dev + 웹 미리보기'],
    ['운영', 'fit-link-6922f, GitHub Pages, GitHub Releases APK', '+ Play 스토어 (5단계)'],
], [2.4, 7.2, 7.4], size=8.5)
R.h2('7-3. 자동화 (GitHub Actions)')
T(['시점', '[현재]', '[목표]'], [
    ['PR · master 푸시', 'flutter analyze · flutter test · flutter build web', '+ 서버 함수 빌드·테스트, 보안 규칙 테스트(에뮬레이터)'],
    ['master 합치기', '웹 배포 (GitHub Pages, base-href /fit_link/)', '+ 개발용 Firebase에 서버·규칙 배포'],
    ['태그 vX.Y.Z', '테스트 → 서명 APK gymvia-X.Y.Z.apk(버전 코드 X*10000+Y*100+Z) → 서명 확인(키 이름 CN=FIT LINK 그대로) → GitHub Release', '+ 운영용 Firebase 배포 → Play 스토어 업로드'],
], [2.6, 7.6, 6.8], size=8.5)
R.h2('7-4. 릴리스 절차 [현재]')
R.numbered(['기능 브랜치 → PR → CI 통과 → master 합치기 (웹 자동 배포)',
            'vX.Y.Z 태그 푸시 → release.yml이 서명 APK 빌드·검증·게시',
            '2번 버전 보고서 새 판, 5번 추적표 상태 갱신 (문서 체계 규칙)',
            '서명 키·비밀번호는 저장소에 넣지 않음 (android/key.properties는 git 제외, CI는 Secrets)'], size=9)
R.h2('7-5. 데이터 갱신 절차 [현재]')
R.numbered(['data/*.csv를 엑셀로 수정 → "CSV UTF-8"로 저장',
            'dart run tool/data/import_gym_data.dart → 오류 시 파일·행 번호 확인 후 수정',
            'CSV와 lib/data/gym_data.dart를 함께 커밋 → PR (test/gym_data_test.dart가 일치 검사)'], size=9)
R.h2('7-6. 감시 · 장애 대응 [목표]')
B(['**오류:** Crashlytics(앱 충돌), Cloud Logging(서버 오류) → 급증 시 메일 알림',
   '**비용:** Google Cloud·Anthropic 예산 알림 (Q-10), AI 사용량 일별 확인',
   '**백업:** Firestore 매일 내보내기(dailyBackup), 복원 절차 문서화',
   '**긴급 조치:** app_config로 공지·기능 끄기·최소 버전 강제',
   '**관리:** Firebase 콘솔 + 관리 웹 — 상품·헬스장·특가·공지·신고'], size=9)

# =====================================================================
R.page_break()
R.h1('8. 주요 처리 흐름')
B(['[현재] = 2.0.0 동작 그대로 · [목표] = 해당 단계 완료 후 흐름 · [보류] = 재개 시 흐름'], size=9)
flow('8-1. [현재] 회원 기구 제보 공유', 'F-SIG-6.3, F-SIG-6.4 · D-005, D-006', [
    '앱 시작 → 화면 표시 후 Firebase 익명 로그인 → gear_reports 구독 시작 (오프라인이면 기기 저장만)',
    '확정 화면에서 "있어요/없어요" → 내 기기에 즉시 반영 → gear_reports/{uid__gym__gear} 저장 (포인트 없음)',
    '연결 전에 한 제보는 연결 시 1회 업로드 — 모두 성공해야 완료 표시(uploadedLocal)',
    '매칭: 내 "없어요"는 나에게 즉시 제외, 다른 회원은 "없어요" 2명 이상 + "있어요"보다 많을 때 모두에게 제외, 운영자 등록 헬스장은 운영자 목록 우선',
])
flow('8-2. [목표] 첫 실행 · 로그인 (1단계)', 'F-APP-3, F-SYS-7 · Q-01', [
    '앱 실행 → 익명 계정 자동 생성 → 온보딩(목표·빈도·관심) 저장',
    '"카카오로 계속하기" → 카카오 로그인 → 토큰을 kakaoSignIn에 전달',
    '서버: 토큰 확인 → 익명 계정과 연결 → 기기 데이터 1회 업로드',
    '다른 기기에서 카카오 로그인 시 같은 데이터 사용',
])
flow('8-3. [목표] 시그니처: 기구 사진 → 헬스장 (3단계)', 'F-SIG-1 ~ F-SIG-6 · D-008', [
    '사진 선택 → 휴대폰 안 ML Kit로 로고 글자 판독 → 카탈로그 브랜드 대조',
    '판독 실패 시만 recognizeGear(Claude Haiku)',
    '후보 화면에서 사용자가 기구 확정 (사람 확인 유지)',
    '헬스장 매칭: 운영자 등록 > 기본 데이터 + 회원 제보 규칙(8-1)으로 점수 계산',
    '지도 → 확정 → 네이버 지도 길찾기 / 제보 → gear_reports',
])
flow('8-4. [목표] 운영자 인증 · 보유 기구 등록 (2단계)', 'F-B2B-2, F-B2B-2.1 · D-005, Q-03', [
    '사업자번호·대표자·개업일 입력 → verifyBusiness',
    '서버: 국세청 진위확인 → 일치·계속사업자면 role=operator, 헬스장 연결',
    '보유 기구 체크 → gym_gear 저장 (보안 규칙: 인증된 운영자의 본인 헬스장만)',
    '모든 회원의 매칭에 "운영자 등록" 표시, 이전 회원 제보는 처리 완료로 간주',
])
flow('8-5. [현재] 오늘 할 운동으로 찾기 · 내 이용권', 'F-SIG-7, F-SIG-8 · D-018', [
    '내 이용권: 체인 선택 → AppState.myChains 저장 → gymsForMe(선택 체인 지점, 비면 전체)를 모든 찾기의 대상으로',
    '운동 고르기 → 운동마다 필요한 기구 종류 중 하나라도 있는 헬스장 → routineGyms가 되는 운동 수 순으로 정렬',
    '보유 기구는 gymGearNow(운영자 등록·회원 제보 반영) 기준 → 같은 수면 거리순 → 길찾기',
])
flow('8-6. [보류] 마켓 · 배달 결제 (재개 시)', 'F-MKT-7.1, F-DLV-5.3 · C-3, C-4', [
    '장바구니 → "주문하기" → createOrder(상품 ID·수량·포인트 사용)',
    '서버: 현재 가격·재고·할인·포인트 한도로 금액 계산 → orders(status=CREATED)',
    '앱: 토스페이먼츠 결제창 → paymentKey 수신',
    '앱 → confirmPayment → 서버: 금액 대조 → 토스 승인 API → status=PAID',
    'onOrderPaid: 포인트 차감·적립, 미션, 판매자·매장 알림, 푸시',
    '이후: 준비 → 배송·배달 → 완료 / 취소 시 cancelOrder → 환불·포인트 복구',
])
flow('8-7. [목표] AI 코치 질문 (3단계)', 'F-COACH-1, F-COACH-2 · Q-06', [
    '추천 질문: 앱이 회원 기록으로 템플릿 답변 (서버 호출 없음)',
    '자유 질문: askCoach → 하루 횟수 확인 → 기록 요약 첨부 → Claude Haiku → 답변',
    '지원 기기는 Gemini Nano(휴대폰 안)로 먼저 처리',
])
flow('8-8. [목표] 커뮤니티 인증 글 (2단계)', 'F-COMM-1.1, F-COMM-1.2, F-COMM-1.6', [
    '글쓰기 → 사진을 Storage에 올림 → posts 작성',
    'onPhotoUploaded: 형식·크기 검사, 썸네일',
    'onPostCreated: 인증 태그면 챌린지 진행·랭킹 반영 (포인트 없음)',
    '신고 누적 시 자동 숨김 → 관리자 검토',
])
flow('8-9. [목표] 예약 작업', 'F-COMM-4, F-HOME-9, F-COACH-3', [
    '매주 월 00:00(한국 시간): 지난주 랭킹 확정',
    '매시: 운동 시간이 된 회원에게 리마인더 푸시',
    '매주 일: 주간 리포트',
    '매일: Firestore 백업, 랭킹 집계',
])

R.h1('부록. 용어')
B(['용어집: 1번 서비스·기능 정의서 부록 B (단일 원천 — 이 문서에는 두지 않음)'], size=9.5)

R.save(OUT)
print('saved')
