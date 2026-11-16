#!/usr/bin/env python3
"""Usta Şef Modu ve Mod Seçim Ekranı varlıklarını referans görsellerden çıkarır."""
from pathlib import Path
from PIL import Image

SRC1 = Path("/home/umut/.gemini/antigravity/brain/0c0bda92-d995-4119-97ab-510f4b563af8/.user_uploaded/media_1794782695094.jpg")
SRC2 = Path("/home/umut/.gemini/antigravity/brain/0c0bda92-d995-4119-97ab-510f4b563af8/.user_uploaded/media_1794782703177.jpg")

OUT_SKILLED = Path("/home/umut/tost-flip-(copy)/assets/skilled")
OUT_MODES = Path("/home/umut/tost-flip-(copy)/assets/modes")

OUT_SKILLED.mkdir(parents=True, exist_ok=True)
OUT_MODES.mkdir(parents=True, exist_ok=True)

im1 = Image.open(SRC1).convert("RGBA")
im2 = Image.open(SRC2).convert("RGBA")

# 1. Altın Madalya / Para İkonu (SRC1 sağ üst: 865, 18, 915, 60)
coin = im1.crop((866, 18, 914, 58))
coin.save(OUT_SKILLED / "coin.png", optimize=True)
print("Saved coin.png", coin.size)

# 2. Dükkan İkonları (SRC1 sağdaki kartlardan)
# Tereyağı kapasitesi / tereyağı ikonu: (668, 200, 725, 256)
butter_up = im1.crop((668, 200, 725, 256))
butter_up.save(OUT_SKILLED / "butter_upgrade.png", optimize=True)

# Hava hakkı / kanat ikonu: (670, 272, 724, 326)
wing_up = im1.crop((670, 272, 724, 326))
wing_up.save(OUT_SKILLED / "air_boost_upgrade.png", optimize=True)

# Denge / Ekmek ikonu için:
# SRC1 sol alttaki ekmek ikonu çok net: (58, 455, 126, 517)
bread_up = im1.crop((58, 455, 126, 517))
bread_up.save(OUT_SKILLED / "bread_upgrade.png", optimize=True)

# Dükkan Başlık Tenteli Amblem: (785, 80, 840, 130) veya tente başlığı
shop_badge = im1.crop((785, 78, 843, 132))
shop_badge.save(OUT_SKILLED / "chef_hat_badge.png", optimize=True)

# Dükkan Açma Butonu için mini dükkan ikonu (tente + şef şapkası):
shop_roof = im1.crop((650, 60, 970, 140))
shop_roof.save(OUT_SKILLED / "shop_roof.png", optimize=True)

print("Saved upgrade icons")

# 3. Mod Seçim Kartları (SRC2)
# Kart boyutları: ~170 x 275
cards = [
    ("card_classic.png", (76, 155, 245, 430)),
    ("card_chef.png", (255, 155, 424, 430)),
    ("card_sandwich.png", (432, 155, 600, 430)),
    ("card_chaos.png", (606, 155, 775, 430)),
    ("card_space.png", (781, 155, 950, 430)),
]

for name, box in cards:
    card = im2.crop(box)
    card.save(OUT_MODES / name, optimize=True)
    print("Saved", name, card.size)

# Mod Menü Başlık Logosu: (300, 15, 700, 135)
title_board = im2.crop((300, 15, 700, 135))
title_board.save(OUT_MODES / "mode_title_board.png", optimize=True)
print("All assets extracted successfully.")
