# FIT LINK 문서 5종을 한 번에 다시 만든다.
#   python tool/docs/build_all.py
#   powershell -ExecutionPolicy Bypass -File tool/docs/finalize.ps1   (Word 목차 · Excel 수식 계산)
# 필요: Python 3.12+, python-docx, openpyxl, matplotlib, Windows 글꼴 '맑은 고딕'
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
STEPS = [
    'arch_diagram.py',            # docs/_그림/arch.png   (3번 1-4 구성도)
    'docmap_diagram.py',          # docs/_그림/docmap.png (문서 지도, docs/README)
    'make_trace.py',              # 5 기능 추적표 — 다른 문서가 읽으므로 먼저
    'make_definition_report.py',  # 1 서비스·기능 정의서
    'make_version_report.py',     # 2 버전 보고서
    'make_sysdesign_report.py',   # 3 시스템 설계서
    'make_plan_report.py',        # 4 구축 계획서
]
sys.stdout.reconfigure(encoding='utf-8')
env = dict(os.environ, PYTHONIOENCODING='utf-8')
for s in STEPS:
    print(f'== {s}', flush=True)
    subprocess.run([sys.executable, os.path.join(HERE, s)], check=True, env=env)
print('완료 — 이어서 tool/docs/finalize.ps1 실행 (Word 목차 채우기, Excel 수식 계산)')
