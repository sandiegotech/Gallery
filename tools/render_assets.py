#!/usr/bin/env python3
"""Render the Gallery app's tvOS brand assets in the SDIT product-design style.

The mark: a picture-frame outline with a mat line and a single accent dot —
three stroke-based elements on the 24pt grid, ink on warm paper.
Generates the full asset catalog: layered app icons (two sizes), top shelf
images (two widths), and launch images, with all Contents.json files.
"""
import json
import shutil
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Gallery/Resources/Assets.xcassets"
FONTS = ROOT / "Gallery/Resources/Fonts"

INK = (16, 28, 44, 255)        # #101C2C
PAPER_TILE = (244, 241, 232, 255)  # #F4F1E8 — icon tile
PAPER = (252, 251, 248, 255)   # #FCFBF8 — canvas

SS = 4  # supersample factor


import math


def draw_frame(draw, cx, cy, grid, color=INK):
    """The frame alone — outer stroke on the 24-unit grid."""
    w = 1.8 * grid
    draw.rounded_rectangle(
        [cx + (2.5 - 12) * grid, cy + (5.0 - 12) * grid,
         cx + (21.5 - 12) * grid, cy + (19.0 - 12) * grid],
        radius=w / 2, outline=color, width=max(1, round(w)))


def draw_landscape(draw, cx, cy, grid, color=INK):
    """The work inside the frame: a line of hills and a sun. Two elements."""
    def pt(x, y):
        return (cx + (x - 12) * grid, cy + (y - 12) * grid)
    # Hills — one smooth swell across the lower half, drawn as a stamped
    # stroke so the joins stay clean at every scale
    r_stroke = 0.75 * grid
    for i in range(241):
        t = i / 240
        x = 5.9 + (18.1 - 5.9) * t
        y = 14.7 - 1.25 * math.sin(t * math.pi * 1.45 + 0.25)
        px, py = pt(x, y)
        draw.ellipse([px - r_stroke, py - r_stroke, px + r_stroke, py + r_stroke], fill=color)
    # The sun
    r = 1.0 * grid
    sx, sy = pt(16.1, 9.2)
    draw.ellipse([sx - r, sy - r, sx + r, sy + r], fill=color)


def draw_mark(draw, cx, cy, grid, color=INK):
    """The full mark: frame + landscape, for flat (non-layered) renders."""
    draw_frame(draw, cx, cy, grid, color)
    draw_landscape(draw, cx, cy, grid, color)


def render(size, painter):
    """Render at supersample then downscale."""
    img = Image.new("RGBA", (size[0] * SS, size[1] * SS), (0, 0, 0, 0))
    painter(ImageDraw.Draw(img), size[0] * SS, size[1] * SS)
    return img.resize(size, Image.LANCZOS)


def save(img, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    img.save(path, "PNG")


def contents(path, payload):
    payload["info"] = {"author": "xcode", "version": 1}
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, indent=2))


def back_layer(w, h):
    return Image.new("RGBA", (w, h), PAPER_TILE)


def frame_layer(w, h):
    def paint(d, W, H):
        draw_frame(d, W / 2, H / 2, grid=H * 0.030)
    return render((w, h), paint)


def art_layer(w, h):
    def paint(d, W, H):
        draw_landscape(d, W / 2, H / 2, grid=H * 0.030)
    return render((w, h), paint)


if CATALOG.exists():
    shutil.rmtree(CATALOG)

contents(CATALOG / "Contents.json", {})

