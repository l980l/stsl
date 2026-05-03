#!/usr/bin/env python3
"""
STSL 오디오 에셋 생성 스크립트 V2 (ComfyUI API)

SFX: stable-audio-open-1.0 / duration=1초 / trailing silence 트림 / 진폭 검증
BGM: ace-step-1.5 XL / 신화별×3 + 보스별 phase1+p2 / 진폭 검증

파일명 규칙:
  SFX: assets/audio/sfx/{key}_{N}.mp3   (N=variant 번호)
  BGM: assets/audio/bgm/{key}.mp3       (신화 variant도 key에 번호 포함)

사용법 (프로젝트 루트에서 실행):
  python tools/generate_audio_assets.py --key impact_slash        # 단일 SFX 전체 variant
  python tools/generate_audio_assets.py --all-sfx                 # SFX 51개
  python tools/generate_audio_assets.py --all-bgm-mythology       # 신화BGM 19개(메뉴+신화18)
  python tools/generate_audio_assets.py --all-bgm-boss            # 보스BGM 36개
  python tools/generate_audio_assets.py --all-bgm                 # BGM 전체 55개
  python tools/generate_audio_assets.py --regenerate impact_slash # 덮어쓰고 재생성

의존성: pydub (pip install pydub) + ffmpeg (PATH에 있어야 함)
"""

import argparse
import json
import random
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

import os
import shutil

# ffmpeg 경로 자동 감지 (PATH에 없으면 알려진 위치 탐색)
_FFMPEG_CANDIDATES = [
    r"H:\AIRelatedDefaultPath\GeminiCLI_Base\Done\youtube_downloader\bin\ffmpeg.exe",
    r"C:\Program Files\SteelSeries\GG\apps\moments\ffmpeg.exe",
]
_ffmpeg_path = shutil.which("ffmpeg")
if not _ffmpeg_path:
    for _cand in _FFMPEG_CANDIDATES:
        if os.path.isfile(_cand):
            _ffmpeg_path = _cand
            os.environ["PATH"] = os.path.dirname(_cand) + os.pathsep + os.environ.get("PATH", "")
            break

try:
    import miniaudio
    MINIAUDIO_OK = True
except ImportError:
    MINIAUDIO_OK = False

try:
    from mutagen.mp3 import MP3 as MutagenMP3
    MUTAGEN_OK = True
except ImportError:
    MUTAGEN_OK = False

DEFAULT_COMFY_URL = "http://127.0.0.1:8188"
SFX_WORKFLOW = "tools/audio_workflow_sfx.json"
BGM_WORKFLOW = "tools/audio_workflow_bgm.json"
SFX_OUT_DIR = Path("assets/audio/sfx")
BGM_OUT_DIR = Path("assets/audio/bgm")
MAX_RETRY = 2

# SFX 품질 기준 (pydub 사용 시)
SFX_PEAK_MIN_DBFS = -10.0
SFX_RMS_MIN_DBFS  = -35.0
SFX_DUR_MIN_MS    = 80
SFX_DUR_MAX_MS    = 3500
# BGM 품질 기준
BGM_PEAK_MIN_DBFS = -10.0
BGM_RMS_MIN_DBFS  = -30.0
BGM_DUR_MIN_MS    = 75_000   # 75초
BGM_DUR_MAX_MS    = 100_000  # 100초
# fallback: pydub 없을 때 파일 크기 기준
SFX_MIN_BYTES = 8 * 1024
BGM_MIN_BYTES = 1_000 * 1024

# ───────────────────────────────────────────
# SFX variant 개수
# ───────────────────────────────────────────
VARIANT_COUNTS: dict[str, int] = {
    "impact_slash": 3, "impact_blunt": 2, "impact_projectile": 1,
    "impact_explosive": 2, "impact_poison": 1, "impact_divine": 1,
    "impact_curse": 1, "impact_fire": 1, "impact_ice": 1,
    "impact_lightning": 1, "impact_default": 1,
    "card_hold": 1, "card_hover": 1,
    "heal": 1, "block": 1, "ui_click": 1, "card_draw": 1,
    "enemy_death": 1, "hero_death": 1,
    "ui_hover": 1,
}

# SFX 생성 duration (초) — 모델 최소 1초, 생성 후 앞뒤 무음 트림
SFX_DURATIONS: dict[str, float] = {
    "impact_slash": 1.0, "impact_blunt": 1.0, "impact_projectile": 1.0,
    "impact_explosive": 2.0, "impact_poison": 1.5, "impact_divine": 2.0,
    "impact_curse": 2.0, "impact_fire": 1.5, "impact_ice": 1.5,
    "impact_lightning": 1.0, "impact_default": 1.0,
    "card_hold": 1.0, "card_hover": 1.0,
    "heal": 2.0, "block": 1.0, "ui_click": 1.0, "card_draw": 1.0,

    "enemy_death": 2.0, "hero_death": 3.0,
    "ui_hover": 1.0,
}

