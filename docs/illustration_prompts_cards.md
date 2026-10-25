# 카드 일러스트 프롬프트 v13 — 전체 216장 명세

> v12 (245장) 는 파일명 자동 변환에서 owner_id 단축(genghis_khan→genghis 등)·카드명 변형이 일어나 128/216 만 매칭됐음.
> v13 은 **카드별 desc 를 모두 명시**하고 **파일명 규칙을 절대화**해서 다시는 매칭 어긋남이 없게 함.

## 0. 전체 규칙

### 0-1. 파일명 (절대 규칙)

- 형식: `{owner_id}_{card_id}.png` — 그 외 변형 일절 금지
- owner_id: `cleopatra` / `napoleon` / `yi_sun_sin` / `joan_of_arc` / `genghis_khan` / `musashi`
  - 단축 금지: `genghis_khan_horse_charge.png` (O), `genghis_horse_charge.png` (X)
  - 단축 금지: `yi_sun_sin_turtle_ship_charge.png` (O), `yi_turtle_ship_charge.png` (X)
- card_id 는 아래 표에서 그대로 복사. 절대 변형·재해석 X
- 모두 소문자 + snake_case + .png

### 0-2. 해상도 (절대 규칙)

- **1024×906 (1.13:1)** — 게임 ArtRect 654×576 비율 일치
- 모든 카드 동일 크기 (예외 X)
- PNG, 24bit

### 0-3. 검증

생성 후:
```bash
python tools/verify_card_illustrations.py <폴더경로>
```
누락 카드 / 잉여 일러스트 / 크기 불일치 즉시 보고.

---

## 1. 조립 순서

```
STYLE_PREFIX + 카드 desc + HERO_CONTEXT + (PERSON_ADDON, 인물일 때만) + HERO_STYLE
```

v9 와 동일 구조. ComfyUI z_image_turbo (CFG=1, 8 steps, seed=20260517, 1024×906) 입력.

---

## 2. 공통 STYLE_PREFIX

```
modern sophisticated editorial illustration in the style of contemporary art prints,
full bleed cinematic composition where the artwork extends to all four edges of the canvas,
subject and background fill the entire image frame from edge to edge,
wide environmental landscape shot, immersive scenery wraps around the subject,
rich detailed background fills 100 percent of the canvas behind the subject
(sky with clouds, distant mountains, ocean waves, palace architecture, desert dunes,
battlefield terrain, forest, courtyard buildings, ambient environment),
muted earthy harmonious color palette with subtle grain and paper texture overlay,
sophisticated mature tone, refined adult illustration, fine art quality,
contemporary graphic design poster aesthetic like a high end gallery art print,
bold confident hand-drawn lines, expressive abstract simplified forms,
slightly rough handcrafted quality, sophisticated visual storytelling,
naïve folk art meets modern design sensibility,
```

## 3. PERSON_ADDON (인물 감지 시 suffix)

자동 감지 키워드 (desc 소문자에 하나라도 포함되면 인물로 판정):
`soldier, officer, warrior, knight, samurai, horseman, cavalry, archer, figure, cleopatra, napoleon, joan, genghis, musashi, admiral, guard, commander, pharaoh, queen, isis, sekhmet, goddess, people, person, khan, marshal, scout, drummer, bugler, saint, rider, men, musketeer, grenadier, hussar, monk, priest, priestess, kneeling, leaning, blowing, swinging, raising, charging, dancing, meditating, praying, standing, exhaling, embracing, fighting, ridden, riding, mummy, ridge, woman, man, figures, sailor, oarsman, archers, gunner, gunners, troops, infantry, mongol, angel, angels, executioner, nuns, choir, prisoners, raider, raiders, raiding, swordsman, archers, noble, nobles, attendants, crew, recruits, warriors, riders`

```
, humans depicted as bold abstract figures with strong distinctive silhouettes,
recognizable by their iconic clothing and accessories from their era,
expressive simplified features, refined editorial illustration style
```

---

## 4. 영웅별 HERO_CONTEXT (인물 카드 desc 뒤 괄호)

| owner_id | HERO_CONTEXT |
|---|---|
| napoleon | `napoleon bonaparte french emperor with bicorne hat and military uniform` |
| cleopatra | `egyptian queen cleopatra with snakes and gold jewelry` |
| yi_sun_sin | `korean joseon admiral yi sun sin with red brigandine armor and helmet` |
| joan_of_arc | `saint joan of arc french medieval knight in shining armor with holy light` |
| genghis_khan | `mongol warrior genghis khan with fur hat and horse archer bow` |
| musashi | `japanese samurai miyamoto musashi with two katana swords and topknot` |

## 5. 영웅별 HERO_STYLE (프롬프트 맨 끝 — 국가/문화 톤)

### napoleon — 프랑스 아르데코 / 아르누보
```
, inspired by vintage french art deco and art nouveau poster aesthetics,
palette of cream, deep crimson red, navy blue, antique gold,
elegant european illustration tradition
```

