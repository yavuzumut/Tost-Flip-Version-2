#!/usr/bin/env python3
"""Tost Flip – oynanış sahnesi görsellerini katmanlara ayırır.

Kaynaklar (tools/source/):
  kitchen_full.jpg  – HUD'suz, tabaksız mutfak + masa (1376x768)
  plate_green.jpg   – yeşil (#00FF00) zemin üzerinde tabak

Çıktılar (assets/gameplay/):
  kitchen_back.png  – duvar, pencere, raflar, ocak, buzdolabı, kedi (masa kenarına kadar)
  table.png         – ön plandaki ahşap masa + kupa/tereyağı/reçel dekorları
  plate.png         – şeffaf arka planlı tabak

Kullanım:  python3 tools/split_gameplay_bg.py   (proje kökünden)
"""
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "tools" / "source"
OUT = ROOT / "assets" / "gameplay"

# Masanın arka kenar çizgisi kaynak görselde y≈581. Katmanlar birkaç piksel üst üste biner
# (dikiş görünmesin diye); masa katmanı mutfak katmanının üstünde çizilir.
TABLE_EDGE_Y = 578
OVERLAP = 6

# Tabağın yeşil zemin görselindeki kırpma kutusu (sol, üst, sağ, alt)
PLATE_BOX = (440, 584, 936, 720)


def split_kitchen() -> None:
    im = Image.open(SRC / "kitchen_full.jpg").convert("RGB")
    w, h = im.size
    im.crop((0, 0, w, TABLE_EDGE_Y + OVERLAP)).save(OUT / "kitchen_back.png", optimize=True)
    im.crop((0, TABLE_EDGE_Y, w, h)).save(OUT / "table.png", optimize=True)
    print(f"kitchen_back.png  {w}x{TABLE_EDGE_Y + OVERLAP}")
    print(f"table.png         {w}x{h - TABLE_EDGE_Y}  (y offset {TABLE_EDGE_Y})")


def key_plate() -> None:
    im = Image.open(SRC / "plate_green.jpg").convert("RGB").crop(PLATE_BOX)
    px = im.load()
    out = Image.new("RGBA", im.size)
    opx = out.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b = px[x, y]
            spill = g - max(r, b)
            # spill <= 20 → tamamen opak, spill >= 90 → tamamen şeffaf
            a = 1.0 - min(1.0, max(0.0, (spill - 20) / 70.0))
            if spill > 0:
                g = max(r, b)  # yeşil taşmayı temizle
            opx[x, y] = (r, g, b, int(a * 255))
    bbox = out.getbbox()
    out = out.crop(bbox)
    out.save(OUT / "plate.png", optimize=True)
    print(f"plate.png         {out.width}x{out.height}")


if __name__ == "__main__":
    OUT.mkdir(parents=True, exist_ok=True)
    split_kitchen()
    key_plate()
