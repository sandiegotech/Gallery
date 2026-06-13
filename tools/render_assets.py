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
from PIL import Image, ImageDraw, ImageFont, ImageFilter, ImageOps

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "Gallery/Resources/Assets.xcassets"
FONTS = ROOT / "Gallery/Resources/Fonts"
MEDIA = ROOT / "Gallery/Resources/Media"
MANIFEST = ROOT / "Gallery/Resources/manifest.json"

INK = (16, 28, 44, 255)        # #101C2C
PAPER_TILE = (244, 241, 232, 255)  # #F4F1E8 — icon tile
PAPER = (252, 251, 248, 255)   # #FCFBF8 — canvas

# App icon palette: the mark sits cream-on-deep, lit like the gallery wall,
# with a single gold sun. Switch ICON_STYLE to recolor the whole icon + launch.
# Each palette is (top, bottom, spotlight) — the spotlight is an in-hue lift so
# the centre glows without washing the colour out to grey.
ICON_STYLE = "ink"             # "ink" (navy/blue) or "charcoal"
ICON_PALETTES = {
    "ink":      ((28, 50, 86), (8, 15, 30), (58, 96, 152)),    # #1C3256 → #080F1E
    "charcoal": ((56, 53, 49), (20, 19, 17), (98, 93, 86)),    # #383531 → #141311
}
ICON_MARK = (244, 241, 232, 255)   # warm paper — frame + hills
ICON_SUN = (218, 182, 96, 255)     # brand gold — the sun

SS = 4  # supersample factor


import math


def draw_frame(draw, cx, cy, grid, color=INK):
    """The frame alone — outer stroke on the 24-unit grid."""
    w = 1.8 * grid
    draw.rounded_rectangle(
        [cx + (2.5 - 12) * grid, cy + (5.0 - 12) * grid,
         cx + (21.5 - 12) * grid, cy + (19.0 - 12) * grid],
        radius=w / 2, outline=color, width=max(1, round(w)))


def draw_landscape(draw, cx, cy, grid, color=INK, sun_color=None):
    """The work inside the frame: a line of hills and a sun. Two elements."""
    sun_color = sun_color or color
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
    draw.ellipse([sx - r, sy - r, sx + r, sy + r], fill=sun_color)


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


def _vgrad(w, h, top, bot):
    """A vertical top→bottom gradient as an RGB image."""
    col = Image.new("RGB", (1, h))
    px = col.load()
    for y in range(h):
        t = y / max(1, h - 1)
        px[0, y] = tuple(round(top[i] + (bot[i] - top[i]) * t) for i in range(3))
    return col.resize((w, h))


def back_layer(w, h, style=None):
    """The icon tile: a deep gallery-wall gradient with a soft in-hue spotlight
    where the mark hangs."""
    top, bot, spot = ICON_PALETTES[style or ICON_STYLE]
    base = _vgrad(w, h, top, bot).convert("RGBA")
    glow = Image.new("L", (w, h), 0)
    ImageDraw.Draw(glow).ellipse(
        [w * 0.5 - w * 0.58, -h * 0.42, w * 0.5 + w * 0.58, h * 0.82], fill=130)
    glow = glow.filter(ImageFilter.GaussianBlur(h * 0.17))
    light = Image.new("RGBA", (w, h), spot + (0,))
    light.putalpha(glow)
    return Image.alpha_composite(base, light)


def frame_layer(w, h):
    def paint(d, W, H):
        draw_frame(d, W / 2, H / 2, grid=H * 0.030, color=ICON_MARK)
    return render((w, h), paint)


def art_layer(w, h):
    def paint(d, W, H):
        draw_landscape(d, W / 2, H / 2, grid=H * 0.030, color=ICON_MARK, sun_color=ICON_SUN)
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


# ---- Top shelf: a salon-hung gallery wall of the real masterpieces ----
#
# The old banner was a logo on blank paper. This builds the thing the app is
# actually about: public-domain masterpieces, each in its in-app frame style,
# hung salon-style on a warm, top-lit gallery wall, with the wordmark engraved
# below. Frame chrome here mirrors FramedArtworkView so the shelf reads as the
# app's own wall.

