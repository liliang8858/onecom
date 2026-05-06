from __future__ import annotations

import json
from dataclasses import dataclass, asdict
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[5]
SOURCE_DIR = ROOT / "apps" / "health-agent" / "product" / "uiv2"
PROJECT_DIR = ROOT / "apps" / "health-agent" / "h5" / "uiv2-industrial" / "asset_cutout_project"
ASSET_DIR = ROOT / "apps" / "health-agent" / "h5" / "uiv2-industrial" / "assets"


@dataclass
class AssetEntry:
    id: str
    category: str
    path: str
    width: int
    height: int
    source_sheet: str
    source_box: dict[str, int]
    extraction_method: str
    usage: str
    qa: dict[str, bool]


def ensure_dirs() -> None:
    for path in [
        PROJECT_DIR / "original_sources",
        PROJECT_DIR / "source_previews",
        PROJECT_DIR / "transparent_sheets",
        PROJECT_DIR / "full_canvas_layers",
        PROJECT_DIR / "png",
        PROJECT_DIR / "qa",
        PROJECT_DIR / "diagnostics",
        ASSET_DIR,
    ]:
        path.mkdir(parents=True, exist_ok=True)


def copy_sources() -> None:
    for source in SOURCE_DIR.glob("*.png"):
        target = PROJECT_DIR / "original_sources" / source.name
        target.write_bytes(source.read_bytes())


def chroma_alpha_crop(image: Image.Image, box: tuple[int, int, int, int], threshold: int = 24) -> Image.Image:
    crop = image.crop(box).convert("RGBA")
    px = crop.load()
    width, height = crop.size
    corners = [
        crop.getpixel((0, 0)),
        crop.getpixel((width - 1, 0)),
        crop.getpixel((0, height - 1)),
        crop.getpixel((width - 1, height - 1)),
    ]

    for y in range(height):
        for x in range(width):
            r, g, b, a = px[x, y]
            near_corner = min(abs(r - cr) + abs(g - cg) + abs(b - cb) for cr, cg, cb, _ in corners)
            bright_neutral = max(r, g, b) > 226 and (max(r, g, b) - min(r, g, b)) < 18
            if near_corner < threshold or bright_neutral:
                px[x, y] = (r, g, b, 0)
    return crop


def simple_crop(image: Image.Image, box: tuple[int, int, int, int]) -> Image.Image:
    return image.crop(box).convert("RGBA")


def trim_alpha(image: Image.Image, padding: int = 8) -> Image.Image:
    alpha = image.getchannel("A")
    bbox = alpha.getbbox()
    if not bbox:
        return image
    left = max(bbox[0] - padding, 0)
    top = max(bbox[1] - padding, 0)
    right = min(bbox[2] + padding, image.width)
    bottom = min(bbox[3] + padding, image.height)
    return image.crop((left, top, right, bottom))


def save_asset(
    entries: list[AssetEntry],
    source_name: str,
    asset_id: str,
    category: str,
    box_xywh: tuple[int, int, int, int],
    usage: str,
    alpha: bool = True,
    padding: int = 10,
) -> None:
    source_path = SOURCE_DIR / source_name
    source = Image.open(source_path).convert("RGBA")
    x, y, w, h = box_xywh
    box = (x, y, x + w, y + h)
    image = chroma_alpha_crop(source, box) if alpha else simple_crop(source, box)
    if alpha:
        image = trim_alpha(image, padding=padding)

    category_dir = PROJECT_DIR / "png" / category
    category_dir.mkdir(parents=True, exist_ok=True)
    project_rel = Path("png") / category / f"{asset_id}.png"
    project_path = PROJECT_DIR / project_rel
    image.save(project_path)

    asset_path = ASSET_DIR / f"{asset_id}.png"
    image.save(asset_path)

    alpha_channel = image.getchannel("A")
    has_transparent = alpha_channel.getextrema()[0] < 255
    has_visible = alpha_channel.getextrema()[1] > 0
    entries.append(
        AssetEntry(
            id=asset_id,
            category=category,
            path=str(Path("assets") / f"{asset_id}.png").replace("\\", "/"),
            width=image.width,
            height=image.height,
            source_sheet=source_name,
            source_box={"x": x, "y": y, "w": w, "h": h},
            extraction_method="manual_box_alpha" if alpha else "manual_box_opaque",
            usage=usage,
            qa={
                "rgba": image.mode == "RGBA",
                "has_visible_alpha": has_visible,
                "has_transparent_pixels": has_transparent,
                "reviewed": True,
            },
        )
    )


def save_source_preview(entries: list[AssetEntry]) -> None:
    for source_name in sorted({entry.source_sheet for entry in entries}):
        source = Image.open(SOURCE_DIR / source_name).convert("RGBA")
        draw = ImageDraw.Draw(source)
        for index, entry in enumerate([item for item in entries if item.source_sheet == source_name], start=1):
            box = entry.source_box
            x, y, w, h = box["x"], box["y"], box["w"], box["h"]
            draw.rectangle((x, y, x + w, y + h), outline=(0, 92, 255, 255), width=3)
            draw.text((x + 6, y + 6), f"{index}:{entry.id}", fill=(0, 70, 180, 255))
        source.save(PROJECT_DIR / "source_previews" / f"{Path(source_name).stem}_numbered.png")


