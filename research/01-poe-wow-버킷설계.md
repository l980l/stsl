# Path of Exile & WoW — 모디파이어 버킷 설계
> 리서치 일시: 2026-05-22
> 리서치 방법: 웹검색

## 요약

- **Path of Exile**는 데미지 모디파이어를 두 종류로 나눈다. `increased/reduced`(증가/감소)는 모두 **하나의 풀에 합산**된 뒤 베이스에 **1회 곱연산**되고, `more/less`(더/덜)는 각각이 **독립적으로 연쇄 곱연산**된다.
- PoE의 데미지 계산 순서는 `base damage → added damage → increased(합산 풀) → more(연쇄 곱) → 크리티컬·DoT 등 추가 배수` 이다.
- `increased`는 합산되므로 쌓을수록 **체감 효율이 떨어지는 수확 체감**이 발생하고, `more`는 곱연산이라 항상 동일 비율로 작용한다. 이 이원 체계 덕에 GGG는 합산 모디파이어를 흔하게(가성비 낮게) 풀고 곱연산 모디파이어를 희소하게(서포트 젬·키스톤) 배치해 **수치 인플레이션을 통제**한다.
- **WoW**는 같은 종류/유사 효과의 버프·디버프는 **중첩되지 않고 최댓값만 적용**(예: Wing Clip + Hamstring → 50% 둘 중 큰 값)되며, **종류가 다른 모디파이어는 서로 곱연산**된다. 데미지 감소 역시 곱연산으로 누적되어 100% 감소가 수학적으로 불가능하다.
- 두 게임 모두 "곱연산 버킷을 잘게 나누고, 같은 버킷 안에서는 합산 또는 비중첩으로 묶는" 방식으로, 모디파이어를 무한정 합산해 폭발적으로 강해지는 것을 막아 밸런스를 유지한다.

## 상세 내용

### 1. Path of Exile — `increased` vs `more` 이원 모디파이어 체계

PoE의 모든 퍼센트 데미지 모디파이어는 두 부류로 명확히 구분된다.

- **`increased` / `reduced` (증가/감소)** — 적용 가능한 모든 출처가 **합산(additive)**된다. 예를 들어 `10% increased damage`가 두 개 있으면 `100% + 10% + 10% = 120%`가 되어 베이스에 한 번 곱해진다.
- **`more` / `less` (더/덜)** — 각 출처가 서로 **독립적으로 곱연산(multiplicative)**된다. `10% more damage`가 두 개면 `1.10 × 1.10 = 1.21`(= 121%)이 된다.

핵심 차이는 **수확 체감(diminishing returns)**이다. 이미 `increased`를 많이 쌓은 상태라면, `20% increased`를 추가해도 실제 데미지 증가율은 20%가 아니다. 예를 들어 합산 풀이 이미 1.2(=120%)일 때 20%p를 더해 1.4가 되면, 실제 증가폭은 `1.4 / 1.2 ≈ 1.1667`로 **16.67%에 불과**하다. 반면 `more`는 곱연산이므로 합산 풀 크기와 무관하게 항상 정확히 그 비율(예: 1.2배)로 작용한다. 이 때문에 동일 수치라면 `more`가 거의 항상 `increased`보다 강력하다.

플레이어에게는 보통 다음과 같이 설명된다. 베이스 데미지 1000에 장비·패시브가 각각 `100% increased`, 젬이 추가로 `100% increased`를 줄 경우 → 총 `300% increased`(합산) → 4000 데미지. 그러나 그 젬이 `100% more`였다면 → `200% increased` + `100% more` → `1000 × 3.0 × 2.0 = 6000` 데미지. 같은 "100%"라도 곱연산 버킷에 들어가면 결과가 크게 달라진다는 점을 구체적 예시로 가르친다.

**왜 이원 체계를 쓰는가:** 만약 모든 모디파이어가 합산이라면, 플레이어는 출처만 계속 늘려 선형(혹은 그 이상)으로 무한정 강해질 수 있다. PoE는 합산 모디파이어에 의도적으로 수확 체감을 부여해, 흔하고 값싼 `increased`는 마음껏 풀되 자연스럽게 효율이 떨어지게 만든다. 반대로 진짜 강력한 곱연산 `more`는 **서포트 젬, 키스톤 패시브** 등 희소하고 비용·트레이드오프가 있는 출처로만 제한해 빌드 설계의 핵심 의사결정 지점으로 만든다.

### 2. PoE 데미지 계산 순서 (Order of Operations)

데미지 계산은 다음 순서로 진행된다.

1. **Base Damage** — 공격은 무기 데미지, 주문은 젬 레벨 기반의 기본 데미지.
2. **Added Damage** — 장비·서포트가 주는 플랫(고정 수치) 추가 데미지. 로컬 모디파이어(무기에 붙은 대부분의 모디파이어)는 이 단계의 베이스에 먼저 적용된다.
3. **Increased / Reduced (합산 풀)** — 적용 가능한 모든 `increased`·`reduced`를 **하나로 합산**한 단일 배수를 만들어 베이스에 **1회 곱한다**.
4. **More / Less (연쇄 곱)** — 모든 `more`·`less` 출처를 **순차적으로 각각 곱한다**.
5. **추가 배수** — 크리티컬 스트라이크 배수, 도트(DoT) 배수 등 별도 곱셈 단계.

즉 개념적으로 `최종 = (base + added) × (1 + Σincreased) × Π(1 + more) × 기타배수` 형태다.

### 3. World of Warcraft — 모디파이어 분류와 곱연산 버킷

WoW는 PoE처럼 모디파이어 단어를 명시적으로 둘로 나누지는 않지만, **버프 종류(category)**를 기준으로 스택 규칙을 다르게 적용한다.

