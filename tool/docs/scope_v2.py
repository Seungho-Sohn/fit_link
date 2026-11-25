# 2.0.0(짐비아) 범위 조정 반영 — feature_rows.py(1.0.3 기준 152행) 위에 덧씌우는 변경
# 근거: docs/_보관/FITLINK 기능추적표_범위 조정안.xlsx (2026-11-21, 넣기/빼기),
#       범위조정 영향보고서 Q-14~Q-23 (2026-11-24 권장안 전부 채택), v2.0.0 코드

NEW_ = '— (원본에 없음)'
HOLD_TARGET = '인지도가 생긴 뒤 다시 추가 — 2.0.0에서 코드 삭제, 태그 archive/store-delivery-points에 보관'

# 보류(빼기)한 기능: 번호 접두어 → 관련 결정. 영역 행(7, 9)도 포함
HOLD = {'7': 'D-010', '9': 'D-010', '11.3': 'D-010', '3.6.2': 'D-010'}
# 아예 뺀 기능 (보류가 아님)
DROP = {'10.3.2': 'D-014'}


def held(num):
    for p, dec in HOLD.items():
        if num == p or num.startswith(p + '.'):
            return dec
    return None


# 2.0.0에서 동작이 바뀐 기능 (기존 값 대신 쓸 필드만)
OVR = {
    '1.2': dict(does='커뮤니티 글·댓글·좋아요, 운영자 등록, 내 기구 제보, 내 이용권, 온보딩 목표 복원'),
    '2.3': dict(does='헬스장 찾기 탭(시그니처)으로 이동'),
    '2.5': dict(name='바로가기 2개', how='음식 기록 · 챌린지', does='칼로리·커뮤니티 탭으로 이동 (마켓 바로가기는 보류, D-010)'),
    '2.8': dict(does='참가비 0원 · 완주 시 완주 배지 · 순위 표시 (포인트 대신 배지, D-015)', left='진행률·순위 고정'),
    '2.8.1': dict(left='실제 인증·진행률·배지 지급 없음'),
    '2.12.2': dict(does='"랫풀다운 신기록!" 알림 (주간 미션은 포인트와 함께 보류)'),
    '2.16': dict(stage='2단계 공유'),
    '2.16.1': dict(stage='2단계 공유'),
    '2.16.2': dict(target='예약 요청 저장·트레이너 알림 (결제는 현장, D-017)', cost='C-2', stage='2단계 공유', dec='D-017'),
    '3': dict(name='헬스장 찾기 (시그니처: 기구 → 같은 기구가 있는 헬스장)', how='하단 "헬스장 찾기" 탭'),
    '3.5': dict(left='실서비스 전 지도 제공 업체 변경 필요 → 네이버 지도(NCP Maps)로 교체 예정',
                target='네이버 지도(NCP Maps) 지도 화면으로 교체', stage='1단계 기반', dec='D-016'),
    '3.6': dict(does='헬스장·매칭 정도·보유 기구·거리·도보·운영 시간·정보 출처, "운영자이신가요? 보유 기구 등록하기" 링크'),
    '3.6.1': dict(does='네이버 지도 앱 도보 길찾기 (2.0.1) — 앱이 없으면 Play 스토어·App Store, PC 웹은 안내 문구', left='',
                  code='lib/services/directions.dart · lib/screens/gear_flow.dart', target='현재 유지',
                  iface='nmap:// URL Scheme (키 없음)', dec='D-016', note='2026-11-25 실기기(Galaxy A18) 확인'),
    '3.6.3': dict(does='처음 확인하면 "있어요/없어요" 저장, "없어요"면 나에게서 바로 제외 (포인트 보상 없음, D-015)'),
    '3.6.5': dict(st='실동작', does='마이 → 개인정보 처리방침(웹 페이지) · 내 기구 제보 지우기(서버·기기), 문의처 짐비아 운영팀', left='',
                  code='lib/screens/my_screen.dart · web/privacy.html', target='현재 유지', stage='완료', dec='D-009', note=''),
    '6.1.1': dict(does='글 저장(최근 100개), 태그(운동 인증·식단 인증·꿀팁·질문) 표시 — 인증 보상 포인트는 보류(D-015)'),
    '8': dict(how='마이 → "🏢 헬스장 운영자 전용관" 또는 확정 화면 링크', url='#/b2b'),
    '8.1': dict(does='기구 9종, 카테고리 필터, 도매가·최소 수량 (판매처 표시 없음)'),
    '11': dict(name='마이 탭'),
    '11.1': dict(name='프로필 · 배지', does='"짐비아 회원 · 🔥 12일 연속", 배지 4개 (등급 없음, D-015)', left='배지 획득·연속 기록 계산 없음(고정)'),
    '11.2': dict(does='챌린지·찜한 헬스장·인식 이력·식단·웨어러블·알림 설정(고정 표시), 운영자 전용관 바로가기, 개인정보 · 데이터',
                 left='챌린지·찜·인식 이력·식단·알림 설정은 고정 표시'),
    '12.1': dict(does='정식 키 서명, 태그로 자동 빌드·업로드 (gymvia-X.Y.Z.apk · 앱 ID kr.gymvia.app)'),
    '12.2': dict(does='master에 합치면 자동 배포 (짐비아)'),
}