# ───────────────────────────────────────────
# SFX 프롬프트 (stable-audio-open-1.0)
# 형식: foley/field recording + 주체 + 동작 + 표면/대상 + 톤 형용사
# ───────────────────────────────────────────
SFX_PROMPTS: dict[str, str] = {
    "impact_slash":      "foley sword whoosh, fast steel blade swing through air, sharp dry close-mic recording",
    "impact_blunt":      "heavy mace hitting wooden shield, deep thud impact, foley field recording, dry",
    "impact_projectile": "arrow puncture into wood, quick sharp thud, foley field recording, dry close-mic",
    "impact_explosive":  "short powerful explosion, low boom with debris crackle, cinematic dry close-mic",
    "impact_poison":     "wet acid splash and bubbling burst, slimy hiss, foley close-mic recording",
    "impact_divine":     "soft golden bell chime, warm shimmer resonance, magical foley, clean dry",
    "impact_curse":      "dark low resonance hum, ominous ritual tone, foley close-mic, dry",
    "impact_fire":       "flame ignition snap, crackling fire burst, foley field recording, dry sharp",
    "impact_ice":        "glassy crystalline shatter, cold cracking ice, foley close-mic, dry",
    "impact_lightning":  "electric zap snap, sharp thunder crack, foley close-mic, dry",
    "impact_default":    "solid impact thud, neutral hit, foley field recording, dry close-mic",
    "card_hold":         "soft card pickup lift, gentle paper rustle, subtle magical shimmer, foley close-mic, dry",
    "card_hover":        "very soft card hover, light airy swipe, gentle paper rustle, subtle UI hover sound, foley dry",
    "heal":              "warm golden bell shimmer, magical healing chime, soft resonance, foley dry",
    "block":             "metallic shield raise clink, armor brace thud, foley close-mic, solid dry",
    "ui_click":          "short crisp mechanical button click, clean interface sound, foley dry",
    "card_draw":         "single playing card slide from deck, quick paper swipe, foley close-mic, dry",

    "enemy_death":       "monster death grunt and collapse, organic impact, foley close-mic, dry",
    "hero_death":        "dramatic warrior fall, cloth foley and somber thud, cinematic close-mic",
    "ui_hover":          "soft whoosh hover, light airy swipe, clean UI interface sound, gentle dry",
}
SFX_NEGATIVE = "Low quality, distorted, average quality, noise, hum, silence"

# ───────────────────────────────────────────
# BGM 프롬프트 (ace-step-1.5 XL, 90초)
# 형식: genre/era → instruments → mood → production
# ───────────────────────────────────────────
def _bgm(tags: str, bpm: int, key: str, dur: int = 90) -> dict:
    return {"tags": tags, "lyrics": "[instrumental]", "bpm": bpm,
            "keyscale": key, "duration": dur}

