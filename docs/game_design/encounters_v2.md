# 일반 인카운터 v2 설계 — 중복 제거 + 난이도 1~10 + Floor 가중치

## 설계 원칙

1. **신화당 정확히 10개 인카운터**, 인덱스 0~9 = 난이도 1~10 (오름차순)
2. **모든 몬스터 종은 단 1개의 인카운터에만 배치** (인카운터 내 동일 종 다수는 허용)
3. **신화당 20종 몬스터** (기존 6종 재배치 + 신규 14종 추가)
4. **Floor 가중치 선택**: `_make_normal_enemies()`에서 floor 진행도에 따라 약 → 강 방향으로 가중치 적용

---

## 표준 인카운터 모양 (신화 공통)

| # | 난이도 | 모양 | 예상 총 HP |
|---|---|---|---|
| 1 | 매우 약함 | A 단독 | 220~330 |
| 2 | 약함 | B × 2 | 500~660 |
| 3 | 약함+ | C 단독 (중간 솔로) | 330~450 |
| 4 | 보통 | D + E | 580~760 |
| 5 | 보통+ | F × 3 | 780~960 |
| 6 | 다소 강함 | G + H + I | 840~1080 |
| 7 | 강함 | J × 2 + K | 1100~1300 |
| 8 | 강함 | L + M + N + O | 1100~1320 |
| 9 | 강함+ | P + Q + R | 1200~1400 |
| 10 | 매우 강함 | S + T | 1300~1450 |

총 슬롯: 1+1+1+2+1+3+2+4+3+2 = **20종** / 신화

> **제약**: #10 총 HP는 Act1 엘리트 최저(1600) 이하. 일반 인카운터는 어떤 경우에도 엘리트보다 강해서는 안 됨.

---

## Floor 가중치 알고리즘

**변경 파일**: `autoload/game_manager.gd` `_make_normal_enemies()` (L587-601)

```gdscript
# 현재
var encounter: Array = encounters.pick_random()

# 변경 후
var encounter: Array = _pick_weighted_encounter(encounters, current_floor)

func _pick_weighted_encounter(pool: Array, floor_idx: int) -> Array:
    var progress: float = clamp(float(floor_idx) / 9.0, 0.0, 1.0)
    var target: float = progress * float(pool.size() - 1)
    var weights: Array = []
    for i in range(pool.size()):
        var dist: float = abs(float(i) - target)
        weights.append(maxf(0.0, 4.0 - dist))  # ±3 윈도우, peak=4
    return _weighted_pick(pool, weights)

func _weighted_pick(items: Array, weights: Array) -> Variant:
    var total: float = 0.0
    for w in weights:
        total += w
    var r: float = randf() * total
    var acc: float = 0.0
    for i in range(items.size()):
        acc += weights[i]
        if r <= acc:
            return items[i]
    return items[-1]
```

**효과**: floor 0 → 인카운터 0~3 위주, floor 5 → 2~7 위주, floor 9 → 6~9 위주

---

## 그리스 신화 (Greek)

### 인카운터 배치표

| # | 구성 | 총 HP |
|---|---|---|
| 1 | fly_harpy 단독 | 220 |
| 2 | myrmidon × 2 | 500 |
| 3 | satyr 단독 | 350 |
| 4 | snake + lamia | 590 |
| 5 | harpy × 3 | 840 |
| 6 | stymphalian_bird + giant_ant + dryad | 870 |
| 7 | centaur × 2 + ares_soldier | 1180 |
| 8 | griffin_cub + medusid + fire_crab + stone_shard | 1240 |
| 9 | cyclops + chimera_cub + hydra_head | 1450 |
| 10 | cerberus + tartaros_shade | 1400 |

### 몬스터 명세 (20종)