### cleopatra — 이집트 벽화
```
, inspired by ancient egyptian wall fresco and tomb painting style,
palette of gold, lapis lazuli blue, turquoise, terracotta red, deep ochre, malachite green,
stylized figures with profile poses, hieroglyphic motifs in background
```

### yi_sun_sin — 조선 단청 민화
```
, inspired by korean joseon era folk painting (minhwa) and dancheong temple decoration,
palette of traditional dancheong vermillion red, cobalt blue, jade green, ochre, white, black,
hanji paper texture background, traditional korean motifs
```

### joan_of_arc — 중세 채색 필사본 + 스테인드글라스
```
, inspired by medieval illuminated manuscript and gothic stained glass style,
palette of gold leaf, deep crimson, royal blue, ivory parchment, emerald green,
gothic ornamental borders, sacred religious art tradition
```

### genghis_khan — 몽골 초원 펠트
```
, inspired by mongolian steppe folk art and central asian nomadic aesthetics,
palette of earthy umber browns, felt grey, sky blue, ochre yellow, leather tan,
raw natural earth tones, rugged textured background like felt or hide
```

### musashi — 일본 우키요에 + 수묵
```
, inspired by japanese ukiyo-e woodblock prints and sumi-e ink painting,
palette of indigo blue, vermillion bengala red, sumi black ink, washi cream, sage green,
washi paper texture, japanese traditional flat composition with bold negative space
```

---

## 6. 영웅별 216 카드 전체 desc

### 6-1. cleopatra (35장)

| # | card_id | 한글명 | 아키타입 | desc (영문) |
|--:|---|---|---|---|
| 1 | `seductive_stillness` | 유혹의 정체 | 조종 | `cleopatra standing seductively still with serpent coiled around her arm freezing time` |
| 2 | `strike` | 스트라이크 | 독살 | `cleopatra striking with a curved bronze dagger dripping venom` |
| 3 | `defend` | 디펜드 | 저주 | `cleopatra raising a golden ankh shield against incoming darkness` |
| 4 | `venom_needle` | 독침 | 독살 | `slender golden needle tip with green poison droplet hovering in air` |
| 5 | `royal_guard` | 왕실 방어 | 저주 | `royal egyptian guard with crossed khopesh swords protecting the throne` |
| 6 | `poison_seed` | 독의 씨앗 | 독살 | `single dark seed sprouting venomous green vines and toxic flowers` |
| 7 | `asp_fang` | 아스프의 독니 | 독살 | `huge asp serpent fang dripping with glowing green venom` |
| 8 | `nile_mist` | 나일의 안개 | 독살 | `thick green poisonous mist rolling over the nile river at twilight` |
| 9 | `poison_feast` | 독의 향연 | 독살 | `banquet table with golden goblets overflowing with poisoned green wine` |
| 10 | `serpent_power` | 독사의 권능 | 독살 | `colossal coiled cobra goddess radiating green venom aura with divine presence` |
| 11 | `pharaoh_venom` | 파라오의 독력 | 독살 | `pharaoh skull mask surrounded by swirling venom and golden hieroglyphs` |
| 12 | `poison_ritual` | 독살의 의식 | 독살 | `egyptian priestess pouring poison from a golden chalice on a stone altar` |
| 13 | `pharaohs_plague` | 파라오의 역병 | 독살 | `swarming locust plague descending over pyramid silhouettes at blood sunset` |
| 14 | `poison_throne` | 독의 왕좌 | 독살 | `cleopatra seated on throne made of intertwined serpents oozing venom` |
| 15 | `poison_party` | 독의 잔치 | 독살 | `egyptian feast scene with dancing figures collapsing from poisoned cups` |
| 16 | `poison_purge` | 독의 정화 | 독살 | `green venom being purified into golden light by ritual flame` |
| 17 | `nile_fury` | 나일의 분노 | 독살 | `furious nile river tidal wave full of crocodiles and serpents` |
| 18 | `cursed_gaze` | 저주의 시선 | 저주 | `single huge eye of horus glowing red casting curse rays outward` |
| 19 | `sandstorm` | 모래 폭풍 | 저주 | `massive desert sandstorm engulfing ancient ruins with swirling sand spirits` |
| 20 | `snake_gaze` | 뱀의 눈빛 | 저주 | `close up of mesmerizing slit-pupiled cobra eye with golden iris` |
| 21 | `ramesses_shield` | 람세스의 방패 | 저주 | `huge round shield carved with ramesses face surrounded by protective hieroglyphs` |
| 22 | `isis_wrath` | 이시스의 진노 | 저주 | `goddess isis with wings spread wide unleashing storm of golden judgment lightning` |
| 23 | `curse_brand` | 저주의 낙인 | 저주 | `glowing red hieroglyphic curse brand burning into stone surface` |
| 24 | `isis_judgment` | 이시스의 심판 | 저주 | `goddess isis weighing a beating heart on golden scales against feather of maat` |
| 25 | `desert_recipe` | 사막의 약법 | 저주 | `egyptian apothecary table with desert herbs scarab beetles and alchemy vials` |
| 26 | `pharaoh_fury` | 파라오의 분노 | 저주 | `pharaoh mask cracking with rays of golden fury bursting outward` |
| 27 | `venom_bloom` | 독꽃의 만개 | 저주 | `enormous toxic lotus flower blooming releasing clouds of green spores` |
| 28 | `temptation` | 유혹 | 조종 | `cleopatra extending hand with golden ring offering temptation` |
| 29 | `nile_whisper` | 나일의 속삭임 | 조종 | `serpent whispering into the ear of a kneeling captivated figure by the nile` |
| 30 | `cleopatras_kiss` | 파라오의 입맞춤 | 조종 | `cleopatra blowing a poison kiss with shimmering red lips` |
| 31 | `queens_dignity` | 여왕의 위엄 | 조종 | `cleopatra standing tall in full regalia with peacock fan attendants bowing` |
| 32 | `charming_perfume` | 매혹의 향기 | 조종 | `ornate golden perfume bottle releasing pink fragrant mist with rose petals` |
| 33 | `charm_execution` | 매혹의 처형 | 조종 | `enchanted figure walking willingly to executioner under cleopatras gaze` |
| 34 | `serpent_ritual` | 뱀의 의식 | 조종 | `egyptian priestess dancing surrounded by ring of coiled charmed cobras` |
| 35 | `golden_throne` | 황금 왕좌 | 조종 | `massive ornate golden throne with sphinx armrests and falcon crown above` |