# 새 기능 (뒤에 붙일 번호, 행) — 행 형식은 feature_rows.R과 같음
NEW_ROWS = [
    ('3.6.5', ('3.7', '오늘 할 운동으로 찾기', '헬스장 찾기 → "오늘 할 운동으로 찾기"', '구현', '신규',
               '운동 고르기(5종) → 고른 운동을 할 수 있는 헬스장, 많이 되는 순·같으면 거리순 → 길찾기', '운동·기구 데이터 목업', '#/gear')),
    ('3.7', ('3.8', '내 이용권 (체인 모드)', '헬스장 찾기 1단계 "내 이용권"', '구현', '신규',
             '이용권이 있는 체인 선택 → 그 체인 지점만 기구 찾기·운동 찾기 결과에 표시, 저장', '체인·지점 데이터 목업(가상 체인)', '#/gear')),
    ('6.4', ('6.5', '헬스 소개팅', '—', '미구현', '',
             '—', '만 19세 이상 본인인증, 신고·차단, 연락처·위치 비공개 필수 — 법률 검토·운영 인력 확보 후 결정', '')),
]
# 새 기능의 추적 정보 (make_trace.X와 같은 형식)
NEW_X = {
    '3.7': (NEW_, 'lib/screens/gear_flow.dart (routine) · lib/data/equipment.dart (routineGyms) · data/exercises.csv',
            '현재 유지 (실제 운동·기구 데이터로 교체)', '3-2, 3-4', 'exercises · gymGearNow', '—', '완료', 'D-018', ''),
    '3.8': (NEW_, 'lib/state/app_state.dart (myChains · gymsForMe) · data/gyms.csv (체인 열)',
            '현재 유지 (실제 체인·지점 데이터로 교체)', '3-2, 3-4', 'gyms.체인 · AppState.myChains', '—', '완료', 'D-018', ''),
    '6.5': (NEW_, '—', '조건 충족 시 소수 시험 운영 → 처리방침·약관·스토어 등급 갱신 후 공개', '3-3, 3-4, 3-6',
            '본인확인 서비스 · Firestore · 채팅', 'C-2', '미정', 'D-018', 'Q-22'),
}

# 2.0.0에서 바뀐 웹 주소
URLS = {'#/market/b2b': '#/b2b', '#/market/b2b/gear': '#/b2b/gear', '#/market/b2b/quote': '#/b2b/quote',
        '#/market/used': '#/b2b/used', '#/market/dashboard': '#/b2b/dashboard'}
CODE = {'lib/screens/market_b2b.dart': 'lib/screens/b2b_screen.dart'}


def rows(base):
    """feature_rows.R에 새 행을 끼워 넣은 목록"""
    out = list(base)
    for after, row in NEW_ROWS:
        i = next(k for k, r in enumerate(out) if r[0] == after)
        # 같은 상위 번호의 하위 행까지 건너뛰고 넣는다
        j = i + 1
        while j < len(out) and out[j][0].startswith(after + '.'):
            j += 1
        out.insert(j, row)
    return out


def apply(d, num):
    """make_trace의 행(dict)에 2.0.0 변경을 적용"""
    dec = held(num)
    if dec or num in DROP:
        dec = dec or DROP[num]
        if d['lv'] > 1:
            d.update(does=('없음 (2.0.0에서 삭제) — 1.0.3: ' + d['does']) if d['does'] else '없음 (2.0.0에서 삭제)')
            d.update(st='범위 제외', left='보류 — 인지도가 생긴 뒤 추가' if num not in DROP else '빼기 (2.0.0에서 삭제)',
                     code='— (2.0.0에서 삭제)', target=HOLD_TARGET if num not in DROP else '만들지 않음',
                     design='—', iface='—', cost='—', stage='보류' if num not in DROP else '범위 제외', dec=dec, test='—')
        d['url'] = ''
        return d
    for k, v in OVR.get(num, {}).items():
        d[k] = v
    for a, b in CODE.items():
        d['code'] = d['code'].replace(a, b)
    return d
