# League of Legends — 모디파이어 스택과 적용 순서

> 리서치 일시: 2026-05-22
> 리서치 방법: 웹검색

## 요약

League of Legends(LoL)의 데미지 한 인스턴스는 크게 다음 순서로 처리된다:
**기본 데미지(base) + 비례/추가 데미지(ratio·bonus, 합연산) → 데미지 증폭/감소 모디파이어(곱연산) → 방어 관통/감소(armor·MR 가공) → 방어 공식 적용 → 체력 차감.**

핵심 설계 특징은 다음과 같다.

- **추가 데미지(bonus damage)는 합연산**으로 base damage에 더해진다. 즉 스킬 계수(AD·AP ratio)나 추가 피해는 한 인스턴스의 raw 값을 키운다.
- **데미지 모디파이어(증폭·감소)는 모두 곱연산**으로 적용된다. 여러 증폭/감소 효과가 동시에 걸려도 단순 합산이 아니라 각 배율을 곱한다(별도 명시가 없는 한). 따라서 증폭 소스를 쌓을수록 한계효용이 줄어든다(diminishing returns).
- **취약(Vulnerable)류 "받는 피해 증가" 디버프**도 데미지 모디파이어의 일종이며, 다른 증폭·감소와 곱연산으로 결합된다. 예: 정복자/집중공격(Press the Attack)의 8% 받는 피해 증가는 "모든 소스"의 데미지에 ×1.08로 곱해진다.
- **방어력 관통/감소는 (1) % 방어 감소 → (2) flat 방어 감소 → (3) % 관통 → (4) flat 관통(치명력)** 순서로 적용된다. % 끼리는 곱연산, flat 끼리는 합연산 성격이며, % 효과가 flat 효과보다 먼저 처리된다.
- LoL은 **곱연산 데미지 소스를 의도적으로 적게 두어** 수치 폭증(stat inflation)을 억제한다. 대부분의 빌드업은 합연산(추가 AD·AP, 추가 피해)이고, 곱연산은 소수의 증폭 룬·아이템·취약 디버프로 제한된다.

## 상세 내용

### 1. 데미지 계산 순서 (base → bonus → 증폭 → 방어/관통)

LoL의 데미지 한 인스턴스(autoattack·ability·item active)는 다음 단계를 거친다.