### 6-2. napoleon (41장)

| # | card_id | 한글명 | 아키타입 | desc (영문) |
|--:|---|---|---|---|
| 1 | `blitz_advance` | 전격 진군 | 돌격 | `napoleonic hussar cavalry charging forward in lightning fast formation` |
| 2 | `strike` | 스트라이크 | 돌격 | `napoleonic grenadier thrusting bayonet forward in striking pose` |
| 3 | `defend` | 디펜드 | 군단 | `french infantry square formation with bayonets raised defensively outward` |
| 4 | `war_bugle` | 전투 나팔 | 지휘 | `french bugler raising brass war bugle to lips signaling charge` |
| 5 | `swift_march` | 신속 행군 | 돌격 | `column of french infantry marching swiftly down dusty road at dawn` |
| 6 | `swift_advance` | 신속 기동 | 돌격 | `french light cavalry galloping in formation across battlefield` |
| 7 | `line_reform` | 전열 재편 | 지휘 | `french officers reorganizing infantry line with raised swords` |
| 8 | `hussar_charge` | 경기병 돌격 | 돌격 | `french hussar cavalry with pelisse cloaks charging with curved sabres raised` |
| 9 | `grand_armee_shield` | 그랑다르메의 방패 | 군단 | `grand armee infantry locked shields with napoleonic eagle emblem` |
| 10 | `salvo` | 살보 사격 | 돌격 | `line of french musketeers firing coordinated salvo with smoke bursts` |
| 11 | `marshal_appointment` | 원수 서임 | 지휘 | `napoleon presenting marshal baton to kneeling officer in ceremonial hall` |
| 12 | `arcole_breakthrough` | 아르콜레 돌파 | 돌격 | `napoleon waving tricolor flag charging across arcole bridge under fire` |
| 13 | `artillery_volley` | 포병 일제사격 | 군단 | `row of bronze napoleonic cannons firing simultaneous volley with flame bursts` |
| 14 | `borodino_bombardment` | 보로디노 포격 | 군단 | `massive artillery bombardment over borodino battlefield with smoke columns` |
| 15 | `emperors_command` | 황제의 명령 | 지휘 | `napoleon on horseback pointing forward issuing commanding gesture to troops` |
| 16 | `emperors_spirit` | 황제의 기개 | 돌격 | `napoleon standing proudly on hilltop overlooking battlefield with cape flowing` |
| 17 | `trench_construction` | 참호 구축 | 군단 | `french engineers digging trenches with shovels around fortified camp` |
| 18 | `drum_beat` | 북소리 | 군단 | `young french drummer boy beating military drum leading column` |
| 19 | `charge_bugle` | 진격 나팔 | 지휘 | `napoleonic bugler with raised brass instrument announcing advance` |
| 20 | `cavalry_threat` | 기병 위협 | 돌격 | `french cuirassier cavalry intimidating enemy with raised sabres on horseback` |
| 21 | `guard_charge` | 근위대 돌격 | 군단 | `imperial guard grenadiers charging in bearskin hats with bayonets fixed` |
| 22 | `breakthrough_advance` | 전선 돌파 | 돌격 | `french infantry breaking through enemy line with bayonet charge` |
| 23 | `artillery_gather` | 포병 집결 | 군단 | `multiple french artillery teams converging cannons into firing battery` |
| 24 | `imperial_artillery` | 황실 포병대 | 군단 | `huge bronze imperial cannon firing flame with crew loading` |
| 25 | `imperial_infantry_call` | 제국 보병 소집 | 군단 | `column of fresh french infantry arriving from distance to rally point` |
| 26 | `austerlitz_maneuver` | 아우스터리츠 기동 | 돌격 | `french troops maneuvering brilliantly through fog at austerlitz at dawn` |
| 27 | `eagle_standard` | 독수리 군기 | 군단 | `french imperial golden eagle standard on pole rising above battlefield` |
| 28 | `victory_proclamation` | 승리의 포고 | 지휘 | `napoleon proclaiming victory on horseback as troops cheer with raised arms` |
| 29 | `great_army_siege` | 대육군 포위전 | 군단 | `grande armee surrounding fortress city with siege trenches and cannons` |
| 30 | `emperors_encirclement` | 황제의 포위령 | 지휘 | `napoleon directing flanking maneuver with arms outstretched on map table` |
| 31 | `one_man_army` | 일기당천 | 돌격 | `napoleonic officer single-handedly fighting off multiple enemies with sword` |
| 32 | `emperors_assault` | 황제의 돌격 | 돌격 | `napoleon personally leading furious cavalry charge with sword raised` |
| 33 | `empire_glory` | 제국의 영광 | 군단 | `radiant tricolor flag with imperial eagle bathed in glorious golden sunlight` |
| 34 | `legion_charge` | 군단의 진격 | 군단 | `massive french legion charging forward in unstoppable wave of bayonets` |
| 35 | `glory_shout` | 영광의 함성 | 사기 | `french soldiers raising rifles and shouting cheer in unison vive lempereur` |
| 36 | `emperors_power` | 황제의 권능 | 돌격 | `napoleon with arms raised radiating imperial power and golden aura` |
| 37 | `conquest_decree` | 정복 칙령 | 돌격 | `wax sealed imperial decree scroll declaring conquest with quill and crown` |
| 38 | `alps_crossing` | 알프스 횡단 | 돌격 | `napoleon on rearing white horse leading army across snowy alpine pass` |
| 39 | `emperors_legion` | 황제의 군단 | 군단 | `imperial guard veteran legion standing tall in perfect formation with bearskins` |
| 40 | `emperors_will` | 황제의 의지 | 지휘 | `napoleon studying map by candlelight with determined focused expression` |
| 41 | `reconnaissance` | 정찰 | 지휘 | `french scout on horseback with spyglass observing enemy from ridge` |

