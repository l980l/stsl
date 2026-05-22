# 메이플스토리·한국 RPG — 데미지 공식과 스탯 표기

> 리서치 일시: 2026-05-22
> 리서치 방법: 웹검색

## 요약

메이플스토리의 데미지 공식은 **여러 개의 독립된 "버킷(bucket)"** 으로 구성되며, 각 버킷은 곱연산으로 합쳐지지만 **버킷 내부는 합연산** 으로 누적된다는 점이 핵심이다.

- **데미지%(뎀퍼)·보스 데미지%(보공)·크리티컬 데미지%(크뎀)** 는 각각의 카테고리(버킷) 안에서 여러 소스가 단순히 **더해지는 합산 풀(additive pool)** 이다. 누적될수록 효율이 점점 떨어진다(체감 효율 감소).
- **최종 데미지%(최뎀)** 는 다른 데미지%와 합쳐지지 않고, 소스마다 **독립적으로 곱해지는 별도 버킷**이다. `(1+최뎀1)×(1+최뎀2)×…` 형태로 곱연산되어 효율 감소 없이 그대로 반영된다.
- **방어율 무시(방무)** 는 합산되지 않고 `1−(1−a)(1−b)(1−c)…` 형태의 곱연산으로 합성된다. 그래서 아무리 많이 쌓아도 100%에 도달할 수 없다.
- 전체 데미지 공식은 대략 `스탯 × 무기상수 × 공격력 × (1+데미지%+보스데미지%) × (1+최종데미지%) × 방무보정 × (1+크리티컬데미지%) × 속성내성` 순으로 곱해진다 — 버킷끼리는 곱, 버킷 안은 합.
- 인게임 스탯창은 "데미지"와 "최종 데미지"를 **별도 항목으로 분리 표시**하여, 합산 스탯과 곱연산 스탯이 다른 종류임을 UI 차원에서 구분해 준다.
- 한국 게이머의 멘탈 모델: "**뎀퍼는 쌓을수록 효율이 떨어지고, 최뎀은 효율 감소가 없다**" 가 정설로 통하며, 표기에서도 "%p(퍼센트 포인트, 합산)" vs "%(곱연산 증가율)"을 구분한다.

## 상세 내용

### 1. 데미지%(뎀퍼) — 합산 풀(additive pool)

스탯창의 "데미지"는 조건 없이 모든 몬스터에게 적용되는 피해 증가 수치이다. 여러 장비·잠재·버프에서 오는 데미지% 소스는 **하나의 풀로 전부 더해진다**.

