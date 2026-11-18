# 비용 계산 모델 — 4번 구축 계획서 1장의 모든 금액은 여기서 계산

FX = 1400  # 원/달러 (가정)

# ---------------- 금액 표시 ----------------
def won(krw):
    krw = round(krw)
    if krw == 0:
        return '0원'
    if krw >= 10000:
        man = krw / 10000
        s = f'{man:,.1f}'.rstrip('0').rstrip('.')
        return f'{s}만 원'
    return f'{round(krw, -2):,}원'


def usd(krw):
    d = krw / FX
    if d == 0:
        return '$0'
    return f'${d:,.0f}' if d >= 10 else f'${d:,.1f}'


def money(krw):
    return f'{won(krw)}({usd(krw)})'


def rng(lo, hi):
    if round(lo, -2) == round(hi, -2):
        return money(lo)
    return f'{won(lo)}~{won(hi)}({usd(lo)}~{usd(hi)})'


# ---------------- AI 사용료 계산 (Claude API, 100만 토큰당 달러) ----------------
SONNET = (2.00, 10.00)   # Claude Sonnet 5.5 입력·출력
HAIKU = (0.10, 0.50)     # Claude Haiku 5.5 입력·출력


def ai_cost(calls, tin, tout, model, mult=1.0, batch=False):
    usd_ = calls * (tin * model[0] + tout * mult * model[1]) / 1e6
    return usd_ * (0.5 if batch else 1.0) * FX


# 사용량 가정 (활성 회원 1,000명, 월)
U = {  # 이름: (월 호출 수, 입력 토큰, 출력 토큰, 포함 기능)
 'gear':    (10000, 2600, 300, '기구 인식(2단계 분석 · AI 기구 인식)'),
 'food':    (10000, 2600, 300, '칼로리 분석 · 결과(음식 인식)'),
 'body':    (4000, 3400, 200, '눈바디 · 바디 변화(사진 정렬)'),
 'coach':   (30000, 4000, 500, 'AI 코치 추천 질문 · 자유 질문'),
 'report':  (4300, 3000, 600, '주간 리포트'),
 'inbody':  (1000, 3000, 600, '인바디 결과 AI 상담'),
 'routine': (4300, 2500, 700, 'AI 적응형 루틴'),
 'live':    (40000, 800, 80, '실시간 코칭 · 심박·자세 코칭 문구'),
}

# A안: 모두 Claude Sonnet 5.5 (낮은 값 = 생각 토큰 없음, 높은 값 = 출력 2배)
A = {k: (ai_cost(c, i, o, SONNET, 1), ai_cost(c, i, o, SONNET, 2)) for k, (c, i, o, _) in U.items()}
# B안: 비용 최소화 방안
B = {
 'gear': (ai_cost(3000, 2600, 300, HAIKU, 1), ai_cost(10000, 2600, 300, HAIKU, 2)),   # 로고 글자 인식 실패분만 Haiku (30~100%)
 'food': (ai_cost(3000, 2600, 300, HAIKU, 1), ai_cost(10000, 2600, 300, HAIKU, 2)),   # 분류 실패분만 Haiku
 'body': (0, 0),                                                                      # ML Kit 포즈 감지
 'coach': (ai_cost(30000, 4000, 500, HAIKU, 1), ai_cost(30000, 4000, 500, HAIKU, 2)), # 자유 질문 Haiku, 추천 질문은 템플릿
 'report': (0, ai_cost(4300, 3000, 600, HAIKU, 2, batch=True)),                       # 템플릿, 문장 다듬기만 Batch Haiku
 'inbody': (0, 0),                                                                    # 규칙 기반 해설
 'routine': (0, 0),                                                                   # 규칙 기반 루틴
 'live': (0, 0),                                                                      # 템플릿 + ML Kit
}
B_HOW = {
 'gear': '로고 글자 인식(ML Kit, 무료) + 실패분만 Haiku 5.5',
 'food': '식약처 DB 검색 + 휴대폰 안 분류 모델 + 실패분만 Haiku 5.5',
 'body': 'ML Kit 포즈 감지(무료)',
 'coach': '추천 질문은 템플릿, 자유 질문만 Haiku 5.5',
 'report': '템플릿 (문장 다듬기만 Batch Haiku 5.5, 50% 할인)',
 'inbody': '표준 범위 비교 규칙 기반 해설',
 'routine': '기구 카탈로그·목표 기반 규칙 생성',
 'live': '심박 존별 문구 템플릿 + ML Kit',
}

def tot(d):
    return sum(v[0] for v in d.values()), sum(v[1] for v in d.values())

AI_A, AI_B = tot(A), tot(B)

# ---------------- 고정·기타 비용 (원) ----------------
PG_JOIN = 220000      # 토스페이먼츠 가입비(1회)
PG_YEAR = 110000      # 연관리비
CARD_RATE = 0.034     # 카드 수수료 3.4% + 부가세 10%
LICENSE = 40500       # 통신판매업 등록면허세(연, 서울 추정)
PLAY = 25 * FX        # Google Play 등록비(1회)
APPLE = 99 * FX       # Apple 개발자(연, 선택)
SERVER = (0, 10000)   # Firebase Blaze 월 (소규모)
MAP = (0, 0)          # Mapbox 모바일 월 2.5만 명까지 무료
SALES_EX = 10_000_000 # 결제 수수료 예시용 월 결제액

ONE_TIME = PG_JOIN + PLAY
YEARLY = PG_YEAR + LICENSE
YEARLY_IOS = YEARLY + APPLE
MON_A = (AI_A[0] + SERVER[0] + MAP[0], AI_A[1] + SERVER[1] + MAP[1])
MON_B = (AI_B[0] + SERVER[0] + MAP[0], AI_B[1] + SERVER[1] + MAP[1])
Y1_A = (ONE_TIME + YEARLY + MON_A[0] * 12, ONE_TIME + YEARLY + MON_A[1] * 12)
Y1_B = (ONE_TIME + YEARLY + MON_B[0] * 12, ONE_TIME + YEARLY + MON_B[1] * 12)
FEE_EX = SALES_EX * CARD_RATE * 1.1
