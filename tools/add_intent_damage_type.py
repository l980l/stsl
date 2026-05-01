"""
적 인텐트에 damage_type을 일괄 추가하는 스크립트.
각 적(static func) 단위로 모든 ATTACK 인텐트에 동일한 damage_type을 부여한다.
"""

import re
from pathlib import Path

# 적 함수명 -> damage_type 매핑
ENEMY_TYPE_MAP = {
    # ─── Greek ───
    # normals
    "satyr": "blunt",
    "harpy": "slash",
    "cyclops": "blunt",
    "snake": "poison",
    "cerberus": "slash",  # normals 케르베로스
    "myrmidon": "slash",
    # act1
    "minotaur": "blunt",
    "medusa": "curse",
    "gorgon": "slash",
    "scylla": "slash",
    "hydra": "poison",
    # act2 (cerberus는 normals와 같은 이름이지만 act2 파일에 있음 - 같은 type 사용)
    "charon": "curse",
    "erinyes": "curse",
    "hades": "curse",
    # act3
    "ares_hound": "slash",
    "poseidon_apostle": "blunt",
    "hephaestus_automaton": "explosive",
    "kronos": "divine",

    # ─── Japanese ───
    # normals
    "oni": "blunt",
    "tengu": "slash",
    "yuki_onna": "ice",
    "kappa": "blunt",
    "shuten_minion": "blunt",
    "ronin_ghost": "slash",
    # act1
    "oni_general": "blunt",
    "yamamba": "curse",
    "invincible_ronin": "slash",
    "raijin": "lightning",
    # act2
    "chaos_tengu": "slash",
    "yasha": "slash",
    "nureriyon": "curse",
    "shuten_doji": "blunt",
    # act3
    "iwato_guardian": "divine",
    "susanoo_blade": "lightning",
    "blizzard_queen": "ice",
    "yamata_no_orochi": "poison",

    # ─── Norse ───
    # normals
    "draugr": "slash",
    "urdr_spider": "poison",
    "jotun_soldier": "blunt",
    "volva_witch": "curse",
    "hrimfaxi_rider": "blunt",
    "garlarr_snake": "poison",
    # act1
    "nidhogg_larva": "poison",
    "skoll": "slash",
    "hrimthurs_scout": "ice",
    "fjorgynn": "divine",
    # act2
    "troll_warrior": "blunt",
    "norn": "divine",
    "vanir_elf": "projectile",
    "surtr": "fire",
    # act3
    "fenrir_cub": "slash",
    "valkyrie": "slash",
    "jormungandr_shard": "poison",
    "jormungandr": "poison",

    # ─── Chinese ───
    # normals
    "yaksha": "slash",
    "nezha_soldier": "slash",
    "heavenly_king_soldier": "slash",
    "shanhaijing_beast": "slash",
    "immortal_trainee": "divine",
    "azure_dragon_guard": "slash",
    # act1
    "golden_horn_king": "divine",
    "silver_horn_king": "divine",
    "black_wind_demon": "curse",
    "chiyou": "blunt",
    # act2
    "red_boy": "fire",
    "nine_dragon_general": "divine",
    "heavenly_hound_brothers": "slash",
    "erlang_shen": "divine",
    # act3
    "white_tiger_general": "slash",
    "vermilion_bird_general": "fire",
    "black_tortoise_general": "blunt",
    "pangu": "divine",

    # ─── Egyptian ───
    # normals
    "sand_scout": "projectile",
    "desert_scorpion": "poison",
    "mummy_warrior": "blunt",
    "sphinx_cub": "slash",
    "sand_ifrit": "fire",
    "ka_spirit": "curse",
    # act1
    "jackal_warrior": "slash",
    "scarab_queen": "poison",
    "obelisk_guardian": "divine",
    "sekhmet": "blunt",
    # act2
    "apep_snake": "poison",
    "seth_hound": "slash",
    "ba_bird": "projectile",
    "osiris": "divine",
    # act3
    "apophis_serpent": "poison",
    "set_tempest": "lightning",
    "isis_phantom": "divine",
    "ra_horakhty": "divine",

    # ─── Korean ───
    # normals
    "death_reaper": "slash",
    "cheoyong": "divine",
    "dokkaebi": "blunt",
    "three_legged_crow": "fire",
    "gumiho": "curse",
    "bulgasari": "blunt",
    # act1
    "haechi": "divine",
    "jangseung": "blunt",
    "haemosu": "divine",
    "dangun": "divine",
    # act2
    "dokkaebi_chief": "blunt",
    "sea_dragon_general": "divine",
    "dongmyeong": "divine",
    "samsin_grandma": "divine",
    # act3
    "underworld_judge": "curse",
    "gat_spirit": "curse",
    "cheoyong_god": "divine",
    "gusamseung_halmang": "divine",
}

# `i1.target = IntentRes.TargetType.RANDOM` 으로 끝나는 ATTACK 인텐트 라인 매칭
# 이미 damage_type이 있으면 매칭 안 됨
ATTACK_LINE_RE = re.compile(
    r'^(?P<indent>\s*)'
    r'(?P<var>\w+)\.action_type = IntentRes\.ActionType\.ATTACK;\s*'
    r'(?P=var)\.value = -?\d+;\s*'
    r'(?P=var)\.target = IntentRes\.TargetType\.\w+\s*$'
)

FUNC_RE = re.compile(r'^static func (\w+)\(')


def update_file(path: Path) -> tuple[int, int]:
    """파일 갱신. (수정한 라인 수, 처리 못한 ATTACK 라인 수) 반환."""
    lines = path.read_text(encoding='utf-8').splitlines(keepends=True)
    out: list[str] = []
    current_func: str | None = None
    modified = 0
    skipped = 0

    for line in lines:
        fm = FUNC_RE.match(line)
        if fm:
            current_func = fm.group(1)

        if current_func and current_func in ENEMY_TYPE_MAP:
            am = ATTACK_LINE_RE.match(line.rstrip('\n').rstrip('\r'))
            if am and 'damage_type' not in line:
                dtype = ENEMY_TYPE_MAP[current_func]
                var = am.group('var')
                stripped = line.rstrip('\n').rstrip('\r').rstrip()
                # 줄 끝 newline 보존
                ending = line[len(line.rstrip('\n').rstrip('\r')):]
                line = f'{stripped}; {var}.damage_type = "{dtype}"{ending}'
                modified += 1
            elif current_func in ENEMY_TYPE_MAP and 'action_type = IntentRes.ActionType.ATTACK' in line and 'damage_type' not in line:
                skipped += 1

        out.append(line)

    path.write_text(''.join(out), encoding='utf-8')
    return modified, skipped


def main():
    root = Path(__file__).resolve().parent.parent / 'resources' / 'enemies'
    total_mod = 0
    total_skip = 0
    for gd_file in sorted(root.rglob('*.gd')):
        mod, skip = update_file(gd_file)
        if mod or skip:
            print(f'{gd_file.relative_to(root)}: +{mod} damage_type'
                  + (f' (SKIPPED {skip} unmatched ATTACK lines)' if skip else ''))
            total_mod += mod
            total_skip += skip
    print(f'\nTotal: +{total_mod} damage_type lines')
    if total_skip:
        print(f'WARN: {total_skip} ATTACK lines skipped (unexpected format)')


if __name__ == '__main__':
    main()
