# 몬스터 일러스트 명세 v1 — 전체 192종

> 6 신화 × 32종 = 192 적 전체 명세. 카드 일러스트 명세 v13 과 같은 구조 (파일명/크기 규칙 동일).

## 0. 전체 규칙

### 0-1. 파일명 (절대 규칙)

- 형식: `{mythology}_{enemy_id}.png` — 그 외 변형 일절 금지
- mythology: `greek` / `egyptian` / `norse` / `buddhist` / `daoist` / `japanese`
- enemy_id 는 아래 표에서 그대로 복사. 절대 변형·재해석 X
- 모두 소문자 + snake_case + .png
- 예: `greek_minotaur.png`, `egyptian_ra_horakhty.png`, `japanese_yamata_no_orochi.png`

### 0-2. 해상도 (절대 규칙)

- **1024×1024 (1:1)** — 적은 정사각형 권장 (전투 화면 캐릭터 표시·신성/거인급 대형 적도 동일 비율)
- 모든 적 동일 크기
- PNG, 알파 채널 포함 (배경 투명) — 전투 씬 위 합성용
- 대안 (배경 포함): 1024×1024 풀배경도 가능. 한 종류로 통일.

### 0-3. 구도

- 적 캐릭터 단일 중앙 배치, 전신 또는 상반신
- 등급별 화면 점유율:
  - NORMAL: 캐릭터가 화면의 60-75%
  - ELITE: 캐릭터가 화면의 70-85% (위협감)
  - BOSS: 캐릭터가 화면의 80-95% (압도적 존재감)
- 정면 또는 약간 옆모습. 카메라 시선과 마주보거나 인접
- 텍스트·UI 요소·서명·워터마크 X

### 0-4. 신화별 톤 가이드

| 신화 | 톤 |
|---|---|
| greek | 고대 그리스 — 대리석 신전·청동/금 갑옷·올림포스 신·키마이라/켄타우로스 등 혼종 |
| egyptian | 고대 이집트 — 황금 가면·자칼/스카라베·미라·모래폭풍·상형문자 |
| norse | 북유럽 — 얼음·서리·룬 문자·거인·늑대·까마귀·붉은 광휘 |
| buddhist | 불교 — 천왕·여래·보살·야차·명왕·만다라·연꽃·금강 |
| daoist | 도교 — 선인·청룡/백호/주작/현무·옥·구름·산수화 |
| japanese | 일본 — 오니·텐구·갓파·요괴·사무라이 망령·키츠네·다양한 요괴 |

---

## 1. greek (그리스 신화) — 32종