**기존 6종 (재배치)**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| myrmidon | 미르미돈 | 250 | ATK 60 RANDOM slash → BUFF strength 1 → ATK 60 RANDOM slash → ATK 90 RANDOM slash |
| satyr | 사티로스 | 350 | ATK 80 RANDOM blunt → ATK 80 RANDOM blunt |
| snake | 독뱀 | 300 | ATK 60 RANDOM poison → DEBUFF vulnerable 2 |
| harpy | 하르피아 | 280 | ATK 45 RANDOM slash × 4 → SPECIAL 0 |
| cyclops | 키클롭스 | 700 | PREPARE 0 (준비) → ATK 200 RANDOM blunt |
| cerberus | 케르베로스 | 900 | ATK 70 RANDOM slash × 5 → ATK 90 ALL slash |

**신규 14종**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| fly_harpy | 소형 하르피아 | 220 | ATK 50 RANDOM slash → ATK 60 RANDOM slash |
| lamia | 라미아 | 290 | DEBUFF vulnerable 2 → ATK 70 RANDOM poison → ATK 70 LOWEST_HP poison |
| stymphalian_bird | 스팀팔리데스 | 290 | ATK 55 RANDOM slash → DEBUFF weak 1 → ATK 55 RANDOM slash |
| giant_ant | 거인 개미 | 310 | ATK 60 RANDOM blunt → BUFF strength 1 → ATK 80 RANDOM blunt |
| dryad | 드리아드 | 270 | DEBUFF vulnerable 1 → ATK 50 RANDOM curse → DEBUFF weak 2 |
| centaur | 켄타우로스 | 400 | ATK 90 RANDOM blunt → ATK 80 LOWEST_HP blunt → ATK 110 RANDOM blunt |
| ares_soldier | 아레스 병사 | 380 | BUFF strength 1 → ATK 100 RANDOM slash → ATK 100 ALL slash |
| griffin_cub | 그리핀 새끼 | 320 | BUFF strength 1 → ATK 75 RANDOM slash → ATK 75 RANDOM slash |
| medusid | 메두사 화신 | 300 | DEBUFF weak 2 → ATK 65 RANDOM curse → DEBUFF vulnerable 1 → ATK 65 RANDOM curse |
| fire_crab | 헤파이스토스 불게 | 280 | ATK 55 RANDOM fire → BUFF block 20 → ATK 70 RANDOM fire |
| stone_shard | 석상 파편 | 340 | BUFF block 30 → ATK 90 RANDOM blunt → ATK 90 RANDOM blunt |
| chimera_cub | 키마이라 새끼 | 400 | ATK 110 ALL fire → BUFF strength 1 → ATK 130 RANDOM fire |
| hydra_head | 히드라의 머리 | 350 | ATK 100 RANDOM poison → ATK 100 RANDOM slash → DEBUFF weak 2 |
| tartaros_shade | 타르타로스의 망령 | 500 | BUFF strength 2 → ATK 130 LOWEST_HP curse → ATK 130 LOWEST_HP curse |

---

## 북유럽 신화 (Norse)

### 인카운터 배치표

| # | 구성 | 총 HP |
|---|---|---|
| 1 | urdr_spider 단독 | 300 |
| 2 | volva_witch × 2 | 640 |
| 3 | garlarr_snake 단독 | 340 |
| 4 | hrimfaxi_rider + ice_wolf | 730 |
| 5 | raven_scout × 3 | 840 |
| 6 | frost_wight + bone_archer + dark_elf | 885 |
| 7 | draugr × 2 + berserker | 1290 |
| 8 | runestone_golem + night_hag + lindworm_spawn + einherjar_ghost | 1250 |
| 9 | jotun_soldier + garmr + nidhogg_scale | 1450 |
| 10 | frost_giant + ragnarok_herald | 1350 |

※ 9/10번 총 HP가 같으나 10번 몬스터의 단일 데미지가 더 높음 (강도 차별화).

### 몬스터 명세 (20종)

