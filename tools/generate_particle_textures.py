#!/usr/bin/env python3
"""BurstParticles2D 파티클 텍스처 PNG 생성 (PIL 기반).

사용법:
  python tools/generate_particle_textures.py

출력: addons/BurstParticles2D/extra/ 에 PNG 저장.
모두 흰색 grayscale + 알파 마스크 — BurstParticleGradientMap 셰이더가 그라디언트로 색 입힘.
"""

import math
from pathlib import Path
from PIL import Image, ImageFilter

OUT = Path(__file__).parent.parent / "addons" / "BurstParticles2D" / "extra"


def _save(img: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    path = OUT / name
    img.save(path, "PNG")
    print(f"  saved: {path}")


def make_slash_blade() -> None:
    """256×48 — 가로 검광 streak, 양 끝 페이드."""
    W, H = 256, 48
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cy = H // 2
    for x in range(W):
        t_x = x / (W - 1)
        edge_fade = math.sin(t_x * math.pi) ** 1.5
        for y in range(H):
            dy = abs(y - cy)
            blade_r, soft_r = 1.5, 5.0
            if dy < blade_r:
                vert = 1.0
            elif dy < soft_r:
                vert = 1.0 - ((dy - blade_r) / (soft_r - blade_r)) ** 2
            else:
                vert = 0.0
            alpha = int(edge_fade * vert * 255)
            if alpha > 0:
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.2))
    _save(img, "slash_blade_256x48.png")


def make_slash_arc() -> None:
    """192×96 — 곡선 호, 안쪽 밝음."""
    W, H = 192, 96
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cx, cy = W // 2, H + 10
    r_inner, r_outer = 60, 110
    arc_half = 55
    for y in range(H):
        for x in range(W):
            dx, dy = x - cx, y - cy
            r = math.sqrt(dx * dx + dy * dy)
            angle = math.degrees(math.atan2(-dy, dx))
            if r_inner <= r <= r_outer and abs(angle - 90) < arc_half:
                t_r = (r - r_inner) / (r_outer - r_inner)
                radial = 1.0 - t_r ** 1.4
                t_a = abs(angle - 90) / arc_half
                angular = 1.0 - t_a ** 1.2
                alpha = int(radial * angular * 220)
                if alpha > 0:
                    img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=2.5))
    _save(img, "slash_arc_192x96.png")


def make_spark_diamond() -> None:
    """24×24 — 4점 마름모."""
    S = 24
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    rx, ry = S / 2 - 0.5, S / 2 - 0.5
    for y in range(S):
        for x in range(S):
            dx, dy = abs(x - cx), abs(y - cy)
            t = dx / rx + dy / ry
            if t <= 1.0:
                alpha = int((1.0 - t) ** 0.6 * 255)
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
    _save(img, "spark_diamond_24.png")


def make_lensflare() -> None:
    """128×128 — 4갈래 광선 + 중심 원."""
    S = 128
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    ray_angles = [0, 90, 180, 270]
    ray_w = 10.0
    for y in range(S):
        for x in range(S):
            dx, dy = x - cx, y - cy
            r = math.sqrt(dx * dx + dy * dy)
            if r < 1:
                img.putpixel((x, y), (255, 255, 255, 255))
                continue
            angle = math.degrees(math.atan2(dy, dx)) % 360
            ray_v = 0.0
            for ra in ray_angles:
                diff = min(abs(angle - ra), 360 - abs(angle - ra))
                if diff < ray_w:
                    angular = 1.0 - (diff / ray_w) ** 1.5
                    radial = max(0.0, 1.0 - (r / cx) ** 0.7)
                    ray_v = max(ray_v, angular * radial)
            glow = max(0.0, 1.0 - (r / (cx * 0.25)) ** 1.5)
            v = min(1.0, ray_v + glow)
            alpha = int(v * 230)
            if alpha > 0:
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.5))
    _save(img, "lensflare_128.png")


# ── Phase B~G 텍스처 ─────────────────────────────────────────────────────────

def make_dust_chunk() -> None:
    """64×64 — 거친 흙먼지 덩어리 (blunt용)."""
    import random
    S = 64
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    rng = random.Random(42)
    for y in range(S):
        for x in range(S):
            r = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            t = max(0.0, 1.0 - r / (S * 0.42))
            alpha = int(t ** 1.2 * (0.7 + 0.3 * rng.random()) * 200)
            if alpha > 0:
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=2.0))
    _save(img, "dust_chunk_64.png")


def make_impact_ring() -> None:
    """192×192 — 충격 ring (blunt용)."""
    S = 192
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    r_mid, r_thick = S * 0.4, S * 0.06
    for y in range(S):
        for x in range(S):
            r = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            dist = abs(r - r_mid)
            if dist < r_thick:
                alpha = int((1.0 - (dist / r_thick) ** 1.5) * 220)
                if alpha > 0:
                    img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=2.5))
    _save(img, "impact_ring_192.png")