1. **기본 데미지 산출**: 스킬 base damage + 계수(AD/AP ratio)에서 나오는 값 + 조건부 추가 피해. 이 단계의 합산된 결과가 그 인스턴스의 raw(pre-mitigation) 데미지다.
2. **데미지 모디파이어 적용(곱연산)**: 가하는 쪽(outgoing)의 증폭/감소 버프, 받는 쪽(incoming)의 취약/경감 디버프가 raw 값에 배율로 곱해진다. 위키는 "데미지 모디파이어는 보너스 데미지를 *더하는* 것이 아니라 인스턴스 전체 데미지에 영향을 준다"고 명시한다. [출처](https://wiki.leagueoflegends.com/en-us/Damage_modifier)
3. **방어/관통 가공**: 대상의 armor(물리)·magic resist(마법)에 관통·감소 효과를 순서대로 적용해 "유효 저항(effective resistance)"을 산출한다.
4. **방어 공식 적용**: post-mitigation 데미지 = `물리 데미지 × [100 / (100 + Armor)]` (Armor ≥ 0인 경우), Armor가 음수면 `2 − 100 / (100 − Armor)`. 마법도 magic resist로 동일 형태. [출처](https://wiki.leagueoflegends.com/en-us/Damage)
5. **체력 차감**: 최종 값이 대상 체력에 직접 적용된다.

위키 Damage modifier 문서는, 받는 피해 디버프의 경우 "공격·스킬의 *최종 값*이 모디파이어로 증가/감소된 뒤 대상 체력에 직접 적용된다"고 설명한다. [출처](https://wiki.leagueoflegends.com/en-us/Damage_modifier)

### 2. 데미지 증폭(amplify) 효과끼리 — 곱연산

위키 Stacking / Damage modifier 문서는 명확히 규정한다:

> "All damage modifiers stack multiplicatively." (모든 데미지 모디파이어는 곱연산으로 누적된다.)
> 데미지 증폭은 데미지 감소와도 곱연산으로 누적된다(별도 명시가 없는 한).

[출처](https://wiki.leagueoflegends.com/en-us/Stacking) · [출처](https://wiki.leagueoflegends.com/en-us/Damage_modifier)

곱연산 누적은 각 소스의 배율을 곱해 계산한다. 위키 예시:

- 데미지 감소 10% 효과 두 개 → 0.9 × 0.9 = 0.81 → 실제 경감률은 19%(단순 합 20%가 아님). [출처](https://wiki.leagueoflegends.com/en-us/Stacking)
- 따라서 증폭도 마찬가지로, +10% 증폭 두 개는 1.1 × 1.1 = 1.21배(=+21%)이지 +20%가 아니다.

이로 인해 증폭 소스를 여러 개 쌓을수록 **한계효용이 감소(diminishing returns)** 한다. 단순 합연산이라면 무한히 선형 증가하지만, 곱연산이라 폭증이 완화된다.

### 3. 취약(Vulnerability)류 — 받는 피해 증가 디버프

"취약(Vulnerable)"은 대상이 **모든 소스로부터 받는 피해가 증가**하는 디버프로, 데미지 모디파이어의 incoming(받는 쪽) 케이스다.

대표 예시 — **정복자 룬 트리의 집중공격(Press the Attack)**:

> 적 챔피언에게 기본 공격 3회를 연속으로 적중시키면 추가 적응형 피해를 입히고 대상을 **취약(Vulnerable)** 상태로 만들어, 전투에서 벗어날 때까지 **모든 소스로부터 받는 피해를 8% 증가**시킨다.

[출처](https://wiki.leagueoflegends.com/en-us/Press_the_Attack)

이 8% 취약은 데미지 모디파이어이므로 다른 증폭·감소와 **곱연산**으로 결합된다. 즉 취약 대상에게 들어가는 모든 데미지 인스턴스의 최종 값에 ×1.08이 곱해진다. 위키 설명상 "받는 피해 디버프는 인스턴스의 최종 값을 모디파이어로 증가시킨 뒤 체력에 적용"하므로, base/bonus를 따로 늘리는 게 아니라 인스턴스 전체에 배율로 작용한다. [출처](https://wiki.leagueoflegends.com/en-us/Damage_modifier)

핵심 포인트:
- 취약은 "받는 쪽" 모디파이어 → 가하는 쪽 증폭과 곱연산으로 함께 곱해짐.
- 데미지 서브타입(물리/마법/고정)에 따라 특정 타입만 적용되는 모디파이어도 존재하지만, 취약(집중공격)은 "모든 소스"에 적용된다. [출처](https://wiki.leagueoflegends.com/en-us/Damage_modifier)

### 4. 방어력 관통(penetration)의 적용 순서

armor(또는 magic resist)에 대한 감소·관통 효과는 **고정된 순서**로 적용되며, 순서가 결과를 바꾼다. 위키 Armor penetration 문서 기준:

| 순서 | 효과 | 성격 |
|------|------|------|
| 1 | **% 방어 감소** (armor reduction, %) | 대상 실제 방어력을 깎음 |
| 2 | **flat 방어 감소** (armor reduction, flat) | 대상 실제 방어력을 깎음 |
| 3 | **% 방어 관통** (armor penetration, %) | 데미지 계산용으로만 방어력 감소 취급 |
| 4 | **flat 방어 관통 / 치명력(Lethality)** | 데미지 계산용으로만 방어력 감소 취급 |

[출처](https://wiki.leagueoflegends.com/en-us/Armor_penetration)

세부 규칙:

- **% 효과는 flat 효과보다 먼저** 적용된다. % 감소·관통은 base armor와 bonus armor 모두에 적용된다.
  - 예: base 20 + bonus 40 armor 대상에 30% 관통 → (20×0.7) + (40×0.7) = 42로 취급. [출처](https://wiki.leagueoflegends.com/en-us/Armor_penetration)
- **% 끼리는 곱연산**, **flat 끼리는 합연산** 성격이다(% 감소·관통 여러 개는 배율을 곱하고, flat 치명력·flat 감소는 더해진다).
- **방어 감소(reduction)와 방어 관통(penetration)의 차이**: 감소는 대상의 *실제* 방어력 수치를 변경한다(다른 아군 공격에도 영향). 관통은 *공격자 본인의 데미지 계산에만* 영향을 주고 대상의 실제 방어력은 그대로다. [출처](https://wiki.leagueoflegends.com/en-us/Armor_penetration)
- 관통으로 유효 방어력이 **음수가 될 수 없다**(0에서 멈춤). 단, 방어 *감소*는 실제 방어력을 음수로 만들 수 있고, 이때는 음수 방어 공식(`2 − 100/(100−Armor)`)으로 데미지가 증폭된다. [출처](https://wiki.leagueoflegends.com/en-us/Armor)
- 마법 관통(magic penetration)도 동일한 순서·규칙을 따른다. [출처](https://wiki.leagueoflegends.com/en-us/Magic_penetration)
- 위키 Damage 문서: 일부 flat 데미지 감소는 armor/MR 적용 *이후*에 처리되어, 저항이 높을수록 더 효율적이다. [출처](https://wiki.leagueoflegends.com/en-us/Damage)

### 5. 곱연산 소스를 적게 둔 설계 철학

LoL 시스템은 의도적으로 **곱연산 데미지 소스를 소수로 제한**하여 수치 폭증을 막는다.

- 데미지 빌드업의 대부분은 **합연산**이다: 추가 공격력(bonus AD)·주문력(AP)·스킬 계수·조건부 추가 피해는 한 인스턴스의 raw 값을 *더해서* 키운다. 위키 Stacking 문서는 "공격력 같은 대부분의 스탯은 합연산으로 누적"된다고 설명한다. [출처](https://wiki.leagueoflegends.com/en-us/Stacking)
- 반면 **곱연산은 데미지 모디파이어(증폭/감소)와 저항(armor·MR) 경감에 국한**된다. 위키: "퍼센트 데미지 모디파이어는 저항을 통한 데미지 감소와 곱연산으로 누적된다." [출처](https://wiki.leagueoflegends.com/en-us/Damage)
- 게임 내 순수 "데미지 증폭" 소스는 룬(예: 집중공격 취약 8%), 일부 챔피언 스킬, 소수 아이템 등으로 **개수 자체가 적다**. 곱연산은 쌓을수록 한계효용이 감소하므로, 소스를 적게 두면 한두 개로는 큰 폭증이 없고, 동시에 여러 개를 모두 갖추기도 어렵다.
- 결과적으로 LoL의 데미지 스케일링은 **주로 선형(합연산) 성장**을 따르며, 곱연산 레이어는 "보너스 한 겹"으로만 작동해 빌드 간 격차와 후반 수치 인플레이션을 완만하게 유지한다. (이는 위키에 기술된 합연산/곱연산 구분과 곱연산의 diminishing returns 특성에서 도출되는 설계 결과다. [출처](https://wiki.leagueoflegends.com/en-us/Stacking))

> 참고: Riot 개발자가 "곱연산을 적게 둔다"를 명시적으로 선언한 1차 출처는 이번 검색에서 확보하지 못했다. 위 항목은 위키에 문서화된 스택 규칙(합연산 위주의 스탯 + 소수의 곱연산 모디파이어, 곱연산의 한계효용 감소)에서 도출한 해석이다.

## 출처

- [Damage — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Damage)
- [Damage modifier — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Damage_modifier)
- [Stacking — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Stacking)
- [Armor penetration — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Armor_penetration)
- [Magic penetration — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Magic_penetration)
- [Armor — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Armor)
- [Press the Attack — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Press_the_Attack)
- [Ability damage — League of Legends Wiki](https://wiki.leagueoflegends.com/en-us/Ability_damage)
