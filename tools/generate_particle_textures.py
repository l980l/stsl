"""파티클 텍스처 5종 생성 — Pillow로 절차적 PNG 생성."""
import math
import random
from pathlib import Path

try:
    from PIL import Image, ImageFilter
except ImportError:
    print("pip install pillow 후 실행하세요.")
    raise

OUT = Path(__file__).parent.parent / "assets" / "art" / "particles"
OUT.mkdir(parents=True, exist_ok=True)


def make_circle(size=128):
    """부드러운 발광 원 — 가우시안 감쇠, 중심부 과노출."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = (size - 1) / 2.0
    r = cx
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / r
            a = max(0.0, 1.0 - d * d)
            a = a ** 1.2
            v = int(min(255, a * 320))   # 중심 과노출 → bloom 트리거
            alpha = int(min(255, a * 255))
            img.putpixel((x, y), (v, v, v, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.5))
    return img


def make_slash(w=128, h=16):
    """가로 스트릭 — 양 끝 페이드, 세로 페이드, 중심 과노출."""
    img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    cx = (w - 1) / 2.0
    cy = (h - 1) / 2.0
    for y in range(h):
        for x in range(w):
            ax = max(0.0, 1.0 - abs(x - cx) / cx) ** 1.8
            ay = max(0.0, 1.0 - abs(y - cy) / (cy + 0.5)) ** 1.0
            a = ax * ay
            v = int(min(255, a * 340))
            alpha = int(min(255, a * 255))
            img.putpixel((x, y), (v, v, v, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
    return img


def make_dust(size=64):
    """거칠고 불규칙한 파편 — 랜덤 노이즈로 깨진 암석 느낌."""
    rng = random.Random(1337)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = (size - 1) / 2.0
    r = cx * 0.9
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / r
            if d > 1.0:
                continue
            base = max(0.0, 1.0 - d)
            noise = 0.6 + 0.4 * rng.random()
            a = base * noise
            edge = min(x, y, size - 1 - x, size - 1 - y)
            if edge < 2:
                a *= edge / 2.0
            v = int(min(255, a * 255))
            alpha = int(min(255, a * 240))
            img.putpixel((x, y), (v, v, v, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=0.6))
    return img


def make_star(size=128):
    """4점 별 — 수평·수직 광선 + 중심 코어 과노출."""
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = (size - 1) / 2.0
    r = cx
    for y in range(size):
        for x in range(size):
            dx = abs(x - cx)
            dy = abs(y - cy)
            d = math.hypot(x - cx, y - cy)
            beam = max(0.0, 1.0 - min(dx, dy) / (r * 0.14)) ** 2.0
            core = max(0.0, 1.0 - d / (r * 0.35)) ** 1.8
            fade = max(0.0, 1.0 - d / r)
            a = min(1.0, beam * fade * 0.9 + core)
            v = int(min(255, a * 350))   # 중심 과노출
            alpha = int(min(255, a * 255))
            img.putpixel((x, y), (v, v, v, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.2))
    return img


def make_smoke(size=128):
    """솜털 연기 — 가우시안 기반 + 고주파 노이즈로 울퉁불퉁."""
    rng = random.Random(4242)
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    cx = cy = (size - 1) / 2.0
    r = cx
    for y in range(size):
        for x in range(size):
            d = math.hypot(x - cx, y - cy) / r
            base = max(0.0, 1.0 - d) ** 1.1
            noise = 0.55 + 0.45 * rng.random()
            a = base * noise
            v = int(min(255, a * 200))
            alpha = int(min(255, a * 210))
            img.putpixel((x, y), (v, v, v, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=4.0))
    return img


if __name__ == "__main__":
    specs = [
        ("circle_128.png",    make_circle(128)),
        ("slash_128x16.png",  make_slash(128, 16)),
        ("dust_64.png",       make_dust(64)),
        ("star_128.png",      make_star(128)),
        ("smoke_128.png",     make_smoke(128)),
    ]
    for name, img in specs:
        path = OUT / name
        img.save(path)
        print(f"저장: {path}  ({img.size})")
    print("완료.")
