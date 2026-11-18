# FIT LINK 문서 체계 지도 — 5종 (PNG)
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

fig, ax = plt.subplots(figsize=(16, 9.6), dpi=150)
ax.set_xlim(0, 160)
ax.set_ylim(0, 96)
ax.axis('off')

ax.text(80, 95.5, 'FIT LINK 문서 체계 (제안 · 5종)', fontsize=16, weight='bold', ha='center', va='top', color=INK)

cols = [
    ('1', '서비스·기능 정의서', '[기준선] 무엇을 만드는가', '#EEF4FB', '범위·기능이 바뀔 때',
     ['1부 서비스 정의', '  비전 · 사용자 · 범위 · 수익 모델', '2부 기능 명세', '  12개 영역 · 기능별 동작 규칙', '  화면 목록(주소)', '부록 원본 요약 · 용어집']),
    ('2', '버전 보고서 (v1.0.3)', '[현재] 어디까지 왔는가', '#EEF7EE', '릴리스마다 새 판',
     ['1부 버전 현황', '  구현 상태 · 원본 대비 차이', '  미완성 이유 · 알려진 문제', '2부 테스트 가이드', '  설치 · 바로가기 · 시나리오', '  피드백 양식']),
    ('3', '시스템 설계서', '[현재→목표] 어떻게 만드는가', '#F1EEF8', '구조가 바뀔 때 (장별)',
     ['1장 아키텍처 개요', '2장 앱   3장 서버', '4장 데이터베이스', '5장 인터페이스', '6장 보안·개인정보', '7장 운영·배포   8장 처리 흐름']),
    ('4', '구축 계획서', '[목표] 얼마나·언제·무엇을 정하나', '#FBEFEF', '단계 시작 전 · 결정 시',
     ['1장 비용', '  총비용 · 항목별 금액 · 절감', '2장 로드맵', '  단계 · 선행 조건 · 완료 기준', '3장 의사결정 기록', '  확정 결정 · 미결정 목록']),
]
W, X0, GAP = 35.5, 3, 3.8
for i, (code, name, q, color, upd, lines) in enumerate(cols):
    x = X0 + i * (W + GAP)
    ax.add_patch(FancyBboxPatch((x, 33), W, 52, boxstyle='round,pad=0.4,rounding_size=1.5', fc=color, ec=GOLD, lw=1.6))
    ax.text(x + 1.4, 84, code, fontsize=20, weight='bold', color=GOLD, va='top')
    ax.text(x + 6.2, 83.4, name, fontsize=12.5, weight='bold', color=INK, va='top')
    ax.text(x + 6.2, 79.6, q, fontsize=8.6, color='#555555', va='top')
    ax.add_patch(FancyBboxPatch((x + 1.6, 40.5), W - 3.2, 34, boxstyle='round,pad=0.25,rounding_size=0.7', fc='white', ec='#9C8F74', lw=1))
    for j, ln in enumerate(lines):
        head = not ln.startswith('  ')
        ax.text(x + 3, 72.6 - j * 5.2, ln.strip(), fontsize=9.4 if head else 8.4,
                weight='bold' if head else 'normal', color=INK if head else '#444444', va='top')
    ax.text(x + W / 2, 37.6, '갱신: ' + upd, fontsize=8.4, color='#6B5A33', ha='center', va='center')


def arrow(x1, y1, x2, y2, label=None, lx=None, ly=None, both=False):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle='<|-|>' if both else '-|>', mutation_scale=11, color='#6B5A33', lw=1.3))
    if label:
        ax.text(lx, ly, label, fontsize=7.8, color='#6B5A33', ha='center',
                bbox=dict(fc='white', ec='none', pad=0.5, alpha=0.95))


for i, lab in enumerate(['기준선 대비', '남은 것', '만들 순서·비용']):
    x1 = X0 + (i + 1) * W + i * GAP + 0.4
    arrow(x1, 60, x1 + GAP - 0.8, 60)
    ax.text(x1 + GAP / 2 - 0.4, 62.2, lab, fontsize=7.4, color='#6B5A33', ha='center', rotation=90, va='bottom')

# Excel 추적표
ax.add_patch(FancyBboxPatch((3, 13), 154, 12, boxstyle='round,pad=0.4,rounding_size=1.5', fc='#FFF5E0', ec=GOLD, lw=1.6))
ax.text(4.4, 24, '5', fontsize=20, weight='bold', color=GOLD, va='top')
ax.text(9.6, 23.4, '기능 추적표 (Excel) — 단일 원천', fontsize=12.5, weight='bold', color=INK, va='top')
ax.text(9.6, 19.4, '기능 ID 한 줄에:  원본 위치 ↔ 1.0.3 상태 ↔ 목표 동작 ↔ 설계 위치 ↔ 비용 항목 ↔ 단계 ↔ 결정 ↔ 테스트',
        fontsize=9.2, color='#444444', va='top')
ax.text(9.6, 16.0, '시트: 기능 목록 · 요약(자동 집계) · 점검(빈 칸 자동 표시) · 문서 목록 · 범례     갱신: 기능·상태가 바뀔 때마다',
        fontsize=8.4, color='#6B5A33', va='top')
for i in range(4):
    cx = X0 + i * (W + GAP) + W / 2
    arrow(cx, 32.6, cx, 25.4, both=True)
ax.text(80, 29, '모든 문서가 같은 기능 ID(예: F-SIG-4.2)로 연결', fontsize=8.4, color='#6B5A33', ha='center',
        bbox=dict(fc='white', ec='none', pad=0.6))

ax.text(80, 7.5, '읽는 순서 — 처음 보는 사람: 1 → 2(1부) → 3(1장) → 4   ·   테스터: 2(2부)   ·   개발자: 3 → 5   ·   의사결정자: 4',
        fontsize=9.6, ha='center', color='#1F4E8C', weight='bold')
ax.text(80, 3.2, '문서 안내: docs/README (1쪽) + 각 문서 첫 장의 "문서 체계" 표     ·     공통 표시: [기준선] · [현재] · [목표], 상태 색 5가지',
        fontsize=8.6, ha='center', color='#555555')

plt.savefig(os.path.join(FIG, 'docmap.png'), bbox_inches='tight', facecolor='white')
print('ok')