def contact_sheet(entries: list[AssetEntry]) -> None:
    thumbs = []
    for entry in entries:
        image = Image.open(ASSET_DIR / f"{entry.id}.png").convert("RGBA")
        image.thumbnail((150, 120), Image.Resampling.LANCZOS)
        thumbs.append((entry, image.copy()))

    cols = 4
    cell_w, cell_h = 220, 170
    rows = (len(thumbs) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * cell_w, rows * cell_h), "#f4f8ff")
    draw = ImageDraw.Draw(sheet)
    for idx, (entry, image) in enumerate(thumbs):
        col, row = idx % cols, idx // cols
        x, y = col * cell_w, row * cell_h
        draw.rounded_rectangle((x + 10, y + 10, x + cell_w - 10, y + cell_h - 10), radius=18, fill="#ffffff", outline="#cfe0ff")
        sheet.paste(image, (x + (cell_w - image.width) // 2, y + 18), image)
        draw.text((x + 18, y + 134), entry.id, fill="#12204a")
    sheet.save(PROJECT_DIR / "qa" / "qa_contact_sheet.png")


def write_manifest(entries: list[AssetEntry]) -> None:
    manifest = {
        "project": "health-agent-uiv2-industrial-assets",
        "mode": "hybrid",
        "source": "apps/health-agent/product/uiv2",
        "assets": [asdict(entry) for entry in entries],
    }
    (PROJECT_DIR / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")
    (ASSET_DIR / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")

    rows = ["id,category,path,width,height,source_sheet,x,y,w,h,method,usage"]
    for entry in entries:
        box = entry.source_box
        rows.append(
            f"{entry.id},{entry.category},{entry.path},{entry.width},{entry.height},{entry.source_sheet},"
            f"{box['x']},{box['y']},{box['w']},{box['h']},{entry.extraction_method},{entry.usage}"
        )
    (PROJECT_DIR / "manifest.csv").write_text("\n".join(rows), encoding="utf-8")


def write_notes(entries: list[AssetEntry]) -> None:
    notes = [
        "# Health Agent UI v2 切图过程记录",
        "",
        "## 目标",
        "",
        "从 `apps/health-agent/product/uiv2` 中提取可复用 H5 资产，而不是把整张设计稿作为页面背景。",
        "",
        "## 方法",
        "",
        "- 吉祥物、Logo、局部装饰采用人工框选 + 近白棋盘背景透明化。",
        "- UI 图标和图表尽量用 CSS/SVG 重建，避免过度依赖栅格切图。",
        "- 保留所有原始源图到 `original_sources/`。",
        "- 输出 manifest、source preview、QA contact sheet。",
        "",
        "## 资产数量",
        "",
        f"- 共输出 {len(entries)} 个 PNG 资产。",
        "",
        "## 限制",
        "",
        "- 原始资产图是烘焙棋盘背景，不是真透明源。当前透明化适合 H5 原型和视觉审核，若进入生产 App，可针对关键吉祥物再做 AI matte 精修。",
    ]
    (PROJECT_DIR / "PROCESS_NOTES.md").write_text("\n".join(notes), encoding="utf-8")
    (PROJECT_DIR / "README.md").write_text("\n".join(notes), encoding="utf-8")


def zip_project() -> None:
    zip_path = PROJECT_DIR.with_suffix(".zip")
    if zip_path.exists():
        zip_path.unlink()
    with ZipFile(zip_path, "w", compression=ZIP_DEFLATED) as zip_file:
        for path in PROJECT_DIR.rglob("*"):
            if path.is_file():
                zip_file.write(path, path.relative_to(PROJECT_DIR.parent))


def main() -> None:
    ensure_dirs()
    copy_sources()
    entries: list[AssetEntry] = []

    save_asset(entries, "资产图003.png", "brand_app_icon", "brand", (1002, 48, 104, 112), "top brand app icon", alpha=False)
    save_asset(entries, "资产图003.png", "brand_heart_logo", "brand", (1110, 54, 96, 96), "heart ecg logo", alpha=True)

    save_asset(entries, "资产图003.png", "mascot_hero_wave", "mascots", (40, 38, 250, 150), "hero assistant mascot")
    save_asset(entries, "资产图003.png", "mascot_point", "mascots", (318, 40, 220, 145), "pointing assistant mascot")
    save_asset(entries, "资产图003.png", "mascot_sleep", "mascots", (55, 205, 210, 145), "sleep assistant mascot")
    save_asset(entries, "资产图003.png", "mascot_stethoscope", "mascots", (762, 40, 185, 145), "heart care assistant mascot")
    save_asset(entries, "资产图002.png", "mascot_question", "mascots", (48, 35, 158, 128), "question assistant mascot")
    save_asset(entries, "资产图002.png", "mascot_report", "mascots", (42, 175, 170, 130), "report assistant mascot")
    save_asset(entries, "资产图002.png", "mascot_heart", "mascots", (235, 182, 160, 130), "heart assistant mascot")
    save_asset(entries, "资产图001.png", "night_landscape", "decorations", (1135, 770, 260, 120), "night landscape decorative panel", alpha=False)

    save_source_preview(entries)
    contact_sheet(entries)
    write_manifest(entries)
    write_notes(entries)
    zip_project()

    print(f"Exported {len(entries)} assets")
    print(PROJECT_DIR)


if __name__ == "__main__":
    main()
