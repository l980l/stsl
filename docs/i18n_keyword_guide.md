# i18n 키워드 사용 가이드

게임 텍스트 (카드 효과 desc, 시그니처 desc, 상태이상 툴팁 등) 에서 **raw 영어 단어를 다국어 column 에 직접 박지 않도록** 한 곳에서 키워드를 관리한다.

## 원칙

1. **한 단어 = 한 키**: 같은 의미의 게임 용어는 항상 같은 키로 참조.
2. **raw 영어 금지**: 한국어 (또는 다른 비영어) column 에 `ATTACK`, `vulnerable` 같은 영어 단어가 raw 로 들어가면 안 됨. 모두 `tr("...")` 결과로 합성.
3. **동적 합성**: desc 텍스트는 `%s` placeholder + `tr("키워드.X")` 합성. 호출처에서 `_trf(key, args)` 또는 `tr(key) % args`.

## namespace 분리

두 namespace 가 공존. 사용 목적이 다름:

### `status.X.name` — 상태이상/지속 효과 표시 이름

상태이상 아이콘, 툴팁, 효과 라벨에 직접 노출되는 이름. `_STATUS_NAME_KEYS` 맵 (effect_resource.gd) 이 이걸 lookup.

| 키 | 한국어 | 의미 |
|---|---|---|
| `status.weak.name` | 약화 | 공격력 감소 디버프 |
| `status.vulnerable.name` | 취약 | 받는 피해 증가 디버프 |
| `status.strength.name` | 강화 | 공격력 증가 버프 |
| `status.poison.name` | 독 | 매턴 피해 디버프 |
| `status.poison_dmg.name` | 독 | 독 피해 표시용 |
| `status.morale.name` | 사기 | 누적 버프 |
| `status.charm.name` | 매혹 | CC 디버프 |
| `status.enthrall.name` | 매혹됨 | 영구 매혹 상태 |
| `status.taunt.name` | 도발 | 대상 강제 |
| `status.invuln.name` | 결계 | 무적 |
| `status.counter_block.name` | 반격 방어 | 반격 시스템 |
| `status.counter_pool.name` | 반격 누적 | 반격 시스템 |
| `status.charm_resistance.name` | 매혹 저항 | 매혹 면역 |
| `status.marked_by.name` | 마킹 | 표적 마킹 |
| `status.death_rattle.name` | 사망 발동 | 사망 시 효과 |
| `status.speed_bonus.name` | 신속 | 속도 버프 |
| `status.heal_block.name` | 회복 차단 | 힐 무효 |
| `status.silence.name` | 침묵 | 카드 사용 불가 |

### `keyword.X` — 카드 동작/시스템 용어

카드 효과 desc / 시그니처 desc 안에서 합성용으로 참조하는 일반 동사/명사. 직접 상태이상 아이콘에는 매핑 안 됨.

| 키 | 한국어 | 의미 |
|---|---|---|
| `keyword.attack` | 공격 | 공격 카드 / 공격 시점 |
| `keyword.block` | 방어 | 방어도 부여 |
| `keyword.damage` | 피해 | 피해 효과 일반 |
| `keyword.heal` | 회복 | 체력 회복 |
| `keyword.sacrifice` | 희생 | 영웅/카드 희생 |
| `keyword.draw` | 드로우 | 카드 뽑기 |
| `keyword.discard` | 버리기 | 패에서 버리기 |
| `keyword.exhaust` | 소멸 | 카드 소멸 |
| `keyword.summon` | 소환 | 토큰/유닛 소환 |

## 새 desc 작성 가이드

### ❌ 금지 — raw 영어 박기

```csv
# bad
signature.egyptian.desc,저주 누적 — ATTACK 시 영웅에 vulnerable +1 자동,...
```

### ✅ 권장 — placeholder + 합성

CSV:
```csv
signature.egyptian.desc,저주 누적 — %s 시 영웅에 %s +1 자동,Eternal Curse — On %s: target hero gets %s +1.,...
```

코드 (호출처):
```gdscript
var args := [tr("keyword.attack"), tr("status.vulnerable.name")]
tooltip = _trf("signature.egyptian.desc", args)
```

## 키 선택 규칙

새 desc 작성 시 어떤 namespace 를 쓸지:

- **상태이상/지속 효과 이름** (예: 약화, 취약, 강화) → `status.X.name`
- **카드 동작 동사** (예: 공격, 방어, 드로우) → `keyword.X`
- **둘 다 해당** (예: heal — 효과 동사 + 회복 효과 자체 — 효과 동사가 더 일반적) → `keyword.heal`

기존에 있는 키는 절대 중복 등록하지 말 것. 추가 시 이 문서에 행 추가.

## 신규 키 추가 절차

1. `resources/translations/strings_status.csv` (또는 적절한 strings_*.csv) 에 14언어 column 모두 채워서 추가.
2. 이 문서의 표에 행 추가.
3. desc 에서 사용 시 `tr("keyword.X")` 로 참조.
4. `--import` 로 reimport (CSV 변경 후 .translation 캐시 갱신).

## 호출처 패턴 (battle_scene.gd 예시)

```gdscript
# signature.X.desc 용 args
func _signature_desc_args(mythology: String) -> Array:
    match mythology:
        "greek", "norse":
            return [tr("status.strength.name")]
        "egyptian":
            return [tr("keyword.attack"), tr("status.vulnerable.name")]
        "daoist":
            return [tr("status.strength.name"), tr("keyword.block")]
        "japanese":
            return [tr("keyword.block")]
        _:
            return []

# 호출
SacredTheme.attach_tooltip(sig_lbl, _trf("signature.%s.desc" % mythology, _signature_desc_args(mythology)))
```