### 6-3. yi_sun_sin (35장)

| # | card_id | 한글명 | 아키타입 | desc (영문) |
|--:|---|---|---|---|
| 1 | `turtleship_drill` | 거북선 점호 | 학익진 | `korean joseon admiral inspecting turtle ship crew lined up on deck` |
| 2 | `strike` | 스트라이크 | 거북선 | `korean turtle ship dragon head spitting cannon flame at enemy` |
| 3 | `defend` | 디펜드 | 거북선 | `iron-plated turtle ship hull deflecting arrows with iron spikes on roof` |
| 4 | `shield` | 방패 | 거북선 | `korean joseon warrior holding round leather shield with taegeuk symbol` |
| 5 | `counter_strike` | 역공 | 거북선 | `turtle ship swiftly turning to counter strike enemy from blind side` |
| 6 | `turtle_shield` | 거북선 방패 | 거북선 | `turtle ship roof of iron spikes deflecting incoming arrows and cannonballs` |
| 7 | `turtle_ship_charge` | 거북선 돌격 | 거북선 | `korean turtle ship with dragon head charging through enemy fleet with fire` |
| 8 | `counter` | 반격 | 거북선 | `joseon archer turning quickly to return arrow fire from cover` |
| 9 | `turtle_power` | 거북의 권능 | 거북선 | `mythic giant turtle rising from sea with shell glowing with divine power` |
| 10 | `cannon_rhythm` | 포격 리듬 | 거북선 | `row of joseon cannons firing in rhythmic sequence with smoke trails` |
| 11 | `volley_fire` | 일제 사격 | 거북선 | `korean joseon archers and gunners releasing volley together from ship deck` |
| 12 | `fleet_fire` | 함포 일제사 | 거북선 | `fleet of panokseon warships firing coordinated broadside cannon salvo` |
| 13 | `consecutive_defense` | 연속 방어 | 거북선 | `turtle ship absorbing multiple cannonball impacts with iron armor sparking` |
| 14 | `charge_stance` | 돌격 태세 | 거북선 | `turtle ship in charging stance with dragon head smoke rising` |
| 15 | `iron_ram` | 철갑 충각 | 거북선 | `iron reinforced ram bow of turtle ship piercing enemy hull at impact` |
| 16 | `formation_bond` | 진형 결속 | 학익진 | `joseon fleet ships linked tightly in crane wing formation seen from above` |
| 17 | `formation_boost` | 진형 강화 | 학익진 | `crane wing fleet formation glowing with strengthening blue aura` |
| 18 | `discipline` | 군기 진작 | 학익진 | `joseon admiral raising military banner with disciplined soldiers below` |
| 19 | `fleet_command` | 함대 지휘 | 학익진 | `admiral yi sun sin on flagship deck directing fleet with signal flags` |
| 20 | `formation_strength` | 진형의 힘 | 학익진 | `tight crane wing formation creating impenetrable defensive circle` |
| 21 | `hold_formation` | 진형 사수 | 학익진 | `joseon ships holding tight formation against enemy assault with shields raised` |
| 22 | `command_instinct` | 지휘 본능 | 학익진 | `admiral yi sun sin with sharp focused gaze making instant tactical decision` |
| 23 | `naval_training` | 수군 훈련 | 학익진 | `joseon naval recruits training with spears and bows on shoreline` |
| 24 | `regroup` | 전열 정비 | 학익진 | `joseon fleet regrouping into fresh formation after engagement` |
| 25 | `strict_training` | 엄정한 훈련 | 학익진 | `joseon admiral overseeing strict spear drill of disciplined soldiers` |
| 26 | `miraculous_recovery` | 기사회생 | 필사즉생 | `wounded joseon warrior rising from ground with miraculous renewed strength` |
| 27 | `all_in` | 이판사판 | 필사즉생 | `joseon warrior throwing all weapons forward in desperate final commitment` |
| 28 | `last_stand` | 배수진 | 필사즉생 | `joseon soldiers fighting with sea at their backs in desperate last stand` |
| 29 | `death_resolve` | 죽음의 결의 | 필사즉생 | `admiral yi sun sin with steeled face and clenched jaw before final battle` |
| 30 | `fighting_spirit` | 투지 | 필사즉생 | `joseon warrior with intense fighting spirit aura radiating fierce determination` |
| 31 | `death_or_glory` | 필사즉생 | 필사즉생 | `joseon warrior facing certain death with sword raised in resolute glory` |
| 32 | `crisis_breakthrough` | 위기 돌파 | 필사즉생 | `turtle ship breaking through encirclement of enemy ships in dramatic escape` |
| 33 | `decisive_strike` | 사지결단 | 필사즉생 | `admiral yi sun sin delivering decisive killing blow with two-handed sword` |
| 34 | `bloody_battle` | 혈전 | 필사즉생 | `chaotic close-quarters sea battle with blood-stained ship decks and clashing warriors` |
| 35 | `phoenix` | 불사조 | 필사즉생 | `mythic phoenix rising from burning ship wreckage with rebirth flames` |