**기존 6종 (재배치)**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| urdr_spider | 우르드 거미 | 300 | ATK 60 RANDOM poison → DEBUFF poison 3 → ATK 60 RANDOM poison × 2 → DEBUFF poison 3 |
| volva_witch | 볼바 마녀 | 320 | DEBUFF weak 2 → DEBUFF vulnerable 2 → ATK 110 RANDOM curse |
| garlarr_snake | 갈라르 뱀 | 340 | SPECIAL 1 (카드 버리기) → ATK 85 RANDOM poison → ATK 85 RANDOM poison |
| hrimfaxi_rider | 흐림팍시 기수 | 380 | ATK 70 RANDOM blunt → ATK 70 LOWEST_HP blunt → ATK 140 RANDOM blunt |
| draugr | 드라우그 | 420 | ATK 90 RANDOM slash → ATK 90 RANDOM slash → BUFF strength 10 |
| jotun_soldier | 요툰 병사 | 600 | BUFF block 80 → ATK 180 RANDOM blunt → ATK 120 ALL blunt |

**신규 14종**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| ice_wolf | 얼음 늑대 | 350 | ATK 75 RANDOM blunt → ATK 75 RANDOM blunt → DEBUFF weak 1 |
| raven_scout | 라그나로크 까마귀 | 280 | ATK 55 RANDOM slash → DEBUFF poison 2 → ATK 70 RANDOM slash |
| frost_wight | 서리 거인 새끼 | 310 | BUFF block 25 → ATK 70 RANDOM blunt → ATK 90 RANDOM blunt |
| bone_archer | 뼈 궁수 | 280 | ATK 60 RANDOM slash → DEBUFF vulnerable 1 → ATK 60 RANDOM slash |
| dark_elf | 다크 엘프 | 295 | DEBUFF weak 2 → ATK 65 RANDOM curse → ATK 65 RANDOM curse |
| berserker | 버서커 | 450 | BUFF strength 2 → ATK 110 RANDOM slash → ATK 130 RANDOM slash |
| runestone_golem | 룬 골렘 | 350 | BUFF block 40 → ATK 95 RANDOM blunt → ATK 95 RANDOM blunt |
| night_hag | 밤 마녀 | 280 | DEBUFF vulnerable 2 → DEBUFF weak 2 → ATK 80 RANDOM curse |
| lindworm_spawn | 린드웜 새끼 | 320 | ATK 75 RANDOM poison → DEBUFF poison 2 → ATK 75 RANDOM slash |
| einherjar_ghost | 전사의 유령 | 300 | BUFF strength 1 → ATK 80 RANDOM slash → ATK 80 RANDOM slash |
| garmr | 펜리르 강아지 | 450 | ATK 110 RANDOM blunt → BUFF strength 1 → ATK 130 LOWEST_HP blunt |
| nidhogg_scale | 니드호그의 비늘 | 400 | ATK 90 RANDOM poison → DEBUFF poison 3 → ATK 90 RANDOM slash |
| frost_giant | 서리 거인 | 680 | BUFF block 60 → ATK 150 RANDOM blunt → ATK 110 ALL blunt |
| ragnarok_herald | 라그나로크 전령 | 670 | BUFF strength 2 → ATK 140 RANDOM slash → ATK 140 LOWEST_HP slash → ATK 80 ALL slash |

---

## 이집트 신화 (Egyptian)

### 인카운터 배치표

| # | 구성 | 총 HP |
|---|---|---|
| 1 | ka_spirit 단독 | 320 |
| 2 | scarab × 2 | 520 |
| 3 | sphinx_cub 단독 | 350 |
| 4 | desert_scorpion + sand_wraith | 730 |
| 5 | sand_rat × 3 | 840 |
| 6 | anubis_guard + sand_scout + nile_crocodile | 1070 |
| 7 | clay_soldier × 2 + sand_ifrit | 1210 |
| 8 | tomb_wraith + khopesh_warrior + jackal_priest + desert_ghoul | 1230 |
| 9 | mummy_warrior + sobek_spawn + ammit_cub | 1450 |
| 10 | sphinx_adult + pyramid_golem | 1400 |

### 몬스터 명세 (20종)

