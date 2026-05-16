#!/usr/bin/env python3
# tools/trim_svg_viewbox.py
# SVG 파일들의 viewBox 를 실제 콘텐츠 BBox 로 줄임 (여백 제거).
# split 쌍 (예: cypress_a_trunk + cypress_a_leaves, altar_norse_a_base + altar_norse_a_flame)
# 은 두 SVG 의 BBox 합집합으로 같은 viewBox 적용 (정렬 유지).
# 콘텐츠 좌표는 그대로 — viewBox 의 min-x/min-y 변경으로 SVG 표준상 자동 shift.
# 출력: OBJECT_SIZE 자동 갱신용 dict (stdout).

import glob, os, re
from collections import defaultdict

SVG_DIRS = [
    "assets/art/backgrounds/objects/greek",
    "assets/art/backgrounds/objects/norse",
    "assets/art/backgrounds/objects/egyptian",
    "assets/art/backgrounds/objects/buddhist",
]

def parse_path_coords(d):
    """path d 의 모든 숫자 좌표 (x, y) 쌍 반환. 상대/절대 구분 없이 단순 추출."""
    coords = re.findall(r'[-+]?\d*\.?\d+', d)
    nums = list(map(float, coords))
    return list(zip(nums[0::2], nums[1::2]))

def parse_points(pts):
    """polygon/polyline points 의 (x, y) 쌍."""
    nums = list(map(float, re.findall(r'[-+]?\d*\.?\d+', pts)))
    return list(zip(nums[0::2], nums[1::2]))

def get_float(attrs, key, default=0.0):
    return float(attrs.get(key, default))

def element_bbox(tag, attrs):
    """element 의 (min_x, min_y, max_x, max_y) 반환. None 이면 무시."""
    sw = get_float(attrs, "stroke-width") if "stroke" in attrs else 0.0
    half = sw / 2.0
    if tag == "rect":
        x = get_float(attrs, "x"); y = get_float(attrs, "y")
        w = get_float(attrs, "width"); h = get_float(attrs, "height")
        return (x - half, y - half, x + w + half, y + h + half)
    if tag == "circle":
        cx = get_float(attrs, "cx"); cy = get_float(attrs, "cy"); r = get_float(attrs, "r")
        return (cx - r - half, cy - r - half, cx + r + half, cy + r + half)
    if tag == "ellipse":
        cx = get_float(attrs, "cx"); cy = get_float(attrs, "cy")
        rx = get_float(attrs, "rx"); ry = get_float(attrs, "ry")
        return (cx - rx - half, cy - ry - half, cx + rx + half, cy + ry + half)
    if tag == "line":
        x1 = get_float(attrs, "x1"); y1 = get_float(attrs, "y1")
        x2 = get_float(attrs, "x2"); y2 = get_float(attrs, "y2")
        return (min(x1, x2) - half, min(y1, y2) - half, max(x1, x2) + half, max(y1, y2) + half)
    if tag == "path":
        pts = parse_path_coords(attrs.get("d", ""))
        if not pts: return None
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
        return (min(xs) - half, min(ys) - half, max(xs) + half, max(ys) + half)
    if tag == "polygon" or tag == "polyline":
        pts = parse_points(attrs.get("points", ""))
        if not pts: return None
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
        return (min(xs) - half, min(ys) - half, max(xs) + half, max(ys) + half)
    return None

# 모든 element + attr 추출 (정규식 — XML parser 안 쓰고 단순)
ELEM_RE = re.compile(r'<(rect|circle|ellipse|line|path|polygon|polyline)\b([^/>]*)/?>', re.DOTALL)
ATTR_RE = re.compile(r'(\S+?)\s*=\s*"([^"]*)"')

def svg_bbox(text):
    """SVG text 의 모든 element 의 BBox 합집합 반환. (min_x, min_y, max_x, max_y)"""
    boxes = []
    for m in ELEM_RE.finditer(text):
        tag = m.group(1)
        attrs = dict(ATTR_RE.findall(m.group(2)))
        bb = element_bbox(tag, attrs)
        if bb is None: continue
        boxes.append(bb)
    if not boxes:
        return None
    min_x = min(b[0] for b in boxes)
    min_y = min(b[1] for b in boxes)
    max_x = max(b[2] for b in boxes)
    max_y = max(b[3] for b in boxes)
    return (min_x, min_y, max_x, max_y)