BGM_PROMPTS: dict[str, dict] = {
    # ── 메뉴 (1개) ──
    "bgm_menu": _bgm(
        "ambient orchestral, soft strings, distant choir, contemplative, slow, no vocals, no percussion, peaceful fantasy",
        65, "Am"),

    # ── 그리스 일반 전투 ×3 ──
    "bgm_battle_greek_1": _bgm(
        "ancient greek battle, lyre, aulos, pan flute, war drums, dorian mode, tense, no vocals, intense",
        105, "Em"),
    "bgm_battle_greek_2": _bgm(
        "ancient hellenic war, brass horns, marching strings, heroic stoic, tense, no vocals, driving",
        112, "Am"),
    "bgm_battle_greek_3": _bgm(
        "greek epic battle, kithara, battle percussion, modal, dark orchestral, no vocals, relentless",
        118, "Dm"),

    # ── 이집트 일반 전투 ×3 ──
    "bgm_battle_egyptian_1": _bgm(
        "ancient egyptian war, oud, ney, frame drum, mystical battle, no vocals, driving",
        100, "Am"),
    "bgm_battle_egyptian_2": _bgm(
        "egyptian pharaoh battle, qanun, doumbek, brass, tense mystical, no vocals, intense",
        108, "Dm"),
    "bgm_battle_egyptian_3": _bgm(
        "desert sand battle, sistrum, war drums, dark orchestral, no vocals, relentless",
        115, "Am"),

    # ── 북유럽 일반 전투 ×3 ──
    "bgm_battle_norse_1": _bgm(
        "viking battle, throat singing, deep war horns, tribal drums, runic harsh, no vocals, driving",
        110, "Em"),
    "bgm_battle_norse_2": _bgm(
        "norse epic war, frame drum, low brass, snare, dark relentless, no vocals, intense",
        118, "Am"),
    "bgm_battle_norse_3": _bgm(
        "frost battle, deep horns, battle percussion, ominous, nordic harsh, no vocals",
        105, "Dm"),

    # ── 한국 일반 전투 ×3 ──
    "bgm_battle_korean_1": _bgm(
        "korean epic war battle, fierce taepyeongso, thunderous buk drums, haegeum tension, dark intense ferocious, no vocals",
        115, "Am"),
    "bgm_battle_korean_2": _bgm(
        "joseon fierce battle, driving janggu percussion, daegeum war cry, dark ominous strings, relentless intense, no vocals",
        120, "Em"),
    "bgm_battle_korean_3": _bgm(
        "korean warring states, massive war drums ensemble, haegeum dark tension, geomungo low drones, brutal ferocious, no vocals",
        112, "Dm"),

    # ── 중국 일반 전투 ×3 ──
    "bgm_battle_chinese_1": _bgm(
        "ancient chinese battle, erhu, dizi, war gongs, dragon epic, no vocals, intense",
        110, "Am"),
    "bgm_battle_chinese_2": _bgm(
        "chinese imperial war, pipa, suona, large drum, relentless, no vocals, driving",
        118, "Em"),
    "bgm_battle_chinese_3": _bgm(
        "chinese epic battle, guqin, bronze bells, war percussion, modal tense, no vocals",
        106, "Dm"),

    # ── 일본 일반 전투 ×3 ──
    "bgm_battle_japanese_1": _bgm(
        "samurai battle, taiko, shakuhachi, fierce wadaiko, dorian, no vocals, intense",
        112, "Em"),
    "bgm_battle_japanese_2": _bgm(
        "japanese war, biwa, taiko storm, koto, dark tense, no vocals, driving",
        120, "Am"),
    "bgm_battle_japanese_3": _bgm(
        "feudal japan battle, shamisen, large taiko, relentless, no vocals, harsh",
        115, "Dm"),

    # ── 그리스 보스 ──
    "bgm_boss_hydra": _bgm(
        "greek epic boss battle, full orchestra ensemble, dark strings and brass, tympani war drums, serpent menace, majestic ominous, no vocals",
        112, "Em"),
    "bgm_boss_hydra_p2": _bgm(
        "hydra multi-headed fury, full orchestral climax, frantic string ensemble, thunderous brass and tympani, relentless overwhelming, no vocals",
        152, "Em"),
    "bgm_boss_hades": _bgm(
        "greek underworld god, grand orchestral ensemble, deep bass choir, dark brass, pipe organ, ominous majestic, no vocals",
        92, "Am"),
    "bgm_boss_hades_p2": _bgm(
        "hades divine wrath, full orchestra eruption, demonic choir ensemble, thunderous brass, frantic strings, overwhelming darkness, no vocals",
        155, "Am"),
    "bgm_boss_kronos": _bgm(
        "greek titan lord, massive full orchestra, brass ensemble fanfare, thunderous tympani, ominous choir, overwhelming titan majesty, no vocals",
        115, "Dm"),
    "bgm_boss_kronos_p2": _bgm(
        "kronos titan rage, full orchestral fury, frantic brass ensemble, shattering percussion, choir eruption, world-shaking power, no vocals",
        158, "Dm"),
    "bgm_boss_kronos_p3": _bgm(
        "kronos final stand, absolute orchestral chaos, catastrophic brass, world-ending percussion, desperate choir, ultimate climax, no vocals",
        172, "Dm"),

    # ── 이집트 보스 ──
    "bgm_boss_sekhmet": _bgm(
        "egyptian war goddess, grand orchestral ensemble, fierce oud and qanun, powerful brass, war drums, lion goddess majesty, no vocals",
        118, "Am"),
    "bgm_boss_sekhmet_p2": _bgm(
        "sekhmet blood frenzy, full orchestra climax, frantic qanun ensemble, thunderous brass, desert fury overwhelming, no vocals",
        158, "Am"),
    "bgm_boss_osiris": _bgm(
        "egyptian death god, grand orchestral ceremony, deep choir ensemble, oud, ceremonial brass, divine judgement majesty, no vocals",
        96, "Dm"),
    "bgm_boss_osiris_p2": _bgm(
        "osiris final judgement, full orchestral eruption, choir ensemble climax, thunderous ceremonial drums, overwhelming divine power, no vocals",
        150, "Dm"),
    "bgm_boss_ra_horakhty": _bgm(
        "egyptian sun god, radiant full orchestra, brass fanfare ensemble, frame drum, blazing strings, solar divine majesty, no vocals",
        118, "Am"),
    "bgm_boss_ra_horakhty_p2": _bgm(
        "ra horakhty solar wrath, full orchestra blaze, frantic brass ensemble, blazing percussion, divine overwhelming climax, no vocals",
        160, "Am"),
    "bgm_boss_ra_horakhty_p3": _bgm(
        "ra horakhty absolute power, catastrophic brass orchestra, blinding climax ensemble, solar apocalypse, ultimate overwhelming, no vocals",
        175, "Am"),

    # ── 북유럽 보스 ──
    "bgm_boss_fjorgynn": _bgm(
        "norse storm god, grand orchestral ensemble, deep war horns, thunder tympani, dark strings, storm majesty overwhelming, no vocals",
        114, "Em"),
    "bgm_boss_fjorgynn_p2": _bgm(
        "fjorgynn storm fury, full orchestra thunder, frantic horn ensemble, crashing percussion, runic choir, overwhelming tempest, no vocals",
        155, "Em"),
    "bgm_boss_surtr": _bgm(
        "fire giant lord, grand orchestral inferno, blazing brass ensemble, massive tympani, dark strings, fire god majesty, no vocals",
        120, "Am"),
    "bgm_boss_surtr_p2": _bgm(
        "surtr world-burning rage, full orchestra inferno, frantic brass ensemble, catastrophic percussion, overwhelming fire climax, no vocals",
        162, "Am"),
    "bgm_boss_jormungandr": _bgm(
        "world serpent rising, grand orchestral ensemble, deep brass menace, massive tympani, dark strings, ocean abyss majesty, no vocals",
        108, "Dm"),
    "bgm_boss_jormungandr_p2": _bgm(
        "jormungandr world-ending fury, full orchestra chaos, frantic brass ensemble, thunderous percussion, overwhelming serpent climax, no vocals",
        152, "Dm"),
    "bgm_boss_jormungandr_p3": _bgm(
        "jormungandr ragnarok, absolute orchestral apocalypse, catastrophic brass, world-shattering percussion, ultimate overwhelming climax, no vocals",
        168, "Dm"),

    # ── 한국 보스 ──
    "bgm_boss_dangun": _bgm(
        "korean god-king battle, grand orchestral ensemble, daegeum and taepyeongso, heroic brass, janggu war drums, divine majesty, no vocals",
        112, "Am"),
    "bgm_boss_dangun_p2": _bgm(
        "dangun divine wrath, full orchestral climax, frantic daegeum ensemble, thunderous buk drums, overwhelming divine power, no vocals",
        155, "Am"),
    "bgm_boss_samsin_grandma": _bgm(
        "korean fate goddess, grand orchestral ensemble, haegeum and gayageum, mysterious strings, ominous percussion, dark mystical majesty, no vocals",
        95, "Em"),
    "bgm_boss_samsin_grandma_p2": _bgm(
        "samsin grandma fate wrath, full orchestral eruption, frantic haegeum ensemble, fate percussion climax, overwhelming darkness, no vocals",
        148, "Em"),
    "bgm_boss_gusamseung_halmang": _bgm(
        "korean sea goddess boss battle, no intro, starts immediately full energy, grand orchestral gayageum haegeum, thunderous janggu drums from bar one, intense relentless, no vocals",
        100, "Dm"),
    "bgm_boss_gusamseung_halmang_p2": _bgm(
        "sea goddess ocean fury, no intro, full energy from start, frantic gayageum orchestral storm, thunderous ocean drums immediately, overwhelming climax, no vocals",
        150, "Dm"),
    "bgm_boss_gusamseung_halmang_p3": _bgm(
        "sea goddess final wrath, no intro, maximum intensity from first beat, absolute orchestral tempest, catastrophic percussion ensemble, ultimate overwhelming, no vocals",
        165, "Dm"),

    # ── 중국 보스 ──
    "bgm_boss_chiyou": _bgm(
        "chinese war god, grand orchestral ensemble, fierce erhu and dizi, war gongs and brass, battle drums, ancient warrior majesty, no vocals",
        118, "Am"),
    "bgm_boss_chiyou_p2": _bgm(
        "chiyou berserker fury, full orchestral battle, frantic erhu ensemble, thunderous gongs, overwhelming ancient war climax, no vocals",
        160, "Am"),
    "bgm_boss_erlang_shen": _bgm(
        "chinese divine warrior, grand orchestral ensemble, dizi and pipa, heroic brass, battle drums, divine warrior majesty, no vocals",
        116, "Em"),
    "bgm_boss_erlang_shen_p2": _bgm(
        "erlang shen divine strike, full orchestral power, frantic dizi ensemble, thunderous percussion, overwhelming divine climax, no vocals",
        158, "Em"),
    "bgm_boss_pangu": _bgm(
        "world creation god, colossal full orchestra, massive brass ensemble, epic choir, ancient tympani, primal creation majesty, no vocals",
        95, "Dm"),
    "bgm_boss_pangu_p2": _bgm(
        "pangu world-splitting fury, full orchestral eruption, thunderous brass ensemble, colossal percussion, overwhelming creation climax, no vocals",
        148, "Dm"),
    "bgm_boss_pangu_p3": _bgm(
        "pangu absolute creation, catastrophic orchestral power, world-shattering brass ensemble, ultimate percussion climax, no vocals",
        165, "Dm"),

    # ── 일본 보스 ──
    "bgm_boss_raijin": _bgm(
        "japanese thunder god, grand orchestral ensemble, taiko storm, shakuhachi tension, brass thunder, lightning divine majesty, no vocals",
        120, "Em"),
    "bgm_boss_raijin_p2": _bgm(
        "raijin thunder fury, full orchestral storm, frantic taiko ensemble, thunderous brass, lightning climax, overwhelming divine power, no vocals",
        162, "Em"),
    "bgm_boss_shuten_doji": _bgm(
        "demon oni lord, grand orchestral ensemble, dark biwa and koto, ominous taiko, brass menace, demonic majesty, no vocals",
        114, "Am"),
    "bgm_boss_shuten_doji_p2": _bgm(
        "shuten doji demon rage, full orchestral darkness, frantic biwa ensemble, demonic taiko climax, overwhelming dark power, no vocals",
        156, "Am"),
    "bgm_boss_yamata_no_orochi": _bgm(
        "eight-headed serpent god, grand orchestral ensemble, koto and biwa, massive taiko, dark brass, serpent deity majesty, no vocals",
        110, "Dm"),
    "bgm_boss_yamata_no_orochi_p2": _bgm(
        "yamata no orochi fury, full orchestral chaos, frantic koto ensemble, thunderous taiko, multi-headed climax, overwhelming, no vocals",
        155, "Dm"),
    "bgm_boss_yamata_no_orochi_p3": _bgm(
        "yamata no orochi final form, absolute orchestral apocalypse, catastrophic taiko ensemble, ultimate serpent overwhelming climax, no vocals",
        170, "Dm"),

    # ── 이벤트 BGM (4타입 × 2~3개) ──
    "bgm_event_mysterious_1": _bgm(
        "mysterious ancient library, soft ethereal strings, distant harp glissando, mystical flute melody, arcane wonder, ambient fantasy, no vocals",
        65, "Am", 80),
    "bgm_event_mysterious_2": _bgm(
        "magical enchantment chamber, eerie woodwinds, soft choir pads, shimmering bells, arcane atmosphere, ethereal ambient wonder, no vocals",
        70, "Em", 80),
    "bgm_event_mysterious_3": _bgm(
        "ancient oracle vision, haunting oboe melody, soft string pads, mystic celesta shimmer, prophetic ethereal, no vocals",
        60, "Dm", 80),
    "bgm_event_dark_1": _bgm(
        "cursed altar encounter, dark orchestral strings, low brass ominous, tense tympani, foreboding sinister atmosphere, no vocals",
        75, "Am", 80),
    "bgm_event_dark_2": _bgm(
        "underworld pact, deep bass strings, dark pipe organ drone, ominous choir whispers, tense dramatic suspense, no vocals",
        72, "Dm", 80),
    "bgm_event_dark_3": _bgm(
        "demonic contract, low brass menace, dark string tremolo, ominous tympani rumble, sinister foreboding tension, no vocals",
        80, "Em", 80),
    "bgm_event_encounter_1": _bgm(
        "dramatic meeting, cinematic strings, gentle brass stings, adventurous storytelling, heroic narrative moment, no vocals",
        80, "Am", 80),
    "bgm_event_encounter_2": _bgm(
        "heroic encounter, warm orchestral strings, gentle horn calls, dramatic adventure narrative, cinematic storytelling, no vocals",
        85, "G major", 80),
    "bgm_event_fortune_1": _bgm(
        "lucky discovery, playful pizzicato strings, bright harp glissando, cheerful woodwinds, treasure found, light adventurous joy, no vocals",
        90, "G major", 80),
    "bgm_event_fortune_2": _bgm(
        "gambler tension, rhythmic plucked strings, playful brass stabs, tense excitement, fortune and fate suspense, no vocals",
        95, "Em", 80),
}