# ---- Brand assets (icon stacks + top shelf) ----
brand = CATALOG / "App Icon & Top Shelf Image.brandassets"
contents(brand / "Contents.json", {"assets": [
    {"filename": "App Icon - App Store.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "1280x768"},
    {"filename": "App Icon.imagestack", "idiom": "tv", "role": "primary-app-icon", "size": "400x240"},
    {"filename": "Top Shelf Image Wide.imageset", "idiom": "tv", "role": "top-shelf-image-wide", "size": "2320x720"},
    {"filename": "Top Shelf Image.imageset", "idiom": "tv", "role": "top-shelf-image", "size": "1920x720"},
]})


LAYERS = [("Art", art_layer), ("Frame", frame_layer), ("Back", back_layer)]  # front to back


def icon_stack(name, w, h, scales):
    stack = brand / f"{name}.imagestack"
    contents(stack / "Contents.json", {"layers": [
        {"filename": f"{layer}.imagestacklayer"} for layer, _ in LAYERS
    ]})
    for layer, maker in LAYERS:
        ldir = stack / f"{layer}.imagestacklayer"
        contents(ldir / "Contents.json", {})
        images = []
        for scale in scales:
            fname = f"{layer.lower()}{'' if scale == 1 else f'@{scale}x'}.png"
            save(maker(w * scale, h * scale), ldir / "Content.imageset" / fname)
            images.append({"filename": fname, "idiom": "tv", "scale": f"{scale}x"})
        contents(ldir / "Content.imageset" / "Contents.json", {"images": images})


icon_stack("App Icon - App Store", 1280, 768, [1])
icon_stack("App Icon", 400, 240, [1, 2])


def top_shelf(w, h):
    """Paper banner: the mark and the wordmark, side by side."""
    def paint(d, W, H):
        d.rectangle([0, 0, W, H], fill=PAPER)
        font = ImageFont.truetype(str(FONTS / "EBGaramond-Medium.ttf"), int(H * 0.205))
        text = "The Gallery"
        tw = d.textlength(text, font=font)
        mark_w = H * 0.42
        gap = H * 0.11
        total = mark_w + gap + tw
        x0 = (W - total) / 2
        draw_mark(d, x0 + mark_w / 2, H / 2, grid=H * 0.0165)
        d.text((x0 + mark_w + gap, H / 2), text, font=font, fill=INK, anchor="lm")
    return render((w, h), paint)


for name, w, h in [("Top Shelf Image Wide", 2320, 720), ("Top Shelf Image", 1920, 720)]:
    iset = brand / f"{name}.imageset"
    big = top_shelf(w * 2, h * 2)
    save(big.resize((w, h), Image.LANCZOS), iset / "shelf.png")
    save(big, iset / "shelf@2x.png")
    contents(iset / "Contents.json", {"images": [
        {"filename": "shelf.png", "idiom": "tv", "scale": "1x"},
        {"filename": "shelf@2x.png", "idiom": "tv", "scale": "2x"},
    ]})

# ---- Launch image: paper, the mark alone, centered ----


def launch(w, h):
    def paint(d, W, H):
        d.rectangle([0, 0, W, H], fill=PAPER)
        draw_mark(d, W / 2, H / 2, grid=H * 0.0125)  # mark ~ 23% of screen height
    return render((w, h), paint)


ldir = CATALOG / "LaunchImage.launchimage"
save(launch(1920, 1080), ldir / "launch.png")
save(launch(3840, 2160), ldir / "launch@2x.png")
contents(ldir / "Contents.json", {"images": [
    {"extent": "full-screen", "filename": "launch.png", "idiom": "tv",
     "minimum-system-version": "11.0", "orientation": "landscape", "scale": "1x"},
    {"extent": "full-screen", "filename": "launch@2x.png", "idiom": "tv",
     "minimum-system-version": "11.0", "orientation": "landscape", "scale": "2x"},
]})

# Preview composite for eyeballing: icon as it will appear
preview = Image.new("RGBA", (400, 240), PAPER_TILE)
preview.alpha_composite(frame_layer(400, 240))
preview.alpha_composite(art_layer(400, 240))
save(preview, Path("/tmp/icon-preview.png"))
save(top_shelf(1920, 720), Path("/tmp/shelf-preview.png"))

print("Asset catalog written to", CATALOG)
