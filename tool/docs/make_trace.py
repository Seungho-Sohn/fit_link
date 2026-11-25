# GYMVIA-5 기능 추적표 r2 (Excel) — 2.0.0(짐비아) 기준
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DOCS = os.path.join(ROOT, 'docs')
FIG = os.path.join(DOCS, '_그림')
sys.path.insert(0, HERE)
import re
from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation
from openpyxl.formatting.rule import FormulaRule

OUT = os.path.join(DOCS, 'GYMVIA-5_기능추적표_r2.xlsx')
PROTO = os.path.join(ROOT, 'FIT_LINK_prototype.html')
FONT = '맑은 고딕'
WEB = 'https://seungho-sohn.github.io/fit_link/'

# ---------------- 기존 데이터(기능_구현현황 수정본) ----------------
from feature_rows import R as ROWS  # (번호, 기능, 실행 방법, 구현 상태, 세부 구분, 1.0.3 동작, 미구현 내용, 웹 주소)
import scope_v2  # 2.0.0 범위 조정(보류·변경·신규) 덧씌우기
ROWS = scope_v2.rows(ROWS)

AREA = {  # 번호: (코드, 원본 위치 기본값, 코드 위치 기본값)
    '1': ('APP', '온보딩 오버레이 · renderOb()', 'lib/screens/onboarding.dart'),
    '2': ('HOME', 'tab-home', 'lib/screens/home_screen.dart'),
    '3': ('SIG', 'tab-gear · goTo()', 'lib/screens/gear_flow.dart'),
    '4': ('COACH', 'tab-coach', 'lib/screens/coach_screen.dart'),
    '5': ('INB', 'tab-inbody · openInbody()', 'lib/screens/inbody_screen.dart'),
    '6': ('COMM', 'tab-comm · commView()', 'lib/screens/community_screen.dart'),
    '7': ('MKT', 'tab-market · goMarket()', 'lib/screens/market_screen.dart'),
    '8': ('B2B', "tab-market · goMarket('b2b')", 'lib/screens/b2b_screen.dart'),
    '9': ('DLV', 'tab-delivery · goDeliv()', 'lib/screens/delivery_screen.dart'),
    '10': ('CAL', 'tab-cal · goCal()', 'lib/screens/calorie_screen.dart'),
    '11': ('MY', 'tab-my · tab-points', 'lib/screens/my_screen.dart'),
    '12': ('SYS', '— (원본에 없음)', ''),
}

