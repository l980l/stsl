#!/usr/bin/env python3
"""
STSL 아이콘 일괄 생성 스크립트 (ComfyUI API)

사용법 (프로젝트 루트에서 실행):
  python tools/generate_icons.py                          # 전체 64종
  python tools/generate_icons.py --category status        # 상태이상 9종만
  python tools/generate_icons.py --category synergy       # 시너지 15종만
  python tools/generate_icons.py --category relic         # 렐릭 40종만
  python tools/generate_icons.py --dry-run                # 목록만 출력, 생성 안 함
  python tools/generate_icons.py --skip-existing=false    # 기존 파일도 덮어쓰기

생성 해상도:
  상태이상(status): 512x512 → 게임 내 128x128로 다운스케일 필요
  시너지(synergy):  1024x1024 → 게임 내 256x256으로 다운스케일 필요
  렐릭(relic):      1024x1024 → 게임 내 256x256으로 다운스케일 필요
"""

import argparse
import json
import random
import sys
import time
import urllib.parse
import urllib.request
from pathlib import Path

# --- 설정 ---
DEFAULT_COMFY_URL = "http://127.0.0.1:8188"
DEFAULT_WORKFLOW = r"C:\Users\k9102\Downloads\image_z_image_turbo (1).json"
DEFAULT_GMIC_WORKFLOW = "tools/gmic_workflow.json"
DEFAULT_Z_LORA_WORKFLOW = "tools/z_lora_workflow.json"
DEFAULT_PROMPTS_MD = "docs/image_gen_prompts.md"
DEFAULT_OUTPUT_DIR = "assets/art/ui"

# z-lora 트리거 (gmic icon_z_image Dark themed LoRA)
TRIGGER_Z_LORA = r"gmic icon_\(Game ai Institute \)"

# 통일된 아이콘 스타일 — 모든 프롬프트 앞에 자동으로 삽입
QUALITY_PREFIX = (
    "high resolution, "
    "(flat minimalist game icon:1.5), (2 to 3 colors only:1.4), "
    "(bold black outline:1.3), single centered object, "
    "transparent background, clean simple shapes, no texture, "
    "no gradient, no background scenery, no text, no numbers, no letters, "
)

SIMPLICITY_SUFFIX = ""

CATEGORY_CONFIG = {
    "status":         {"subdir": "status",    "width": 256, "height": 256},
    "synergy":        {"subdir": "synergy",   "width": 256, "height": 256},
    "relic":          {"subdir": "relic",     "width": 256, "height": 256},
    "map_node":       {"subdir": "map_node",  "width": 256, "height": 256},
    "intent":         {"subdir": "intent",    "width": 256, "height": 256},
    "energy_orb":     {"subdir": "hud",       "width": 256, "height": 256},
    "hp_bar":         {"subdir": "hud",       "width": 512, "height": 128},
    "portrait_frame": {"subdir": "hud",       "width": 256, "height": 256},
}

# 마크다운 섹션 헤더 → 카테고리 매핑
SECTION_TO_CATEGORY = {
    "상태이상 아이콘": "status",
    "시너지 아이콘":   "synergy",
    "렐릭 아이콘":     "relic",
    "맵 노드 아이콘":  "map_node",
    "의도 아이콘":     "intent",
    "에너지 오브":     "energy_orb",
    "HP 바":          "hp_bar",
    "초상화 프레임":   "portrait_frame",
}


# --- 파싱 ---

def parse_prompts(md_path: str) -> list[tuple[str, str, str]]:
    """
    image_gen_prompts.md에서 (category, icon_id, prompt_text) 목록을 추출.
    아이콘 항목은 헤더에 ' — '가 포함된 경우만 처리.
    """
    content = Path(md_path).read_text(encoding="utf-8")
    lines = content.split("\n")
    results = []
    current_category = None
    i = 0

    while i < len(lines):
        line = lines[i]

        # 카테고리 섹션 감지 (## 헤더)
        if line.startswith("## "):
            for header, cat in SECTION_TO_CATEGORY.items():
                if header in line:
                    current_category = cat
                    break

        # 아이콘 항목 감지 (### 또는 #### 헤더, ' — ' 포함)
        elif current_category and (line.startswith("### ") or line.startswith("#### ")):
            header_text = line.lstrip("#").strip()
            if " — " not in header_text:
                i += 1
                continue  # 서브섹션 헤더, 아이콘 아님

            icon_id = header_text.split(" — ")[0].strip()

            # 다음 코드블록(```) 찾기
            j = i + 1
            while j < len(lines) and not lines[j].startswith("```"):
                j += 1

            if j < len(lines):
                prompt_lines = []
                j += 1
                while j < len(lines) and not lines[j].startswith("```"):
                    prompt_lines.append(lines[j])
                    j += 1
                prompt_text = "\n".join(prompt_lines).strip()
                if prompt_text:
                    results.append((current_category, icon_id, prompt_text))

        i += 1

    return results


