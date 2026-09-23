"""
FireShield AI — iOS App Icon Generator
Generates all required iOS icon sizes from a programmatic source.
Run from: demo_app/ios/
"""
from PIL import Image, ImageDraw, ImageFont
import os, math

ICON_DIR = os.path.join(os.path.dirname(__file__),
                        "Runner", "Assets.xcassets", "AppIcon.appiconset")

# All required sizes: (filename, logical_size, scale)
SIZES = [
    ("Icon-App-20x20@1x.png",      20,   1),
    ("Icon-App-20x20@2x.png",      20,   2),
    ("Icon-App-20x20@3x.png",      20,   3),
    ("Icon-App-29x29@1x.png",      29,   1),
    ("Icon-App-29x29@2x.png",      29,   2),
    ("Icon-App-29x29@3x.png",      29,   3),
    ("Icon-App-40x40@1x.png",      40,   1),
    ("Icon-App-40x40@2x.png",      40,   2),
    ("Icon-App-40x40@3x.png",      40,   3),
    ("Icon-App-60x60@2x.png",      60,   2),
    ("Icon-App-60x60@3x.png",      60,   3),
    ("Icon-App-76x76@1x.png",      76,   1),
    ("Icon-App-76x76@2x.png",      76,   2),
    ("Icon-App-83.5x83.5@2x.png",  84,   2),  # rounded to int
    ("Icon-App-1024x1024@1x.png", 1024,  1),
]

BG_COLOR       = (13, 13, 26)       # #0D0D1A deep navy
GOLD_COLOR     = (251, 194, 40)     # EY gold #FBC228
TEXT_COLOR     = (255, 255, 255)
SHIELD_COLOR   = (251, 194, 40)


def draw_icon(size_px: int) -> Image.Image:
    img = Image.new("RGB", (size_px, size_px), BG_COLOR)
    draw = ImageDraw.Draw(img)

    cx, cy = size_px / 2, size_px / 2

    # --- Shield shape (polygon) ---
    s = size_px * 0.72          # shield width
    top = cy - s * 0.52
    bot = cy + s * 0.62
    pts = [
        (cx,          top),               # top centre
        (cx + s/2,    top + s * 0.18),    # top-right
        (cx + s/2,    cy + s * 0.10),     # mid-right
        (cx,          bot),               # bottom point
        (cx - s/2,    cy + s * 0.10),     # mid-left
        (cx - s/2,    top + s * 0.18),    # top-left
    ]
    draw.polygon(pts, fill=GOLD_COLOR)

    # --- "F" letter inside shield ---
    if size_px >= 40:
        f_size = max(int(size_px * 0.38), 8)
        try:
            font = ImageFont.truetype("arial.ttf", f_size)
        except Exception:
            font = ImageFont.load_default()

        bbox = draw.textbbox((0, 0), "F", font=font)
        tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
        draw.text((cx - tw / 2, cy - th / 2 - size_px * 0.03),
                  "F", fill=BG_COLOR, font=font)

    # --- "AI" tiny label below shield (only on large icons) ---
    if size_px >= 120:
        ai_size = max(int(size_px * 0.09), 7)
        try:
            font_small = ImageFont.truetype("arial.ttf", ai_size)
        except Exception:
            font_small = ImageFont.load_default()
        bbox2 = draw.textbbox((0, 0), "AI", font=font_small)
        tw2 = bbox2[2] - bbox2[0]
        draw.text((cx - tw2 / 2, bot + size_px * 0.02),
                  "AI", fill=GOLD_COLOR, font=font_small)

    return img


def main():
    os.makedirs(ICON_DIR, exist_ok=True)
    for filename, logical, scale in SIZES:
        px = logical * scale
        img = draw_icon(px)
        out = os.path.join(ICON_DIR, filename)
        img.save(out, "PNG")
        print(f"  {filename:45s}  {px}x{px}px")
    print(f"\nDone — {len(SIZES)} icons written to:\n  {ICON_DIR}")


if __name__ == "__main__":
    main()