# Frame style per artwork image, read from the manifest so the two stay in sync.
_MANIFEST = json.loads(MANIFEST.read_text())
FRAME_OF = {a["image"]: a.get("frameStyle", "none") for a in _MANIFEST["artworks"]}

# The curated hang, left to right — chosen for a rhythm of landscape and
# portrait and a spread across the collections and frame styles. The wide
# shelf shows the whole row; the narrower shelf shows the first six.
HANG = [
    "great-wave.jpg",          # Hokusai — landscape, matted print
    "madame-x.jpg",            # Sargent — tall portrait, baroque gold
    "wheat-field.jpg",         # Van Gogh — landscape, gilded
    "mucha-zodiac.jpg",        # Mucha — tall poster, matted
    "water-lilies.jpg",        # Monet — square-ish, gilded
    "young-woman-pitcher.jpg", # Vermeer — portrait, Dutch ebony
    "musicians.jpg",           # Caravaggio — landscape, baroque gold
    "mada-primavesi.jpg",      # Klimt — portrait, Secession gold
    "harvesters.jpg",          # Bruegel — landscape, Dutch ebony
]

WALL_TOP = (236, 230, 219)
WALL_BOT = (208, 199, 183)


def _band(w, h, top, bot):
    """A vertical metal/wood gradient sized to fill a frame band."""
    return _vgrad(w, h, top, bot).convert("RGBA")


def _pad(img, p, fill):
    """Grow img by a uniform border of a solid color."""
    p = max(1, round(p))
    out = Image.new("RGBA", (img.width + 2 * p, img.height + 2 * p), fill)
    out.paste(img, (p, p))
    return out


def frame_image(art, style, a):
    """Wrap a raster artwork in chrome echoing the app's FramedArtworkView.

    `a` is the artwork's pixel height; band widths scale off it so every frame
    reads at the same weight regardless of the work's size.
    """
    u = a / 100.0  # one frame "unit"
    x = art.convert("RGBA")
    if style == "gilded":
        x = _pad(x, 1.6 * u, (56, 41, 13))               # inner dark liner
        b = round(5.2 * u)
        g = _band(x.width + 2 * b, x.height + 2 * b,
                  (224, 188, 104), (150, 116, 48))        # gold band
        # a brighter diagonal highlight so the gold isn't flat
        hi = _band(g.width, g.height, (245, 214, 138), (180, 142, 66))
        g = Image.blend(g, hi, 0.35)
        g.paste(x, (b, b))
        x = _pad(g, 1.4 * u, (38, 27, 7))                 # outer edge
    elif style == "baroque":
        x = _pad(x, 1.4 * u, (40, 28, 8))                 # dark sight edge
        b = round(3.0 * u)                                # bright inner ogee
        g = _band(x.width + 2 * b, x.height + 2 * b, (242, 212, 130), (168, 128, 54))
        g.paste(x, (b, b)); x = g
        x = _pad(x, 2.4 * u, (51, 36, 13))                # carved dark recess
        b = round(6.4 * u)                                # broad antiqued course
        g = _band(x.width + 2 * b, x.height + 2 * b, (204, 163, 77), (128, 96, 38))
        hi = _band(g.width, g.height, (224, 186, 104), (150, 116, 48))
        g = Image.blend(g, hi, 0.3)
        g.paste(x, (b, b)); x = g
        x = _pad(x, 1.4 * u, (40, 28, 8))                 # outer edge
    elif style == "dutch":
        x = _pad(x, 1.0 * u, (143, 112, 46))             # gold sight fillet
        b = round(6.6 * u)                                # ebonized black band
        w = _band(x.width + 2 * b, x.height + 2 * b, (27, 24, 21), (9, 8, 7))
        w.paste(x, (b, b)); x = w
        x = _pad(x, 1.0 * u, (0, 0, 0))                   # outer edge
    elif style == "secession":
        x = _pad(x, 1.2 * u, (40, 33, 15))               # dark sight line
        x = _pad(x, 2.0 * u, (201, 166, 79))             # flat gold (inner)
        x = _pad(x, 0.7 * u, (40, 33, 15))               # incised rule
        x = _pad(x, 5.2 * u, (214, 178, 89))             # flat gold (wide)
        x = _pad(x, 0.7 * u, (40, 33, 15))               # outer incised rule
    elif style == "classic":
        x = _pad(x, 1.6 * u, (18, 12, 8))                 # inner liner
        b = round(4.4 * u)
        w = _band(x.width + 2 * b, x.height + 2 * b,
                  (74, 53, 34), (38, 26, 16))             # walnut band
        w.paste(x, (b, b))
        x = _pad(w, 1.2 * u, (0, 0, 0))                   # black edge
    elif style == "modern":
        x = _pad(x, 2.6 * u, (20, 20, 22))                # slim dark frame
    elif style == "float":
        x = _pad(x, 6.5 * u, (244, 239, 229))             # wide cream mat
        x = _pad(x, 1.6 * u, (28, 28, 30))                # thin dark edge
    return x