BGM_MYTHOLOGY_KEYS = [k for k in BGM_PROMPTS if k.startswith("bgm_menu") or k.startswith("bgm_battle_")]
BGM_BOSS_KEYS      = [k for k in BGM_PROMPTS if k.startswith("bgm_boss_")]
BGM_EVENT_KEYS     = [k for k in BGM_PROMPTS if k.startswith("bgm_event_")]


# ───────────────────────────────────────────
# ComfyUI API
# ───────────────────────────────────────────

def healthcheck(comfy_url: str) -> bool:
    try:
        with urllib.request.urlopen(f"{comfy_url}/system_stats", timeout=5):
            return True
    except Exception:
        return False


def queue_prompt(workflow: dict, comfy_url: str) -> str:
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(
        f"{comfy_url}/prompt", data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())["prompt_id"]


def wait_for_completion(prompt_id: str, comfy_url: str, timeout: int = 1200) -> dict:
    elapsed = 0
    while elapsed < timeout:
        try:
            with urllib.request.urlopen(
                f"{comfy_url}/history/{prompt_id}", timeout=5
            ) as resp:
                history = json.loads(resp.read())
            if prompt_id in history:
                return history[prompt_id]
        except Exception:
            pass
        time.sleep(5)
        elapsed += 5
    raise TimeoutError(f"타임아웃 ({timeout}s): {prompt_id}")