### 6-4. joan_of_arc (35장)

| # | card_id | 한글명 | 아키타입 | desc (영문) |
|--:|---|---|---|---|
| 1 | `grace_of_spirit` | 성령의 가호 | 축복 | `joan of arc kneeling in prayer bathed in descending dove of holy spirit light` |
| 2 | `strike` | 스트라이크 | 신성공격 | `joan of arc thrusting holy sword forward with golden light trail` |
| 3 | `defend` | 디펜드 | 신성 | `joan of arc raising white shield emblazoned with cross against darkness` |
| 4 | `holy_smite` | 신성 강타 | 신성공격 | `divine pillar of holy light smiting target from heaven` |
| 5 | `shield_prayer` | 방패 기도 | 신성 | `joan of arc kneeling with shield raised in fervent prayer position` |
| 6 | `holy_bolt` | 신성 화살 | 신성공격 | `radiant golden arrow of holy light streaking through air with cross trail` |
| 7 | `orleans_charge` | 오를레앙의 돌격 | 성전 | `joan of arc on white horse charging with orleans banner at city gates` |
| 8 | `holy_wave` | 신성의 물결 | 신성공격 | `expanding wave of holy white-gold radiance washing outward` |
| 9 | `holy_fury` | 성스러운 분노 | 성전 | `joan of arc surrounded by holy explosion of righteous radiance with raised sword` |
| 10 | `crusaders_faith` | 십자군의 신앙 | 신성 | `crusader knights kneeling before glowing cross with white tabards` |
| 11 | `divine_echo` | 성스러운 갑주 | 신성 | `gleaming divine white armor radiating soft golden light from within` |
| 12 | `archangels_wrath` | 대천사의 분노 | 신성공격 | `archangel michael with flaming sword and outspread wings descending in wrath` |
| 13 | `divine_punishment` | 신성한 징벌 | 신성공격 | `divine hand of god descending from clouds delivering golden judgment strike` |
| 14 | `crusade` | 십자군 | 신성공격 | `column of crusader knights marching under unified golden cross banner` |
| 15 | `holy_judge` | 신성 심판 | 신성공격 | `divine scales of judgment hovering above kneeling figure with light from above` |
| 16 | `oracle_light` | 신탁의 빛 | 신성 | `joan of arc bathed in pillar of oracle light receiving divine vision` |
| 17 | `holy_touch` | 성녀의 손길 | 축복 | `saint joan touching wounded soldier with healing golden palm light` |
| 18 | `communion` | 성찬 | 축복 | `golden chalice and bread on altar with descending dove of holy spirit` |
| 19 | `hymn` | 성가 | 축복 | `choir of nuns singing hymn with notes of golden light rising` |
| 20 | `guardian_angel` | 수호 천사 | 부활 | `winged guardian angel hovering protectively over fallen knight with shield` |
| 21 | `angel_wings` | 천사의 날개 | 축복 | `pair of huge feathered angel wings spreading with rays of light` |
| 22 | `miracle_revive` | 기적의 부활 | 부활 | `fallen knight rising from ground with divine miraculous golden light surrounding` |
| 23 | `joan_return` | 성녀의 귀환 | 부활 | `joan of arc returning from death with radiant halo and outstretched arms` |
| 24 | `holy_purification` | 신성한 정화 | 정화 | `purifying white flame burning away dark curse marks on stone floor` |
| 25 | `knights_oath` | 기사단의 맹세 | 부활 | `circle of knights with swords pointed up in solemn oath ceremony` |
| 26 | `flag_of_orleans` | 신국의 깃발 | 깃발 | `huge white banner of orleans with fleur-de-lis cross fluttering on tall pole` |
| 27 | `martyrs_will` | 순교의 의지 | 순교 | `joan of arc tied to wooden stake with eyes raised to heaven in martyrdom` |
| 28 | `altar_flame` | 제단의 불꽃 | 순교 | `tall stone altar with eternal sacred flame burning bright in dim chapel` |
| 29 | `martyrdom_steps` | 순교의 발걸음 | 순교 | `joan of arc walking solemnly toward pyre with chains and serene face` |
| 30 | `passion_power` | 수난의 권능 | 순교 | `joan of arc with arms outstretched cruciform radiating divine passion light` |
| 31 | `martyr_strength` | 순교의 힘 | 순교 | `joan of arc rising from flames with strengthened sacred power` |
| 32 | `saints_revelation` | 성흔의 결실 | 순교 | `stigmata wounds glowing on saints palms with light beams rising upward` |
| 33 | `martyrs_light` | 순교자의 빛 | 순교 | `martyred saint dissolving into ascending golden divine light particles` |
| 34 | `last_shield` | 최후의 방패 | 순교 | `joan of arc raising shield one final time against overwhelming dark assault` |
| 35 | `saints_flame` | 성녀의 화염 | 순교 | `joan of arc engulfed in sacred white-gold pyre flames with serene face` |

