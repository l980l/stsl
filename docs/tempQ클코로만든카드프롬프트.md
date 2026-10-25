# V9 카드 생성에 사용된 프롬프트 정리

ComfyUI z_image_turbo (CFG=1, 8 steps, seed=20260517, 1024×912) 입력으로 들어가는 텍스트 구조.

조립 순서:
```
STYLE_PREFIX + 카드 desc + HERO_CONTEXT + (PERSON_ADDON, 인물일 때만) + HERO_STYLE
```

---

## 1. 공통: STYLE_PREFIX (모든 카드 앞에 붙음)

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

## 2. 공통: PERSON_ADDON (인물이 등장하는 카드만 suffix)

자동 감지 키워드 (소문자 desc에 하나라도 포함되면 인물로 판정):
`soldier, officer, warrior, knight, samurai, horseman, cavalry, archer, figure, cleopatra, napoleon, joan, genghis, musashi, admiral, guard, commander, pharaoh, queen, isis, sekhmet, goddess, people, person, khan, marshal, scout, drummer, bugler, saint, rider, men, musketeer, grenadier, hussar, monk, priest, kneeling, leaning, blowing, swinging, raising, charging, dancing, meditating, praying, standing, exhaling, embracing, fighting, ridden, riding, mummy, ridge`

```
, humans depicted as bold abstract figures with strong distinctive silhouettes,
recognizable by their iconic clothing and accessories from their era,
expressive simplified features, refined editorial illustration style
```

---

## 3. 영웅별 HERO_CONTEXT (카드 desc 뒤 괄호 안)

| 영웅 | 컨텍스트 |
|---|---|
| napoleon | `napoleon bonaparte french emperor with bicorne hat and military uniform` |
| cleopatra | `egyptian queen cleopatra with snakes and gold jewelry` |
| yi_sun_sin | `korean joseon admiral yi sun sin with red brigandine armor and helmet` |
| joan_of_arc | `saint joan of arc french medieval knight in shining armor with holy light` |
| genghis_khan | `mongol warrior genghis khan with fur hat and horse archer bow` |
| musashi | `japanese samurai miyamoto musashi with two katana swords and topknot` |

## 4. 영웅별 HERO_STYLE (프롬프트 맨 끝 suffix — 국가/문화 톤 결정)

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

## 5. 영웅별 카드 desc 샘플 (각 3장)

### napoleon
| slug | desc |
|---|---|
| arcole_breakthrough | `napoleon waving tricolor flag charging across bridge` |
| imperial_artillery | `huge bronze cannon firing flame` |
| eagle_standard | `french imperial golden eagle standard on pole` |

### cleopatra
| slug | desc |
|---|---|
| cleopatras_kiss | `cleopatra blowing a poison kiss` |
| isis_judgment | `isis weighing a heart on golden scales` |
| nile_doom | `blood red nile wave of doom` |

### yi_sun_sin
| slug | desc |
|---|---|
| turtle_ship_charge | `korean turtle ship boat with dragon head charging with fire` |
| crane_wing | `v-shaped crane wing fleet formation` |
| hansan_victory | `hansan battle crane wing formation sinking enemy ships` |

### joan_of_arc
| slug | desc |
|---|---|
| orleans_charge | `joan of arc charging with banner at orleans` |
| holy_fury | `knight with sword surrounded by holy explosion radiance` |
| altar_flame | `a stone altar with eternal flame` |

### genghis_khan
| slug | desc |
|---|---|
| cavalry_charge | `mongol cavalry charging on horseback` |
| arrow_volley | `volley of arrows raining down` |
| steppe_storm | `great steppe sandstorm with riders` |

### musashi
| slug | desc |
|---|---|
| niten_slash | `samurai two sword niten ichi slash` |
| five_rings_realm | `five elements rings realm earth water fire wind void` |
| flying_swallow | `samurai swallow swift cutting motion` |

---

## 6. 실제 조립된 프롬프트 예시

### `napoleon_arcole_breakthrough` (인물 있음)
```
{STYLE_PREFIX} napoleon waving tricolor flag charging across bridge,
(napoleon bonaparte french emperor with bicorne hat and military uniform){PERSON_ADDON}{HERO_STYLE[napoleon]}
```

### `napoleon_eagle_standard` (인물 없음 — 사물)
```
{STYLE_PREFIX} french imperial golden eagle standard on pole{HERO_STYLE[napoleon]}
```

(인물 없는 카드는 HERO_CONTEXT, PERSON_ADDON 모두 생략. 사물 단독 묘사 후 영웅 톤만 적용.)

---

## 7. 메모

- z_image_turbo는 CFG=1이라 negative prompt 무효. 모든 표현이 긍정형.
- 모든 카드 같은 seed(20260517) 사용 → 영웅별 톤 일관성 ↑.
- 한 카드당 약 30~60초, 245장 ~약 2시간.
- ComfyUI 워크플로우: `image_z_image_turbo.json` (8 steps, res_multistep sampler, simple scheduler, shift=3).
