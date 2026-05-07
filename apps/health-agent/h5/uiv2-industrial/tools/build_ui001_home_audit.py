from __future__ import annotations

import json
import math
import shutil
from pathlib import Path

import numpy as np
from PIL import Image, ImageChops, ImageDraw


ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "asset_cutout_project" / "original_sources" / "ui001.png"
RENDER = ROOT / "qa-ui001-home.png"
PROJECT = ROOT / "ui001_home_audit"
LAYERS = PROJECT / "full_canvas_layers"
COMPONENTS = PROJECT / "component_images"
DIAGNOSTICS = PROJECT / "diagnostics"


REGIONS = [
    ("010_brand_header", "品牌图标、标题、副标题", (64, 29, 746, 109)),
    ("020_mascot_and_speech", "顶部小智吉祥物和气泡", (82, 114, 535, 124)),
    ("030_trust_cards", "隐私、本地、非诊断三张信任卡", (821, 51, 571, 70)),
    ("110_phone_today_home", "手机 1 今日健康首页", (31, 239, 313, 686)),
    ("120_phone_agent_discovery", "手机 2 Agent 发现页", (383, 239, 313, 687)),
    ("130_phone_recovery_analysis", "手机 3 恢复睡眠分析页", (736, 239, 307, 687)),
    ("140_phone_ecg_reading", "手机 4 ECG 解读页", (1083, 239, 307, 687)),
    ("210_captions", "四个页面编号标题", (112, 936, 1220, 35)),
    ("300_bottom_value_bar", "底部价值主张条", (28, 991, 1388, 60)),
]


PALETTE = {
    "canvas": {
        "top_left": "#cde3fc",
        "center": "#f8fafc",
        "bottom": "#eaf5ff",
    },
    "text": {
        "title": "#131432",
        "body_muted": "#5f6c8a",
        "phone_primary": "#172148",
    },
    "brand": {
        "blue": "#1267ff",
        "cyan": "#2bd2de",
        "heart_green": "#20b86a",
    },
    "health_status": {
        "red": "#ff4a53",
        "orange": "#ff9c20",
        "green": "#20b86a",
    },
    "surfaces": {
        "card": "#ffffff",
        "card_border": "#d8e7fb",
        "phone_black": "#0b0b0c",
        "screen": "#fbfdff",
    },
}


def ensure_dirs() -> None:
    if PROJECT.exists():
        shutil.rmtree(PROJECT)
    for path in [LAYERS, COMPONENTS, DIAGNOSTICS, PROJECT / "original_sources"]:
        path.mkdir(parents=True, exist_ok=True)


def save_region_layers(source: Image.Image) -> list[dict]:
    entries = []
    canvas = source.size
    for idx, (asset_id, usage, box) in enumerate(REGIONS, start=1):
        x, y, w, h = box
        crop = source.crop((x, y, x + w, y + h)).convert("RGBA")
        full = Image.new("RGBA", canvas, (0, 0, 0, 0))
        full.alpha_composite(crop, (x, y))
        full_path = LAYERS / f"{idx:03d}_{asset_id}.png"
        crop_path = COMPONENTS / f"{asset_id}.png"
        full.save(full_path)
        crop.save(crop_path)
        entries.append(
            {
                "id": asset_id,
                "usage": usage,
                "source_box": {"x": x, "y": y, "w": w, "h": h},
                "full_canvas_layer": str(full_path.relative_to(PROJECT)).replace("\\", "/"),
                "component_image": str(crop_path.relative_to(PROJECT)).replace("\\", "/"),
                "z_order": idx,
            }
        )
    return entries


def make_numbered_preview(source: Image.Image) -> None:
    preview = source.convert("RGBA")
    draw = ImageDraw.Draw(preview)
    for idx, (_, usage, box) in enumerate(REGIONS, start=1):
        x, y, w, h = box
        draw.rectangle((x, y, x + w, y + h), outline=(18, 103, 255, 255), width=3)
        draw.ellipse((x, y, x + 29, y + 29), fill=(18, 103, 255, 255))
        draw.text((x + 9, y + 6), str(idx), fill=(255, 255, 255, 255))
        draw.text((x + 34, y + 6), usage, fill=(18, 32, 75, 255))
    preview.save(DIAGNOSTICS / "ui001_regions_numbered.png")


def pixel_diff(source: Image.Image, render: Image.Image) -> dict:
    source_rgb = source.convert("RGB")
    render_rgb = render.convert("RGB").resize(source_rgb.size)
    diff = ImageChops.difference(source_rgb, render_rgb)
    arr = np.asarray(diff).astype(np.float32)
    per_pixel = arr.mean(axis=2)
    mae = float(arr.mean())
    rmse = float(math.sqrt(np.mean(arr * arr)))
    within_8 = float((per_pixel <= 8).mean())
    within_16 = float((per_pixel <= 16).mean())
    within_32 = float((per_pixel <= 32).mean())
    heat = np.clip(per_pixel * 5.5, 0, 255).astype(np.uint8)
    heat_img = Image.fromarray(heat, "L").convert("RGBA")
    red = Image.new("RGBA", source_rgb.size, (255, 45, 64, 0))
    red.putalpha(heat_img.getchannel("R"))
    overlay = source_rgb.convert("RGBA")
    overlay.alpha_composite(red)
    diff.save(DIAGNOSTICS / "ui001_pixel_diff_raw.png")
    overlay.save(DIAGNOSTICS / "ui001_pixel_diff_heatmap.png")
    return {
        "reference": "original_sources/ui001.png",
        "render": "../qa-ui001-home.png",
        "mae_rgb_0_255": round(mae, 3),
        "rmse_rgb_0_255": round(rmse, 3),
        "pixel_mean_diff_within_8": round(within_8, 4),
        "pixel_mean_diff_within_16": round(within_16, 4),
        "pixel_mean_diff_within_32": round(within_32, 4),
        "diff_raw": "diagnostics/ui001_pixel_diff_raw.png",
        "diff_heatmap": "diagnostics/ui001_pixel_diff_heatmap.png",
    }