- **같은 종류 / 유사 효과는 비중첩 — 최댓값 적용:** 비슷하거나 동일한 효과(특히 디버프)는 동시에 적용되지 않는다. 예를 들어 Wing Clip과 Hamstring을 동시에 받아도 이동속도 감소는 합산 100%가 아니라 둘 중 **큰 값인 50%만** 적용된다. 같은 "버킷"의 효과끼리는 더해지지 않고 최댓값으로 묶이는 것이다.
- **다른 종류의 모디파이어는 서로 곱연산:** 종류가 다른 데미지 감소·증폭 효과는 합산이 아니라 **곱연산으로 누적**된다. 예를 들어 300k 타격에 40% 감소가 있으면 180k가 되고, 거기에 다시 20% 감소가 적용되면 이미 줄어든 값 기준으로 또 곱해져 144k가 된다.
- **데미지 감소의 곱연산은 의도된 안전장치:** 감소가 합산이라면 여러 효과를 모아 100% 감소(완전 무적)가 가능해진다. WoW는 감소를 곱연산으로 처리해(`1000 × 0.6 × 0.6 = 360`) 수학적으로 **100% 감소에 도달할 수 없게** 만든다.
- **Versatility(특화 능력치):** 데미지·치유 증가와 데미지 감소를 동시에 제공하는 2차 능력치. 1 Versatility는 대략 데미지·치유 0.20% 증가, 데미지 감소 0.10%를 준다(감소는 표기된 증가량의 절반). Versatility는 Mastery 등 다른 모디파이어와 **서로 곱연산**되어, 단순 합산보다 함께 쌓을 때 더 효율적이다.
- **스펙(전문화) 단위 곱연산 버킷:** Blizzard는 각 전문화의 상대적 위력을 조정하기 위해 **스펙 전체에 곱해지는 데미지 모디파이어 오라(aura)**를 둔다. 예: 비전 마법사 0%, 화염 마법사 -6%, 냉기 마법사 -19% 같은 식의 보정. 펫 데미지, 특정 대상 종류에 대한 데미지 등도 별도의 "Mod All Damage Done" 류 오라 버킷으로 관리된다.

요약하면 WoW의 곱연산 버킷은 대략 ① 같은 카테고리 버프(내부적으로 비중첩·최댓값) ② 서로 다른 카테고리 버프/디버프 간(곱연산) ③ 스펙·펫 등 시스템 레벨 보정 오라(별도 곱연산) 로 나뉜다.

### 4. 두 게임이 버킷 체계로 수치 인플레이션을 통제하는 방식

- **PoE:** 가성비 낮은 합산 풀(`increased`)에는 수확 체감을 걸어 흔하게 풀어도 무한 폭주하지 않게 하고, 강력한 곱연산(`more`)은 희소 자원으로 제한한다. 합산 풀은 "쌓을수록 효율이 떨어지는" 자연스러운 상한 역할을 하고, 곱연산은 빌드별 핵심 선택지로만 등장하므로, 신규 콘텐츠를 추가할 때도 대부분 `increased` 위주로 풀어 **선형적이고 예측 가능한 인플레이션**만 발생시킨다.
- **WoW:** 같은 종류 효과를 비중첩(최댓값)으로 묶어 "같은 버프를 여러 개 겹쳐 무한히 강해지는" 경로를 차단하고, 서로 다른 종류만 곱연산으로 허용해 조합 다양성은 유지하되 폭발적 누적은 막는다. 데미지 감소를 곱연산으로 강제해 100% 무적을 원천 봉쇄하고, 스펙 단위 보정 오라로 패치마다 전문화별 위력을 미세 조정한다.
- **공통 설계 철학:** 두 게임 모두 모디파이어를 **여러 개의 작은 버킷으로 분할**하고, 같은 버킷 안에서는 합산(PoE) 또는 비중첩(WoW)으로 묶으며, 버킷 사이는 곱연산으로 연결한다. 이렇게 하면 한 버킷이 아무리 커져도 전체 위력이 통제 가능한 범위에 머물러, 콘텐츠를 계속 추가하면서도 수치 인플레이션을 다룰 수 있다.

## 출처

- [Damage | PoE Wiki](https://www.poewiki.net/wiki/Damage)
- [Path of Exile Damage Guide for Beginners — Maxroll.gg](https://maxroll.gg/poe/getting-started/damage-for-beginners)
- [PoE 2 Guide: Full Order of Operations Damage & Defence — Mobalytics](https://mobalytics.gg/poe-2/guides/damage-defence-calc-order)
- [Increased damage vs more damage — Path of Exile Forum](https://www.pathofexile.com/forum/view-thread/320366)
- [Damage "more" Multipliers and their Interactions — Path of Exile Forum](https://www.pathofexile.com/forum/view-thread/1561128)
- [Stat — Path of Exile Wiki (Fandom)](https://pathofexile.fandom.com/wiki/Stat)
- [PoE More VS Increased — vhpg.com](http://www.vhpg.com/poe-more-vs-increased/)
- [Understanding Damage Stacks: Is Versatility Truly Multiplicative? — LevelUpTalk](https://leveluptalk.com/news/understanding-damage-stacks-versatility-explained/)
- [Stack — Wowpedia](https://wowpedia.fandom.com/wiki/Stack)
- [How do damage reducing CDs stack? — MMO-Champion](https://www.mmo-champion.com/threads/1083264-How-do-damage-reducing-CDs-stack)
- [Question about Versatility stacking? — World of Warcraft Forums](https://us.forums.blizzard.com/en/wow/t/question-about-versatility-stacking/95873)
- [Frost Mage Aura Damage Modifier — World of Warcraft Forums](https://us.forums.blizzard.com/en/wow/t/frost-mage-aura-damage-modifier/814066)
