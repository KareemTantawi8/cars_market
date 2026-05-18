#!/usr/bin/env python3
"""Generate App Store screenshots for iPhone and iPad at required pixel dimensions."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
CURSOR_ASSETS = Path(
    "/Users/kareemmahmoud/.cursor/projects/Users-kareemmahmoud-Projects-cars-market/assets"
)
OUT_IPHONE = ROOT / "assets" / "iPhone"
OUT_IPAD = ROOT / "assets" / "iPad"

# App Store Connect sizes (portrait)
IPHONE_SIZE = (1284, 2778)  # 6.5" display (iPhone 14 Plus, 13 Pro Max, etc.)
IPAD_SIZE = (2048, 2732)  # 12.9" / 13" iPad Pro

SCREENS = [
    ("01_splash.png", "WhatsApp_Image_1447-11-30_at_10.04.14-7762d74c-8e6d-4f53-a1c7-c819cb349547.png"),
    ("02_vendor_dashboard.png", "WhatsApp_Image_1447-11-30_at_10.04.16-68cb6a3c-b5ab-4684-ba81-f9a6e910a12d.png"),
    ("03_home_request_part.png", "WhatsApp_Image_1447-11-30_at_10.04.18-186e852c-aaa7-4fd5-8ab9-941aef922e5c.png"),
    ("04_brand_selection.png", "Screenshot_1447-11-26_at_9.08.10_AM-e3131e1d-c2bb-4bdf-b0e7-0aa3a7778ceb.png"),
    ("05_ads_results.png", "Screenshot_1447-11-26_at_9.09.09_AM-e2701583-cb16-43c1-b0d7-7d41345f7bf6.png"),
    ("06_my_ads.png", "Screenshot_1447-11-26_at_9.09.19_AM-276ed5f0-d0c6-4a04-9f5f-35f4e0798670.png"),
    ("07_chats.png", "Screenshot_1447-11-26_at_9.09.28_AM-0b0ad318-9621-4798-ade5-35a158e70091.png"),
    ("08_profile.png", "Screenshot_1447-11-26_at_9.09.36_AM-fae7feac-5a8d-46f1-b591-e577dcba6819.png"),
]


def sample_background(img: Image.Image) -> tuple[int, int, int]:
    """Average corner pixels for letterbox fill."""
    w, h = img.size
    points = [
        img.getpixel((2, 2)),
        img.getpixel((w - 3, 2)),
        img.getpixel((2, h - 3)),
        img.getpixel((w - 3, h - 3)),
    ]
    if isinstance(points[0], int):
        return (points[0], points[0], points[0])
    r = sum(p[0] for p in points) // 4
    g = sum(p[1] for p in points) // 4
    b = sum(p[2] for p in points) // 4
    return (r, g, b)


def fit_on_canvas(src: Image.Image, canvas_size: tuple[int, int]) -> Image.Image:
    out_w, out_h = canvas_size
    bg = sample_background(src)
    canvas = Image.new("RGB", canvas_size, bg)

    scale = min(out_w / src.width, out_h / src.height)
    new_w = int(src.width * scale)
    new_h = int(src.height * scale)
    resized = src.resize((new_w, new_h), Image.Resampling.LANCZOS)

    x = (out_w - new_w) // 2
    y = (out_h - new_h) // 2
    canvas.paste(resized, (x, y))
    return canvas


def main() -> None:
    OUT_IPHONE.mkdir(parents=True, exist_ok=True)
    OUT_IPAD.mkdir(parents=True, exist_ok=True)

    for filename, source_name in SCREENS:
        src_path = CURSOR_ASSETS / source_name
        if not src_path.exists():
            raise FileNotFoundError(f"Missing source: {src_path}")

        src = Image.open(src_path).convert("RGB")

        iphone = fit_on_canvas(src, IPHONE_SIZE)
        ipad = fit_on_canvas(src, IPAD_SIZE)

        iphone_path = OUT_IPHONE / filename
        ipad_path = OUT_IPAD / filename

        iphone.save(iphone_path, "PNG", optimize=True)
        ipad.save(ipad_path, "PNG", optimize=True)

        print(f"✓ {filename}")
        print(f"  iPhone: {iphone_path} ({IPHONE_SIZE[0]}×{IPHONE_SIZE[1]})")
        print(f"  iPad:   {ipad_path} ({IPAD_SIZE[0]}×{IPAD_SIZE[1]})")

    print(f"\nDone — {len(SCREENS)} screenshots × 2 platforms")


if __name__ == "__main__":
    main()