def split_pair_key(filename):
    """split 쌍 (trunk+leaves, base+flame) 의 그룹 key 반환. 단일 SVG 면 None."""
    base = os.path.splitext(filename)[0]
    for suffix in ["_trunk", "_leaves", "_base", "_flame"]:
        if base.endswith(suffix):
            return base[:-len(suffix)]
    return None

def update_viewbox(text, new_vb):
    """SVG 의 viewBox + width + height 를 new_vb (min_x, min_y, w, h) 로 갱신."""
    vb_str = f"{new_vb[0]:g} {new_vb[1]:g} {new_vb[2]:g} {new_vb[3]:g}"
    text = re.sub(r'viewBox="[^"]*"', f'viewBox="{vb_str}"', text)
    text = re.sub(r'\bwidth="[^"]*"', f'width="{new_vb[2]:g}"', text, count=1)
    text = re.sub(r'\bheight="[^"]*"', f'height="{new_vb[3]:g}"', text, count=1)
    return text

def main():
    # 1) 모든 SVG 의 BBox 측정
    svg_data = {}  # path -> (text, bbox)
    for d in SVG_DIRS:
        for path in sorted(glob.glob(f"{d}/*.svg")):
            with open(path, "r", encoding="utf-8") as f:
                text = f.read()
            # g transform 사용 시 (flower/edelweiss/egypt_lotus 등) — script 가 local 좌표
            # 만 보고 BBox 계산하면 음수 viewBox 됨. skip.
            if re.search(r'<g\s+transform=', text):
                print(f"  SKIP (has g transform): {path}")
                continue
            bb = svg_bbox(text)
            if bb is None:
                print(f"  SKIP (no elements): {path}")
                continue
            svg_data[path] = (text, bb)

    # 2) split 쌍 그룹화 (같은 base name + 같은 dir)
    groups = defaultdict(list)  # (dir, base_key) -> [path,...]
    singles = []  # split 아닌 SVG path
    for path in svg_data:
        d = os.path.dirname(path)
        fn = os.path.basename(path)
        key = split_pair_key(fn)
        if key:
            groups[(d, key)].append(path)
        else:
            singles.append(path)

    # 3) 그룹별 BBox 합집합 → 같은 viewBox 적용
    updates = {}  # path -> new_vb
    for grp_paths in groups.values():
        bbs = [svg_data[p][1] for p in grp_paths]
        min_x = min(b[0] for b in bbs)
        min_y = min(b[1] for b in bbs)
        max_x = max(b[2] for b in bbs)
        max_y = max(b[3] for b in bbs)
        new_vb = (min_x, min_y, max_x - min_x, max_y - min_y)
        for p in grp_paths:
            updates[p] = new_vb

    # 4) 단일 SVG — 각자 BBox
    for p in singles:
        bb = svg_data[p][1]
        updates[p] = (bb[0], bb[1], bb[2] - bb[0], bb[3] - bb[1])

    # 5) 파일 쓰기
    for path, new_vb in updates.items():
        text = svg_data[path][0]
        new_text = update_viewbox(text, new_vb)
        if new_text != text:
            with open(path, "w", encoding="utf-8") as f:
                f.write(new_text)

    # 6) OBJECT_SIZE 갱신용 dict 출력
    print("\n# === OBJECT_SIZE 갱신 (scene_background.gd) ===")
    # base name 별로 viewBox width/height 추출 (같은 base 의 모든 variant 가 같은 viewBox 보장)
    by_base = defaultdict(list)
    for path, vb in updates.items():
        fn = os.path.basename(path)
        base_no_ext = os.path.splitext(fn)[0]
        # split suffix 제거 — OBJECT_SIZE 의 key 는 base name (예: cypress_a)
        for suffix in ["_trunk", "_leaves", "_base", "_flame"]:
            if base_no_ext.endswith(suffix):
                base_no_ext = base_no_ext[:-len(suffix)]
                break
        by_base[base_no_ext].append((vb[2], vb[3]))

    for base in sorted(by_base):
        sizes = by_base[base]
        # 같은 base 의 모든 variant 가 같은 크기여야 — assert
        w, h = sizes[0]
        print(f'\t"{base}":'.ljust(28) + f' Vector2({w:g}, {h:g}),')

    print(f"\nModified {len(updates)} SVG files.")

if __name__ == "__main__":
    main()