def download_audio(filename: str, subfolder: str, comfy_url: str) -> bytes:
    params = urllib.parse.urlencode({
        "filename": filename, "subfolder": subfolder, "type": "output",
    })
    with urllib.request.urlopen(f"{comfy_url}/view?{params}", timeout=60) as resp:
        return resp.read()


def extract_audio_output(entry: dict) -> tuple[str, str] | None:
    for node_out in entry.get("outputs", {}).values():
        for info in node_out.get("audio", []):
            return info["filename"], info.get("subfolder", "")
    return None


# ───────────────────────────────────────────
# 워크플로우 빌더
# ───────────────────────────────────────────

def build_sfx_workflow(template: dict, prompt: str, seed: int, duration: float = 1.0) -> dict:
    """노드 3=KSampler(seed), 6=positive(text), 7=negative(text), 11=EmptyLatentAudio(seconds)"""
    wf = json.loads(json.dumps(template))
    wf["6"]["inputs"]["text"] = prompt
    wf["7"]["inputs"]["text"] = SFX_NEGATIVE
    wf["3"]["inputs"]["seed"] = seed
    wf["11"]["inputs"]["seconds"] = duration
    return wf


_KEY_MAP = {
    "Am": "A minor", "Em": "E minor", "Dm": "D minor", "Cm": "C minor",
    "Gm": "G minor", "Fm": "F minor", "Bm": "B minor",
    "C": "C major", "G": "G major", "D": "D major", "A": "A major",
    "F": "F major", "E": "E major", "B": "B major",
}