**기존 6종 (재배치)**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| ka_spirit | 카 영혼 | 320 | ATK 55 RANDOM curse → DEBUFF vulnerable 2 → ATK 55 RANDOM curse → DEBUFF weak 2 |
| sphinx_cub | 스핑크스 새끼 | 350 | ATK 80 RANDOM slash × 4 → SPECIAL 1 (카드 버리기) |
| desert_scorpion | 사막 전갈 | 420 | ATK 70 RANDOM poison + DEBUFF poison 4 → ATK 70 RANDOM poison |
| sand_scout | 사막 척후병 | 380 | ATK 90 RANDOM projectile → BUFF strength 1 → ATK 90 RANDOM projectile |
| sand_ifrit | 모래 이프리트 | 450 | BUFF strength 2 (준비) → ATK 230 ALL fire |
| mummy_warrior | 미라 전사 | 600 | ATK 110 RANDOM blunt → DEBUFF weak 2 → ATK 140 RANDOM blunt |

**신규 14종**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| scarab | 스카라베 | 260 | ATK 50 RANDOM slash → ATK 65 RANDOM slash |
| sand_wraith | 모래 망령 | 310 | DEBUFF weak 1 → ATK 70 RANDOM curse → DEBUFF vulnerable 1 → ATK 70 RANDOM curse |
| sand_rat | 사막 들쥐 | 280 | ATK 55 RANDOM slash → ATK 55 RANDOM slash → DEBUFF poison 1 |
| anubis_guard | 아누비스 수호병 | 330 | BUFF block 30 → ATK 80 RANDOM slash → ATK 80 RANDOM slash |
| nile_crocodile | 나일 악어 | 360 | ATK 85 RANDOM blunt → ATK 85 LOWEST_HP blunt → DEBUFF vulnerable 1 |
| clay_soldier | 점토 병사 | 380 | BUFF block 35 → ATK 90 RANDOM blunt → ATK 90 RANDOM blunt |
| tomb_wraith | 무덤 망령 | 320 | DEBUFF weak 2 → ATK 75 RANDOM curse → ATK 75 RANDOM curse |
| khopesh_warrior | 코페쉬 전사 | 340 | BUFF strength 1 → ATK 85 RANDOM slash → ATK 110 RANDOM slash |
| jackal_priest | 자칼 사제 | 280 | DEBUFF vulnerable 2 → ATK 65 RANDOM curse → DEBUFF weak 1 |
| desert_ghoul | 사막 구울 | 290 | ATK 65 RANDOM slash → ATK 65 RANDOM slash → BUFF strength 1 |
| sobek_spawn | 소베크의 자식 | 450 | ATK 110 RANDOM blunt → ATK 110 LOWEST_HP blunt → DEBUFF vulnerable 2 |
| ammit_cub | 암밋 새끼 | 400 | BUFF strength 1 → ATK 100 RANDOM slash → ATK 100 ALL slash |
| sphinx_adult | 성체 스핑크스 | 720 | ATK 120 RANDOM slash × 3 → SPECIAL 1 → ATK 150 LOWEST_HP slash |
| pyramid_golem | 피라미드 골렘 | 680 | BUFF block 70 → ATK 160 RANDOM blunt → ATK 120 ALL blunt |

---

## 불교 신화 (Buddhist)

### 인카운터 배치표

| # | 구성 | 총 HP |
|---|---|---|
| 1 | garuda 단독 | 280 |
| 2 | yaksha × 2 | 640 |
| 3 | pishacha 단독 | 350 |
| 4 | dharma_puppet + lotus_spirit | 610 |
| 5 | hungry_ghost × 3 | 840 |
| 6 | asura + naga_spawn + rakshasa | 970 |
| 7 | virudhaka × 2 + karmic_fiend | 1270 |
| 8 | sky_beast + earth_spirit + wrathful_spirit + cursed_monk | 1210 |
| 9 | vajrapani + deva_soldier + ashura_warrior | 1230 |
| 10 | mara_general + hell_guardian | 1370 |

※ vajrapani HP 500으로 리밸런싱 (기존 900 → 일반 인카운터 적정 수준 조정). intent는 유지.

