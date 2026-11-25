# 짐비아 브랜드 이미지(assets/brand/ 시안)에서 앱·웹에 쓰는 파일을 만든다.
#   python tool/brand/make_brand_assets.py
#   dart run flutter_launcher_icons   (앱·웹 아이콘 생성 — CLAUDE.md "App icon" 주의 사항 참고)
#
# 원본(디자인 시안, 2026-11-25 제공):
#   assets/brand/짐비아_화이트블랙 로고.png — 왼쪽(밝은 배경)·오른쪽(어두운 배경) 아이콘 + 글자 로고
#   assets/brand/짐비아_대표이미지.png     — 소개 이미지 1800×1200
# 원본 파일에 아이콘 단독 파일이 없어, 시안의 아이콘(약 640px, 둥근 모서리)을 잘라
# 모서리를 배경색으로 채운 정사각형으로 만든다.
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
BRAND = os.path.join(ROOT, 'assets', 'brand')
LOCKUP = os.path.join(BRAND, '짐비아_화이트블랙 로고.png')
HERO = os.path.join(BRAND, '짐비아_대표이미지.png')


def lum(p):
    return 0.299 * p[0] + 0.587 * p[1] + 0.114 * p[2]


def tile_box(img, x0, x1, dark=True):
    """시안에서 아이콘(어두운 둥근 사각형)의 위치를 찾는다 — 글자 로고 위쪽만 본다"""
    w, h = img.size
    px = img.load()
    xs, ys = [], []
    for y in range(int(h * 0.15), int(h * 0.63), 2):
        for x in range(x0, x1, 2):
            v = lum(px[x, y])
            if (v < 60) if dark else (v > 28):
                xs.append(x)
                ys.append(y)
    return min(xs), min(ys), max(xs), max(ys)


def rounded_mask(size, radius, scale=4):
    m = Image.new('L', (size * scale, size * scale), 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size * scale - 1, size * scale - 1], radius * scale, fill=255)
    return m.resize((size, size), Image.LANCZOS)


def square_icon(src, box, out=1024):
    """둥근 아이콘을 모서리까지 채운 정사각형으로"""
    l, t, r, b = box
    side = min(r - l, b - t)
    cx, cy = (l + r) // 2, (t + b) // 2
    tile = src.crop((cx - side // 2, cy - side // 2, cx + side // 2, cy + side // 2)).resize((out, out), Image.LANCZOS)
    # 모서리 바로 안쪽 4곳의 평균 색 = 채울 배경색
    s = [tile.getpixel((int(out * a), int(out * b))) for a, b in ((.16, .16), (.84, .16), (.16, .84), (.84, .84))]
    bg = tuple(sum(c[i] for c in s) // 4 for i in range(3))
    canvas = Image.new('RGB', (out, out), bg)
    canvas.paste(tile, (0, 0), rounded_mask(out, int(out * 0.235)))
    return canvas, bg


def main():
    lock = Image.open(LOCKUP).convert('RGB')
    W, H = lock.size
    # 왼쪽(밝은 배경) 시안의 아이콘 — 어두운 사각형이 밝은 배경 위에 있어 경계가 뚜렷함
    box = tile_box(lock, 0, W // 2, dark=True)
    icon, bg = square_icon(lock, box)
    os.makedirs(os.path.join(ROOT, 'assets', 'icon'), exist_ok=True)
    icon.save(os.path.join(ROOT, 'assets', 'icon', 'icon.png'))
    # Android 적응형 아이콘 전경: 원·둥근 사각형 마스크에서 글자가 잘리지 않게 80%로 줄여 가운데
    fg = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    small = icon.resize((820, 820), Image.LANCZOS)
    fg.paste(small, (102, 102), rounded_mask(820, int(820 * 0.06)))
    fg.save(os.path.join(ROOT, 'assets', 'icon', 'icon_foreground.png'))
    hexbg = '#%02X%02X%02X' % bg
    # 웹 브라우저 탭 아이콘: 아이콘 전체는 16~48px에서 글자가 뭉개지므로 나침반 원만 잘라 씀
    s = int(1024 * 0.36)
    cx, cy = 512, int(1024 * 0.375)
    star = icon.crop((cx - s // 2, cy - s // 2, cx + s // 2, cy + s // 2))
    star.resize((48, 48), Image.LANCZOS).save(os.path.join(ROOT, 'web', 'icons', 'favicon-48.png'))
    # 안드로이드 시작 화면 가운데 아이콘
    icon.resize((288, 288), Image.LANCZOS).save(os.path.join(ROOT, 'android', 'app', 'src', 'main', 'res', 'drawable', 'splash_icon.png'))

    # 글자 로고 포함 잠금형 로고 (README 등): 왼쪽 = 밝은 배경용, 오른쪽 = 어두운 배경용
    l, t, r, b = box
    pad = int((r - l) * 0.18)
    for name, dx, bgc in (('logo_light.png', 0, None), ('logo_dark.png', W // 2, None)):
        crop = lock.crop((l - pad + dx, t - pad, r + pad + dx, int(H * 0.74)))
        crop.thumbnail((520, 1000), Image.LANCZOS)
        crop.save(os.path.join(BRAND, name), optimize=True)

    # 대표이미지 → 웹 공유 이미지 1200×630 (내용이 가운데 몰려 있어 위아래만 잘라 냄)
    hero = Image.open(HERO).convert('RGB')
    hw, hh = hero.size
    ch = int(hw * 630 / 1200)
    top = (hh - ch) // 2
    hero.crop((0, top, hw, top + ch)).resize((1200, 630), Image.LANCZOS).save(
        os.path.join(ROOT, 'web', 'og-image.jpg'), quality=90, optimize=True, progressive=True)
    # 온보딩 소개 화면용 (앱에 들어가므로 작게)
    hero.resize((1080, 720), Image.LANCZOS).save(os.path.join(BRAND, 'gymvia_hero.jpg'), quality=88, optimize=True, progressive=True)

    print('아이콘 위치', box, '배경색', hexbg)
    print('→ pubspec.yaml adaptive_icon_background / 시작 화면 색을', hexbg, '로 맞출 것')


if __name__ == '__main__':
    main()