NEW_ = '— (원본에 없음)'
DONE = '현재 유지'
# 번호: (원본 위치, 코드 위치, 목표 동작, 설계 위치, 인터페이스·데이터, 비용, 단계, 결정, 비고)
# None = 기본값 사용
X = {
 '1.1': ('renderOb() · obNext()', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '1.1.1': ('fpick() · obNext()', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '1.1.2': ('fpick()', None, '선택한 운동 빈도를 루틴 추천(F-HOME-11)에 반영', '3-2', 'AppState(온보딩 답변)', '없음', '3단계 AI', '', '원본도 반영 안 함'),
 '1.1.3': ('fpick()', None, '관심 운동을 루틴·피드 추천에 반영', '3-2', 'AppState(온보딩 답변)', '없음', '3단계 AI', '', '원본도 반영 안 함'),
 '1.1.4': ('obNext()', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '1.1.5': ('finishOnboard()', 'lib/screens/onboarding.dart · lib/state/app_state.dart', DONE, '3-2', 'AppState(goal)', '—', '완료', '', ''),
 '1.2': (NEW_, 'lib/state/app_state.dart · lib/state/persistence.dart', '계정 서버 동기화로 기기 변경 시에도 복원, 운동 기록·챌린지·물 섭취 저장 추가', '3-2, 3-4', 'shared_preferences → Firestore users/{uid}', 'C-2', '1단계 기반', '', ''),
 '1.3': (NEW_, 'lib/main.dart · lib/services/gear_cloud.dart', '익명 계정 → 카카오·이메일 계정 연결', '3-3, 3-6', 'Firebase Auth', 'C-2, C-12', '1단계 기반', 'D-004', ''),
 '1.4': ('— (원본은 switchTab()만, 주소 없음)', 'lib/state/routes.dart · lib/state/router.dart', DONE, '3-2, 3-5', '웹 주소(#/…)', '—', '완료', '', ''),
 '2.1': ('tab-home 상단 인사', None, '시간대별 인사, 출석·운동 기록으로 연속 일수 계산', '3-2', 'AppState 출석·운동 기록', '없음', '1단계 기반', '', ''),
 '2.2': ('tab-home 오늘 목표 카드', None, '칼로리 기록(F-CAL-3)과 연결해 섭취·목표 실제 계산', '3-2', 'AppState 식사 기록', '없음', '3단계 AI', '', ''),
 '2.3': ('openGear()', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '2.4': ('openCoach()', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '2.5': ("switchTab('cal'·'comm'·'market')", None, DONE, '3-2', '—', '—', '완료', '', ''),
 '2.6': ('renderGyms() · setPref()', 'lib/screens/home_screen.dart · lib/data/gym_data.dart', '실시간 인원 없이 거리·운영 시간·보유 기구 기준 추천 (범위 결정 필요)', '3-2, 3-4', 'Firestore gyms', '없음', '미정', 'D-007', '4번 3장 Q-08'),
 '2.6.1': ('setPref()', None, DONE, '3-2', '—', '—', '완료', '', '인원 값은 고정 데이터'),
 '2.6.2': ('renderGyms()', 'lib/screens/home_screen.dart · lib/services/location.dart', DONE, '3-2', '—', '—', '완료', '', '인원 값은 고정 데이터'),
 '2.6.3': ('renderGyms()', 'data/gyms.csv', '만들지 않음', '—', '—', '없음', '범위 제외', 'D-007', ''),
 '2.7': ('tab-home 운동 메이트', None, '같은 헬스장·목표의 실제 회원 매칭', '3-3, 3-4', '매칭 함수 · Firestore mates', 'C-2', '2단계 공유', '', ''),
 '2.7.1': ('mateReq()', None, '신청 전달·수락, 푸시 알림', '3-3, 3-5', 'Firestore mate_requests · FCM', 'C-2', '2단계 공유', '', ''),
 '2.8': ('tab-home 리워드 챌린지', None, '참여·진행률·순위 서버 집계', '3-3, 3-4', 'Firestore challenges', 'C-2', '2단계 공유', '', ''),
 '2.8.1': ('tab-home 오늘 운동 인증하기', None, '운동 인증 글(F-COMM-1.1)과 연결해 진행률·포인트 지급', '3-3', 'Firestore challenges · 포인트 함수', 'C-2', '2단계 공유', '', ''),
 '2.9': ('tab-home 스마트 리마인더', None, '설정한 시간에 푸시 알림', '3-3, 3-5', '예약 함수 · FCM', 'C-2, C-12', '2단계 공유', '', ''),
 '2.10': ('renderNews()', 'lib/screens/home/news_section.dart', '직접 작성 기사 또는 제휴 기사 연결', '3-4', 'Firestore news', 'C-10', '2단계 공유', '', '직접 작성 시 비용 없음'),
 '2.11': ('tab-home AI 적응형 루틴', None, '목표·기구 카탈로그 기반 규칙 생성 루틴', '3-2, 3-3', 'gear_catalog · 운동 기록', 'C-1', '3단계 AI', 'D-008', 'B안: 규칙 기반 → AI 비용 없음'),
 '2.12': ('toggleSet() · startRest() · addSet()', 'lib/screens/home/workout_log_section.dart', '하위 기능 참조', '3-2', '—', '—', '—', '', ''),
 '2.12.1': ('toggleSet() · startRest() · skipRest() · endRest()', 'lib/screens/home/workout_log_section.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '2.12.2': ('toggleSet()', 'lib/screens/home/workout_log_section.dart · lib/state/app_state.dart', DONE, '3-2', 'AppState 미션', '—', '완료', '', ''),
 '2.12.3': ('addSet()', 'lib/screens/home/workout_log_section.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '2.12.4': ('—', 'lib/screens/home/workout_log_section.dart', '세트·무게 기록 저장, 운동 종목 선택', '3-2, 3-4', 'AppState → Firestore workouts', 'C-2', '1단계 기반', '', ''),
 '2.13': ('tab-home 이번 주 운동', 'lib/screens/home/progress_section.dart', '저장된 운동 기록(F-HOME-12.4)으로 주간 볼륨·PR·순위 계산', '3-2', '운동 기록', '없음', '1단계 기반', '', ''),
 '2.14': ('tab-home 눈바디', 'lib/screens/home/body_section.dart', '눈바디 사진 + ML Kit 포즈 정렬, 체성분은 Health Connect·직접 입력', '3-2', 'ML Kit · Health Connect', 'C-1, C-9', '3단계 AI', 'D-008', 'B안: ML Kit·Health Connect → 비용 없음'),
 '2.14.1': ('openInbody()', 'lib/screens/home/body_section.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '2.15': ('calc1RM() · renderPlates()', 'lib/screens/home/strength_tools.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '2.16': ('renderTrainers()', 'lib/screens/home/trainer_section.dart', '제휴 트레이너 실제 데이터', '3-4', 'Firestore trainers', 'C-2', '4단계 결제', '', ''),
 '2.16.1': ('openBook() · pickDay() · pickSlot() · renderBkDate() · renderBkSlots()', 'lib/screens/home/trainer_section.dart', '실제 예약 가능 시간 조회', '3-4, 3-5', 'Firestore trainers/{id}/slots', 'C-2', '4단계 결제', '', ''),
 '2.16.2': ('confirmBook() · updateBookBtn() · closeBook()', 'lib/screens/home/trainer_section.dart', '예약 저장·트레이너 알림, 유료 PT 결제', '3-3, 3-5', 'createBooking 함수 · 토스페이먼츠', 'C-2, C-3, C-4', '4단계 결제', '', ''),
 '2.17': ('tab-home 근육 밸런스', 'lib/screens/home/muscle_map.dart', '운동 기록으로 부위별 세트 수 계산', '3-2', '운동 기록', '없음', '1단계 기반', '', ''),
 '2.18': ('applyProg()', 'lib/screens/home/programs_section.dart', '선택 프로그램을 루틴·운동 기록에 반영·저장', '3-2', 'AppState 루틴', '없음', '1단계 기반', '', ''),
 '2.19': ('pickWatch() · syncWatch()', 'lib/screens/home/watch_section.dart', '갤럭시워치는 Health Connect, 애플워치는 HealthKit 연동', '3-2, 3-5', 'Health Connect · HealthKit', 'C-7, C-12', '3단계 AI', 'D-008', ''),
 '3.1': ('goTo(1)', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '3.1.1': ('goTo(1) 사진 영역', 'lib/screens/gear_flow.dart · lib/services/photo_picker.dart', DONE, '3-2', 'image_picker', '—', '완료', '', ''),
 '3.1.2': (NEW_, None, DONE, '3-2', '—', '—', '완료', '', ''),
 '3.2': ('goTo(2) · replayLog()', None, '실제 인식 결과가 나올 때까지 진행 표시', '3-2', 'GearRecognizer', '—', '3단계 AI', '', ''),
 '3.2.1': ('goTo(2) 분석 로그', 'lib/services/gear_recognizer.dart', 'ML Kit 로고 글자 인식 + 실패 시 서버 Claude Haiku', '3-2, 3-3, 3-5', 'recognizeGear 함수 · Claude API · ML Kit', 'C-1, C-2', '3단계 AI', 'D-008', '사람 확인 단계(3.3) 유지'),
 '3.3': ('— (원본은 결과 바로 표시)', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '3.3.1': (NEW_, 'lib/screens/gear_flow.dart · lib/data/equipment.dart', DONE, '3-2', 'gear_catalog', '—', '완료', '', ''),
 '3.3.2': (NEW_, 'lib/screens/gear_flow.dart · lib/data/equipment.dart', DONE, '3-2', 'gear_catalog', '—', '완료', '', ''),
 '3.3.3': ('— (원본은 화면 안 고정값)', 'data/gear_catalog.csv → lib/data/gym_data.dart', '실제 기구 카탈로그를 서버에서 관리', '3-4, 3-7', 'Firestore gear_catalog (CSV 가져오기)', 'C-2', '2단계 공유', 'D-003', ''),
 '3.4': ('goTo(4)', 'lib/screens/gear_flow.dart · lib/data/equipment.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '3.4.1': ('goTo(4) 매칭 목록', 'lib/data/equipment.dart (matchGyms · matchLevel)', DONE, '3-2', 'gymGearNow', '—', '완료', '', ''),
 '3.4.2': ('goTo(4) 필터', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '3.4.3': ('goTo(4) 거리 표시', 'lib/services/location.dart', DONE, '3-2', 'geolocator', '—', '완료', '', ''),
 '3.4.4': (NEW_, 'lib/state/app_state.dart (gearSource)', DONE, '3-2', 'GearSource', '—', '완료', 'D-005', ''),
 '3.4.5': ('— (원본은 화면 안 고정값)', 'data/gyms.csv · data/gym_gear.csv', '제휴 헬스장 실제 데이터 + 운영자 등록', '3-4, 3-7', 'Firestore gyms · gym_gear', 'C-2', '2단계 공유', 'D-003', ''),
 '3.5': ('goTo(5)', 'lib/widgets/gym_map.dart', '상용 지도 타일 제공 업체로 교체', '3-2, 3-5', '지도 타일 API', 'C-8', '5단계 출시', 'D-002', '현재 OpenStreetMap 공개 타일'),
 '3.6': ('goTo(6)', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '3.6.1': ('goTo(6) 길찾기', None, DONE, '3-5', '카카오맵 길찾기 링크', 'C-12', '완료', '', ''),
 '3.6.2': ("switchTab('market')", None, '인식한 기구와 관련된 상품 추천', '3-2', 'Firestore products', '없음', '4단계 결제', '', ''),
 '3.6.3': (NEW_, 'lib/screens/gear_flow.dart · lib/state/app_state.dart (reportGear)', DONE, '3-2', 'AppState gearReports', '—', '완료', 'D-006', ''),
 '3.6.4': (NEW_, 'lib/services/gear_cloud.dart · firestore.rules', DONE, '3-4, 3-6', 'Firestore gear_reports', 'C-2', '완료', 'D-005, D-006', 'Firebase 무료 한도 안'),
 '3.6.5': (NEW_, 'lib/screens/my_screen.dart · web/privacy.html (feat/privacy 브랜치)', '내 제보 지우기, 개인정보 처리방침 공개', '3-6', 'gear_reports 삭제 (deleteMine)', '없음', '1단계 기반', '', '1.0.4 포함 예정 — 문의처 확정 필요'),
 '4.1': ('askCoach()', None, '추천 질문은 템플릿 답변', '3-2', '—', 'C-1', '3단계 AI', 'D-008', 'B안: 템플릿 → AI 비용 없음'),
 '4.2': ('coachSend() · coachAppend()', None, '서버 askCoach 함수 → Claude Haiku, 하루 질문 수 제한', '3-3, 3-5', 'askCoach 함수 · Claude API', 'C-1, C-2', '3단계 AI', 'D-008', ''),
 '4.3': ('coachReport()', None, '운동 기록 기반 템플릿 리포트 + Batch Haiku 문장 다듬기', '3-3', '예약 함수(주 1회) · Claude Batch', 'C-1, C-2', '3단계 AI', 'D-008', ''),
 '4.4': ('openLive() · renderLive()', 'lib/screens/coach_screen.dart', '하위 기능 참조', '3-2', '—', '—', '—', '', ''),
 '4.4.1': ('liveAction() · liveEndRest()', 'lib/screens/coach_screen.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '4.4.2': ('renderLive()', 'lib/screens/coach_screen.dart', '워치 심박(Health Connect) + 존별 문구 템플릿, 자세는 ML Kit', '3-2', 'Health Connect · ML Kit', 'C-1, C-7', '3단계 AI', 'D-008', 'B안: 템플릿·ML Kit → AI 비용 없음'),
 '5.1': ('openInbody()', None, '결과지 글자 인식·Health Connect·직접 입력으로 체성분 입력', '3-2, 3-4', 'ML Kit 글자 인식 · Health Connect', 'C-9', '3단계 AI', 'D-008', 'B안: 인바디 API 불필요'),
 '5.2': ('askInbodyCoach()', None, '표준 범위 비교 규칙 기반 해설', '3-2', '—', 'C-1', '3단계 AI', 'D-008', 'B안: 규칙 기반 → AI 비용 없음'),
 '6.1': ('renderFeed()', None, '하위 기능 참조', '3-2', '—', '—', '—', '', ''),
 '6.1.1': ('openCompose() · pickCompTag() · postCompose() · closeCompose()', 'lib/screens/community_screen.dart · lib/state/app_state.dart (addPost)', DONE, '3-2', 'AppState posts', '—', '완료', '', ''),
 '6.1.2': ('openCompose() 사진 버튼', None, '사진 업로드·썸네일 자동 생성', '3-3, 3-4', 'Cloud Storage', 'C-2', '2단계 공유', '', ''),
 '6.1.3': ('toggleLike()', None, DONE, '3-2', 'AppState likes', '—', '완료', '', ''),
 '6.1.4': ('openCmt() · renderCmt() · postCmt() · closeCmt()', None, DONE, '3-2', 'AppState comments', '—', '완료', '', ''),
 '6.1.5': ('renderFeed() 공유 버튼', None, '글 공유 링크(웹 주소)', '3-5', '웹 주소 #/comm/…', '없음', '2단계 공유', '', ''),
 '6.1.6': ('—', None, '글·댓글·좋아요 서버 공유, 신고', '3-3, 3-4, 3-6', 'Firestore posts · comments', 'C-2', '2단계 공유', '', ''),
 '6.2': ('renderChal() · joinChal()', None, '참여·진행률 저장, 인증·보상 서버 처리', '3-3, 3-4', 'Firestore challenges', 'C-2', '2단계 공유', '', ''),
 '6.3': ('renderGroup() · joinGroup()', None, '그룹 참여 저장, 그룹 게시판', '3-3, 3-4', 'Firestore groups', 'C-2', '2단계 공유', '', ''),
 '6.4': ('renderRank()', None, '포인트·운동량 기반 지역 랭킹 집계', '3-3, 3-4', '집계 함수 · Firestore rankings', 'C-2', '2단계 공유', '', ''),
 '7.1': ('renderProducts() · pickCat() · productCard()', None, DONE, '3-2', '—', '—', '완료', '', '상품 데이터는 목업(F-MKT-4)'),
 '7.2': ("goMarket('b2b')", None, DONE, '3-2', '—', '—', '완료', '', ''),
 '7.3': ('renderDeals() · tickDeal()', None, '특가 가격을 장바구니·주문에 적용, 서버가 가격 확인', '3-3', 'createOrder 함수', 'C-2', '4단계 결제', '', '원본도 정가로 담김'),
 '7.4': ('renderSellers() · openStore()', None, '실제 판매자·상품 데이터', '3-4', 'Firestore sellers · products', 'C-2', '4단계 결제', '', ''),
 '7.5': ("openProduct() · openStoreFromPdp() · goMarket('detail')", None, '실제 리뷰 작성·표시', '3-4', 'Firestore reviews', 'C-2', '4단계 결제', '', ''),
 '7.5.1': ('addToCart() · changeQty() · updateBadge()', None, DONE, '3-2', 'AppState cart', '—', '완료', '', ''),
 '7.6': ("renderCart() · removeItem() · cartTotal() · goMarket('cart')", None, DONE, '3-2', 'AppState cart', '—', '완료', '', ''),
 '7.7': ("checkout() · goMarket('done')", None, '하위 기능 참조', '3-2', '—', '—', '—', '', ''),
 '7.7.1': ('checkout()', None, '토스페이먼츠 결제창 + 서버 결제 승인', '3-3, 3-5, 3-6', 'createOrder · confirmPayment 함수 · 토스페이먼츠', 'C-2, C-3, C-4, C-5', '4단계 결제', '', ''),
 '7.7.2': ("goMarket('done') 배송 안내", None, '주문·배송 상태 관리, 택배 조회', '3-3, 3-5', 'Firestore orders · 택배 조회 API', 'C-2, C-11', '4단계 결제', '', ''),
 '8.1': ('renderB2B() · pickB2B()', None, '실제 상업용 기구 데이터', '3-4', 'Firestore b2b_products', 'C-2', '4단계 결제', '', ''),
 '8.1.1': ('renderB2B() 견적담기', None, '견적 목록을 견적 요청서에 자동 포함', '3-2, 3-4', 'Firestore quotes', 'C-2', '4단계 결제', '', ''),
 '8.2': (NEW_, 'lib/screens/market_b2b.dart · lib/state/app_state.dart (registerGymGear)', DONE, '3-2', 'AppState operatorGear', '—', '완료', 'D-005', '기기 저장'),
 '8.2.1': (NEW_, 'lib/state/app_state.dart (myGym)', '국세청 사업자 진위확인 후 운영자 권한 부여, 등록 기구 서버 공유', '3-3, 3-6', 'verifyBusiness 함수 · 국세청 API · Firestore gym_gear', 'C-2, C-12', '2단계 공유', 'D-005', ''),
 '8.3': ("goMarket('b2bform') · fpick() · fmulti()", None, '하위 기능 참조', '3-2', '—', '—', '—', '', ''),
 '8.3.1': ("goMarket('b2bdone')", None, '필수 항목·형식 검사', '3-2', '—', '없음', '2단계 공유', '', '원본도 검사 없음'),
 '8.3.2': ("goMarket('b2bdone')", None, '견적 요청 저장·담당자 알림, 접수번호 발급', '3-3, 3-5', 'submitQuote 함수 · Firestore quotes', 'C-2', '2단계 공유', '', ''),
 '8.4': ("renderUsed() · pickUsed() · goMarket('used')", None, '실제 매물 등록·사진', '3-3, 3-4', 'Firestore used_items · Cloud Storage', 'C-2', '2단계 공유', '', ''),
 '8.4.1': ('renderUsed() 채팅 버튼', None, '판매자 채팅', '3-3, 3-4', 'Firestore chats · FCM', 'C-2', '2단계 공유', '', ''),
 '8.4.2': ("goMarket('b2bform')", None, '매물 등록 양식', '3-2, 3-4', 'Firestore used_items', 'C-2', '2단계 공유', '', ''),
 '8.5': ("goMarket('b2bform')", None, '인테리어·시공, 트레이너 채용 전용 양식 (범위 결정 필요)', '3-2', '—', '없음', '미정', '', '4번 3장 Q-09'),
 '8.6': ("goMarket('dash')", None, '실제 매출·회원 데이터 연동 (헬스장 관리 시스템 제휴)', '3-4, 3-5', '제휴 API', '미집계', '미정', '', '제휴 조건 필요 · 4번 3장 Q-09'),
 '8.6.1': (NEW_, 'lib/screens/market_b2b.dart', DONE, '3-2', 'gearReportCount', '—', '완료', '', ''),
 '8.6.2': ("goMarket('dash') A/S·회원 버튼", None, 'A/S 접수·회원 관리', '3-3, 3-4', 'Firestore as_requests', 'C-2', '미정', '', '4번 3장 Q-09'),
 '9.1': ('renderDShops()', None, '실제 매장·메뉴 데이터', '3-4', 'Firestore stores · menus', 'C-2', '4단계 결제', '', ''),
 '9.1.1': ('setDSort() · renderDShops()', None, DONE, '3-2', '—', '—', '완료', '', ''),
 '9.1.2': ('favToggle() · toggleFavView() · dShopFav()', None, DONE, '3-2', 'AppState favorites', '—', '완료', '', ''),
 '9.2': ('tab-delivery FIT 클럽 배너', None, '정기 구독 결제·회원 상태 관리', '3-3, 3-5', '토스페이먼츠 자동결제 · Firestore subscriptions', 'C-3, C-4, C-5', '4단계 결제', '', ''),
 '9.3': ("goDeliv('store') · renderDMenu()", None, DONE, '3-2', '—', '—', '완료', '', '매장·메뉴는 목업(F-DLV-1)'),
 '9.3.1': ('dAdd() · updateDFoot()', None, DONE, '3-2', 'AppState dCart', '—', '완료', '', ''),
 '9.3.2': ('reorderLast()', None, DONE, '3-2', 'AppState dCart', '—', '완료', '', ''),
 '9.4': ("renderDCart() · dQty() · goDeliv('cart')", None, DONE, '3-2', 'AppState dCart', '—', '완료', '', ''),
 '9.5': ("goDeliv('pay') · renderDPay()", None, '하위 기능 참조', '3-2', '—', '—', '—', '', ''),
 '9.5.1': ('delivMode()', None, '선택값을 주문 정보로 전달', '3-5', 'createOrder 함수', 'C-2', '4단계 결제', '', ''),
 '9.5.2': ('dTotal() · toggleDPts() · placeDOrder() · spendPoints() · earnPoints()', 'lib/screens/delivery_screen.dart · lib/state/app_state.dart (payCalc)', '포인트 차감·적립을 서버에서 처리 (조작 방지)', '3-3, 3-4', '포인트 함수 · Firestore point_logs', 'C-2', '1단계 기반', '', ''),
 '9.5.3': ('placeDOrder()', None, '결제 승인 + 매장·배달 대행 주문 전달', '3-3, 3-5', 'confirmPayment 함수 · 토스페이먼츠 · 배달 대행 API', 'C-2, C-3, C-4, C-5', '4단계 결제', '', ''),
 '9.6': ("goDeliv('done')", None, '실시간 배달 상태 (배달 대행 연동)', '3-5', '배달 대행 API · FCM', '미집계', '4단계 결제', '', '제휴 조건 필요'),
 '10.1': ('goCal(1)', None, '사진 선택 연결 (photo_picker 재사용)', '3-2', 'image_picker', '없음', '3단계 AI', '', ''),
 '10.2': ('goCal(2) · goCal(3)', None, '휴대폰 안 분류 + 식약처 DB, 실패 시 Claude Haiku', '3-2, 3-3, 3-5', 'recognizeFood 함수 · 식약처 DB · Claude API', 'C-1, C-2, C-12', '3단계 AI', 'D-008', '사람 확인 단계 유지'),
 '10.3': ('goCal(4)', None, '식사 기록 저장·하루 합계 계산', '3-2, 3-4', 'AppState → Firestore meals', 'C-2', '3단계 AI', '', ''),
 '10.3.1': ('renderWater() · setWater()', None, '물 섭취 저장', '3-2', 'AppState', '없음', '1단계 기반', '', ''),
 '10.3.2': ("switchTab('market')", None, DONE, '3-2', '—', '—', '완료', '', ''),
 '11.1': ('tab-my 프로필 · myName', None, '배지 획득 조건 계산', '3-2', 'AppState', '없음', '2단계 공유', '', ''),
 '11.2': ('tab-my 메뉴 · myReorder() · myOrders', None, '각 메뉴를 실제 기록(챌린지·찜·인식 이력·식단·알림 설정)과 연결', '3-2', 'AppState · Firestore', '없음', '2단계 공유', '', ''),
 '11.3': ('openPoints() · renderPoints()', None, '포인트 원장을 서버에서 관리', '3-3, 3-4', 'Firestore point_logs', 'C-2', '1단계 기반', '', ''),
 '11.3.1': ('updatePointsUI() · curTierIdx() · lvOf()', None, '서버 포인트 원장 기준 등급', '3-3, 3-4', '포인트 함수 · Firestore point_logs', 'C-2', '1단계 기반', '', ''),
 '11.3.2': ('attendCheck()', 'lib/screens/my_screen.dart · lib/state/app_state.dart (attend)', '출석 확인·적립을 서버에서 처리', '3-3', '포인트 함수', 'C-2', '1단계 기반', '', ''),
 '11.3.3': ('renderMissions() · claimStamp()', 'lib/screens/my_screen.dart · lib/state/app_state.dart (missions)', '미션 진행·보너스 지급을 서버에서 처리', '3-3', '포인트 함수', 'C-2', '1단계 기반', '', ''),
 '11.3.4': ('renderPtDeals() · redeemDeal()', None, '서버 차감 + 실제 상품 발송', '3-3, 3-5', 'redeemPoints 함수', 'C-2', '4단계 결제', '', ''),
 '11.3.5': ('earnPoints() 리뷰 미션', None, '리뷰 작성 화면(F-MKT-5)과 연결', '3-2', 'Firestore reviews', 'C-2', '4단계 결제', '', ''),
 '11.3.6': ("switchTab('comm')", None, DONE, '3-2', '—', '—', '완료', '', ''),
 '11.3.7': ('tab-points 친구 초대', None, '초대 코드·가입 보상', '3-3, 3-4', '보상 함수 · Firestore invites', 'C-2', '2단계 공유', '', ''),
 '11.3.8': ('renderPoints() · fmtP()', None, '서버 원장 기준 내역', '3-4', 'Firestore point_logs', 'C-2', '1단계 기반', '', ''),
 '12.1': (NEW_, 'android/app/build.gradle.kts · .github/workflows/release.yml', 'Play 스토어 출시', '3-7', 'Google Play', 'C-6', '5단계 출시', '', ''),
 '12.2': (NEW_, '.github/workflows/ci.yml', DONE, '3-7', 'GitHub Pages', '—', '완료', '', ''),
 '12.3': (NEW_, 'lib/state/routes.dart (AppPage.parent) · lib/main.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '12.4': (NEW_, 'lib/widgets/common.dart (TapArea) · test/a11y_test.dart', DONE, '3-2', '—', '—', '완료', '', 'WCAG 2.2 AA'),
 '12.5': (NEW_, 'lib/state/app_state.dart · lib/services/gear_cloud.dart', DONE, '3-2', '—', '—', '완료', '', ''),
 '12.6': (NEW_, '—', 'App Check(Play Integrity) 적용', '3-6', 'App Check', 'C-6', '5단계 출시', '', 'Play 배포 앱만 지원'),
 '12.7': (NEW_, '—', '카카오·이메일 로그인, 기기 데이터 이전, 계정 삭제', '3-3, 3-6', 'Firebase Auth · 카카오 로그인', 'C-2, C-12', '1단계 기반', 'D-004', ''),
}
X.update(scope_v2.NEW_X)

# ---------------- 상태 변환 (기존 3단계 + 세부 → 5단계) ----------------
def status(num, old, kind):
    if num == '2.6.3':
        return '범위 제외'
    if old == '구현':
        return '화면 동작' if kind == '화면 동작' else '실동작'
    if old == '부분 구현':
        return '데모' if kind == '데모' else '화면 동작'
    if old == '미구현':
        return '데모' if kind == '데모' else '미구현'
    return ''


STATUSES = ['실동작', '화면 동작', '데모', '미구현', '범위 제외']
SCOL = {'실동작': ('DFF0E3', '1E6B34'), '화면 동작': ('FFF1D6', '8A5A00'), '데모': ('ECECEC', '4A4A4A'),
        '미구현': ('F6E0E0', '9A2B2B'), '범위 제외': ('F4F4F4', '6E6E6E')}
STAGES = ['완료', '1단계 기반', '2단계 공유', '3단계 AI', '4단계 결제', '5단계 출시', '미정', '보류', '범위 제외', '—']

# ---------------- 행 만들기 ----------------
data = []
area_name = ''
for num, name, how, old, kind, does, missing, url in ROWS:
    url = scope_v2.URLS.get(url, url)
    top = num.split('.')[0]
    code, proto_d, code_d = AREA[top]
    level = num.count('.') + 1
    if level == 1:
        SHORT = {'APP': '앱 시작', 'HOME': '홈', 'SIG': '헬스장 찾기', 'COACH': 'AI 코치', 'INB': '인바디', 'COMM': '커뮤니티',
                 'MKT': '마켓 (보류)', 'B2B': '운영자 전용관', 'DLV': '배달 (보류)', 'CAL': '칼로리', 'MY': '마이', 'SYS': '공통·운영'}
        area_name = f'{code} · {SHORT[code]}'
        data.append(dict(id=f'F-{code}', num=num, lv=1, area=area_name, name=name, how=how, proto='', origin='', st='',
                         does='', code='', left='', target='', design='', iface='', cost='', stage='', dec='', test='',
                         url=(WEB + url) if url.startswith('#') else url, note=''))
        scope_v2.apply(data[-1], num)
        continue
    if num not in X:
        raise SystemExit(f'누락: {num}')
    p, c, tgt, des, ifc, cost, stg, dec, note = X[num]
    st = status(num, old, kind)
    rest = num.split('.', 1)[1]
    l2 = rest.split('.')[0]
    test = f'T-{code}-{l2}' if st in ('실동작', '화면 동작', '데모') else '—'
    if kind == '1.0.4 예정':
        note = note or '1.0.4 포함 예정'
    if kind == '목업 데이터':
        note = ('목업 데이터' + (' · ' + note if note else ''))
    data.append(dict(
        id=f'F-{code}-{rest}', num=num, lv=level, area=area_name, name=name, how=how,
        proto=p if p is not None else proto_d, origin='신규' if (kind == '신규' or (p or '').startswith('— (원본에 없음')) else '원본',
        st=st, does=does, code=c if c is not None else code_d, left=missing, target=tgt, design=des, iface=ifc,
        cost=cost, stage=stg, dec=dec, test=test, url=(WEB + url) if url.startswith('#') else url, note=note))
    d = scope_v2.apply(data[-1], num)
    d['test'] = f'T-{code}-{l2}' if d['st'] in ('실동작', '화면 동작', '데모') else '—'

for d in data:  # 덧씌운 주소(#/…)에 웹 주소 붙이기
    if d['url'].startswith('#'):
        d['url'] = WEB + d['url']

ids = [d['id'] for d in data]
assert len(ids) == len(set(ids)), 'ID 중복'
assert all(d['stage'] in STAGES for d in data if d['lv'] > 1), [d['num'] for d in data if d['lv'] > 1 and d['stage'] not in STAGES]

# ---------------- 서식 ----------------
thin = Side(style='thin', color='C9C1AE')
BORDER = Border(left=thin, right=thin, top=thin, bottom=thin)
HFILL = PatternFill('solid', fgColor='3A3226')
GFILL = {'기준선': '5B6F8C', '현재': '4E7A57', '목표': '6E5B8C', '공통': '7A6A4A', '연결': '8A6A1F'}
L1 = PatternFill('solid', fgColor='EFE6D2')
L2 = PatternFill('solid', fgColor='FAF7F0')


def f(size=9.5, bold=False, color='222222', **kw):
    return Font(name=FONT, size=size, bold=bold, color=color, **kw)


def head_row(ws, r, heads, widths, fill=HFILL, height=32):
    for c, (h, w) in enumerate(zip(heads, widths), 1):
        ws.column_dimensions[get_column_letter(c)].width = w
        cell = ws.cell(r, c, h)
        cell.font = f(10, True, 'FFFFFF')
        cell.fill = fill
        cell.alignment = Alignment(horizontal='center', vertical='center', wrap_text=True)
        cell.border = BORDER
    ws.row_dimensions[r].height = height


wb = Workbook()

# ================= 시트 1: 기능 목록 =================
ws = wb.active
ws.title = '기능 목록'
COLS = [  # (머리글, 키, 너비, 묶음)
    ('기능 ID', 'id', 13, '연결'), ('번호', 'num', 7, '연결'), ('수준', 'lv', 5, '연결'), ('영역', 'area', 16, '연결'),
    ('기능명 (실행 순서)', 'name', 34, '연결'), ('실행 방법 (누르는 곳)', 'how', 26, '연결'),
    ('원본 위치\n(HTML 화면·함수)', 'proto', 28, '기준선'), ('원본 / 신규', 'origin', 8, '기준선'),
    ('상태', 'st', 10, '현재'), ('2.0.0 동작', 'does', 36, '현재'), ('코드 위치', 'code', 30, '현재'), ('남은 일 · 필요한 것', 'left', 34, '현재'),
    ('목표 동작', 'target', 34, '목표'), ('설계 위치\n(3번 장)', 'design', 10, '목표'), ('인터페이스 · 데이터', 'iface', 28, '목표'),
    ('비용 항목\n(4번 1장)', 'cost', 11, '목표'), ('단계\n(4번 2장)', 'stage', 11, '목표'), ('관련 결정\n(4번 3장)', 'dec', 10, '공통'),
    ('테스트\n(2번 2부)', 'test', 11, '공통'), ('웹 바로가기', 'url', 30, '공통'), ('비고', 'note', 26, '공통'), ('점검 (자동)', 'chk', 18, '공통'),
]
NC = len(COLS)
KEYCOL = {k: get_column_letter(i + 1) for i, (_, k, _, _) in enumerate(COLS)}
ws['A1'] = 'GYMVIA-5 기능 추적표 r2 — 짐비아 2.0.0 기준 · 기능 ID 하나로 원본 · 현재 · 목표 · 설계 · 비용 · 단계 · 결정 · 테스트 연결 (2026-11-25)'
ws['A1'].font = f(13, True)
ws['A2'] = '수준 1 = 영역, 2 = 화면·단계, 3 = 세부 동작 · 왼쪽 [1][2][3] 버튼으로 접고 펼치기 · 상태·단계는 목록에서 선택 → 요약·점검 시트 자동 재계산 · 각 열의 뜻은 "범례" 시트'
ws['A2'].font = f(9, color='666666')
# 묶음 머리글 (3행) + 열 머리글 (4행)
GROUPS = {'연결': '식별', '기준선': '[기준선] 원본 설계', '현재': '[현재] 2.0.0', '목표': '[목표] 앞으로', '공통': '연결 · 관리'}
start = 1
for i in range(1, NC + 1):
    grp = COLS[i - 1][3]
    nxt = COLS[i][3] if i < NC else None
    if nxt != grp:
        ws.merge_cells(start_row=3, start_column=start, end_row=3, end_column=i)
        cell = ws.cell(3, start, GROUPS[grp])
        cell.font = f(10, True, 'FFFFFF')
        cell.fill = PatternFill('solid', fgColor=GFILL[grp])
        cell.alignment = Alignment(horizontal='center', vertical='center')
        for c in range(start, i + 1):
            ws.cell(3, c).border = BORDER
            ws.cell(3, c).fill = PatternFill('solid', fgColor=GFILL[grp])
        start = i + 1
head_row(ws, 4, [h for h, *_ in COLS], [w for _, _, w, _ in COLS])
HR = 4
FIRST = HR + 1
LAST = FIRST + len(data) - 1
C = KEYCOL
for i, d in enumerate(data):
    r = FIRST + i
    for j, (_, k, _, _) in enumerate(COLS, 1):
        if k == 'chk':
            if d['lv'] == 1:
                v = ''
            else:
                st, cd, tg, ds, sg, cs, dc, idc = (f'${C[x]}{r}' for x in ('st', 'code', 'target', 'design', 'stage', 'cost', 'dec', 'id'))
                v = ('=TRIM(' + f'IF({st}="","상태 ","")'
                     + f'&IF(AND(OR({st}="실동작",{st}="화면 동작",{st}="데모"),{cd}=""),"코드위치 ","")'
                     + f'&IF({tg}="","목표 ","")&IF({ds}="","설계 ","")&IF({sg}="","단계 ","")'
                     + f'&IF(AND({st}<>"실동작",{cs}=""),"비용 ","")'
                     + f'&IF(AND({st}="범위 제외",{dc}=""),"결정 ","")'
                     + f'&IF(AND({st}<>"실동작",{sg}="완료"),"단계불일치 ","")'
                     + f'&IF(COUNTIF(${C["id"]}${FIRST}:${C["id"]}${LAST},{idc})>1,"ID중복 ",""))')
        else:
            v = d[k]
        cell = ws.cell(r, j, v)
        cell.font = f(9.5, bold=(d['lv'] == 1))
        cell.alignment = Alignment(vertical='top', wrap_text=True,
                                   horizontal='center' if k in ('num', 'lv', 'origin', 'st', 'design', 'cost', 'stage', 'dec', 'test') else 'left')
        cell.border = BORDER
        if d['lv'] == 1:
            cell.fill = L1
        elif d['lv'] == 2:
            cell.fill = L2
    ws.cell(r, 2).number_format = '@'
    ws.cell(r, 5).alignment = Alignment(vertical='top', wrap_text=True, indent=d['lv'] - 1)
    if d['lv'] == 1:
        ws.cell(r, 5).font = f(10.5, True)
    if d['url']:
        uc = ws.cell(r, list(KEYCOL).index('url') + 1)
        uc.hyperlink = d['url']
        uc.font = f(9, color='1F4E8C', underline='single', bold=(d['lv'] == 1))
    ws.cell(r, list(KEYCOL).index('chk') + 1).font = f(9, True, '9A2B2B')
    ws.row_dimensions[r].outline_level = d['lv'] - 1
ws.sheet_properties.outlinePr.summaryBelow = False
ws.freeze_panes = f'{C["proto"]}{FIRST}'
ws.auto_filter.ref = f'A{HR}:{get_column_letter(NC)}{LAST}'
srng = f'{C["st"]}{FIRST}:{C["st"]}{LAST}'
for label, (bg, fg) in SCOL.items():
    ws.conditional_formatting.add(srng, FormulaRule(formula=[f'${C["st"]}{FIRST}="{label}"'],
                                  fill=PatternFill('solid', fgColor=bg), font=Font(name=FONT, bold=True, color=fg)))
dv = DataValidation(type='list', formula1='"' + ','.join(STATUSES) + '"', allow_blank=True)
ws.add_data_validation(dv)
dv.add(srng)
dv2 = DataValidation(type='list', formula1='"' + ','.join(STAGES) + '"', allow_blank=True)
ws.add_data_validation(dv2)
dv2.add(f'{C["stage"]}{FIRST}:{C["stage"]}{LAST}')
dv3 = DataValidation(type='list', formula1='"원본,신규"', allow_blank=True)
ws.add_data_validation(dv3)
dv3.add(f'{C["origin"]}{FIRST}:{C["origin"]}{LAST}')

SRC = "'기능 목록'!"
def col(k):
    return f"{SRC}${C[k]}${FIRST}:${C[k]}${LAST}"

# ================= 시트 2: 요약 =================
sm = wb.create_sheet('요약')
sm['A1'] = '요약 — 영역별 · 상태별 · 단계별 집계 (기능 목록의 수준 2·3 기준, 자동 계산)'
sm['A1'].font = f(13, True)
sm['A2'] = '→ 2번 버전 보고서 1부 "영역별 구현 현황"의 출처'
sm['A2'].font = f(9, color='666666')
areas = [d['area'] for d in data if d['lv'] == 1]
heads = ['영역'] + STATUSES + ['합계', '실동작 비율 (범위 안)', '원본 기능', '신규 기능']
head_row(sm, 4, heads, [26, 10, 10, 10, 10, 10, 9, 11, 10, 10])
r0 = 5
for i, a in enumerate(areas):
    r = r0 + i
    sm.cell(r, 1, a)
    for j, s in enumerate(STATUSES):
        sm.cell(r, 2 + j, f'=COUNTIFS({col("area")},$A{r},{col("st")},"{s}")')
    sm.cell(r, 7, f'=SUM(B{r}:F{r})')
    sm.cell(r, 8, f'=IF(G{r}-F{r}=0,0,B{r}/(G{r}-F{r}))')
    sm.cell(r, 9, f'=COUNTIFS({col("area")},$A{r},{col("origin")},"원본")')
    sm.cell(r, 10, f'=COUNTIFS({col("area")},$A{r},{col("origin")},"신규")')
tot = r0 + len(areas)
sm.cell(tot, 1, '전체')
for c in range(2, 11):
    L = get_column_letter(c)
    sm.cell(tot, c, f'=IF(G{tot}-F{tot}=0,0,B{tot}/(G{tot}-F{tot}))' if c == 8 else f'=SUM({L}{r0}:{L}{tot - 1})')
for r in range(r0, tot + 1):
    for c in range(1, 11):
        cell = sm.cell(r, c)
        cell.font = f(10, r == tot)
        cell.border = BORDER
        cell.alignment = Alignment(horizontal='left' if c == 1 else 'center', vertical='center')
        if r == tot:
            cell.fill = L1
    sm.cell(r, 8).number_format = '0%'
for j, s in enumerate(STATUSES):
    bg, fg = SCOL[s]
    sm.cell(4, 2 + j).fill = PatternFill('solid', fgColor=bg)
    sm.cell(4, 2 + j).font = f(10, True, fg)

# 단계별 표
s0 = tot + 3
sm.cell(s0 - 1, 1, '단계별 남은 기능 (상태별)').font = f(11, True)
stg_rows = [s for s in STAGES if s != '—']
head_row(sm, s0, ['단계 (4번 2장)'] + STATUSES + ['합계'], [26, 10, 10, 10, 10, 10, 9])
for i, s in enumerate(stg_rows):
    r = s0 + 1 + i
    sm.cell(r, 1, s)
    for j, st in enumerate(STATUSES):
        sm.cell(r, 2 + j, f'=COUNTIFS({col("stage")},$A{r},{col("st")},"{st}")')
    sm.cell(r, 7, f'=SUM(B{r}:F{r})')
    for c in range(1, 8):
        sm.cell(r, c).font = f(10)
        sm.cell(r, c).border = BORDER
        sm.cell(r, c).alignment = Alignment(horizontal='left' if c == 1 else 'center')
for j, s in enumerate(STATUSES):
    bg, fg = SCOL[s]
    sm.cell(s0, 2 + j).fill = PatternFill('solid', fgColor=bg)
    sm.cell(s0, 2 + j).font = f(10, True, fg)
n = s0 + 1 + len(stg_rows) + 1
sm.cell(n, 1, '※ 단계 "—"는 하위 기능에 위임한 묶음 행 · 수준 1(영역) 행은 세지 않음').font = f(9, color='666666')

# 비용 항목별 기능 수
c0 = n + 3
sm.cell(c0 - 1, 1, '비용 항목별 관련 기능 수').font = f(11, True)
head_row(sm, c0, ['비용 항목 (4번 1장)', '관련 기능 수'], [26, 10])
COSTS = [
    ('C-1', 'AI 사용료 (Claude API)'), ('C-2', '서버 (Firebase Blaze)'), ('C-3', 'PG 결제 계약'), ('C-4', '결제 수수료'),
    ('C-5', '사업자등록 · 통신판매업 신고'), ('C-6', 'Google Play 개발자 등록'), ('C-7', 'Apple 개발자 등록 (선택)'),
    ('C-8', '지도 제공 업체'), ('C-9', '인바디 데이터 연동 API'), ('C-10', '기사 콘텐츠 제휴'), ('C-11', '택배 배송 조회 API'),
    ('C-12', '무료로 해결되는 항목'),
]
for i, (k, nm) in enumerate(COSTS):
    r = c0 + 1 + i
    sm.cell(r, 1, f'{k} {nm}')
    # "C-1"이 "C-10"·"C-11"·"C-12"와 섞이지 않도록 쉼표 경계로 찾기
    sm.cell(r, 2, f'=SUMPRODUCT(--ISNUMBER(SEARCH(", {k},",", "&{col("cost")}&",")))')
    for c in (1, 2):
        sm.cell(r, c).font = f(10)
        sm.cell(r, c).border = BORDER
    sm.cell(r, 2).alignment = Alignment(horizontal='center')

# ================= 시트 3: 점검 =================
ck = wb.create_sheet('점검')
ck['A1'] = '점검 — 빈 칸 · 불일치 · 원본 누락 자동 표시'
ck['A1'].font = f(13, True)
head_row(ck, 3, ['점검 항목', '문제 행 수', '설명'], [34, 11, 80])
CHECKS = [
    ('문제가 있는 행 (전체)', f'=COUNTIF({col("chk")},"?*")', '기능 목록 "점검" 열이 비어 있지 않은 행 — 필터로 찾기'),
    ('상태 빈 칸', f'=COUNTIF({col("chk")},"*상태*")', '수준 2·3 행은 상태 필수'),
    ('코드 위치 빈 칸', f'=COUNTIF({col("chk")},"*코드위치*")', '실동작·화면 동작·데모 행은 코드 위치 필수'),
    ('목표 동작 빈 칸', f'=COUNTIF({col("chk")},"*목표*")', '"현재 유지" 또는 "하위 기능 참조"도 값으로 인정'),
    ('설계 위치 빈 칸', f'=COUNTIF({col("chk")},"*설계*")', '3번 시스템 설계서의 장 번호'),
    ('단계 빈 칸', f'=COUNTIF({col("chk")},"*단계 *")', '4번 2장 단계'),
    ('단계 불일치', f'=COUNTIF({col("chk")},"*단계불일치*")', '실동작이 아닌데 단계가 "완료"'),
    ('비용 빈 칸', f'=COUNTIF({col("chk")},"*비용*")', '실동작이 아닌 행은 비용 항목 또는 "없음" 필수'),
    ('범위 제외 결정 누락', f'=COUNTIF({col("chk")},"*결정*")', '범위 제외는 4번 3장 결정 번호 필수'),
    ('기능 ID 중복', f'=COUNTIF({col("chk")},"*ID중복*")', '한 번 부여한 ID는 재사용 금지'),
    ('"미정" 단계 기능', f'=COUNTIF({col("stage")},"미정")', '4번 3장 미결정 목록에 올라가야 함'),
]
for i, (a, fx, b) in enumerate(CHECKS):
    r = 4 + i
    ck.cell(r, 1, a)
    ck.cell(r, 2, fx)
    ck.cell(r, 3, b)
    for c in (1, 2, 3):
        ck.cell(r, c).font = f(10, c == 1)
        ck.cell(r, c).border = BORDER
        ck.cell(r, c).alignment = Alignment(vertical='top', wrap_text=True, horizontal='center' if c == 2 else 'left')
last_chk = 4 + len(CHECKS) - 1
ck.conditional_formatting.add(f'B4:B{last_chk - 1}', FormulaRule(formula=['B4>0'], fill=PatternFill('solid', fgColor='F6E0E0'), font=Font(name=FONT, bold=True, color='9A2B2B')))
ck.conditional_formatting.add(f'B4:B{last_chk - 1}', FormulaRule(formula=['B4=0'], fill=PatternFill('solid', fgColor='DFF0E3'), font=Font(name=FONT, bold=True, color='1E6B34')))

# 원본 함수 대조
if os.path.exists(PROTO):
    html = open(PROTO, encoding='utf-8').read()
    funcs = sorted(set(re.findall(r'function ([A-Za-z0-9_]+)', html)))
else:  # 원본 HTML이 저장소에 없을 때 (Q-13) — 추출해 둔 함수 목록 사용
    from prototype_functions import FUNCS as funcs
HELPER = {  # 화면 기능이 아닌 공통 도구 함수
    'toast': '알림 표시 공통', 'switchTab': '탭 이동 공통', 'goTo': '기구 찾기 단계 이동', 'goCal': '칼로리 단계 이동',
    'goMarket': '마켓 화면 이동', 'goDeliv': '배달 화면 이동', 'commView': '커뮤니티 화면 전환', 'rmStep': '단계 표시 공통',
    'updateRest': '휴식 타이머 표시 공통', 'renderPlates': '1RM 계산기 원판 표시', 'productCard': '상품 카드 공통',
}
p0 = last_chk + 3
ck.cell(p0 - 1, 1, f'원본 HTML 함수 대조 — 원본의 함수 {len(funcs)}개가 기능 목록 "원본 위치"에 나오는지 (누락 = 원본 기능이 추적표에 없을 가능성)').font = f(11, True)
head_row(ck, p0, ['원본 함수', '추적표 언급 수', '구분'], [34, 11, 80])
for i, fn in enumerate(funcs):
    r = p0 + 1 + i
    ck.cell(r, 1, fn + '()')
    ck.cell(r, 2, f'=COUNTIF({col("proto")},"*{fn}(*")')
    ck.cell(r, 3, ('공통 도구 — ' + HELPER[fn]) if fn in HELPER else '화면 기능')
    for c in (1, 2, 3):
        ck.cell(r, c).font = f(9.5)
        ck.cell(r, c).border = BORDER
    ck.cell(r, 2).alignment = Alignment(horizontal='center')
pl = p0 + len(funcs)
ck.conditional_formatting.add(f'B{p0 + 1}:B{pl}', FormulaRule(formula=[f'AND(B{p0 + 1}=0,LEFT(C{p0 + 1},2)="화면")'],
                              fill=PatternFill('solid', fgColor='F6E0E0'), font=Font(name=FONT, bold=True, color='9A2B2B')))
ck.cell(5 + len(CHECKS) - 1 + 1, 1)  # 자리 유지
sumr = last_chk + 1
ck.cell(sumr, 1, '원본 화면 함수 중 추적표 미언급')
ck.cell(sumr, 2, f'=COUNTIFS(B{p0 + 1}:B{pl},0,C{p0 + 1}:C{pl},"화면 기능")')
ck.cell(sumr, 3, '아래 "원본 HTML 함수 대조" 표에서 빨간 행 확인')
for c in (1, 2, 3):
    ck.cell(sumr, c).font = f(10, c == 1)
    ck.cell(sumr, c).border = BORDER
ck.cell(sumr, 2).alignment = Alignment(horizontal='center')
ck.conditional_formatting.add(f'B{sumr}', FormulaRule(formula=[f'B{sumr}>0'], fill=PatternFill('solid', fgColor='F6E0E0'), font=Font(name=FONT, bold=True, color='9A2B2B')))
ck.conditional_formatting.add(f'B{sumr}', FormulaRule(formula=[f'B{sumr}=0'], fill=PatternFill('solid', fgColor='DFF0E3'), font=Font(name=FONT, bold=True, color='1E6B34')))

# ================= 시트 4: 문서 목록 =================
dl = wb.create_sheet('문서 목록')
dl['A1'] = '문서 목록 — 짐비아(GYMVIA) 문서 체계 5종 (최신 판)'
dl['A1'].font = f(13, True)
head_row(dl, 3, ['번호', '문서', '시점', '파일명 (docs/)', '판', '상태', '마지막 갱신', '담당', '원천 자료 (기존 파일)'], [6, 22, 12, 40, 8, 10, 12, 14, 60])
DOCS = [
    ('1', '서비스·기능 정의서', '[기준선]', 'GYMVIA-1_서비스기능정의서_r2.docx', 'r2', '작성 완료', '2026-11-25', '책임자',
     'FIT_LINK_prototype.html, 범위 조정안(2026-11-21), 이 추적표, README 대응표'),
    ('2', '버전 보고서', '[현재]', 'GYMVIA-2_버전보고서_v2.0.0.docx', 'v2.0.0', '작성 완료', '2026-11-25', '릴리스 담당',
     '이전 판 FITLINK-2 v1.0.3(_보관), 이 추적표 "요약" 시트, GitHub Releases'),
    ('3', '시스템 설계서', '[현재→목표]', 'GYMVIA-3_시스템설계서_r2.docx', 'r2', '작성 완료', '2026-11-25', '개발',
     '이전 판 FITLINK-3 r1(_보관), CLAUDE.md, data/README.md, firestore.rules'),
    ('4', '구축 계획서', '[목표]', 'GYMVIA-4_구축계획서_r2.docx', 'r2', '작성 완료', '2026-11-25', '책임자',
     '이전 판 FITLINK-4 r1(_보관), 범위조정 영향보고서·네이버클라우드 전환방안(2026-11-21, _보관)'),
    ('5', '기능 추적표', '공통', 'GYMVIA-5_기능추적표_r2.xlsx', 'r2', '작성 완료', '2026-11-25', '개발',
     'FITLINK-5 r1 (152행) + 범위 조정안 넣기/빼기 + 신규 3행'),
]
for i, row in enumerate(DOCS):
    r = 4 + i
    for c, v in enumerate(row, 1):
        cell = dl.cell(r, c, v)
        cell.font = f(10, c == 2)
        cell.border = BORDER
        cell.alignment = Alignment(vertical='top', wrap_text=True, horizontal='center' if c in (1, 3, 5, 6, 7) else 'left')
dl.cell(10, 1, '문서 안내: docs/README (1쪽) — 이 시트와 같은 목록 · 이전 판(FITLINK-n)은 docs/_보관/').font = f(9, color='666666')

# ================= 시트 5: 범례 =================
lg = wb.create_sheet('범례')
lg.column_dimensions['A'].width = 20
lg.column_dimensions['B'].width = 100
LEG = [
    ('상태 (5단계)', None),
    ('실동작', '실제 계산·저장·연동으로 동작'),
    ('화면 동작', '화면·버튼은 동작하나 결과가 고정값(목업)이거나 일부만 반영·저장'),
    ('데모', '흉내만 냄 — 정해진 결과나 안내 알림만 표시(가짜 인식·가짜 결제 등)'),
    ('미구현', '화면이나 기능 자체가 없음'),
    ('범위 제외', '만들지 않기로 결정 — 관련 결정 번호 필수'),
    ('기능 ID', None),
    ('형식', 'F-영역코드-번호 — 번호는 영역 안 계층 번호 (예: 번호 3.4.2 → F-SIG-4.2), 영역 행은 F-영역코드'),
    ('규칙', '한 번 부여한 ID는 변경·재사용 금지 · 삭제 기능은 비고에 "폐기" 표시 · 새 기능은 다음 번호'),
    ('영역 코드', 'APP 앱 시작 · HOME 홈 · SIG 헬스장 찾기(시그니처) · COACH AI 코치 · INB 인바디 · COMM 커뮤니티 · MKT 마켓 · B2B 운영자 전용관 · DLV 배달 · CAL 칼로리 · MY 마이·포인트 · SYS 공통'),
    ('테스트 번호', 'T-영역코드-화면번호 (예: T-SIG-4 = 기구 찾기 4단계 시나리오) · 실동작·화면 동작·데모만 부여, 나머지 "—"'),
    ('열 묶음', None),
    ('[기준선] 원본 설계', '원본 위치: FIT_LINK_prototype.html의 화면(tab-…)·함수 이름 · 원본/신규: 원본에 없던 기능은 "신규"'),
    ('[현재] 2.0.0', '상태 · 2.0.0 동작 · 코드 위치(저장소 경로) · 남은 일'),
    ('[목표] 앞으로', '목표 동작("현재 유지" = 더 할 일 없음, "하위 기능 참조" = 묶음 행) · 설계 위치(3번 시스템 설계서 장) · 인터페이스·데이터 · 비용 항목 · 단계'),
    ('연결 · 관리', '관련 결정 · 테스트 · 웹 바로가기 · 비고 · 점검(자동 — 빈 칸·불일치 표시)'),
    ('설계 위치 (3번 장)', None),
    ('3-1 ~ 3-8', '3-1 아키텍처 개요 · 3-2 앱 · 3-3 서버 · 3-4 데이터베이스 · 3-5 인터페이스 · 3-6 보안·개인정보 · 3-7 운영·배포 · 3-8 처리 흐름 (절 번호는 3번 작성 시 추가)'),
    ('비용 항목 (4번 1장)', None),
] + [(k, nm + ' — 4번 구축 계획서 1-3') for k, nm in COSTS] + [
    ('없음 / — / 미집계', '"없음" = 남은 일이 있으나 비용 없음 · "—" = 남은 일 없음 · "미집계" = 제휴·견적 필요'),
    ('단계 (4번 2장)', None),
    ('완료', '2.0.0까지 끝남(더 할 일 없음)'),
    ('1단계 기반', '계정·로그인, 기기 기록 저장, 네이버 지도, 개발·운영 서버 분리'),
    ('2단계 공유', '헬스장·기구 데이터 서버 이전, 사업자 인증, 커뮤니티·챌린지·랭킹, 푸시'),
    ('3단계 AI', '휴대폰 안 AI(ML Kit·Health Connect), 서버 AI(코치·기구·음식 인식), 리포트'),
    ('4단계 결제', '결제가 필요한 기능 — 마켓·배달 재개 시 (현재 보류)'),
    ('5단계 출시', 'Play 스토어, App Check, 상용 지도, iOS(선택)'),
    ('미정 / 보류 / 범위 제외 / —', '미정 = 범위·제휴 결정 필요(4번 3장 미결정) · 보류 = 인지도가 생긴 뒤 추가(D-010, 코드는 태그 보관) · 범위 제외 = 만들지 않음 · — = 하위 기능에 위임'),
    ('관련 결정 (4번 3장)', None),
    ('D-001 (2026-11-12)', 'Flutter 단일 코드로 Android·웹(이후 iOS) 제작'),
    ('D-002 (2026-11-12)', '지도: 공개 OpenStreetMap 사용, 상용 시 타일 제공자 교체 → D-016(네이버 지도)으로 구체화'),
    ('D-003 (2026-11-14)', '헬스장·기구 데이터는 CSV로 관리 → 앱 코드 자동 생성'),
    ('D-004 (2026-11-14)', 'Firebase 익명 로그인 + Firestore, 서울 리전'),
    ('D-005 (2026-11-14)', '서버 공유는 회원 제보만, 운영자 등록은 사업자 인증 전까지 기기 저장'),
    ('D-006 (2026-11-14)', '"없어요" 제보는 다른 회원 2명 이상 + "있어요"보다 많을 때만 전체 반영'),
    ('D-007 (2026-11-17)', '헬스장 실시간 인원("현재 인원")은 범위 제외'),
    ('D-008 (2026-11-17)', 'AI는 휴대폰 안 처리 우선, 서버 AI는 Claude Haiku 최소 사용'),
    ('D-009 (2026-11-21, 11-24 갱신)', '개인정보 처리방침 문의처: 짐비아 운영팀 · gymvia.cs@gmail.com'),
    ('D-010 (2026-11-21)', '범위 조정: 마켓·배달·포인트 허브와 연결 버튼 보류(인지도가 생긴 뒤), 코드는 태그 보관 후 삭제'),
    ('D-011 (2026-11-24)', '이름 짐비아(GYMVIA), 앱 ID kr.gymvia.app, WILD WEAR 표기 제거'),
    ('D-012 (2026-11-24)', '하단 탭: 홈 · 헬스장 찾기 · 커뮤니티 · 칼로리 · 마이'),
    ('D-013 (2026-11-24)', '운영자 전용관 진입: 마이 메뉴 + 확정 화면 링크'),
    ('D-014 (2026-11-24)', '칼로리 "마켓 보기" 빼기'),
    ('D-015 (2026-11-24)', '포인트 전체 보류, 보상은 배지·연속 기록'),
    ('D-016 (2026-11-21)', '지도·길찾기는 네이버 지도 — 길찾기는 앱 URL Scheme(키 없음, 2.0.1), 지도 화면은 NCP Maps'),
    ('D-017 (2026-11-24)', 'PT 예약은 예약 요청만, 결제는 현장'),
    ('D-018 (2026-11-21)', '신규 기능: 오늘 할 운동으로 찾기, 내 이용권(체인), 헬스 소개팅(조건부)'),
    ('기준', None),
    ('기준 버전', '2.0.0 (2026-11-24 배포, Android 앱·웹 데모 동일) · 원본 FIT_LINK_prototype.html 대비'),
    ('출처', 'FIT_LINK_1.0.3_기능_구현현황_수정본.xlsx의 152행을 이어받아 열 추가 · 상태 변환: 구현→실동작(화면만 동작하면 화면 동작), 부분 구현→화면 동작(데모면 데모), 미구현→데모 또는 미구현'),
    ('2.0.0 변경', 'tool/docs/scope_v2.py — 범위 조정안(2026-11-21) 넣기/빼기와 Q-14~Q-23 결정을 1.0.3 행 위에 덧씌움 · 보류 기능은 ID 유지(재사용 금지), 상태 "범위 제외" + 단계 "보류"'),
]
for r, (k, v) in enumerate(LEG, 1):
    a, b = lg.cell(r, 1, k), lg.cell(r, 2, v)
    if v is None:
        a.font = f(11, True, '8A6A1F')
        continue
    a.font = f(10, True)
    b.font = f(10)
    a.border = b.border = BORDER
    a.alignment = Alignment(vertical='top', wrap_text=True)
    b.alignment = Alignment(wrap_text=True, vertical='top')
    if k in SCOL:
        bg, fg = SCOL[k]
        a.fill = PatternFill('solid', fgColor=bg)
        a.font = f(10, True, fg)
        a.alignment = Alignment(horizontal='center')

for sh in wb.worksheets:
    sh.sheet_view.zoomScale = 90
wb.move_sheet('요약', offset=-1)
wb.active = 0
wb.save(OUT)
print('saved', len(data), 'rows; funcs', len(funcs))
missing = [fn for fn in funcs if fn not in HELPER and not any((fn + '(') in d['proto'] for d in data)]
print('uncovered:', missing)