### 몬스터 명세 (20종)

**기존 6종 (재배치, vajrapani HP 조정)**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| garuda | 가루다 | 280 | BUFF strength 1 → ATK 60 ALL fire |
| yaksha | 야차 | 320 | ATK 70 LOWEST_HP slash → DEBUFF weak 2 → ATK 90 LOWEST_HP slash |
| pishacha | 마라 병사 | 350 | DEBUFF vulnerable 1 → ATK 80 RANDOM curse → DEBUFF weak 2 → ATK 60 RANDOM curse |
| asura | 아수라 | 380 | BUFF strength 1 → DEBUFF vulnerable 2 → ATK 90 RANDOM blunt |
| virudhaka | 증장천 | 450 | BUFF block 40 → ATK 100 RANDOM divine → ATK 120 RANDOM divine → BUFF block 20 |
| vajrapani | 금강역사 | **500** | BUFF strength 2 → ATK 100 RANDOM blunt → ATK 130 RANDOM blunt |

**신규 14종**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| dharma_puppet | 법 꼭두각시 | 300 | DEBUFF vulnerable 1 → ATK 70 RANDOM curse → ATK 70 RANDOM curse |
| lotus_spirit | 연꽃 정령 | 310 | DEBUFF weak 2 → ATK 70 RANDOM divine → ATK 70 RANDOM divine |
| hungry_ghost | 아귀 | 280 | ATK 60 RANDOM curse → ATK 60 RANDOM curse → DEBUFF vulnerable 1 |
| naga_spawn | 나가 알 | 310 | ATK 70 RANDOM poison → DEBUFF poison 2 → ATK 70 RANDOM slash |
| rakshasa | 마군 병사 | 280 | BUFF strength 1 → ATK 70 RANDOM blunt → ATK 70 RANDOM blunt |
| karmic_fiend | 업 마귀 | 370 | DEBUFF weak 2 → DEBUFF vulnerable 2 → ATK 90 RANDOM curse |
| sky_beast | 천신 짐승 | 330 | BUFF strength 1 → ATK 80 RANDOM divine → ATK 80 RANDOM divine |
| earth_spirit | 지령 | 290 | DEBUFF vulnerable 2 → ATK 70 RANDOM blunt → ATK 70 RANDOM blunt |
| wrathful_spirit | 분노 유령 | 310 | ATK 75 RANDOM curse → DEBUFF weak 1 → ATK 90 RANDOM curse |
| cursed_monk | 저주 승려 | 280 | SPECIAL 1 → ATK 65 RANDOM curse → ATK 65 RANDOM curse |
| deva_soldier | 천병 | 380 | BUFF strength 1 → ATK 90 RANDOM divine → ATK 90 RANDOM divine |
| ashura_warrior | 아수라 전사 | 350 | BUFF strength 2 → ATK 95 RANDOM blunt → ATK 120 RANDOM blunt |
| mara_general | 마라 대장 | 680 | BUFF strength 2 → ATK 140 RANDOM curse → ATK 140 LOWEST_HP curse → ATK 90 ALL curse |
| hell_guardian | 지옥 수호자 | 690 | BUFF block 60 → ATK 150 RANDOM divine → ATK 120 ALL divine |

---

## 도교 신화 (Daoist)

### 인카운터 배치표

| # | 구성 | 총 HP |
|---|---|---|
| 1 | child_immortal 단독 | 280 |
| 2 | dao_disciple × 2 | 600 |
| 3 | hermit_ghost 단독 | 340 |
| 4 | mountain_spirit + thunder_messenger | 700 |
| 5 | immortal_sprite × 3 | 780 |
| 6 | cloud_beast + jade_puppet + river_spirit | 900 |
| 7 | elder_hermit × 2 + celestial_soldier | 1230 |
| 8 | fire_salamander + iron_guard + wind_sprite + earth_dragon | 1260 |
| 9 | azure_guardian + celestial_lion + nine_tailed_spirit | 1450 |
| 10 | dragon_king_child + immortal_warrior | 1400 |