# --- ComfyUI API ---

def queue_prompt(workflow: dict, comfy_url: str) -> str:
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(
        f"{comfy_url}/prompt", data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())["prompt_id"]


def wait_for_completion(prompt_id: str, comfy_url: str, timeout: int = 600) -> dict:
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
        time.sleep(2)
        elapsed += 2
    raise TimeoutError(f"생성 타임아웃 ({timeout}s): {prompt_id}")


def download_image(filename: str, subfolder: str, comfy_url: str) -> bytes:
    params = urllib.parse.urlencode({
        "filename": filename,
        "subfolder": subfolder,
        "type": "output",
    })
    with urllib.request.urlopen(f"{comfy_url}/view?{params}", timeout=30) as resp:
        return resp.read()


def build_workflow(template: dict, prompt_text: str, icon_id: str,
                   width: int, height: int,
                   lora_name: str = "", lora_strength: float = 1.0,
                   steps: int = 8, cfg: float = 1.0,
                   sampler: str = "res_multistep", scheduler: str = "simple",
                   shift: float = 3.0, clip_skip: int = 0,
                   model_name: str = "") -> dict:
    wf = json.loads(json.dumps(template))  # deep copy
    final_prompt = QUALITY_PREFIX + prompt_text + SIMPLICITY_SUFFIX
    wf["57:27"]["inputs"]["text"] = final_prompt
    if model_name:
        wf["57:28"]["inputs"]["unet_name"] = model_name
    wf["57:13"]["inputs"]["width"] = width
    wf["57:13"]["inputs"]["height"] = height
    wf["57:3"]["inputs"]["seed"] = random.randint(0, 2**32 - 1)
    wf["57:3"]["inputs"]["steps"] = steps
    wf["57:3"]["inputs"]["cfg"] = cfg
    wf["57:3"]["inputs"]["sampler_name"] = sampler
    wf["57:3"]["inputs"]["scheduler"] = scheduler
    wf["57:11"]["inputs"]["shift"] = shift
    wf["9"]["inputs"]["filename_prefix"] = f"stsl_{icon_id}"

    # CLIP이 연결될 소스 노드 ID (lora 삽입 여부에 따라 변경됨)
    clip_source = ["57:30", 0]

    if lora_name:
        wf["lora"] = {
            "inputs": {
                "lora_name": lora_name,
                "strength_model": lora_strength,
                "strength_clip": lora_strength,
                "model": ["57:28", 0],
                "clip":  ["57:30", 0],
            },
            "class_type": "LoraLoader",
            "_meta": {"title": "LoRA 로드"},
        }
        wf["57:11"]["inputs"]["model"] = ["lora", 0]
        clip_source = ["lora", 1]

    if clip_skip >= 2:
        wf["clip_skip"] = {
            "inputs": {
                "stop_at_clip_layer": -clip_skip,
                "clip": clip_source,
            },
            "class_type": "CLIPSetLastLayer",
            "_meta": {"title": "CLIP Skip"},
        }
        clip_source = ["clip_skip", 0]

    wf["57:27"]["inputs"]["clip"] = clip_source

    return wf


def build_z_lora_workflow(template: dict, prompt_text: str, icon_id: str,
                          width: int, height: int) -> dict:
    """Unsaved Workflow (2).json 기반 — Lora Loader Stack (rgthree) LoRA 포함."""
    wf = json.loads(json.dumps(template))
    wf["67"]["inputs"]["text"] = TRIGGER_Z_LORA + ", " + prompt_text
    wf["68"]["inputs"]["width"] = width
    wf["68"]["inputs"]["height"] = height
    wf["68"]["inputs"]["batch_size"] = 1
    wf["69"]["inputs"]["seed"] = random.randint(0, 2**32 - 1)
    wf["9"]["inputs"]["filename_prefix"] = f"stsl_{icon_id}"
    return wf


