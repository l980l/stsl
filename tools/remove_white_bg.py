#!/usr/bin/env python3
"""
흰 배경 제거 스크립트
엣지에서 BFS로 연결된 흰(또는 거의 흰) 픽셀만 투명으로 변환.
아이콘 내부의 흰색 영역은 검은 외곽선에 막혀 보호됨.

사용법 (프로젝트 루트에서):
  python tools/remove_white_bg.py                    # 전체 64종
  python tools/remove_white_bg.py --category status  # 상태이상만
  python tools/remove_white_bg.py --threshold 230    # 더 엄격한 기준
  python tools/remove_white_bg.py --dry-run          # 목록만 출력
"""

import argparse
import sys
from collections import deque
from pathlib import Path

import numpy as np
from PIL import Image


ICON_DIRS = {
    "status":  "assets/art/ui/status",
    "synergy": "assets/art/ui/synergy",
    "relic":   "assets/art/ui/relic",
}


def remove_bg(path: Path, threshold: int) -> bool:
    img = Image.open(path).convert("RGBA")
    data = np.array(img, dtype=np.uint8)

    r, g, b = data[:, :, 0], data[:, :, 1], data[:, :, 2]
    is_white = (r >= threshold) & (g >= threshold) & (b >= threshold)

    h, w = is_white.shape
    visited = np.zeros((h, w), dtype=bool)
    q: deque = deque()

    # 네 모서리 엣지에서 시드
    for x in range(w):
        for y in (0, h - 1):
            if is_white[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if is_white[y, x] and not visited[y, x]:
                visited[y, x] = True
                q.append((y, x))

    # BFS — 연결된 흰 픽셀만 방문
    while q:
        cy, cx = q.popleft()
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            ny, nx = cy + dy, cx + dx
            if 0 <= ny < h and 0 <= nx < w and not visited[ny, nx] and is_white[ny, nx]:
                visited[ny, nx] = True
                q.append((ny, nx))

    if not visited.any():
        return False  # 변경 없음

    data[visited, 3] = 0
    Image.fromarray(data).save(path)
    return True


def main():
    parser = argparse.ArgumentParser(description="흰 배경 → 투명 변환")
    parser.add_argument("--category", choices=["status", "synergy", "relic", "all"],
                        default="all")
    parser.add_argument("--threshold", type=int, default=240,
                        help="흰색 판정 기준 (0~255, 기본 240)")
    parser.add_argument("--dry-run", action="store_true",
                        help="목록만 출력, 실제 변환 안 함")
    args = parser.parse_args()

    cats = list(ICON_DIRS.keys()) if args.category == "all" else [args.category]
    paths = []
    for cat in cats:
        d = Path(ICON_DIRS[cat])
        if d.exists():
            paths.extend(sorted(d.glob("*.png")))

    print(f"대상 {len(paths)}개 (threshold={args.threshold}){' [dry-run]' if args.dry_run else ''}")

    changed = skipped = 0
    for p in paths:
        if args.dry_run:
            print(f"  {p}")
            continue
        ok = remove_bg(p, args.threshold)
        if ok:
            print(f"  변환: {p}")
            changed += 1
        else:
            print(f"  skip: {p} (흰 배경 없음)")
            skipped += 1

    if not args.dry_run:
        print(f"\n완료: 변환 {changed} / 변경없음 {skipped}")


if __name__ == "__main__":
    main()