### 몬스터 명세 (20종)

**기존 6종 (재배치)**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| child_immortal | 동자선 | 280 | ATK 50 RANDOM slash → ATK 50 RANDOM slash → BUFF strength 1 |
| dao_disciple | 도사 수련생 | 300 | BUFF strength 1 → BUFF strength 1 → BUFF strength 2 → ATK 120 RANDOM divine |
| hermit_ghost | 시해선 | 340 | ATK 70 RANDOM slash → BUFF strength 1 → ATK 90 RANDOM slash |
| mountain_spirit | 산신 | 380 | DEBUFF vulnerable 2 → ATK 80 RANDOM slash → ATK 60 ALL slash → DEBUFF vulnerable 1 |
| celestial_soldier | 천병 | 450 | BUFF block 50 → ATK 110 RANDOM slash → ATK 90 RANDOM slash → BUFF block 30 |
| azure_guardian | 청룡 호법 | 520 | BUFF strength 1 → BUFF block 40 → ATK 100 RANDOM slash → ATK 120 RANDOM slash |

**신규 14종**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| thunder_messenger | 뇌신 전령 | 320 | ATK 75 RANDOM divine → DEBUFF vulnerable 1 → ATK 75 RANDOM divine |
| immortal_sprite | 선신 정령 | 260 | ATK 55 RANDOM divine → ATK 55 RANDOM divine |
| cloud_beast | 구름 짐승 | 310 | BUFF strength 1 → ATK 75 RANDOM blunt → ATK 75 RANDOM blunt |
| jade_puppet | 옥 꼭두각시 | 290 | DEBUFF weak 2 → ATK 65 RANDOM blunt → ATK 65 RANDOM blunt |
| river_spirit | 하천 신 | 300 | ATK 70 RANDOM poison → DEBUFF vulnerable 1 → ATK 70 RANDOM poison |
| elder_hermit | 고령 선인 | 390 | BUFF strength 1 → ATK 95 RANDOM divine → ATK 95 RANDOM divine → BUFF strength 1 |
| fire_salamander | 불 도롱뇽 | 330 | ATK 80 RANDOM fire → ATK 80 RANDOM fire → BUFF strength 1 |
| iron_guard | 철 수호병 | 350 | BUFF block 40 → ATK 90 RANDOM blunt → ATK 90 RANDOM blunt |
| wind_sprite | 바람 요정 | 270 | ATK 60 RANDOM slash → ATK 60 RANDOM slash → DEBUFF weak 1 |
| earth_dragon | 지룡 | 310 | BUFF strength 1 → ATK 75 RANDOM blunt → ATK 75 RANDOM slash |
| celestial_lion | 천사자 | 480 | BUFF strength 1 → ATK 110 RANDOM divine → ATK 110 LOWEST_HP divine |
| nine_tailed_spirit | 구미호 선 | 450 | DEBUFF weak 2 → ATK 105 RANDOM curse → ATK 105 RANDOM curse |
| dragon_king_child | 용왕의 아들 | 720 | BUFF block 60 → ATK 150 RANDOM divine → ATK 120 ALL divine |
| immortal_warrior | 선인 전사 | 680 | BUFF strength 2 → ATK 140 RANDOM slash → ATK 140 LOWEST_HP slash |

---

## 일본 신화 (Japanese)

### 인카운터 배치표

| # | 구성 | 총 HP |
|---|---|---|
| 1 | yuki_onna 단독 | 300 |
| 2 | tengu × 2 | 640 |
| 3 | shuten_minion 단독 | 350 |
| 4 | kappa + foxfire | 670 |
| 5 | koropokkuru × 3 | 780 |
| 6 | yamabiko + ittan_momen + azuki_washer | 850 |
| 7 | oni × 2 + samurai_ghost | 1270 |
| 8 | tennyo + hone_onna + cursed_scroll + tatami_monster | 1260 |
| 9 | ronin_ghost + yamabushi_ghost + dragon_serpent | 1370 |
| 10 | gashadokuro + hannya | 1380 |