def build_gmic_workflow(template: dict, prompt_text: str, icon_id: str,
                        width: int, height: int,
                        ckpt_name: str = "",
                        steps: int = 20, cfg: float = 8.0,
                        sampler: str = "euler_ancestral",
                        lora_name: str = "", lora_strength: float = 1.0) -> dict:
    wf = json.loads(json.dumps(template))
    wf["3"]["inputs"]["text"] = prompt_text
    wf["5"]["inputs"]["width"] = width
    wf["5"]["inputs"]["height"] = height
    wf["6"]["inputs"]["seed"] = random.randint(0, 2**32 - 1)
    wf["6"]["inputs"]["steps"] = steps
    wf["6"]["inputs"]["cfg"] = cfg
    wf["6"]["inputs"]["sampler_name"] = sampler
    wf["8"]["inputs"]["filename_prefix"] = f"stsl_{icon_id}"
    if ckpt_name:
        wf["1"]["inputs"]["ckpt_name"] = ckpt_name

    if lora_name:
        wf["lora"] = {
            "inputs": {
                "lora_name": lora_name,
                "strength_model": lora_strength,
                "strength_clip": lora_strength,
                "model": ["1", 0],
                "clip":  ["2", 0],
            },
            "class_type": "LoraLoader",
            "_meta": {"title": "LoRA 로드"},
        }
        wf["6"]["inputs"]["model"] = ["lora", 0]
        wf["3"]["inputs"]["clip"] = ["lora", 1]
        wf["4"]["inputs"]["clip"] = ["lora", 1]

    return wf


# --- 메인 ---