### 6-5. genghis_khan (35장)

| # | card_id | 한글명 | 아키타입 | desc (영문) |
|--:|---|---|---|---|
| 1 | `cavalry_charge_speed` | 기마 돌격 | 기동 | `mongol cavalry galloping at full speed across open steppe with raised swords` |
| 2 | `strike` | 스트라이크 | 기동 | `mongol horse archer firing arrow at full gallop in striking pose` |
| 3 | `defend` | 디펜드 | 기동 | `mongol warrior on horseback raising round leather shield against arrows` |
| 4 | `horse_thrust` | 기마 돌격 | 기동 | `mongol cavalry thrusting spear forward while charging at full speed` |
| 5 | `rider_call` | 기마 소환 | 몽골 기병 | `mongol khan raising war horn summoning distant cavalry over hill` |
| 6 | `swift_raid` | 급습 | 기동 | `mongol raiders sweeping into village at dawn on swift horses` |
| 7 | `cavalry_crossing` | 기마 도하 | 기동 | `mongol cavalry crossing river fording with horses kicking up spray` |
| 8 | `horse_charge` | 돌격 | 기동 | `mongol horseman charging directly forward with curved sabre raised` |
| 9 | `desert_cavalry` | 사막 기마 | 기동 | `mongol cavalry riding across vast desert dunes at golden hour` |
| 10 | `khans_fury` | 칸의 분노 | 기동 | `genghis khan roaring with arms raised radiating wrathful red energy` |
| 11 | `mobility_power` | 기동의 권능 | 기동 | `genghis khan astride black warhorse with aura of wind speed swirling` |
| 12 | `long_march` | 만리 원정 | 기동 | `endless column of mongol cavalry marching across vast distant horizon` |
| 13 | `red_horizon` | 붉은 지평선 | 기동 | `crimson sunset horizon with mongol cavalry silhouettes riding into red sky` |
| 14 | `great_khans_command` | 대칸의 명령 | 기동 | `genghis khan pointing decisively with bone scepter directing troops` |
| 15 | `signal_horn` | 신호 나팔 | 기동 | `mongol warrior blowing massive curved war horn from hilltop` |
| 16 | `flanking` | 측면 우회 | 기동 | `mongol cavalry sweeping wide to flank enemy from the side` |
| 17 | `genghis_fury` | 징기스의 분노 | 기동 | `genghis khan with eyes ablaze unleashing concentrated fury swing` |
| 18 | `cavalry_summon` | 기병 소집 | 몽골 기병 | `genghis khan raising banner summoning cavalry from all directions` |
| 19 | `arrow_volley` | 화살 세례 | 몽골 기병 | `dense volley of arrows raining down from sky over battlefield` |
| 20 | `horde_advance` | 호드 진군 | 몽골 기병 | `vast horde of mongol cavalry advancing in overwhelming massed wave` |
| 21 | `war_horse_power` | 군마의 권능 | 몽골 기병 | `mighty mongol warhorse rearing up with mane flowing radiating raw power` |
| 22 | `khans_banner` | 칸의 깃발 | 몽골 기병 | `nine-tailed white horsetail banner of genghis khan rising tall over camp` |
| 23 | `horde_volley` | 토큰 일제 사격 | 몽골 기병 | `row of mongol horse archers firing simultaneous arrow volley at gallop` |
| 24 | `ten_thousand_army` | 천만의 군세 | 몽골 기병 | `endless ocean of mongol troops stretching to horizon under one banner` |
| 25 | `cavalry_retreat` | 기병 후퇴 | 몽골 기병 | `mongol cavalry executing feigned retreat firing parthian shots backward` |
| 26 | `cavalry_encirclement` | 기병 포위망 | 몽골 기병 | `mongol cavalry encircling enemy in tight ring on open plain` |
| 27 | `plunderers_instinct` | 약탈자의 본능 | 몽골 기병 | `mongol raider with sharp eyes spotting prey from horseback` |
| 28 | `loot` | 노획 | 약탈 | `pile of looted gold jewels weapons and silks scattered in mongol camp` |
| 29 | `execution_ground` | 처형대 | 약탈 | `mongol execution ground with raised executioner and bound prisoners` |
| 30 | `spoils_distribution` | 전리품 배분 | 약탈 | `genghis khan distributing gold and spoils to bowing warriors around throne` |
| 31 | `executioners_bounty` | 처형 현상금 | 약탈 | `mongol executioner displaying severed enemy banner for bounty reward` |
| 32 | `massacre_khan` | 학살의 칸 | 약탈 | `genghis khan looming over burning city with blood-red sky behind` |
| 33 | `khans_treasury` | 칸의 보고 | 약탈 | `mongol khan treasury chamber overflowing with gold silk and silver coins` |
| 34 | `war_tribute` | 전쟁의 대가 | 약탈 | `kneeling conquered nobles offering tribute chests to mongol khan` |
| 35 | `khans_gamble` | 칸의 도박 | 약탈 | `genghis khan tossing bone dice on war table with map in candlelight` |