### 몬스터 명세 (20종)

**기존 6종 (재배치)**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| yuki_onna | 유키온나 | 300 | DEBUFF weak 2 → ATK 70 LOWEST_HP ice → DEBUFF vulnerable 1 |
| tengu | 텐구 | 320 | DEBUFF weak 1 → ATK 80 RANDOM slash → ATK 70 RANDOM slash → DEBUFF vulnerable 1 |
| shuten_minion | 슈텐 졸개 | 350 | ATK 70 RANDOM blunt → ATK 70 RANDOM blunt → BUFF strength 1 → ATK 100 RANDOM blunt |
| kappa | 갓파 | 380 | BUFF block 30 → ATK 80 RANDOM blunt → ATK 90 RANDOM blunt → DEBUFF weak 1 |
| oni | 오니 | 420 | ATK 90 RANDOM blunt → BUFF strength 1 → ATK 110 RANDOM blunt |
| ronin_ghost | 로닌 망령 | 450 | BUFF strength 2 → ATK 130 LOWEST_HP slash → ATK 100 RANDOM slash |

**신규 14종**

| key | 한국어 | HP | intent 요약 |
|---|---|---|---|
| foxfire | 여우불 | 290 | ATK 60 RANDOM fire → DEBUFF vulnerable 1 → ATK 75 RANDOM fire |
| koropokkuru | 코로포쿠루 | 260 | ATK 50 RANDOM slash → ATK 65 RANDOM slash |
| yamabiko | 야마비코 | 300 | ATK 65 RANDOM curse → ATK 65 RANDOM curse → DEBUFF weak 1 |
| ittan_momen | 잇탄모멘 | 280 | DEBUFF weak 2 → ATK 60 RANDOM slash → ATK 60 RANDOM slash |
| azuki_washer | 아즈키 씻는 귀신 | 270 | ATK 55 RANDOM blunt → DEBUFF vulnerable 1 → ATK 70 RANDOM blunt |
| samurai_ghost | 사무라이 영령 | 430 | BUFF strength 1 → ATK 100 RANDOM slash → ATK 100 LOWEST_HP slash → ATK 80 ALL slash |
| tennyo | 강물 갓파 | 350 | BUFF block 35 → ATK 85 RANDOM blunt → ATK 85 RANDOM blunt |
| hone_onna | 눈의 여인 | 310 | DEBUFF weak 2 → ATK 75 LOWEST_HP ice → DEBUFF vulnerable 1 |
| cursed_scroll | 저주 두루마리 | 270 | SPECIAL 1 → ATK 65 RANDOM curse → ATK 65 RANDOM curse |
| tatami_monster | 다다미 괴물 | 330 | BUFF block 30 → ATK 80 RANDOM blunt → ATK 95 RANDOM blunt |
| yamabushi_ghost | 야마부시 영령 | 480 | BUFF strength 1 → ATK 110 RANDOM slash → ATK 110 RANDOM slash → ATK 80 ALL slash |
| dragon_serpent | 수룡 | 440 | ATK 100 RANDOM blunt → DEBUFF vulnerable 2 → ATK 100 RANDOM blunt |
| gashadokuro | 오니 왕 | 700 | BUFF strength 2 → ATK 150 RANDOM blunt → ATK 120 ALL blunt |
| hannya | 한냐 | 680 | BUFF strength 1 → ATK 140 LOWEST_HP curse → ATK 140 LOWEST_HP curse → ATK 90 ALL curse |

---

## 검증 체크리스트

- [ ] 신화당 정확히 10개 인카운터
- [ ] 신화당 정확히 20종 몬스터
- [ ] 모든 종이 단 1개 인카운터에만 등장
- [ ] 인카운터 1~10 총 HP 오름차순
- [ ] 신규 종의 번역 키 추가 (`strings_enemy.csv`)
- [ ] `*_normals.gd` encounters() 재작성 + 20 팩토리 함수
- [ ] `game_manager.gd` 가중치 선택 로직 적용
