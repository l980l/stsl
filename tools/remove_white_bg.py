#!/usr/bin/env python3
"""
배경 제거 스크립트 (흰색 + 검은색 모두 지원)
엣지에서 BFS로 연결된 배경 픽셀만 투명으로 변환.
아이콘 내부 동일 색상 영역은 외곽선에 막혀 보호됨.

사용법 (프로젝트 루트에서):
  python tools/remove_white_bg.py                    # 전체 64종 (자동 감지)
  python tools/remove_white_bg.py --category status  # 상태이상만
  python tools/remove_white_bg.py --threshold 230    # 더 엄격한 기준
  python tools/remove_white_bg.py --bg white         # 흰 배경만
  python tools/remove_white_bg.py --bg black         # 검은 배경만
  python tools/remove_white_bg.py --dry-run          # 목록만 출력
"""

import argparse
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


ICON_DIRS = {
    "status":  "assets/art/ui/status",
    "synergy": "assets/art/ui/synergy",
    "relic":   "assets/art/ui/relic",
}


def _detect_bg(data: np.ndarray) -> str:
    h, w = data.shape[:2]
    corners = [
        data[0, 0, :3], data[0, w - 1, :3],
        data[h - 1, 0, :3], data[h - 1, w - 1, :3],
    ]
    avg = np.mean([c.mean() for c in corners])
    return "black" if avg < 128 else "white"


def remove_bg(path: Path, threshold: int, bg: str = "auto") -> bool:
    img = Image.open(path).convert("RGBA")
    data = np.array(img, dtype=np.uint8)

    detected = _detect_bg(data) if bg == "auto" else bg

    r, g, b = data[:, :, 0], data[:, :, 1], data[:, :, 2]
    if detected == "black":
        dark = 255 - threshold  # threshold=240 → dark<=15
        is_bg = (r <= dark) & (g <= dark) & (b <= dark)
    else:
        is_bg = (r >= threshold) & (g >= threshold) & (b >= threshold)

    h, w = is_bg.shape
    visited = np.zeros((h, w), dtype=bool)
    q: deque = deque()

    for x in range(w):
        for y in (0, h - 1):
            if is_bg[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if is_bg[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))

    while q:
        cy, cx = q.popleft()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_bg[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    if not visited.any():
        return False

    data[visited, 3] = 0
    Image.fromarray(data).save(path)
    return True


def main():
    parser = argparse.ArgumentParser(description="흰색/검은색 배경 → 투명 변환")
    parser.add_argument("--category", choices=["status", "synergy", "relic", "all"],
                        default="all")
    parser.add_argument("--threshold", type=int, default=240,
                        help="배경 판정 기준 (0~255, 기본 240)")
    parser.add_argument("--bg", choices=["auto", "white", "black"], default="auto",
                        help="배경 색상 (기본: auto — 코너 픽셀로 자동 감지)")
    parser.add_argument("--dry-run", action="store_true",
                        help="목록만 출력, 실제 변환 안 함")
    args = parser.parse_args()

    cats = list(ICON_DIRS.keys()) if args.category == "all" else [args.category]
    paths = []
    for cat in cats:
        d = Path(ICON_DIRS[cat])
        if d.exists():
            paths.extend(sorted(d.glob("*.png")))

    print(f"대상 {len(paths)}개 (threshold={args.threshold}, bg={args.bg})"
          f"{' [dry-run]' if args.dry_run else ''}")

    changed = skipped = 0
    for p in paths:
        if args.dry_run:
            print(f"  {p}")
            continue
        ok = remove_bg(p, args.threshold, args.bg)
        if ok:
            print(f"  변환: {p}")
            changed += 1
        else:
            print(f"  skip: {p}")
            skipped += 1

    if not args.dry_run:
        print(f"\n완료: 변환 {changed} / 변경없음 {skipped}")


if __name__ == "__main__":
    main()
