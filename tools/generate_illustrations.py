#!/usr/bin/env python3
"""
STSL 일러스트 일괄 생성 스크립트 (ComfyUI API)

사용법 (프로젝트 루트에서 실행):
  python tools/generate_illustrations.py                          # 전체 생성
  python tools/generate_illustrations.py --category hero          # 영웅 6종만
  python tools/generate_illustrations.py --category event         # 이벤트 11종만
  python tools/generate_illustrations.py --category rest          # 휴식 1종만
  python tools/generate_illustrations.py --category chapter       # 챕터 2종만
  python tools/generate_illustrations.py --category background    # 배경 2종만
  python tools/generate_illustrations.py --workflow z-image       # z-image-turbo 워크플로우 사용
  python tools/generate_illustrations.py --dry-run                # 목록만 출력
  python tools/generate_illustrations.py --skip-existing=false    # 기존 파일도 덮어쓰기
  python tools/generate_illustrations.py --seed 12345             # 시드 고정
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
DEFAULT_QWEN_WORKFLOW = "tools/qwen_workflow.json"
DEFAULT_Z_IMAGE_WORKFLOW = "tools/z_image_workflow.json"
DEFAULT_PROMPTS_MD = "docs/illustration_prompts.md"

# 공통 quality prefix — 모든 프롬프트 앞에 삽입
QUALITY_PREFIX = (
    "score_9, score_8_up, score_7_up, masterpiece, best quality, "
    "highly detailed, intricate details, "
)

# 카테고리별 출력 경로·해상도
CATEGORY_CONFIG = {
    "event":      {"subdir": "assets/art/events",      "width": 1664, "height": 640},
    "rest":       {"subdir": "assets/art/scenes",      "width": 1664, "height": 640},
    "hero":       {"subdir": "assets/art/heroes",      "width": 1024, "height": 1280},
    "chapter":    {"subdir": "assets/art/chapters",    "width": 1280, "height": 896},
    "background": {"subdir": "assets/art/backgrounds", "width": 1664, "height": 928},
}

# 마크다운 섹션 헤더 → 카테고리 매핑
SECTION_TO_CATEGORY = {
    "이벤트 일러스트":     "event",
    "휴식 씬 일러스트":    "rest",
    "영웅 일러스트":       "hero",
    "챕터 일러스트":       "chapter",
    "맵·배틀 배경":        "background",
}


# --- 파싱 ---

def parse_prompts(md_path: str) -> list[tuple[str, str, str]]:
    """
    illustration_prompts.md에서 (category, illust_id, prompt_text) 목록 추출.
    generate_icons.py의 parse_prompts()와 동일 형식.
    """
    content = Path(md_path).read_text(encoding="utf-8")
    lines = content.split("\n")
    results = []
    current_category = None
    i = 0

    while i < len(lines):
        line = lines[i]

        if line.startswith("## "):
            current_category = None
            for header, cat in SECTION_TO_CATEGORY.items():
                if header in line:
                    current_category = cat
                    break

        elif current_category and (line.startswith("### ") or line.startswith("#### ")):
            header_text = line.lstrip("#").strip()
            if " — " not in header_text:
                i += 1
                continue

            illust_id = header_text.split(" — ")[0].strip()

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
                    results.append((current_category, illust_id, prompt_text))

        i += 1

    return results


# --- ComfyUI API (generate_icons.py 공통 패턴) ---

def queue_prompt(workflow: dict, comfy_url: str) -> str:
    data = json.dumps({"prompt": workflow}).encode("utf-8")
    req = urllib.request.Request(
        f"{comfy_url}/prompt", data=data,
        headers={"Content-Type": "application/json"},
    )
    with urllib.request.urlopen(req, timeout=10) as resp:
        return json.loads(resp.read())["prompt_id"]


def wait_for_completion(prompt_id: str, comfy_url: str, timeout: int = 900) -> dict:
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
        time.sleep(3)
        elapsed += 3
    raise TimeoutError(f"생성 타임아웃 ({timeout}s): {prompt_id}")


def download_image(filename: str, subfolder: str, comfy_url: str) -> bytes:
    params = urllib.parse.urlencode({
        "filename": filename,
        "subfolder": subfolder,
        "type": "output",
    })
    with urllib.request.urlopen(f"{comfy_url}/view?{params}", timeout=60) as resp:
        return resp.read()


# --- 워크플로우 빌더 ---

def build_qwen_workflow(template: dict, prompt_text: str, illust_id: str,
                        width: int, height: int, seed: int) -> dict:
    """
    qwen_workflow.json (Qwen Image 2512 + LoRA) 패치.
    노드: 108=positive, 107=latent, 106=KSampler, 123=SaveImage
    """
    wf = json.loads(json.dumps(template))
    final_prompt = QUALITY_PREFIX + prompt_text
    wf["108"]["inputs"]["text"] = final_prompt
    wf["107"]["inputs"]["width"] = width
    wf["107"]["inputs"]["height"] = height
    wf["106"]["inputs"]["seed"] = seed
    wf["123"]["inputs"]["filename_prefix"] = f"stsl_illust_{illust_id}"
    return wf


def build_z_image_workflow(template: dict, prompt_text: str, illust_id: str,
                            width: int, height: int, seed: int) -> dict:
    """
    z_image_workflow.json (z-image-turbo + Lumina) 패치.
    노드: 57:27=positive, 57:13=latent, 57:3=KSampler, 9=SaveImage
    """
    wf = json.loads(json.dumps(template))
    final_prompt = QUALITY_PREFIX + prompt_text
    wf["57:27"]["inputs"]["text"] = final_prompt
    wf["57:13"]["inputs"]["width"] = width
    wf["57:13"]["inputs"]["height"] = height
    wf["57:3"]["inputs"]["seed"] = seed
    wf["9"]["inputs"]["filename_prefix"] = f"stsl_illust_{illust_id}"
    return wf


# --- 메인 ---

def main():
    parser = argparse.ArgumentParser(description="STSL 일러스트 일괄 생성 (ComfyUI API)")
    parser.add_argument("--category",
                        choices=["event", "rest", "hero", "chapter", "background", "all"],
                        default="all", help="생성할 카테고리 (기본: all)")
    parser.add_argument("--workflow", choices=["qwen", "z-image"], default="qwen",
                        help="사용할 워크플로우 (기본: qwen — Qwen Image 2512+LoRA)")
    parser.add_argument("--comfy-url", default=DEFAULT_COMFY_URL,
                        help=f"ComfyUI 주소 (기본: {DEFAULT_COMFY_URL})")
    parser.add_argument("--prompts-md", default=DEFAULT_PROMPTS_MD,
                        help="프롬프트 마크다운 경로")
    parser.add_argument("--skip-existing", default="true", choices=["true", "false"],
                        help="기존 파일 건너뛰기 (기본: true)")
    parser.add_argument("--seed", type=int, default=-1,
                        help="시드 고정 (-1=매번 랜덤, 기본: -1)")
    parser.add_argument("--limit", type=int, default=0,
                        help="생성할 최대 개수 (0=제한없음)")
    parser.add_argument("--dry-run", action="store_true",
                        help="목록만 출력, 실제 생성 안 함")
    args = parser.parse_args()

    skip_existing = args.skip_existing == "true"

    # 워크플로우 로드
    wf_path = DEFAULT_QWEN_WORKFLOW if args.workflow == "qwen" else DEFAULT_Z_IMAGE_WORKFLOW
    try:
        with open(wf_path, "r", encoding="utf-8") as f:
            template = json.load(f)
    except FileNotFoundError:
        print(f"오류: 워크플로우 파일을 찾을 수 없습니다: {wf_path}")
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

    print(f"워크플로우: {args.workflow} | 카테고리: {args.category} | "
          f"총 {len(prompts)}개 {'(dry-run)' if args.dry_run else ''}")

    if args.dry_run:
        for cat, illust_id, _ in prompts:
            cfg = CATEGORY_CONFIG[cat]
            print(f"  [{cat:10s}] {illust_id}.png  ({cfg['width']}×{cfg['height']})")
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

    for idx, (category, illust_id, prompt_text) in enumerate(prompts, 1):
        config = CATEGORY_CONFIG[category]
        output_path = Path(config["subdir"]) / f"{illust_id}.png"
        output_path.parent.mkdir(parents=True, exist_ok=True)

        prefix = f"[{idx:3d}/{len(prompts)}]"

        if skip_existing and output_path.exists():
            print(f"{prefix} SKIP  {output_path}")
            skipped += 1
            continue

        w, h = config["width"], config["height"]
        seed = args.seed if args.seed >= 0 else random.randint(0, 2**32 - 1)
        print(f"{prefix} 생성중  {illust_id} ({w}×{h}) seed={seed}...", end="", flush=True)

        try:
            if args.workflow == "qwen":
                wf = build_qwen_workflow(template, prompt_text, illust_id, w, h, seed)
            else:
                wf = build_z_image_workflow(template, prompt_text, illust_id, w, h, seed)

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
                    output_path.write_bytes(image_data)
                    print(f"  저장됨 → {output_path}  ({len(image_data)//1024}KB)")
                    saved = True
                    break
                if saved:
                    break

            if not saved:
                print(f"  경고: 이미지를 찾을 수 없음 (outputs={list(entry.get('outputs', {}).keys())})")
                errors += 1
            else:
                success += 1

        except Exception as e:
            print(f"\n  오류: {e}")
            errors += 1

    print(f"\n완료: 성공 {success} / 건너뜀 {skipped} / 오류 {errors}")


if __name__ == "__main__":
    main()