def make_bubble() -> None:
    """48×48 — 독 거품 (poison용)."""
    S = 48
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    r_out, r_in = S * 0.44, S * 0.31
    for y in range(S):
        for x in range(S):
            r = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if r <= r_out:
                ring_v = max(0.0, (r - r_in) / (r_out - r_in)) if r > r_in else 0.0
                ring_alpha = int(ring_v ** 0.7 * 200)
                hx, hy = cx - r_out * 0.3, cy - r_out * 0.3
                hr = math.sqrt((x - hx) ** 2 + (y - hy) ** 2)
                hilite = max(0.0, 1.0 - hr / (r_out * 0.35)) ** 2.5
                alpha = min(255, ring_alpha + int(hilite * 180))
                if alpha > 0:
                    img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
    _save(img, "bubble_48.png")


def make_star_burst() -> None:
    """128×128 — 8점 별 (divine용)."""
    S = 128
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    for y in range(S):
        for x in range(S):
            dx, dy = x - cx, y - cy
            r = math.sqrt(dx * dx + dy * dy)
            if r < 1:
                img.putpixel((x, y), (255, 255, 255, 255))
                continue
            angle = math.degrees(math.atan2(dy, dx)) % 360
            ray_v = 0.0
            for i in range(8):
                ra = i * 45
                diff = min(abs(angle - ra), 360 - abs(angle - ra))
                w = 8.0 if i % 2 == 0 else 4.0
                if diff < w:
                    angular = 1.0 - (diff / w) ** 1.5
                    radial = max(0.0, 1.0 - (r / (cx * 0.9)) ** 0.8)
                    ray_v = max(ray_v, angular * radial)
            glow = max(0.0, 1.0 - (r / (cx * 0.22)) ** 1.5)
            v = min(1.0, ray_v + glow)
            alpha = int(v * 230)
            if alpha > 0:
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.5))
    _save(img, "star_burst_128.png")


def make_holy_ray() -> None:
    """32×192 — 성광 세로 광선 (divine용)."""
    W, H = 32, 192
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cx = W / 2
    for y in range(H):
        edge_fade = math.sin(y / (H - 1) * math.pi) ** 1.2
        for x in range(W):
            vert = max(0.0, 1.0 - (abs(x - cx) / (W * 0.45)) ** 1.5)
            alpha = int(edge_fade * vert * 230)
            if alpha > 0:
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=1.0))
    _save(img, "holy_ray_192x32.png")


def make_smoke_chunk() -> None:
    """128×128 — 연기 구름 (explosive용)."""
    import random
    S = 128
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    rng = random.Random(7)
    for y in range(S):
        for x in range(S):
            r = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            t = max(0.0, 1.0 - r / (S * 0.46))
            alpha = int(t ** 0.85 * (0.55 + 0.45 * rng.random()) * 180)
            if alpha > 0:
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=4.0))
    _save(img, "smoke_chunk_128.png")


def make_shockring() -> None:
    """256×256 — 충격파 외곽 ring (explosive용)."""
    S = 256
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    r_mid, r_thick = S * 0.42, S * 0.05
    for y in range(S):
        for x in range(S):
            r = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            dist = abs(r - r_mid)
            if dist < r_thick:
                alpha = int((1.0 - (dist / r_thick) ** 1.5) * 200)
                if alpha > 0:
                    img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=3.0))
    _save(img, "shockring_256.png")


def make_trail_streak() -> None:
    """320×16 — 발사체 비행 트레일 (projectile용)."""
    W, H = 320, 16
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    cy = H // 2
    for x in range(W):
        t_x = x / (W - 1)
        edge_fade = t_x ** 0.5 * (1.0 - t_x ** 3)
        for y in range(H):
            dy = abs(y - cy)
            blade_r, soft_r = 1.5, 6.0
            if dy < blade_r:
                vert = 1.0
            elif dy < soft_r:
                vert = 1.0 - ((dy - blade_r) / (soft_r - blade_r)) ** 2
            else:
                vert = 0.0
            alpha = int(edge_fade * vert * 255)
            if alpha > 0:
                img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=0.8))
    _save(img, "trail_streak_320x16.png")


def make_vortex_arc() -> None:
    """192×192 — 회오리 호 (curse용)."""
    S = 192
    img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    cx, cy = S / 2, S / 2
    r_inner, r_outer = S * 0.22, S * 0.44
    for y in range(S):
        for x in range(S):
            r = math.sqrt((x - cx) ** 2 + (y - cy) ** 2)
            if r_inner <= r <= r_outer:
                t_r = (r - r_inner) / (r_outer - r_inner)
                alpha = int((1.0 - abs(t_r - 0.5) * 2.0) ** 0.8 * 200)
                if alpha > 0:
                    img.putpixel((x, y), (255, 255, 255, alpha))
    img = img.filter(ImageFilter.GaussianBlur(radius=2.5))
    _save(img, "vortex_arc_192.png")


if __name__ == "__main__":
    print("파티클 텍스처 생성 중...")

    print("\n[Phase A - slash]")
    make_slash_blade()
    make_slash_arc()
    make_spark_diamond()
    make_lensflare()

    print("\n[Phase B - blunt]")
    make_dust_chunk()
    make_impact_ring()

    print("\n[Phase C - poison]")
    make_bubble()

    print("\n[Phase D - divine]")
    make_star_burst()
    make_holy_ray()

    print("\n[Phase E - explosive]")
    make_smoke_chunk()
    make_shockring()

    print("\n[Phase F - projectile]")
    make_trail_streak()

    print("\n[Phase G - curse]")
    make_vortex_arc()

    print("\ndone.")
