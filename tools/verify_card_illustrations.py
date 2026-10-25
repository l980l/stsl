"""카드 일러스트 파일명 매칭 검증 스크립트.

사용:
    python tools/verify_card_illustrations.py <일러스트_폴더_경로>

체크:
- 카드 216장 ↔ 일러스트 파일 1:1 매칭
- 누락 카드 / 잉여 일러스트 / 크기 불일치 보고
- 권장 해상도: 1024×906 (1.13:1)
"""
import re, sys
from pathlib import Path

EXPECTED_WIDTH = 1024
EXPECTED_HEIGHT = 906
EXPECTED_RATIO = EXPECTED_WIDTH / EXPECTED_HEIGHT  # 1.13

HEROES = [
    ('cleopatra',    'resources/cards/cards_cleopatra.gd'),
    ('napoleon',     'resources/cards/cards_napoleon.gd'),
    ('yi_sun_sin',   'resources/cards/cards_yi_sun_sin.gd'),
    ('joan_of_arc',  'resources/cards/cards_joan_of_arc.gd'),
    ('genghis_khan', 'resources/cards/cards_genghis_khan.gd'),
    ('musashi',      'resources/cards/cards_musashi.gd'),
]
NAME_PAT = re.compile(r'c\.card_name\s*=\s*"card\.([a-z_]+)\.([a-z_0-9]+)\.name"')


def collect_expected_files() -> set[str]:
    """cards_*.gd 에서 기대 파일명 stem 목록 추출."""
    expected = set()
    for owner_id, path in HEROES:
        code = Path(path).read_text(encoding='utf-8')
        for m in NAME_PAT.finditer(code):
            _, cid = m.groups()
            expected.add(f"{owner_id}_{cid}")
    return expected


def main() -> int:
    if len(sys.argv) < 2:
        print("Usage: python tools/verify_card_illustrations.py <art_folder>")
        return 1

    art_dir = Path(sys.argv[1])
    if not art_dir.is_dir():
        print(f"ERROR: not a directory: {art_dir}")
        return 1

    expected = collect_expected_files()
    actual = {f.stem: f for f in art_dir.glob('*.png')}

    matched = expected & set(actual.keys())
    missing = sorted(expected - set(actual.keys()))
    extra = sorted(set(actual.keys()) - expected)

    print(f"Expected cards: {len(expected)}")
    print(f"Found PNG files: {len(actual)}")
    print(f"Matched: {len(matched)}")
    print(f"Missing cards (no PNG): {len(missing)}")
    print(f"Extra PNG files (no matching card): {len(extra)}")

    if missing:
        print("\n--- MISSING ---")
        for m in missing:
            print(f"  needed: {m}.png")

    if extra:
        print("\n--- EXTRA (unused) ---")
        for e in extra:
            print(f"  extra: {e}.png")

    # 크기 검증 (Pillow 있을 때만)
    try:
        from PIL import Image
        size_mismatch = []
        for stem in sorted(matched):
            f = actual[stem]
            with Image.open(f) as im:
                if im.size != (EXPECTED_WIDTH, EXPECTED_HEIGHT):
                    size_mismatch.append((stem, im.size))
        if size_mismatch:
            print(f"\n--- SIZE MISMATCH ({len(size_mismatch)}) — expected {EXPECTED_WIDTH}×{EXPECTED_HEIGHT} ---")
            for stem, sz in size_mismatch[:30]:
                print(f"  {stem}.png: {sz[0]}×{sz[1]}")
        else:
            print(f"\nAll matched files are {EXPECTED_WIDTH}×{EXPECTED_HEIGHT} OK")
    except ImportError:
        print("\n(Pillow 미설치 — 크기 검증 skip. pip install Pillow 권장)")

    return 0 if not missing and not extra else 1


if __name__ == '__main__':
    sys.exit(main())