def _wall(W, H):
    """Warm gallery wall: top-lit, gently vignetted at the edges."""
    base = _vgrad(W, H, WALL_TOP, WALL_BOT).convert("RGBA")
    # soft pool of light spilling from above center
    light = Image.new("L", (W, H), 0)
    ImageDraw.Draw(light).ellipse(
        [W * 0.5 - W * 0.5, -H * 0.55, W * 0.5 + W * 0.5, H * 0.85], fill=64)
    light = light.filter(ImageFilter.GaussianBlur(H * 0.16))
    glow = Image.new("RGBA", (W, H), (255, 251, 242, 0))
    glow.putalpha(light)
    base = Image.alpha_composite(base, glow)
    # darken toward the edges
    m = int(min(W, H) * 0.035)
    inner = Image.new("L", (W, H), 0)
    ImageDraw.Draw(inner).rectangle([m, m, W - m, H - m], fill=255)
    inner = inner.filter(ImageFilter.GaussianBlur(min(W, H) * 0.11))
    shade = Image.new("RGBA", (W, H), (46, 34, 18, 0))
    shade.putalpha(ImageOps.invert(inner).point(lambda v: int(v * 0.42)))
    return Image.alpha_composite(base, shade)


def _hang(canvas, framed, cx, baseline, u):
    """Place a framed work centered on cx with its bottom at `baseline`,
    casting a soft drop shadow on the wall."""
    x = round(cx - framed.width / 2)
    y = round(baseline - framed.height)
    sil = Image.new("RGBA", framed.size, (14, 10, 7, 130))
    sil.putalpha(Image.new("L", framed.size, 130))
    shadow = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    shadow.alpha_composite(sil, (x + round(3 * u), y + round(11 * u)))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8 * u))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(framed, (x, y))