def write_outputs(entries: list[dict], diff_summary: dict) -> None:
    manifest = {
        "project": "health-agent-ui001-home-audit",
        "canvas": {"width": 1448, "height": 1086},
        "source": "original_sources/ui001.png",
        "render": "../qa-ui001-home.png",
        "fidelity_mode": "hybrid + pixel_audit",
        "palette": PALETTE,
        "regions": entries,
        "pixel_audit": diff_summary,
    }
    (PROJECT / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    notes = [
        "# UI001 首页专题处理记录",
        "",
        "本工程用于 `ui001.png` 首页专题复刻的工业化拆解与 QA。",
        "",
        "## 本次拆解原则",
        "",
        "- H5 页面不得直接使用 `ui001.png` 作为整图背景。",
        "- 源图被拆成语义区域，用于审查坐标、层级和像素差异。",
        "- 真正 H5 实现由 HTML/CSS/JS 组件和独立资产组成。",
        "- 复杂插画使用切图资产，卡片、手机壳、线条、图表、文案尽量用前端原生实现。",
        "",
        "## 关键视觉基准",
        "",
        "- 画布：1448 × 1086",
        "- 背景：浅蓝到白的医疗科技感背景，叠加低透明网格、点阵和 ECG 线。",
        "- 主文字：深蓝黑 `#131432`，粗重标题。",
        "- 卡片：高透明白，边线 `#d8e7fb`，柔和蓝色阴影。",
        "- 强状态：红 `#ff4a53`、橙 `#ff9c20`、蓝 `#1267ff`、绿 `#20b86a`。",
        "",
        "## 像素审计",
        "",
        f"- MAE: {diff_summary['mae_rgb_0_255']}",
        f"- RMSE: {diff_summary['rmse_rgb_0_255']}",
        f"- 平均像素差 <= 16 的比例：{diff_summary['pixel_mean_diff_within_16']}",
        "",
        "差异主要来自：原设计稿插画/手机内容包含栅格化细节，H5 采用可维护组件重建；后续可继续逐项降低差异。",
    ]
    (PROJECT / "PROCESS_NOTES.md").write_text("\n".join(notes), encoding="utf-8")
    psd_manifest = {
        "canvas": {"width": 1448, "height": 1086, "composite_background": "#eaf5ff"},
        "output": "ui001_audit.psd",
        "preview": "ui001_audit.preview.png",
        "save_layers_dir": "psd_layers",
        "zip_layers": "ui001_audit.layers.zip",
        "layers": [
            {"name": "01 Reference ui001.png", "file": "original_sources/ui001.png", "fit": "none", "remove_background": "none", "opacity": 1},
            {"name": "02 H5 render overlay 45pct", "file": "render_ui001_home.png", "fit": "none", "remove_background": "none", "opacity": 0.45},
            {"name": "03 Pixel diff heatmap 35pct", "file": "diagnostics/ui001_pixel_diff_heatmap.png", "fit": "none", "remove_background": "none", "opacity": 0.35},
        ],
    }
    (PROJECT / "psd_manifest.json").write_text(json.dumps(psd_manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    slides = []
    for title, file, desc in [
        ("原始 UI001 参考图", "original_sources/ui001.png", "源设计稿，用于检查布局、色彩、组件密度。"),
        ("H5 工业化组件复刻", "render_ui001_home.png", "由 HTML/CSS/JS 和独立资产渲染，不使用整图背景。"),
        ("像素差异热力图", "diagnostics/ui001_pixel_diff_heatmap.png", "红色区域代表当前实现和源图的差异集中点。"),
    ]:
        slides.append({
            "name": title,
            "elements": [
                {"kind": "background", "fill": "#eaf5ff"},
                {"kind": "image", "name": title, "file": file, "x": 0, "y": 0, "w": 1448, "h": 1086, "fit": "contain"},
                {"kind": "shape", "shape": "roundRect", "x": 30, "y": 28, "w": 430, "h": 66, "fill": "#ffffff", "stroke": "#cddff3", "stroke_width_px": 1},
                {"kind": "text", "name": "slide title", "text": title, "x": 54, "y": 42, "w": 380, "h": 22, "font_size_px": 24, "font_family": "Arial", "bold": True, "color": "#131432"},
                {"kind": "text", "name": "slide desc", "text": desc, "x": 54, "y": 70, "w": 380, "h": 16, "font_size_px": 12, "font_family": "Arial", "color": "#5f6c8a"},
            ],
        })
    ppt_manifest = {
        "deck": {"canvas_width": 1448, "canvas_height": 1086, "slide_width_in": 14.48, "name": "Health Agent UI001 Audit"},
        "output": "ui001_audit.pptx",
        "slides": slides,
    }
    (PROJECT / "ppt_manifest.json").write_text(json.dumps(ppt_manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def main() -> None:
    ensure_dirs()
    source = Image.open(SOURCE).convert("RGB")
    render = Image.open(RENDER).convert("RGB")
    shutil.copy2(SOURCE, PROJECT / "original_sources" / "ui001.png")
    shutil.copy2(RENDER, PROJECT / "render_ui001_home.png")
    entries = save_region_layers(source)
    make_numbered_preview(source)
    diff_summary = pixel_diff(source, render)
    write_outputs(entries, diff_summary)
    print(json.dumps({"project": str(PROJECT), "regions": len(entries), "pixel_audit": diff_summary}, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