### 6-6. musashi (35장)

| # | card_id | 한글명 | 아키타입 | desc (영문) |
|--:|---|---|---|---|
| 1 | `swift_blade` | 신속의 검 | 무심 | `samurai drawing katana in lightning fast flash motion with motion lines` |
| 2 | `strike` | 스트라이크 | 이도류 | `samurai miyamoto musashi striking with single overhead katana cut` |
| 3 | `defend` | 디펜드 | 결투 | `samurai in low defensive stance with katana held horizontal block position` |
| 4 | `niten_starter` | 이도 입문 | 이도류 | `young samurai studying two sword niten ichi ryu basic stance` |
| 5 | `guard_stance` | 방어 자세 | 결투 | `samurai in firm guard stance with both swords raised crossed defensively` |
| 6 | `niten_slash` | 이도 베기 | 이도류 | `samurai two sword niten ichi simultaneous slash with both blades crossing` |
| 7 | `whirlwind_cut` | 선풍참 | 이도류 | `samurai spinning with both swords creating whirlwind of cutting arcs` |
| 8 | `twin_blades_basic` | 쌍도 기초 | 이도류 | `samurai practicing basic twin blade form with crossed swords stance` |
| 9 | `twin_sword_power` | 쌍검 권능 | 이도류 | `samurai radiating power with both swords held wide in mastery pose` |
| 10 | `rhythm_of_strikes` | 연격의 박자 | 이도류 | `samurai delivering rapid rhythmic strike combination with sequential cuts` |
| 11 | `flying_swallow` | 비연참 | 이도류 | `samurai performing swift swallow-cut motion mid-air leaping forward` |
| 12 | `five_rings_sword` | 오륜의 검 | 이도류 | `samurai with sword and five element rings of earth water fire wind void` |
| 13 | `twin_dragon` | 쌍룡섬 | 이도류 | `samurai unleashing twin dragon spirits from both swords in unison` |
| 14 | `steel_strike` | 강철 일격 | 이도류 | `samurai delivering single devastating heavy steel cut splitting target` |
| 15 | `demon_swordsman` | 검귀의 광기 | 이도류 | `samurai with demon mask snarling and bloodlust eyes wielding both swords` |
| 16 | `blood_path` | 혈로 개척 | 결투 | `samurai cutting his way through enemies leaving blood-soaked path behind` |
| 17 | `peak_aim` | 정점의 겨냥 | 결투 | `samurai with razor focused gaze and katana tip pointed at single target` |
| 18 | `courage` | 담력 | 결투 | `samurai standing fearless against onrushing enemy with calm steely face` |
| 19 | `swordsmans_resolve` | 검사의 결의 | 결투 | `samurai sitting in seiza meditation with sword across lap before duel` |
| 20 | `blade_polish` | 도검 연마 | 결투 | `samurai polishing katana blade with cloth in candlelit room of bamboo` |
| 21 | `single_cut` | 일도양단 | 결투 | `samurai single decisive cut splitting massive boulder cleanly in two` |
| 22 | `final_duel` | 마지막 결투 | 결투 | `two samurai facing each other in final duel on lonely shore at dawn` |
| 23 | `torrent` | 격류 | 결투 | `samurai unleashing torrent of unending blade strikes like river current` |
| 24 | `peerless_cut` | 무쌍 베기 | 결투 | `samurai performing peerless sword art with shimmering blade arc trail` |
| 25 | `fate_duel` | 운명의 결투 | 결투 | `two samurai locked in fateful duel under crimson autumn moonlight` |
| 26 | `meditation` | 명상 | 무심 | `samurai meditating in zen lotus pose under cherry blossom tree by waterfall` |
| 27 | `empty_state` | 무아지경 | 무심 | `samurai in transcendent empty mind state with calm radiance around him` |
| 28 | `void_sword` | 공허의 검 | 무심 | `samurai wielding ethereal void sword that fades into emptiness` |
| 29 | `mushin_power` | 무심의 권능 | 무심 | `samurai with closed eyes radiating mushin no shin empty mind power aura` |
| 30 | `empty_guard` | 공수처 | 무심 | `samurai in empty stance with open hands no weapon ready to receive any attack` |
| 31 | `mushin_blade` | 무심검 | 무심 | `samurai blade striking intuitively without thought flowing like calm water` |
| 32 | `clear_wind` | 청풍명월 | 무심 | `samurai meditating under bright moon with clear wind through pine trees` |
| 33 | `mushin_burst` | 무심 방출 | 무심 | `samurai releasing burst of pure mushin energy outward in shockwave` |
| 34 | `void_guard` | 공허의 방패 | 무심 | `samurai surrounded by void barrier sphere absorbing all incoming strikes` |
| 35 | `five_rings_realm` | 오륜의 경지 | 무심 | `samurai standing centered in realm of five elemental rings earth water fire wind void` |

