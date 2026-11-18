# FIT LINK 목표 아키텍처 구성도 (PNG)
import os
import sys
HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(os.path.dirname(HERE))
DOCS = os.path.join(ROOT, 'docs')
FIG = os.path.join(DOCS, '_그림')
sys.path.insert(0, HERE)
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from matplotlib.patches import FancyBboxPatch, FancyArrowPatch
from matplotlib import font_manager

font_manager.fontManager.addfont(r'C:\Windows\Fonts\malgun.ttf')
font_manager.fontManager.addfont(r'C:\Windows\Fonts\malgunbd.ttf')
plt.rcParams['font.family'] = 'Malgun Gothic'

INK, GOLD = '#2B2620', '#8A6A1F'
C_APP, C_FB, C_EXT, C_OPS = '#EEF4FB', '#FFF5E0', '#EEF7EE', '#F1EEF8'

fig, ax = plt.subplots(figsize=(16, 10.4), dpi=150)
ax.set_xlim(0, 160)
ax.set_ylim(0, 107)
ax.axis('off')


def group(x, y, w, h, title, color, sub=None):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle='round,pad=0.4,rounding_size=1.6', fc=color, ec=GOLD, lw=1.6))
    ax.text(x + 1.5, y + h - 2.6, title, fontsize=13, weight='bold', color=INK, va='top')
    if sub:
        ax.text(x + 1.5, y + h - 6.2, sub, fontsize=8.6, color='#555555', va='top')


def box(x, y, w, h, title, lines=(), fc='white', bold=True):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle='round,pad=0.25,rounding_size=0.8', fc=fc, ec='#9C8F74', lw=1))
    ax.text(x + w / 2, y + h - 1.6, title, fontsize=9.6, weight='bold' if bold else 'normal', color=INK, ha='center', va='top')
    for i, ln in enumerate(lines):
        ax.text(x + w / 2, y + h - 4.6 - i * 2.6, ln, fontsize=7.8, color='#444444', ha='center', va='top')


def arrow(x1, y1, x2, y2, label=None, both=False, dy=0.9, color='#6B5A33', ls='-'):
    a = FancyArrowPatch((x1, y1), (x2, y2), arrowstyle='<|-|>' if both else '-|>', mutation_scale=11, color=color, lw=1.3, linestyle=ls)
    ax.add_patch(a)
    if label:
        ax.text((x1 + x2) / 2, (y1 + y2) / 2 + dy, label, fontsize=7.6, color=color, ha='center', va='bottom',
                bbox=dict(fc='white', ec='none', pad=0.6, alpha=0.9))


ax.text(80, 106.2, 'FIT LINK 목표 아키텍처 (서버리스 · Firebase 중심)', fontsize=16, weight='bold', ha='center', va='top', color=INK)

# 1) 사용자 기기
group(2, 44, 46, 55, '사용자 기기 · Flutter 앱', C_APP, 'Android(현재) · 웹(현재) · iOS(예정)')
box(4.5, 78.5, 41, 10, '화면 (6개 탭 + 하위 화면)', ['홈 · 커뮤니티 · 마켓 · 배달 · 칼로리 · 마이', '기구 찾기 · AI 코치 · 인바디 · 포인트'])
box(4.5, 66, 41, 9.5, '앱 상태 · 화면 이동', ['AppState(상태) · go_router(웹 주소)', '저장소 계층: 로컬 캐시 + 서버 동기화'])
box(4.5, 55.7, 19.5, 8.8, '로컬 저장', ['설정·캐시·오프라인 대기열', '체성분·사진(기기 안)'])
box(26, 55.7, 19.5, 8.8, '휴대폰 안 AI', ['ML Kit 글자·포즈', '음식 분류 · Gemini Nano'])
box(4.5, 45.6, 19.5, 8.6, '기기 기능', ['카메라·앨범 · GPS', 'Health Connect'])
box(26, 45.6, 19.5, 8.6, '외부 앱 연결', ['카카오맵 길찾기', '지도 타일(OSM→Mapbox)'])