def top_shelf(W, H, images):
    """A salon hang of framed masterpieces on a warm wall, wordmark below."""
    canvas = _wall(W, H)

    # vertical layout budget
    side = W * 0.045
    baseline = H * 0.70                 # where frame bottoms rest
    art_top = H * 0.085
    max_fh = baseline - art_top         # tallest a framed work may be
    gap = W * 0.022

    # Build each frame at a salon-varied height, then scale the whole row to fit.
    pieces = []
    for i, img_name in enumerate(images):
        path = MEDIA / img_name
        if not path.exists():
            continue
        art = Image.open(path).convert("RGB")
        jitter = [0.0, 0.06, 0.0, 0.10, 0.0, 0.05, 0.0][i % 7]
        a = (H * 0.46) * (1 - jitter)   # target artwork height
        # constrain portrait widths so tall works don't dominate the row
        w_at_a = art.width * (a / art.height)
        if w_at_a > H * 0.46:
            a = a * (H * 0.46) / w_at_a
        a = round(art.height * (a / art.height))
        scaled = art.resize((round(art.width * a / art.height), a), Image.LANCZOS)
        pieces.append(frame_image(scaled, FRAME_OF.get(img_name, "none"), a))

    row_w = sum(p.width for p in pieces) + gap * (len(pieces) - 1)
    tallest = max(p.height for p in pieces)
    s = min((W - 2 * side) / row_w, max_fh / tallest)
    if s < 1:
        pieces = [p.resize((round(p.width * s), round(p.height * s)), Image.LANCZOS)
                  for p in pieces]
        gap *= s
        row_w = sum(p.width for p in pieces) + gap * (len(pieces) - 1)

    u = H / 100.0
    x = (W - row_w) / 2
    for p in pieces:
        _hang(canvas, p, x + p.width / 2, baseline, u)
        x += p.width + gap

    # Wordmark engraved on the lower wall: the mark + "The Gallery".
    d = ImageDraw.Draw(canvas)
    font = ImageFont.truetype(str(FONTS / "EBGaramond-Medium.ttf"), int(H * 0.125))
    text = "The Gallery"
    tracking = int(H * 0.012)
    tw = sum(d.textlength(c, font=font) + tracking for c in text) - tracking
    mark_w = H * 0.165
    mgap = H * 0.05
    total = mark_w + mgap + tw
    ty = H * 0.855
    x0 = (W - total) / 2
    draw_mark(d, x0 + mark_w / 2, ty, grid=H * 0.0067)
    tx = x0 + mark_w + mgap
    for c in text:                      # manual tracking for an engraved feel
        d.text((tx, ty), c, font=font, fill=INK, anchor="lm")
        tx += d.textlength(c, font=font) + tracking
    return canvas


SHELVES = [
    ("Top Shelf Image Wide", 2320, 720, HANG),
    ("Top Shelf Image", 1920, 720, HANG[:6]),
]
for name, w, h, images in SHELVES:
    iset = brand / f"{name}.imageset"
    big = top_shelf(w * 2, h * 2, images)
    save(big.resize((w, h), Image.LANCZOS), iset / "shelf.png")
    save(big, iset / "shelf@2x.png")
    contents(iset / "Contents.json", {"images": [
        {"filename": "shelf.png", "idiom": "tv", "scale": "1x"},
        {"filename": "shelf@2x.png", "idiom": "tv", "scale": "2x"},
    ]})

# ---- Launch image: the icon's wall, the mark alone, centered ----


def launch(w, h):
    """Match the icon so the open is seamless: deep wall, cream mark, gold sun."""
    img = back_layer(w, h)
    def paint(d, W, H):
        draw_frame(d, W / 2, H / 2, grid=H * 0.0125, color=ICON_MARK)
        draw_landscape(d, W / 2, H / 2, grid=H * 0.0125, color=ICON_MARK, sun_color=ICON_SUN)
    img.alpha_composite(render((w, h), paint))  # mark ~ 23% of screen height
    return img


ldir = CATALOG / "LaunchImage.launchimage"
save(launch(1920, 1080), ldir / "launch.png")
save(launch(3840, 2160), ldir / "launch@2x.png")
contents(ldir / "Contents.json", {"images": [
    {"extent": "full-screen", "filename": "launch.png", "idiom": "tv",
     "minimum-system-version": "11.0", "orientation": "landscape", "scale": "1x"},
    {"extent": "full-screen", "filename": "launch@2x.png", "idiom": "tv",
     "minimum-system-version": "11.0", "orientation": "landscape", "scale": "2x"},
]})

# Preview composites for eyeballing: the icon in both palettes.
def icon_preview(style, w=400, h=240):
    img = back_layer(w, h, style)
    img.alpha_composite(frame_layer(w, h))
    img.alpha_composite(art_layer(w, h))
    return img

save(icon_preview("ink"), Path("/tmp/icon-ink.png"))
save(icon_preview("charcoal"), Path("/tmp/icon-charcoal.png"))
save(top_shelf(2320, 720, HANG), Path("/tmp/shelf-preview.png"))

print("Asset catalog written to", CATALOG, "(icon style:", ICON_STYLE + ")")