def main():
    parser = argparse.ArgumentParser(description="STSL 아이콘 일괄 생성 (ComfyUI API)")
    parser.add_argument("--category",
                        choices=["status", "synergy", "relic",
                                 "map_node", "intent", "energy_orb", "hp_bar", "portrait_frame",
                                 "all"],
                        default="all", help="생성할 카테고리 (기본: all)")
    parser.add_argument("--comfy-url", default=DEFAULT_COMFY_URL,
                        help=f"ComfyUI 주소 (기본: {DEFAULT_COMFY_URL})")
    parser.add_argument("--model", default="",
                        help="UNET 모델 파일명 덮어쓰기 (예: z_image_turbo_fp8_e4m3fn.safetensors)")
    parser.add_argument("--workflow", default=DEFAULT_WORKFLOW,
                        help="워크플로우 JSON 경로")
    parser.add_argument("--workflow-type", choices=["zimage", "gmic", "z-lora"], default="zimage",
                        help="워크플로우 타입 (기본: zimage)")
    parser.add_argument("--prompts-md", default=DEFAULT_PROMPTS_MD,
                        help="프롬프트 마크다운 경로")
    parser.add_argument("--output-dir", default=DEFAULT_OUTPUT_DIR,
                        help="출력 루트 디렉토리")
    parser.add_argument("--skip-existing", default="true",
                        choices=["true", "false"],
                        help="기존 파일 건너뛰기 (기본: true)")
    parser.add_argument("--lora", default="",
                        help="LoRA 파일명 (예: game_res_ui_icon.safetensors)")
    parser.add_argument("--lora-strength", type=float, default=1.0,
                        help="LoRA 강도 (기본: 1.0)")
    parser.add_argument("--lora-trigger", default="",
                        help="LoRA 트리거 워드 (프롬프트 앞에 삽입)")
    parser.add_argument("--steps", type=int, default=8,
                        help="샘플링 스텝 수 (기본: 8)")
    parser.add_argument("--cfg", type=float, default=1.0,
                        help="CFG 스케일 (기본: 1.0)")
    parser.add_argument("--sampler", default="res_multistep",
                        help="샘플러 이름 (기본: res_multistep)")
    parser.add_argument("--scheduler", default="simple",
                        help="스케줄러 (기본: simple, 예: sgm_uniform)")
    parser.add_argument("--shift", type=float, default=3.0,
                        help="ModelSamplingAuraFlow shift 값 (기본: 3.0)")
    parser.add_argument("--clip-skip", type=int, default=0,
                        help="CLIP Skip 레이어 수 (0=비활성, 2=권장)")
    parser.add_argument("--size", type=int, default=0,
                        help="출력 해상도 (예: 512 → 512x512, 0=카테고리 기본값)")
    parser.add_argument("--limit", type=int, default=0,
                        help="생성할 최대 개수 (0=제한없음)")
    parser.add_argument("--dry-run", action="store_true",
                        help="목록만 출력, 실제 생성 안 함")
    args = parser.parse_args()

    skip_existing = args.skip_existing == "true"

    # 워크플로우 로드 (gmic 모드면 기본 경로 자동 전환)
    wf_path = args.workflow
    if args.workflow_type == "gmic" and wf_path == DEFAULT_WORKFLOW:
        wf_path = DEFAULT_GMIC_WORKFLOW
    elif args.workflow_type == "z-lora" and wf_path == DEFAULT_WORKFLOW:
        wf_path = DEFAULT_Z_LORA_WORKFLOW
    try:
        with open(wf_path, "r", encoding="utf-8") as f:
            template = json.load(f)
    except FileNotFoundError:
        print(f"오류: 워크플로우 파일을 찾을 수 없습니다: {args.workflow}")
        sys.exit(1)

    # 프롬프트 파싱
    try:
        prompts = parse_prompts(args.prompts_md)
    except FileNotFoundError:
        print(f"오류: 프롬프트 파일을 찾을 수 없습니다: {args.prompts_md}")
        sys.exit(1)

    # 카테고리 필터
    if args.category != "all":
        prompts = [(c, i, p) for c, i, p in prompts if c == args.category]
    if args.limit > 0:
        prompts = prompts[:args.limit]

    print(f"총 {len(prompts)}개 아이콘 {'(dry-run)' if args.dry_run else ''}")

    if args.dry_run:
        for cat, icon_id, _ in prompts:
            print(f"  [{cat:8s}] {icon_id}")
        return

    # ComfyUI 연결 확인
    try:
        with urllib.request.urlopen(f"{args.comfy_url}/system_stats", timeout=5):
            pass
        print(f"ComfyUI 연결됨: {args.comfy_url}\n")
    except Exception as e:
        print(f"오류: ComfyUI에 연결할 수 없습니다 ({args.comfy_url})\n{e}")
        sys.exit(1)

    success = 0
    skipped = 0
    errors = 0

    for idx, (category, icon_id, prompt_text) in enumerate(prompts, 1):
        config = CATEGORY_CONFIG[category]
        output_path = Path(args.output_dir) / config["subdir"] / f"{icon_id}.png"

        prefix = f"[{idx:3d}/{len(prompts)}]"

        if skip_existing and output_path.exists():
            print(f"{prefix} SKIP  {category}/{icon_id}.png")
            skipped += 1
            continue

        print(f"{prefix} 생성중  {category}/{icon_id} ({config['width']}x{config['height']})...", end="", flush=True)

        try:
            w = args.size if args.size > 0 else config["width"]
            h = args.size if args.size > 0 else config["height"]
            p = (args.lora_trigger + ", " + prompt_text) if args.lora_trigger else prompt_text
            if args.workflow_type == "z-lora":
                wf = build_z_lora_workflow(template, prompt_text, icon_id, w, h)
            elif args.workflow_type == "gmic":
                wf = build_gmic_workflow(template, p, icon_id, w, h,
                                         args.model, args.steps, args.cfg,
                                         args.sampler, args.lora, args.lora_strength)
            else:
                wf = build_workflow(template, p, icon_id,
                                    w, h,
                                    args.lora, args.lora_strength,
                                    args.steps, args.cfg,
                                    args.sampler, args.scheduler,
                                    args.shift, args.clip_skip,
                                    args.model)
            prompt_id = queue_prompt(wf, args.comfy_url)
            entry = wait_for_completion(prompt_id, args.comfy_url)

            saved = False
            for node_out in entry.get("outputs", {}).values():
                for img_info in node_out.get("images", []):
                    image_data = download_image(
                        img_info["filename"],
                        img_info.get("subfolder", ""),
                        args.comfy_url,
                    )
                    output_path.parent.mkdir(parents=True, exist_ok=True)
                    output_path.write_bytes(image_data)
                    print(f" → {output_path}")
                    saved = True
                    break
                if saved:
                    break

            if saved:
                success += 1
            else:
                print(" 경고: 출력 이미지 없음")
                errors += 1

        except Exception as e:
            print(f" 오류: {e}")
            errors += 1

    print(f"\n완료: 성공 {success} / 건너뜀 {skipped} / 오류 {errors}")


if __name__ == "__main__":
    main()