- 영문 위키 설명: "%damage and % damage vs boss stack additively with other sources of %damage/% damage vs boss" — 즉 데미지%와 보스 데미지% 소스는 같은 카테고리 안에서 서로 합산된다. ([StrategyWiki - MapleStory/Formulas](https://strategywiki.org/wiki/MapleStory/Formulas))
- 한국 커뮤니티 설명: "데미지와 보스데미지는 덧셈연산입니다. 데미지 50%, 보스데미지 130%일 때 일반몹 = 100% + 50% = 150%, 보스몹 = 100% + 50% + 130% = 280%". ([에펨코리아 - 메이플스토리 데미지 공식 총정리](https://www.fmkorea.com/8336709224))
- 합산이기 때문에 누적될수록 **체감 효율이 감소**한다. 예: 데미지 100%인 상태에서 +10%는 전체의 1.1배 증가지만, 데미지 300%에서 +10%는 4.0→4.1배로 증가폭 비중이 작아진다. ([나무위키 - 메이플스토리/스탯](https://namu.wiki/w/메이플스토리/스탯))

### 2. 최종 데미지%(최뎀) — 독립 곱연산 버킷

최종 데미지는 다른 데미지%와 같은 풀에 들어가지 않는다. **모든 계산이 끝난 뒤 맨 마지막에 곱해지는 별도 배율**이다.

- 영문 위키: "final damage sources stack multiplicatively: `(1 + 최뎀1) × (1 + 최뎀2) × (1 + 최뎀3) × …`". 데미지%(dmg%)는 하나의 곱연산 인자 `(1 + dmg% + bd%)` 안에서 더해지지만, 최종 데미지(fd%)는 `(1 + fd%)`라는 **별도의 곱연산 인자**로 떨어져 나온다. ([MapleStory Wiki - Damage Formula](https://maplestorywiki.net/w/Damage_Formula), [MapleWiki Fandom - Damage Formula](https://maplestory.fandom.com/wiki/Damage_Formula))
- 한국 커뮤니티: "최종데미지는 다 계산한 뒤에 제일 나중에 곱하는 곱연산. 데미지 50%, 보스 130%, 최종뎀 30%면 150% × 1.3 = 195%". ([에펨코리아 - 메이플스토리 데미지 공식 총정리](https://www.fmkorea.com/8336709224))
- 최종 데미지는 소스마다 따로 곱해지므로 **효율 감소 없이 증가 수치가 그대로 반영**된다. "공퍼·뎀퍼는 스펙업을 할수록 효율이 감소하지만 최종데미지는 효율 감소 없이 그대로 반영되어 가장 좋은 수치"로 평가된다. ([인벤 - 최종데미지 계산식 원리](https://www.inven.co.kr/board/maple/2304/26987), [나무위키 - 메이플스토리/스탯](https://namu.wiki/w/메이플스토리/스탯))

**데미지% vs 최종데미지%의 차이 요약**

| 구분 | 데미지%(뎀퍼) | 최종 데미지%(최뎀) |
|---|---|---|
| 합성 방식 | 같은 풀에 합산(additive) | 소스마다 독립 곱연산(multiplicative) |
| 공식 위치 | `(1 + 데미지% + 보스데미지%)` 인자 안 | `(1 + 최종데미지%)` 별도 인자 |
| 효율 추이 | 누적할수록 체감 효율 감소 | 효율 감소 없이 그대로 반영 |
| 희소성 | 흔한 옵션 | 희귀·고가치 옵션 |

### 3. 방어율 무시(방무) — 곱연산 합성

방어율 무시는 합산되지 않는다. 각 방무 소스는 `1 − (1 − a)(1 − b)(1 − c)…` 형태로 합성된다.

- 합성 공식: `(1 − (1−a%) × (1−b%) × (1−c%) × …) × 100`. 예시: 방무 60%/40%/30%/20% → `(1−0.6)(1−0.4)(1−0.3)(1−0.2) = 0.1344` → 실방무 `100 − 13.44 = 86.56%`. ([인벤 - 아주 쉬운 방무 계산법](https://www.inven.co.kr/board/maple/2304/27115), [나무위키 - 메이플스토리/스탯](https://namu.wiki/w/메이플스토리/스탯))
- 두 소스 합성을 전개하면 `1 − (1−I₁)(1−I₂) = I₁ + I₂ − I₁I₂` 로, 단순 덧셈보다 항상 작다. 이것이 **수확 체감(diminishing returns)** 의 수학적 근거다. ([MapleStory Forums - How does IED work?](https://forums.maplestory.nexon.net/discussion/18108/how-does-ied-work))
- 적에게 적용될 때 데미지 공식의 방어 보정 항은 `1 − PDR × (1 − IED)` 형태이다(PDR = 적의 방어율). ([Grandis Library - Stat Terms](https://grandislibrary.com/content/stat-terms))
- 넥슨이 방무를 곱연산으로 설계한 이유는 합산 수치가 100%를 넘더라도 **실방무가 절대 100%에 도달할 수 없게** 하기 위함이다. ([MapleStory Forums - How does IED work?](https://forums.maplestory.nexon.net/discussion/18108/how-does-ied-work), [나무위키 - 메이플스토리/스탯](https://namu.wiki/w/메이플스토리/스탯))

### 4. 보스 데미지·크리티컬 데미지가 들어가는 버킷

- **보스 데미지%(보공)**: 데미지%와 **같은 버킷에서 합산**된다. `(1 + 데미지% + 보스데미지%)` 인자 안에 함께 들어가며, 단 보스 몬스터를 때릴 때만 보스 데미지% 부분이 적용된다. 합연산이므로 누적 시 효율 감소가 있다. ([에펨코리아 - 메이플스토리 데미지 공식 총정리](https://www.fmkorea.com/8336709224), [StrategyWiki - MapleStory/Formulas](https://strategywiki.org/wiki/MapleStory/Formulas))
- **크리티컬 데미지%(크뎀)**: 기본 크리티컬 데미지(직업·상황별 약 20~50%, 평균 약 35%)에 추가 크리티컬 데미지%가 **합산**되어 적용된다. 즉 크뎀 소스끼리는 합연산이며, 그 결과로 만들어진 `(1 + 크리티컬데미지%)`가 전체 공식에서는 별도의 곱연산 인자로 작용한다. 합연산이므로 기본 크뎀이 높은 직업은 추가 크뎀의 효율이 상대적으로 낮다. ([나무위키 - 메이플스토리/스탯](https://namu.wiki/w/메이플스토리/스탯), [에펨코리아 - 메이플스토리 데미지 공식 총정리](https://www.fmkorea.com/8336709224))

**전체 버킷 구조 정리** — 총데미지는 다음 항들이 곱해진 형태이며, 각 항 내부는 합산이다:

```
총데미지 ≈ (스탯) × (무기상수) × (공격력) × (1 + 데미지% + 보스데미지%)
            × (1 + 최종데미지%) × (방무 보정) × (1 + 크리티컬데미지%) × (속성내성 보정)
```

- 곱연산으로 결합되는 "버킷": 데미지 버킷 / 최종데미지 버킷 / 방무 버킷 / 크뎀 버킷 / 속성내성 버킷.
- 각 버킷 내부 합산: 데미지%·보스데미지%는 같은 버킷에서 합산, 크뎀 소스는 크뎀 버킷에서 합산, 최종데미지 "소스"는 예외적으로 버킷 안에서도 곱연산.

출처: [에펨코리아 - 메이플스토리 데미지 공식 총정리](https://www.fmkorea.com/8336709224), [MapleStory Wiki - Damage Formula](https://maplestorywiki.net/w/Damage_Formula), [DC인사이드 - 글로벌 클래식 메이플 데미지 공식 모음집](https://m.dcinside.com/board/mapleclassic/994)

### 5. 인게임 스탯 창·툴팁 표기

- 메이플스토리 스탯창은 **"데미지"와 "최종 데미지"를 별도 항목으로 분리 표시**한다. 두 수치가 따로 보이기 때문에 유저들이 "스탯창에 데미지랑 최종데미지가 따로 있는데 차이가 뭐냐"는 질문을 자주 한다. 즉 UI 차원에서 합산 스탯과 곱연산 스탯을 구분해 보여 준다. ([인벤 - 스텟창 데미지/최종데미지 차이 질문](http://www.inven.co.kr/board/maple/2300/171926))
- 넥슨 공식 가이드도 "전투력과 특수 스탯" 항목에서 데미지·보스 데미지·방어율 무시·크리티컬 데미지·최종 데미지 등을 개별 스탯으로 안내하며, 스탯창/장비 툴팁에서 각 옵션을 별도 라인으로 노출한다. ([넥슨 공식 - 전투력과 특수 스탯 가이드](https://maplestory.nexon.com/Guide/N23GameInformation/377406))
- 표기 용어 구분: 영문 메이플 커뮤니티 표준상 "**%p / % points**"는 값이 단순히 더해지는(합산) 증가를, 그냥 "**%**"는 곱해지는(곱연산) 증가율을 의미한다. 한국에서도 잠재·장비 옵션 표기에서 "데미지 +X%"(합산되는 옵션)와 곱으로 작용하는 "최종 데미지" 표기를 다르게 인식한다. ([MapleStory Forums - Distinguishing Between Additive and Multiplicative](https://forums.maplestory.nexon.net/discussion/18666/distinguishing-between-additive-and-multiplicative))
- 다만 인게임 스탯창은 "최종적으로 합산된 결과 수치"만 보여줄 뿐, 각 소스가 합연산인지 곱연산인지를 명시적으로 라벨링하지는 않는다. 그래서 합성 방식의 차이는 위키·계산기·커뮤니티 지식에 의존하는 면이 크다. ([Grandis Library - Stat Terms](https://grandislibrary.com/content/stat-terms))

### 6. 한국 게이머에게 친숙한 "합산 vs 최종뎀" 멘탈 모델

- 정설로 통하는 멘탈 모델: "**뎀퍼(데미지%)·공퍼·보공·크뎀은 쌓을수록 효율이 떨어진다(합산이라 분모가 커짐). 최종 데미지는 효율 감소가 없어 항상 좋다(곱연산).**" 그래서 스펙업 우선순위·아이템 가치 평가에서 "최뎀"이 별격 취급을 받는다. ([인벤 - 최종데미지 계산식 원리](https://www.inven.co.kr/board/maple/2304/26987), [나무위키 - 메이플스토리/스탯](https://namu.wiki/w/메이플스토리/스탯))
- 장비 비교 시 흔히 쓰는 사고법: "이 데미지%가 내 현재 데미지 풀에 더해졌을 때 실제 배율 증가가 얼마인가"를 계산한다. 같은 +10%라도 현재 풀 크기에 따라 체감이 다르다는 것을 한국 유저들은 "효율"이라는 단어로 표현한다. ([DC인사이드 - 어떤 장비가 더 세지는지 구별법](https://m.dcinside.com/board/maplerpg/47961))
- 방무에 대해서도 "방무는 곱연산이라 100% 못 채운다, 그래서 적정선까지만 맞추고 나머지는 다른 스탯에 투자"라는 멘탈 모델이 보편적이다. ([인벤 - 아주 쉬운 방무 계산법](https://www.inven.co.kr/board/maple/2304/27115))
- 요약하면 한국 RPG(특히 메이플) 유저의 직관은 **"같은 종류 스탯끼리는 더해진다(합산 풀, 효율 감소), 다른 종류 버킷끼리는 곱해진다(곱연산, 효율 유지), 최종뎀은 그 자체로 별도 곱 버킷이라 OP"** 라는 3분할 모델로 정리된다.

## 출처

- [나무위키 - 메이플스토리/스탯](https://namu.wiki/w/메이플스토리/스탯)
- [에펨코리아 - 메이플스토리 데미지 공식 총정리](https://www.fmkorea.com/8336709224)
- [인벤 - 최종데미지 계산식 원리(추가)](https://www.inven.co.kr/board/maple/2304/26987)
- [인벤 - 스텟창 데미지/최종데미지 차이 질문](http://www.inven.co.kr/board/maple/2300/171926)
- [인벤 - 아주 쉬운 방무 계산법 / 보스포함](https://www.inven.co.kr/board/maple/2304/27115)
- [넥슨 공식 - 전투력과 특수 스탯 가이드](https://maplestory.nexon.com/Guide/N23GameInformation/377406)
- [DC인사이드 - 글로벌 클래식 메이플 최신 데미지 공식 모음집](https://m.dcinside.com/board/mapleclassic/994)
- [DC인사이드 - 어떤 장비가 더 세지는지 구별법](https://m.dcinside.com/board/maplerpg/47961)
- [StrategyWiki - MapleStory/Formulas](https://strategywiki.org/wiki/MapleStory/Formulas)
- [MapleStory Wiki - Damage Formula](https://maplestorywiki.net/w/Damage_Formula)
- [MapleWiki Fandom - Damage Formula](https://maplestory.fandom.com/wiki/Damage_Formula)
- [Grandis Library - Stat Terms](https://grandislibrary.com/content/stat-terms)
- [MapleStory Forums - How does IED work?](https://forums.maplestory.nexon.net/discussion/18108/how-does-ied-work)
- [MapleStory Forums - Distinguishing Between Additive and Multiplicative](https://forums.maplestory.nexon.net/discussion/18666/distinguishing-between-additive-and-multiplicative)
- [GMS Meta - Final damage from ignore enemy defense](https://www.gmsmeta.com/bsm/ied.html)