def build_bgm_workflow(template: dict, cfg: dict, seed: int) -> dict:
    """노드 94=TextEncode, 98=EmptyLatent, 107=SaveAudioMP3, 109=PrimitiveInt(seed)"""
    wf = json.loads(json.dumps(template))
    keyscale = _KEY_MAP.get(cfg["keyscale"], cfg["keyscale"])
    wf["94"]["inputs"]["tags"] = cfg["tags"]
    wf["94"]["inputs"]["lyrics"] = cfg["lyrics"]
    wf["94"]["inputs"]["bpm"] = cfg["bpm"]
    wf["94"]["inputs"]["keyscale"] = keyscale
    wf["94"]["inputs"]["duration"] = float(cfg["duration"])
    wf["98"]["inputs"]["seconds"] = float(cfg["duration"])
    wf["109"]["inputs"]["value"] = seed
    wf["94"]["inputs"]["cfg_scale"] = 2.5
    return wf


# ───────────────────────────────────────────
# 후처리 + 품질 검증
# ───────────────────────────────────────────

def _decode_mp3(mp3_bytes: bytes):
    """miniaudio로 MP3 디코딩 → (samples_array, sample_rate, duration_ms). 실패 시 None."""
    if not MINIAUDIO_OK:
        return None
    try:
        info = miniaudio.decode(mp3_bytes, output_format=miniaudio.SampleFormat.FLOAT32)
        return info.samples, info.sample_rate, int(info.num_frames / info.sample_rate * 1000)
    except Exception:
        return None


def _peak_rms_dbfs(samples) -> tuple[float, float]:
    """float32 샘플 배열 → (peak_dBFS, rms_dBFS)."""
    import math
    if not samples:
        return -999.0, -999.0
    peak = max(abs(s) for s in samples)
    rms = math.sqrt(sum(s * s for s in samples) / len(samples))
    peak_db = 20 * math.log10(max(peak, 1e-9))
    rms_db  = 20 * math.log10(max(rms,  1e-9))
    return peak_db, rms_db


def _get_duration_ms_mutagen(mp3_bytes: bytes) -> int | None:
    if not MUTAGEN_OK:
        return None
    try:
        import io
        audio = MutagenMP3(io.BytesIO(mp3_bytes))
        return int(audio.info.length * 1000)
    except Exception:
        return None


def trim_silence(mp3_bytes: bytes) -> bytes:
    """ffmpeg silenceremove로 앞뒤 무음 제거. ffmpeg 없으면 원본 반환."""
    if not _ffmpeg_path:
        return mp3_bytes
    import subprocess, tempfile
    with tempfile.NamedTemporaryFile(suffix=".mp3", delete=False) as fin:
        fin.write(mp3_bytes)
        fin_path = fin.name
    fout_path = fin_path.replace(".mp3", "_trim.mp3")
    try:
        subprocess.run(
            [
                _ffmpeg_path, "-y", "-i", fin_path,
                "-af",
                "silenceremove=start_periods=1:start_threshold=-45dB:stop_periods=-1:stop_threshold=-45dB:detection=peak",
                "-c:a", "libmp3lame", "-q:a", "2", fout_path,
            ],
            check=True, capture_output=True, timeout=30,
        )
        result = Path(fout_path).read_bytes()
        return result if len(result) > 1024 else mp3_bytes
    except Exception:
        return mp3_bytes
    finally:
        for p in (fin_path, fout_path):
            try:
                Path(p).unlink()
            except Exception:
                pass