---

## 7. 자동 조립 예시

### `napoleon_arcole_breakthrough` (인물 키워드 "charging" + "napoleon" 감지 → PERSON_ADDON 적용)

```
{STYLE_PREFIX}
napoleon waving tricolor flag charging across arcole bridge under fire,
(napoleon bonaparte french emperor with bicorne hat and military uniform)
{PERSON_ADDON}
{HERO_STYLE[napoleon]}
```

### `napoleon_eagle_standard` (인물 키워드 없음 → 사물 단독, HERO_CONTEXT/PERSON_ADDON 모두 생략)

```
{STYLE_PREFIX}
french imperial golden eagle standard on pole rising above battlefield
{HERO_STYLE[napoleon]}
```

---

## 8. ComfyUI 설정 권장

- 워크플로우: `tools/z_image_workflow.json` (기존 사용 가능)
- 모델: z_image_turbo (CFG=1, negative prompt 무효 — 모든 묘사 긍정형)
- 샘플러: res_multistep, scheduler: simple, shift: 3, steps: 8
- 해상도: **1024×906** (1.13:1 — 변경됨, 이전 1024×912 에서 6px 줄임)
- seed: 20260517 (영웅별 톤 일관성)
- 1 카드당 ~30-60초, 216장 ~약 2시간

---

## 9. 생성 후 체크리스트

1. [ ] 폴더에 정확히 **216개** PNG (영웅별 35/41/35/35/35/35)
2. [ ] 모든 파일명 형식 `{owner_id}_{card_id}.png` 일치 (단축 X, 변형 X)
3. [ ] 모든 해상도 1024×906
4. [ ] 텍스트·워터마크·서명·UI 요소 0
5. [ ] `python tools/verify_card_illustrations.py <폴더>` 결과 Missing 0 / Extra 0 / Size mismatch 0