# 2) Firebase
group(56, 30, 54, 69, 'Firebase (Google Cloud · 서울 리전)', C_FB, '개발용 / 운영용 프로젝트 분리')
box(58.5, 80, 24, 8.5, 'Authentication', ['익명 → 카카오·이메일 연결', '권한: 회원·운영자·관리자'])
box(84.5, 80, 23, 8.5, 'App Check', ['우리 앱만 접근 허용', 'Play Integrity'])
box(58.5, 60.5, 24, 15, 'Cloud Firestore', ['회원 · 포인트 내역', '글 · 챌린지 · 랭킹', '헬스장 · 기구 · 제보', '상품 · 주문 · 결제 상태'])
box(84.5, 60.5, 23, 15, 'Cloud Functions', ['서버 코드 (TypeScript)', 'AI 중계 · 포인트 · 결제 승인', '사업자 인증 · 집계', '예약 작업(스케줄러)'])
box(58.5, 50, 24, 9.3, 'Cloud Storage', ['커뮤니티·매물 사진', '썸네일 자동 생성'])
box(84.5, 50, 23, 9.3, 'Cloud Messaging', ['푸시 알림', '리마인더 · 주문 상태'])
box(58.5, 33, 49, 13.5, '보안 · 비밀 · 운영 도구', ['보안 규칙(자기 것만 쓰기 · 돈/포인트는 서버만)', 'Secret Manager(API 키) · Cloud Scheduler', 'Cloud Logging · Crashlytics · 예산 알림 · 매일 백업'], fc='#FFFBF2')

# 3) 외부 서비스
group(117, 30, 41, 69, '외부 서비스', C_EXT, '서버(Functions)를 거쳐서만 호출 — 키는 서버에만')
ext = [('Anthropic Claude API', ['AI 코치 · 인식 실패 보조 (Haiku 5.5)']),
       ('토스페이먼츠', ['결제창(앱) · 결제 승인(서버)']),
       ('국세청 사업자 진위확인', ['운영자 인증 (공공데이터)']),
       ('식약처 식품영양성분 DB', ['음식 칼로리·탄단지']),
       ('카카오 로그인', ['토큰 확인 → Firebase 계정']),
       ('택배 조회 · 배달 대행', ['주문·배송 상태 (제휴 후)'])]
for i, (t, l) in enumerate(ext):
    box(119.5, 82 - i * 8.6, 36, 7.2, t, l)

# 4) 운영·배포
group(2, 2, 156, 22, '개발 · 배포 · 운영', C_OPS)
ops = [('GitHub 저장소', ['앱 · 서버 · 규칙 · 데이터(CSV)']),
       ('GitHub Actions', ['분석 · 테스트 · 에뮬레이터 테스트', '웹 배포 · APK 릴리스 · firebase deploy']),
       ('GitHub Pages', ['웹 데모 / 웹 앱']),
       ('GitHub Releases → Play 스토어', ['서명된 APK (현재)', 'Play 출시 (예정)']),
       ('관리자 도구', ['Firebase 콘솔 · 간단한 관리 웹', '상품·헬스장·신고 관리'])]
for i, (t, l) in enumerate(ops):
    box(4.5 + i * 31, 4, 28.5, 12.5, t, l)


def tag(x, y, s):
    ax.text(x, y, s, fontsize=7.8, color='#6B5A33', ha='center', va='bottom', bbox=dict(fc='white', ec='none', pad=0.5, alpha=0.95))


# 화살표 (라벨은 두 그룹 사이 빈칸에)
arrow(48, 84, 58.5, 84, both=True); tag(52.2, 84.4, '로그인')
arrow(48, 77.6, 90, 75.5); tag(52.2, 78.0, '함수 호출')
arrow(48, 70, 58.5, 70, both=True); tag(52.2, 70.4, '읽기·쓰기')
arrow(48, 58, 58.5, 55); tag(52.2, 57.8, '사진')
arrow(90, 50, 90, 48.6, color='#6B5A33'); arrow(90, 48.6, 48, 48.6); tag(52.2, 49.0, '푸시')
arrow(107.5, 72, 119.5, 85.6); tag(113.5, 79.6, 'API 호출')
arrow(107.5, 66, 119.5, 42.6)
arrow(42, 16.5, 72, 33); tag(64, 27.4, '자동 배포')
arrow(67, 16.5, 34, 44); tag(43, 33.0, '웹 앱 제공')
plt.savefig(os.path.join(FIG, 'arch.png'), bbox_inches='tight', facecolor='white')
print('ok')