def check_sfx_quality(mp3_bytes: bytes) -> tuple[bool, str]:
    decoded = _decode_mp3(mp3_bytes)
    if decoded is None:
        # fallback: 파일 크기
        ok = len(mp3_bytes) >= SFX_MIN_BYTES
        return ok, f"파일크기 {len(mp3_bytes)//1024}KB {'OK' if ok else 'NG'}"

    samples, sr, dur_ms = decoded
    peak_db, rms_db = _peak_rms_dbfs(samples)

    if peak_db < SFX_PEAK_MIN_DBFS:
        return False, f"peak {peak_db:.1f}dB < {SFX_PEAK_MIN_DBFS}dB (너무 조용)"
    if rms_db < SFX_RMS_MIN_DBFS:
        return False, f"RMS {rms_db:.1f}dB < {SFX_RMS_MIN_DBFS}dB (음량 부족)"
    if dur_ms < SFX_DUR_MIN_MS:
        return False, f"dur {dur_ms}ms < {SFX_DUR_MIN_MS}ms"
    if dur_ms > SFX_DUR_MAX_MS:
        return False, f"dur {dur_ms}ms > {SFX_DUR_MAX_MS}ms"
    return True, f"peak={peak_db:.1f}dB rms={rms_db:.1f}dB dur={dur_ms}ms"