### 1-1. 일반 적 (NORMAL, 19종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `cyclops` | 사이클롭스 | Cyclops | `huge one-eyed cyclops giant with massive stone club and shaggy beard` |
| 2 | `tartaros_shade` | 타르타로스의 망령 | Tartaros Shade | `pale ghostly underworld shade with hollow eyes drifting in dark mist` |
| 3 | `centaur` | 켄타우로스 | Centaur | `half-man half-horse centaur warrior with bow and quiver raised` |
| 4 | `chimera_cub` | 키마이라 새끼 | Chimera Cub | `young chimera cub with lion body small goat horns and snake tail` |
| 5 | `hydra_head` | 히드라의 머리 | Hydra Head | `single serpent hydra head with venomous fangs and green scales` |
| 6 | `ares_soldier` | 아레스 병사 | Ares Soldier | `greek hoplite soldier of ares with bronze helmet shield and spear` |
| 7 | `satyr` | 사티로스 | Satyr | `wild satyr with goat legs curved horns playing rustic pan flute` |
| 8 | `stone_shard` | 석상 파편 | Stone Shard | `animated jagged shard of broken marble statue floating menacingly` |
| 9 | `griffin_cub` | 그리핀 새끼 | Griffin Cub | `young griffin with eagle head feathered wings and lion hindquarters` |
| 10 | `giant_ant` | 거인 개미 | Giant Ant | `colossal armored myrmex giant ant with bronze mandibles` |
| 11 | `snake` | 메두사의 뱀 | Medusa's Serpent | `coiled green serpent with glowing yellow eyes from medusa's hair` |
| 12 | `medusid` | 메두사 화신 | Medusid | `lesser medusa avatar with stone gaze and writhing snake hair` |
| 13 | `lamia` | 라미아 | Lamia | `lamia woman with serpent lower body and seductive smile` |
| 14 | `stymphalian_bird` | 스팀팔리데스 | Stymphalian Bird | `vicious bronze-feathered stymphalian bird with metal beak` |
| 15 | `harpy` | 하르피아 | Harpy | `harpy with woman face bird body and razor-sharp talons swooping down` |
| 16 | `fire_crab` | 헤파이스토스 불게 | Fire Crab | `huge crab with shell glowing molten orange forged by hephaestus` |
| 17 | `dryad` | 드리아드 | Dryad | `forest dryad with bark skin leaves in hair and wooden bow` |
| 18 | `myrmidon` | 미르미돈 병사 | Myrmidon Soldier | `myrmidon hoplite in tight phalanx armor with red plume and spear` |
| 19 | `fly_harpy` | 소형 하르피아 | Small Harpy | `small juvenile harpy with patchy feathers and shrill screech` |

### 1-2. 엘리트 (ELITE, 10종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `minotaur` | 미노타우로스 | Minotaur | `massive minotaur with bull head and humanoid body wielding double-headed labrys` |
| 2 | `scylla` | 스킬라 | Scylla | `monstrous scylla with woman torso six dog heads emerging from waist tentacles below` |
| 3 | `gorgon` | 고르곤 | Gorgon | `gorgon woman with bronze claws snake hair and petrifying glare` |
| 4 | `medusa` | 메두사 | Medusa | `medusa with hair of writhing serpents stone-cold gaze and bow drawn` |
| 5 | `cerberus` | 케르베로스 | Cerberus | `three-headed hellhound cerberus with chains and burning eyes guarding underworld gate` |
| 6 | `erinyes` | 에리니에스 | Erinyes | `winged fury erinyes with snake hair brass whip and bloody robes` |
| 7 | `charon` | 카론 | Charon | `cloaked ferryman charon with long pole standing on river styx skiff` |
| 8 | `hephaestus_automaton` | 헤파이스토스 자동기계 | Hephaestus Automaton | `bronze mechanical golem forged by hephaestus with steam vents and gear joints` |
| 9 | `ares_hound` | 아레스의 사냥개 | Hound of Ares | `huge war hound of ares with armored collar bloodied fur and snarling jaws` |
| 10 | `poseidon_apostle` | 포세이돈 사도 | Apostle of Poseidon | `barnacled apostle of poseidon wielding coral trident with seafoam beard` |

### 1-3. 보스 (BOSS, 3종 — Act별 1)

| # | enemy_id | 한글명 | 영문명 | Act | desc (영문) |
|--:|---|---|---|---|---|
| 1 | `hydra` | 히드라 | Hydra | 1 | `nine-headed lernaean hydra with regenerating necks venomous breath and massive serpentine body` |
| 2 | `hades` | 하데스 | Hades | 2 | `lord of the underworld hades on dark throne with bident and helm of darkness shadow flames` |
| 3 | `kronos` | 크로노스 | Kronos | 3 | `titanic kronos with massive scythe time-warping aura and cosmic stars in beard` |

---

## 2. egyptian (이집트 신화) — 32종

### 2-1. 일반 적 (NORMAL, 20종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `sphinx_adult` | 성체 스핑크스 | Adult Sphinx | `adult sphinx with lion body human pharaoh head and outspread wings on sand` |
| 2 | `pyramid_golem` | 피라미드 골렘 | Pyramid Golem | `golem of sandstone bricks shaped like miniature pyramid with glowing hieroglyphs` |
| 3 | `mummy_warrior` | 미라 전사 | Mummy Warrior | `bandaged mummy warrior with khopesh sword and tattered linen wrappings` |
| 4 | `sand_ifrit` | 모래 이프리트 | Sand Ifrit | `swirling sand ifrit elemental with glowing red eyes formed from desert dust` |
| 5 | `sobek_spawn` | 소베크의 자식 | Sobek Spawn | `young crocodile-headed warrior of sobek with bronze armor on the nile bank` |
| 6 | `desert_scorpion` | 사막 전갈 | Desert Scorpion | `huge black desert scorpion with raised stinger and snapping pincers` |
| 7 | `ammit_cub` | 암밋 새끼 | Ammit Cub | `young ammit with crocodile snout lion mane and small hippo hindquarters` |
| 8 | `sand_scout` | 사막 척후병 | Sand Scout | `egyptian desert scout in light linen with composite bow and turban` |
| 9 | `clay_soldier` | 점토 병사 | Clay Soldier | `crude shabti clay soldier animated by ritual with painted face` |
| 10 | `nile_crocodile` | 나일 악어 | Nile Crocodile | `massive nile crocodile with golden eyes rising from murky water` |
| 11 | `sphinx_cub` | 스핑크스 새끼 | Sphinx Cub | `young sphinx cub with small lion body and curious child human face` |
| 12 | `khopesh_warrior` | 코페쉬 전사 | Khopesh Warrior | `egyptian warrior wielding sickle-shaped khopesh sword with striped nemes headdress` |
| 13 | `anubis_guard` | 아누비스 수호병 | Anubis Guard | `jackal-headed anubis guard in black armor holding ankh staff` |
| 14 | `ka_spirit` | 카 영혼 | Ka Spirit | `ethereal blue-glowing ka spirit double of a deceased pharaoh` |
| 15 | `tomb_wraith` | 무덤 망령 | Tomb Wraith | `wraith emerging from sarcophagus with golden tomb mask and rotted bandages` |
| 16 | `sand_wraith` | 모래 망령 | Sand Wraith | `ghostly wraith formed of swirling sand with hollow eye sockets` |
| 17 | `desert_ghoul` | 사막 구울 | Desert Ghoul | `gaunt desert ghoul with cracked sun-bleached skin and long claws` |
| 18 | `sand_rat` | 사막 들쥐 | Sand Rat | `oversized desert rat with patchy fur and sharp red eyes` |
| 19 | `jackal_priest` | 자칼 사제 | Jackal Priest | `jackal-headed egyptian priest in white robes holding ankh and incense` |
| 20 | `scarab` | 스카라베 | Scarab | `large iridescent golden scarab beetle with mystical hieroglyph carvings on shell` |

### 2-2. 엘리트 (ELITE, 9종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `obelisk_guardian` | 오벨리스크 수호자 | Obelisk Guardian | `towering stone obelisk guardian carved with hieroglyphs walking on rocky legs` |
| 2 | `jackal_warrior` | 자칼 전사 | Jackal Warrior | `jackal-headed warrior of anubis with twin curved blades and dark armor` |
| 3 | `scarab_queen` | 스카라베 여왕 | Scarab Queen | `enormous scarab queen with jeweled shell ruling swarm of golden beetles` |
| 4 | `seth_hound` | 세트의 사냥개 | Hound of Seth | `seth hound with long curved snout square ears and forked tail glowing red` |
| 5 | `serqet` | 셀케트 | Serqet | `Egyptian scorpion goddess Serqet, regal woman with a giant scorpion crowning her head, raised venomous stinger tail, golden regalia, dark temple` |
| 6 | `ba_bird` | 바 새 | Ba Bird | `winged ba spirit bird with human head representing a soul in flight` |
| 7 | `set_tempest` | 세트의 폭풍 | Tempest of Set | `chaotic sandstorm avatar of set with eye of storm and lightning bolts` |
| 8 | `apophis_serpent` | 아포피스의 뱀 | Serpent of Apophis | `colossal apophis chaos serpent coiled in cosmic void devouring sun` |
| 9 | `isis_phantom` | 이시스의 환영 | Phantom of Isis | `ethereal phantom of isis with widespread golden wings and mournful gaze` |

### 2-3. 보스 (BOSS, 3종)

| # | enemy_id | 한글명 | 영문명 | Act | desc (영문) |
|--:|---|---|---|---|---|
| 1 | `sekhmet` | 세크메트 | Sekhmet | 1 | `lioness-headed goddess sekhmet in red dress with sun disk and warhammer in fury` |
| 2 | `osiris` | 오시리스 | Osiris | 2 | `mummified osiris with green skin crook flail and atef crown radiating undead majesty` |
| 3 | `ra_horakhty` | 라-호라크티 | Ra-Horakhty | 3 | `falcon-headed ra-horakhty with massive solar disk crown and cosmic light wings spread wide` |

---

## 3. norse (북유럽 신화) — 32종

### 3-1. 일반 적 (NORMAL, 20종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `frost_giant` | 서리 거인 | Frost Giant | `huge jotunn frost giant with blue skin ice beard and massive ice club` |
| 2 | `ragnarok_herald` | 라그나로크 전령 | Ragnarok Herald | `pale herald of ragnarok blowing gjallarhorn with apocalyptic banners` |
| 3 | `jotun_soldier` | 요툰 병사 | Jotun Soldier | `jotunn warrior with fur cloak iron axe and braided beard` |
| 4 | `berserker` | 버서커 | Berserker | `wild norse berserker with bear-pelt cloak frothing mouth and twin axes` |
| 5 | `garmr` | 가름 | Garmr | `Garmr the blood-stained hound of Hel, monstrous black wolfhound with matted gore-soaked fur and burning red eyes, four-eyed Norse guardian beast` |
| 6 | `draugr` | 드라우그르 | Draugr | `undead draugr warrior with rotted face rusted sword and viking helm` |
| 7 | `nidhogg_scale` | 니드호그의 비늘 | Nidhogg Scale | `enchanted dark dragon scale of nidhogg with poison ooze` |
| 8 | `hrimfaxi_rider` | 흐림팍시 기수 | Hrimfaxi Rider | `cloaked rider on hrimfaxi ghostly horse with ice mane and frost trail` |
| 9 | `ice_wolf` | 얼음 늑대 | Ice Wolf | `arctic wolf with frost-white fur icicle fangs and breath of cold mist` |
| 10 | `runestone_golem` | 룬 골렘 | Runestone Golem | `golem of stacked runic stones with glowing carved norse runes` |
| 11 | `garlarr_snake` | 갸르라르 뱀 | Garlarr Snake | `dark coiled garlarr serpent of midgard with iron scales and forked tongue` |
| 12 | `volva_witch` | 볼바 마녀 | Völva Witch | `völva seeress in dark robes with staff bone necklace and hooded prophetic gaze` |
| 13 | `lindworm_spawn` | 린드웜 새끼 | Lindworm Spawn | `young lindworm wyrm with two clawed forelimbs serpentine body and small wings` |
| 14 | `frost_wight` | 서리 망령 | Frost Wight | `Norse frost wight, an undead draugr encased in jagged ice armor, frostbitten grey flesh, glowing pale-blue eyes, hoarfrost trailing from its fists` |
| 15 | `urdr_spider` | 우르드의 거미 | Urdr's Spider | `large spider of urdr at world tree roots weaving threads of fate` |
| 16 | `einherjar_ghost` | 전사의 유령 | Einherjar Ghost | `glowing spectral viking einherjar warrior with valhalla shield and spear` |
| 17 | `dark_elf` | 다크 엘프 | Dark Elf | `pale dark elf svartalfar with long ears black armor and shadow blade` |
| 18 | `raven_scout` | 라그나로크 까마귀 | Raven Scout | `huge black raven of odin huginn with intelligent red eyes` |
| 19 | `bone_archer` | 뼈 궁수 | Bone Archer | `skeletal archer with bone bow and quiver of jagged arrows` |
| 20 | `night_hag` | 밤 마녀 | Night Hag | `gnarled night hag with crooked staff long nose and tattered robes` |

### 3-2. 엘리트 (ELITE, 9종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `skoll` | 스콜 늑대 | Sköll Wolf | `huge dire wolf sköll chasing the sun with snarling teeth and glowing red eyes` |
| 2 | `modgud` | 모드구드 | Modgud | `Modgud the pale maiden guarding the Gjallarbru bridge to Hel, spectral Norse warden in frost-rimed robes holding a lantern, misty death-river behind` |
| 3 | `nidhogg_larva` | 니드호그 유충 | Nidhogg Larva | `juvenile nidhogg dragon larva with developing scales and small bat wings` |
| 4 | `troll_warrior` | 트롤 전사 | Troll Warrior | `mossy mountain troll warrior with stone club and warpaint snarling` |
| 5 | `norn` | 운명의 여신 노른 | Norn of Fate | `mysterious norn weaver of fate at well of urd with thread spindle and runes` |
| 6 | `vanir_elf` | 바나헤임 엘프 | Vanaheim Elf | `vanir elf in golden armor with antlered crown and bow of vanaheim` |
| 7 | `jormungandr_shard` | 요르문간드르 분신 | Shard of Jormungandr | `serpentine shard of jormungandr with glistening green scales and venomous fangs` |
| 8 | `fenrir_cub` | 펜리르 새끼 | Fenrir Cub | `young fenrir wolf cub with rapidly growing fangs and snarling muzzle` |
| 9 | `valkyrie` | 발키리 | Valkyrie | `winged valkyrie maiden in shining armor with spear and shield on flying horse` |

### 3-3. 보스 (BOSS, 3종)

| # | enemy_id | 한글명 | 영문명 | Act | desc (영문) |
|--:|---|---|---|---|---|
| 1 | `fjorgynn` | 피요르기닌 | Fjörgyn | 1 | `primal fjörgyn earth goddess with mossy stone skin antlers and roots growing from arms` |
| 2 | `surtr` | 수르트 | Surtr | 2 | `fire giant surtr with flaming sword laevateinn molten lava skin and ember beard` |
| 3 | `jormungandr` | 요르문간드르 | Jormungandr | 3 | `colossal jormungandr world serpent coiling around midgard with sea-spray scales` |

---

## 4. buddhist (불교) — 32종

### 4-1. 일반 적 (NORMAL, 20종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `hell_guardian` | 지옥 수호자 | Hell Guardian | `buddhist hell guardian with bull head red skin and iron mace` |
| 2 | `mara_general` | 마라 대장 | Mara General | `dark mara demon general in black armor with crown of skulls` |
| 3 | `vajrapani` | 금강역사 | Vajrapani | `muscular vajrapani temple guardian with vajra thunderbolt and fierce expression` |
| 4 | `virudhaka` | 증장천 | Virudhaka | `southern heavenly king virudhaka with blue skin sword and royal armor` |
| 5 | `ashura_warrior` | 아수라 전사 | Ashura Warrior | `three-faced six-armed ashura warrior wielding multiple weapons` |
| 6 | `asura` | 아수라 | Asura | `red-skinned asura demigod with two pairs of arms holding bow and sword` |
| 7 | `deva_soldier` | 천병 | Deva Soldier | `celestial deva soldier in gold and white armor with halo and spear` |
| 8 | `karmic_fiend` | 업 마귀 | Karmic Fiend | `dark karmic fiend bound in chains of bad karma with bloated body` |
| 9 | `pishacha` | 피사차 | Pishacha | `Pishacha, an emaciated flesh-eating demon of Buddhist lore, gaunt grey body, bulging red eyes, jagged fangs, clawed hands dripping with curses` |
| 10 | `sky_beast` | 천신 짐승 | Sky Beast | `celestial sky beast with lion body cloud mane and divine aura` |
| 11 | `yaksha` | 야차 | Yaksha | `yaksha tree spirit with green skin tusks and wooden club guarding forest shrine` |
| 12 | `lotus_spirit` | 연꽃 정령 | Lotus Spirit | `delicate lotus flower spirit with pale petal-skin and graceful pose` |
| 13 | `naga_spawn` | 나가 알 | Naga Spawn | `serpentine naga spawn with seven small cobra hoods emerging from egg` |
| 14 | `wrathful_spirit` | 분노 유령 | Wrathful Spirit | `wrathful tibetan spirit with bared fangs flame halo and skull garland` |
| 15 | `earth_spirit` | 지령 | Earth Spirit | `earth spirit golem of soil rocks and moss with deep voice` |
| 16 | `garuda` | 가루다 | Garuda | `garuda bird-man with massive eagle wings sharp beak and golden body` |
| 17 | `hungry_ghost` | 아귀 | Hungry Ghost | `gaunt preta hungry ghost with bloated belly tiny mouth and emaciated limbs` |
| 18 | `rakshasa` | 나찰 | Rakshasa | `Rakshasa, a ferocious Buddhist demon warrior with blue-black skin, tusked snarling face, lion-like mane, wielding a heavy cleaver, battle-scarred` |
| 19 | `cursed_monk` | 저주 승려 | Cursed Monk | `corrupted monk in tattered black robes with hollow eyes and prayer beads of bone` |
| 20 | `dharma_puppet` | 법 꼭두각시 | Dharma Puppet | `wooden dharma puppet animated by ritual with painted face and lacquered armor` |

### 4-2. 엘리트 (ELITE, 9종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `dharma_general` | 호법신중 | Dharma Guardian | `armored dharma guardian general with halberd and protective sutra banners` |
| 2 | `mahoraga` | 마후라가 | Mahoraga | `Mahoraga, a great serpent-deity of the Eight Legions, human torso with a massive python lower body and serpent-crowned head, hypnotic eyes, playing an eerie celestial flute` |
| 3 | `vaisravana` | 다문천왕 | Vaisravana | `northern heavenly king vaisravana in golden armor holding pagoda and mongoose` |
| 4 | `naga_king` | 용왕 | Naga King | `regal naga king with seven cobra hoods crowned head and serpent body in lotus pool` |
| 5 | `agni_buddha` | 화신여래 | Agni Buddha | `fire buddha agni with flame halo orange robes and lotus throne of fire` |
| 6 | `asura_king` | 아수라왕 | Asura King | `mighty asura king with multiple arms wielding bow arrow sword and shield` |
| 7 | `ksitigarbha` | 지장보살 | Ksitigarbha | `bodhisattva ksitigarbha with monk staff jewel orb and serene face in earth tones` |
| 8 | `yama` | 염라대왕 | Yama | `dark king yama of death with crown buffalo mount and judgment ledger` |
| 9 | `virupaksha` | 광목천왕 | Virupaksha | `Virupaksha, Heavenly King of the West, armored deva guardian with a stern all-seeing third eye, holding a coiled red dragon and a jewel, radiant holy aura` |

### 4-3. 보스 (BOSS, 3종)

| # | enemy_id | 한글명 | 영문명 | Act | desc (영문) |
|--:|---|---|---|---|---|
| 1 | `mahavairocana` | 대일여래 | Mahavairocana | 1 | `supreme cosmic buddha mahavairocana with thousand-armed mandala radiating divine sun light` |
| 2 | `guanyin` | 관세음보살 | Guanyin | 2 | `bodhisattva guanyin with thousand arms each holding eye willow branch and vase of compassion` |
| 3 | `acalanatha` | 부동명왕 | Acalanatha | 3 | `wrathful king acalanatha with flaming sword rope of binding fierce face and fire halo` |

---

## 5. daoist (도교) — 32종

### 5-1. 일반 적 (NORMAL, 20종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `dragon_king_child` | 용왕의 아들 | Dragon King's Child | `young chinese dragon prince with pearl scales antlers and child face` |
| 2 | `immortal_warrior` | 선인 전사 | Immortal Warrior | `daoist immortal warrior in flowing robes with sword cloud beneath feet` |
| 3 | `azure_guardian` | 청룡 호법 | Azure Guardian | `azure dragon guardian in green and blue armor with dragon-motif helm` |
| 4 | `celestial_lion` | 천사자 | Celestial Lion | `celestial lion with curly mane brocade collar and bright cloud aura` |
| 5 | `celestial_soldier` | 천병 | Celestial Soldier | `chinese celestial soldier in red and gold armor with halberd and cloud cape` |
| 6 | `nine_tailed_spirit` | 구미호 선 | Nine-Tailed Spirit | `daoist nine-tailed fox spirit immortal with seductive form and nine glowing tails` |
| 7 | `elder_hermit` | 고령 선인 | Elder Hermit | `elderly daoist hermit with white beard wooden staff and gourd of wine` |
| 8 | `mountain_spirit` | 산신 | Mountain Spirit | `regal mountain god with green robes long beard and tiger mount at side` |
| 9 | `iron_guard` | 철 수호병 | Iron Guard | `chinese iron-clad guard in heavy armor with halberd and stern face` |
| 10 | `hermit_ghost` | 시해선 | Hermit Ghost | `ethereal daoist sage who shed body translucent figure floating with scroll` |
| 11 | `fire_salamander` | 불 도롱뇽 | Fire Salamander | `flame salamander with orange scales fire breath and tail of pure flame` |
| 12 | `thunder_messenger` | 뇌신 전령 | Thunder Messenger | `daoist thunder god messenger with drums lightning bolts and mohawk hair` |
| 13 | `cloud_beast` | 구름 짐승 | Cloud Beast | `mythical chinese cloud beast made of swirling mist with horn and hooves` |
| 14 | `earth_dragon` | 지룡 | Earth Dragon | `serpentine earth dragon burrowing with brown scales and stone-like horns` |
| 15 | `dao_disciple` | 도사 수련생 | Dao Disciple | `young daoist disciple in blue robes practicing tai chi with sword stance` |
| 16 | `river_spirit` | 하천 신 | River Spirit | `chinese river god with flowing water-blue robes pearl and reed flute` |
| 17 | `jade_puppet` | 옥 꼭두각시 | Jade Puppet | `animated jade puppet of warrior carved with delicate detail glowing green` |
| 18 | `child_immortal` | 동자선 | Child Immortal | `child immortal in red robes carrying peach of immortality with topknot` |
| 19 | `wind_sprite` | 바람 요정 | Wind Sprite | `wispy wind sprite of swirling air leaves and flowing translucent silk` |
| 20 | `immortal_sprite` | 선신 정령 | Immortal Sprite | `small radiant immortal sprite with halo flowing sleeves and lotus in hand` |

### 5-2. 엘리트 (ELITE, 9종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `black_wind_immortal` | 흑풍선 | Black Wind Immortal | `black-robed dark wind immortal floating on swirling tornado clouds` |
| 2 | `silver_elixir` | 은단도사 | Silver Elixir Daoist | `daoist alchemist with silver elixir cauldron metallic robes and pill of immortality` |
| 3 | `golden_elixir` | 금단도사 | Golden Elixir Daoist | `daoist alchemist with golden elixir furnace shining gold robes and fire breath` |
| 4 | `nine_dragon` | 구룡선존 | Nine Dragon Immortal | `imperial daoist immortal commanding nine spectral dragons swirling around him` |
| 5 | `crimson_immortal` | 적양선 | Crimson Immortal | `crimson-robed sun immortal radiating red solar fire from outstretched palms` |
| 6 | `twin_immortals` | 쌍선인 | Twin Immortals | `pair of inseparable daoist immortal brothers one with sword one with fan` |
| 7 | `vermilion_bird` | 주작선군 | Vermilion Bird Immortal | `celestial vermilion phoenix bird immortal with red plumage and fire halo` |
| 8 | `white_tiger` | 백호선군 | White Tiger Immortal | `divine white tiger immortal with silver fur fierce stripes and metal claws` |
| 9 | `black_tortoise` | 현무선군 | Black Tortoise Immortal | `mystic black tortoise immortal entwined with snake on dome of dark shell` |

### 5-3. 보스 (BOSS, 3종)

| # | enemy_id | 한글명 | 영문명 | Act | desc (영문) |
|--:|---|---|---|---|---|
| 1 | `eastern_king` | 동왕공 | Eastern King | 1 | `eastern king dongwanggong in imperial yellow robes with phoenix crown and tablet of authority` |
| 2 | `xuanwu` | 진무대제 | Xuanwu | 2 | `dark warrior god xuanwu with black armor seven-star sword and tortoise-snake companion` |
| 3 | `jade_emperor` | 옥황상제 | Jade Emperor | 3 | `supreme jade emperor on celestial throne with dragon robes pearl crown and clouds beneath` |

---

## 6. japanese (일본) — 32종

### 6-1. 일반 적 (NORMAL, 20종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `gashadokuro` | 가샤도쿠로 | Gashadokuro | `Gashadokuro, a colossal vengeful skeleton yokai made of the bones of the starved, towering over a haunted moonlit field, hollow eye sockets glowing pale blue, massive bony hands` |
| 2 | `hannya` | 한냐 | Hannya | `terrifying hannya woman demon with horns sharp fangs and rage-filled hannya mask face` |
| 3 | `yamabushi_ghost` | 야마부시 영령 | Yamabushi Ghost | `ghostly yamabushi monk with conch horn small black cap and tattered pilgrim robes` |
| 4 | `ronin_ghost` | 로닌 망령 | Ronin Ghost | `pale wandering ronin ghost with torn kimono broken sword and hollow eyes` |
| 5 | `dragon_serpent` | 수룡 | Dragon Serpent | `japanese water dragon serpent with long serpentine body antlers and pearl in claws` |
| 6 | `samurai_ghost` | 사무라이 영령 | Samurai Ghost | `phantom samurai in translucent ghostly armor with broken katana and helmet` |
| 7 | `oni` | 오니 | Oni | `red-skinned oni demon with two horns sharp tusks and iron kanabo club` |
| 8 | `kappa` | 갓파 | Kappa | `green kappa river yokai with turtle shell beak water dish on head and webbed hands` |
| 9 | `shuten_minion` | 슈텐도지 졸개 | Shuten-doji Minion | `small oni minion of shuten-doji with sake gourd and red skin laughing` |
| 10 | `tennyo` | 천녀 | Tennyo | `Tennyo, a Japanese celestial maiden in a flowing feathered hagoromo robe, serene benevolent face, descending from gilded clouds with healing light in her hands` |
| 11 | `tatami_monster` | 다다미 괴물 | Tatami Monster | `living tatami floor mat yokai with rolling form and sinister glowing eyes` |
| 12 | `tengu` | 텐구 | Tengu | `karasu tengu crow yokai with long nose feathered wings and mountain ascetic robes` |
| 13 | `hone_onna` | 호네온나 | Hone-Onna | `Hone-onna, a Japanese skeletal woman yokai disguised in tattered funeral kimono, gaunt skull face partly revealed beneath veil, bony fingers reaching to drain the living` |
| 14 | `yuki_onna` | 유키온나 | Yuki-onna | `ghostly yuki-onna snow spirit with floating white kimono and skin pale as snow` |
| 15 | `yamabiko` | 야마비코 | Yamabiko | `mountain echo yokai resembling small monkey-like creature with cupped ears` |
| 16 | `foxfire` | 여우불 | Foxfire | `mystical blue-green foxfire kitsune-bi floating flame with subtle fox face` |
| 17 | `ittan_momen` | 잇탄모멘 | Ittan-Momen | `floating strip of haunted white cloth ittan-momen yokai drifting menacingly` |
| 18 | `azuki_washer` | 아즈키 씻는 귀신 | Azuki Washer | `small azuki-arai yokai by stream washing red azuki beans with eerie smile` |
| 19 | `cursed_scroll` | 저주 두루마리 | Cursed Scroll | `unfurled cursed paper scroll with red ink kanji and floating brush ink dripping` |
| 20 | `koropokkuru` | 코로포쿠루 | Koropokkuru | `tiny ainu koropokkuru folk spirit under butterbur leaf with mischievous face` |

### 6-2. 엘리트 (ELITE, 9종)

| # | enemy_id | 한글명 | 영문명 | desc (영문) |
|--:|---|---|---|---|
| 1 | `invincible_ronin` | 로닌 무적 | Invincible Ronin | `legendary invincible ronin in tattered kimono with two long katanas and steely glare` |
| 2 | `yamamba` | 야마우바 | Yamamba | `mountain hag yamamba with wild white hair tattered robes and twisted yokai claws` |
| 3 | `ushi_oni` | 우시오니 | Ushi-Oni | `Ushi-oni, an ox-headed Japanese demon, massive bovine skull with curved horns atop a hulking spider-clawed body, dripping fangs, blunt rocky fists, coastal cave background` |
| 4 | `yasha` | 야샤 | Yasha | `fierce yasha demon with green skin multiple eyes and bone necklace fangs bared` |
| 5 | `chaos_tengu` | 혼돈의 텐구 | Chaos Tengu | `daitengu great tengu with long red nose huge black wings and chaos magic` |
| 6 | `nureriyon` | 누레리온 | Nurarihyon | `nurarihyon yokai elder with elongated bald head smug face and refined kimono` |
| 7 | `susanoo_blade` | 스사노오의 검 | Blade of Susanoo | `legendary kusanagi sword of susanoo floating with storm clouds and lightning aura` |
| 8 | `iwato_guardian` | 아마노이와토 수문장 | Amano-Iwato Guardian | `divine sun cave guardian in white shinto robes with magatama necklace and ritual mirror` |
| 9 | `jorogumo` | 조로구모 | Jorogumo | `Jorogumo, a Japanese spider-woman yokai, beautiful kimono-clad upper body with eight chitinous spider legs sprouting from her back, weaving glistening silk web traps, ominous` |

### 6-3. 보스 (BOSS, 3종)

| # | enemy_id | 한글명 | 영문명 | Act | desc (영문) |
|--:|---|---|---|---|---|
| 1 | `raijin` | 라이덴 | Raijin | 1 | `thunder god raijin with red skin ring of taiko drums above head and thunderbolt sticks` |
| 2 | `shuten_doji` | 슈텐도지 | Shuten-doji | 2 | `legendary oni king shuten-doji with horns sake cup feast scene and demon-king crown` |
| 3 | `yamata_no_orochi` | 야마타노오로치 | Yamata no Orochi | 3 | `eight-headed eight-tailed serpent yamata no orochi with cedar trees on body venom dripping fangs` |

---

## 7. 생성 후 체크리스트

1. [ ] 폴더에 정확히 **192개** PNG (신화별 32 — greek/egyptian/norse/buddhist/daoist/japanese)
2. [ ] 모든 파일명 형식 `{mythology}_{enemy_id}.png` 일치 (단축 X, 변형 X)
3. [ ] 모든 해상도 1024×1024 (정사각형)
4. [ ] 텍스트·워터마크·서명·UI 요소 0
5. [ ] 등급별 화면 점유율 가이드 준수 (NORMAL 60-75% / ELITE 70-85% / BOSS 80-95%)

## 8. 등급 요약

| 신화 | NORMAL | ELITE | BOSS | 합계 |
|---|--:|--:|--:|--:|
| greek | 19 | 10 | 3 | 32 |

| egyptian | 20 | 9 | 3 | 32 |
| norse | 20 | 9 | 3 | 32 |
| buddhist | 20 | 9 | 3 | 32 |
| daoist | 20 | 9 | 3 | 32 |
| japanese | 20 | 9 | 3 | 32 |
| **총** | **119** | **55** | **18** | **192** |
