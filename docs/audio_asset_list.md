# 오디오 에셋 목록

AudioManager는 에셋이 없으면 경고 1회 후 no-op. 파일을 배치하면 즉시 재생됩니다.

## 배치 경로 규칙

```
assets/audio/sfx/{key}.wav   ← SFX (우선순위: .wav > .ogg > .mp3)
assets/audio/bgm/{key}.ogg   ← BGM (우선순위: .ogg > .wav > .mp3)
```

## SFX 키 목록

### P0 — 임팩트 (데미지 발생 시)

| 키 | 권장 길이 | 설명 |
|---|---|---|
| `impact_slash` | 0.3~0.5s | 베기 — 날카로운 검 소리 |
| `impact_blunt` | 0.3~0.5s | 둔기 — 둔탁한 충격음 |
| `impact_projectile` | 0.3~0.5s | 원거리 — 관통음 |
| `impact_explosive` | 0.5~0.8s | 폭발 — 큰 폭발음 |
| `impact_poison` | 0.3~0.5s | 독 — 거품 터지는 소리 |
| `impact_divine` | 0.4~0.6s | 신성 — 부드러운 종소리 |
| `impact_curse` | 0.3~0.5s | 저주 — 낮은 공명음 |
| `impact_fire` | 0.3~0.5s | 화염 — 불꽃 찍는 소리 |
| `impact_ice` | 0.3~0.5s | 빙결 — 얼음 깨지는 소리 |
| `impact_lightning` | 0.2~0.4s | 번개 — 짧은 전기음 |
| `impact_default` | 0.3~0.5s | 기본 임팩트 (dtype 미지정) |

### P0 — 카드/힐/블록

| 키 | 권장 길이 | 설명 |
|---|---|---|
| `card_play_attack` | 0.2~0.4s | 공격 카드 사용 — 칼/활 소리 |
| `card_play_skill` | 0.2~0.4s | 스킬 카드 사용 — 부드러운 마법음 |
| `card_play_power` | 0.3~0.5s | 파워 카드 사용 — 웅장한 차징음 |
| `heal` | 0.5~1.0s | 회복 — 밝은 치유음 |
| `block` | 0.3~0.5s | 방어 — 방패 강화음 |
| `ui_click` | 0.1s | UI 버튼 클릭 |

### P1 — 턴/사망/드로우

| 키 | 권장 길이 | 설명 |
|---|---|---|
| `turn_player_start` | 0.3~0.6s | 플레이어 턴 시작 |
| `turn_enemy_start` | 0.3~0.6s | 적 턴 시작 |
| `card_draw` | 0.15s | 카드 드로우 |
| `enemy_death` | 0.5~1.0s | 적 사망 |
| `hero_death` | 0.5~1.0s | 영웅 사망 |

## BGM 키 목록

| 키 | 권장 길이 | 설명 |
|---|---|---|
| `bgm_menu` | 1~3분 loop | 메인 메뉴 |
| `bgm_battle_normal` | 1~3분 loop | 일반 전투 |
| `bgm_battle_elite` | 1~3분 loop | 엘리트 전투 (현재 미연결) |
| `bgm_battle_boss` | 1~3분 loop | 보스 전투 (현재 미연결) |
| `bgm_victory` | 30~60s | 승리 (현재 미연결) |

## 포맷 권장

- **SFX:** WAV 16bit 44.1kHz 모노 또는 스테레오
- **BGM:** OGG Vorbis (loop point 메타데이터 포함 권장)
- 파일명은 키 이름 그대로: `impact_slash.wav`, `bgm_menu.ogg`

## 볼륨 설정 API

```gdscript
# 런타임 볼륨 조절 (0.0 ~ 1.0 linear)
AudioManager.set_bus_volume("Master", 0.8)
AudioManager.set_bus_volume("SFX", 1.0)
AudioManager.set_bus_volume("Music", 0.6)
AudioManager.set_bus_volume("UI", 0.9)
# → user://audio_settings.json에 자동 저장, 다음 실행 시 복원
```