def _check_abrupt_end(samples, sample_rate: int) -> bool:
    """마지막 1초 RMS가 전체 RMS의 48% 초과 → 어색한 끝 (갑자기 잘림)."""
    import math
    n = len(samples)
    if n == 0:
        return False
    check_n = min(int(1.0 * sample_rate), n // 4)
    def rms(arr):
        return math.sqrt(sum(x * x for x in arr) / len(arr)) if arr else 0.0
    overall = rms(samples)
    if overall < 1e-6:
        return False
    end_rms = rms(samples[-check_n:])
    return (end_rms / overall) > 0.35


def check_bgm_quality(mp3_bytes: bytes) -> tuple[bool, str]:
    dur_ms = _get_duration_ms_mutagen(mp3_bytes)
    decoded = _decode_mp3(mp3_bytes)

    if decoded is None and dur_ms is None:
        ok = len(mp3_bytes) >= BGM_MIN_BYTES
        return ok, f"파일크기 {len(mp3_bytes)//1024}KB {'OK' if ok else 'NG'}"

    if decoded is not None:
        samples, sr, dur_ms2 = decoded
        if dur_ms is None:
            dur_ms = dur_ms2
        peak_db, rms_db = _peak_rms_dbfs(samples)
        if peak_db < BGM_PEAK_MIN_DBFS:
            return False, f"peak {peak_db:.1f}dB < {BGM_PEAK_MIN_DBFS}dB"
        if rms_db < BGM_RMS_MIN_DBFS:
            return False, f"RMS {rms_db:.1f}dB < {BGM_RMS_MIN_DBFS}dB"
        if _check_abrupt_end(samples, sr):
            return False, f"끝부분 갑자기 잘림 (end RMS 높음)"
        info = f"peak={peak_db:.1f}dB rms={rms_db:.1f}dB"
    else:
        info = f"파일크기 {len(mp3_bytes)//1024}KB"

    if dur_ms is not None:
        if dur_ms < BGM_DUR_MIN_MS:
            return False, f"duration {dur_ms//1000}s < {BGM_DUR_MIN_MS//1000}s"
        info += f" dur={dur_ms//1000}s"

    return True, info


# ───────────────────────────────────────────
# 생성 로직
# ───────────────────────────────────────────

def generate_one(key: str, variant_num: int, is_bgm: bool,
                 comfy_url: str, sfx_tpl: dict, bgm_tpl: dict,
                 seed: int = -1) -> bool:
    if is_bgm:
        out_path = BGM_OUT_DIR / f"{key}.mp3"
    else:
        out_path = SFX_OUT_DIR / f"{key}_{variant_num}.mp3"
    out_path.parent.mkdir(parents=True, exist_ok=True)

    for attempt in range(1, MAX_RETRY + 2):
        actual_seed = seed if (seed >= 0 and attempt == 1) else random.randint(0, 2**32 - 1)
        suffix = f" (재시도 {attempt - 1})" if attempt > 1 else ""
        print(f"  seed={actual_seed}{suffix}...", end="", flush=True)

        try:
            if is_bgm:
                wf = build_bgm_workflow(bgm_tpl, BGM_PROMPTS[key], actual_seed)
            else:
                sfx_dur = SFX_DURATIONS.get(key, 1.0)
                wf = build_sfx_workflow(sfx_tpl, SFX_PROMPTS[key], actual_seed, sfx_dur)

            prompt_id = queue_prompt(wf, comfy_url)
            entry = wait_for_completion(prompt_id, comfy_url)
            result = extract_audio_output(entry)

            if result is None:
                print("\n  오디오 출력 없음")
                if attempt <= MAX_RETRY:
                    continue
                return False

            raw_bytes = download_audio(result[0], result[1], comfy_url)

            raw_bytes = trim_silence(raw_bytes)

            ok, msg = (check_bgm_quality if is_bgm else check_sfx_quality)(raw_bytes)
            if not ok:
                print(f"\n  품질 NG: {msg}")
                if attempt <= MAX_RETRY:
                    continue
                return False

            out_path.write_bytes(raw_bytes)
            print(f"  OK ({msg}) → {out_path.name}")
            return True

        except Exception as e:
            print(f"\n  오류: {e}")
            if attempt <= MAX_RETRY:
                time.sleep(2)
                continue
            return False

    return False


def build_targets(keys: list[str], is_bgm: bool) -> list[tuple[str, int, bool]]:
    targets = []
    for key in keys:
        count = 1 if is_bgm else VARIANT_COUNTS.get(key, 1)
        for n in range(1, count + 1):
            targets.append((key, n, is_bgm))
    return targets


# ───────────────────────────────────────────
# 의존성 검사
# ───────────────────────────────────────────

def check_deps() -> None:
    if not MINIAUDIO_OK:
        print("경고: miniaudio 없음 — 파일 크기 기반 검증으로 fallback. 설치: pip install miniaudio")
    if not MUTAGEN_OK:
        print("경고: mutagen 없음 — BGM duration 검증 불가. 설치: pip install mutagen")
    if not MINIAUDIO_OK and not MUTAGEN_OK:
        print("경고: 진폭·duration 검증 비활성화 — 파일 크기만 체크")


# ───────────────────────────────────────────
# main
# ───────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="STSL 오디오 에셋 V2 생성")
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument("--key", metavar="KEY", help="단일 SFX 키의 모든 variant")
    group.add_argument("--all-sfx", action="store_true", help="SFX 전체 51개")
    group.add_argument("--all-bgm", action="store_true", help="BGM 전체 55개")
    group.add_argument("--all-bgm-mythology", action="store_true", help="신화BGM 19개(메뉴+신화18)")
    group.add_argument("--all-bgm-boss", action="store_true", help="보스BGM 36개")
    group.add_argument("--all-bgm-event", action="store_true", help="이벤트BGM 10개")
    group.add_argument("--regenerate", metavar="KEY", help="덮어쓰고 재생성")
    parser.add_argument("--comfy-url", default=DEFAULT_COMFY_URL)
    parser.add_argument("--seed", type=int, default=-1)
    args = parser.parse_args()

    check_deps()

    try:
        sfx_tpl = json.loads(Path(SFX_WORKFLOW).read_text(encoding="utf-8"))
        bgm_tpl = json.loads(Path(BGM_WORKFLOW).read_text(encoding="utf-8"))
    except FileNotFoundError as e:
        print(f"오류: 워크플로우 없음 — {e}")
        sys.exit(1)

    if not healthcheck(args.comfy_url):
        print(f"오류: ComfyUI 연결 실패 ({args.comfy_url}). 먼저 실행하세요.")
        sys.exit(1)
    print(f"ComfyUI 연결됨: {args.comfy_url}\n")

    if args.key:
        if args.key not in SFX_PROMPTS:
            print(f"오류: 알 수 없는 SFX 키 '{args.key}'")
            sys.exit(1)
        targets = build_targets([args.key], is_bgm=False)
        skip = True
    elif args.all_sfx:
        targets = build_targets(list(SFX_PROMPTS), is_bgm=False)
        skip = True
    elif args.all_bgm:
        targets = (build_targets(BGM_MYTHOLOGY_KEYS, True)
                   + build_targets(BGM_BOSS_KEYS, True)
                   + build_targets(BGM_EVENT_KEYS, True))
        skip = True
    elif args.all_bgm_mythology:
        targets = build_targets(BGM_MYTHOLOGY_KEYS, True)
        skip = True
    elif args.all_bgm_boss:
        targets = build_targets(BGM_BOSS_KEYS, True)
        skip = True
    elif args.all_bgm_event:
        targets = build_targets(BGM_EVENT_KEYS, True)
        skip = True
    else:  # --regenerate
        key = args.regenerate
        is_bgm = key in BGM_PROMPTS
        if not is_bgm and key not in SFX_PROMPTS:
            print(f"오류: 알 수 없는 키 '{key}'")
            sys.exit(1)
        targets = build_targets([key], is_bgm=is_bgm)
        skip = False

    ok_n, skipped, failed = 0, 0, []
    total = len(targets)

    for idx, (key, vnum, is_bgm) in enumerate(targets, 1):
        label = key if is_bgm else f"{key}_{vnum}"
        out = (BGM_OUT_DIR / f"{key}.mp3") if is_bgm else (SFX_OUT_DIR / f"{key}_{vnum}.mp3")
        print(f"[{idx}/{total}] {'BGM' if is_bgm else 'SFX'}  {label}")

        if skip and out.exists():
            print(f"  SKIP")
            skipped += 1
            continue

        if generate_one(key, vnum, is_bgm, args.comfy_url, sfx_tpl, bgm_tpl, args.seed):
            ok_n += 1
        else:
            failed.append(label)

    print(f"\n--- 완료 ---  OK={ok_n}  건너뜀={skipped}  실패={len(failed)}")
    if failed:
        print(f"실패: {', '.join(failed)}")
        print("재생성: python tools/generate_audio_assets.py --regenerate <key>")
        sys.exit(1)


if __name__ == "__main__":
    main()
