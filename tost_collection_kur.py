#!/usr/bin/env python3
"""Tost Flip koleksiyon ekranini Godot .tscn uzerinden guvenle kurar.

Kullanim: python3 tost_collection_kur.py
Betiği ~/Tost-Flip/ klasorune koyup calistirin.
Yalnizca node_2d.tscn dosyasinin CollectionMenu bolumunu duzenler
ve assets/collection_lock.svg olusturur. GDScript / oynanis degismez.
"""
from __future__ import annotations

from datetime import datetime
from pathlib import Path
import os
import shutil
import sys

ROOT = Path(sys.argv[1]).expanduser().resolve() if len(sys.argv) > 1 else Path(__file__).resolve().parent
SCENE = ROOT / "node_2d.tscn"
LOCK = ROOT / "assets" / "collection_lock.svg"

NODE_START = '[node name="CollectionMenu" type="Control"'
CONNECTION_START = '[connection signal="pressed" from="CanvasLayer/MainMenu/MenuButtons/PlayButton"'

LOCK_SVG = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 80 80" width="80" height="80">
  <path d="M25 34 V26 C25 5 55 5 55 26 V34" fill="none" stroke="#5a3219" stroke-width="9" stroke-linecap="round"/>
  <path d="M25 34 V26 C25 5 55 5 55 26 V34" fill="none" stroke="#fff2cf" stroke-width="5" stroke-linecap="round"/>
  <rect x="13" y="33" width="54" height="39" rx="9" fill="#5a3219"/>
  <rect x="17" y="36" width="46" height="32" rx="7" fill="#ffe0a0" stroke="#fff4de" stroke-width="2"/>
  <circle cx="40" cy="48" r="5" fill="#6b3d20"/>
  <path d="M40 50 L36.5 61 H43.5 Z" fill="#6b3d20"/>
</svg>
'''

EXTRA_EXT = '''[ext_resource type="Texture2D" path="res://assets/collection_lock.svg" id="10_collection_lock"]

'''

EXTRA_SUB = '''[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_collection_board"]
bg_color = Color(0.40, 0.25, 0.15, 0.94)
border_width_left = 5
border_width_top = 5
border_width_right = 5
border_width_bottom = 5
border_color = Color(0.24, 0.13, 0.07, 1)
corner_radius_top_left = 20
corner_radius_top_right = 20
corner_radius_bottom_right = 20
corner_radius_bottom_left = 20
shadow_color = Color(0.13, 0.07, 0.02, 0.4)
shadow_size = 8

[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_collection_photo"]
content_margin_left = 6.0
content_margin_top = 6.0
content_margin_right = 6.0
content_margin_bottom = 6.0
bg_color = Color(1, 0.985, 0.945, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.83, 0.71, 0.53, 1)
corner_radius_top_left = 6
corner_radius_top_right = 6
corner_radius_bottom_right = 6
corner_radius_bottom_left = 6

'''

CARD_PATH = 'CanvasLayer/CollectionMenu/CardsContainer'

def n(name: str, kind: str, parent: str, props: str, unique_id: int | None = None) -> str:
    uid = f' unique_id={unique_id}' if unique_id is not None else ''
    return f'[node name="{name}" type="{kind}" parent="{parent}"{uid}]\n{props.strip()}\n\n'


def label(name: str, parent: str, caption: str, font_size: int, color: str, height: int = 30) -> str:
    # Text is encoded for Godot's string literal syntax.
    escaped = caption.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    return n(name, 'Label', parent, f'''
custom_minimum_size = Vector2(0, {height})
layout_mode = 2
theme_override_colors/font_color = {color}
theme_override_font_sizes/font_size = {font_size}
text = "{escaped}"
horizontal_alignment = 1
vertical_alignment = 1
autowrap_mode = 3
''')


def card(name: str, title: str, unlocked: bool, goal: int = 0, behavior: str = '') -> str:
    p = CARD_PATH + '/' + name
    content = p + '/CardContent'
    photo = content + '/PhotoFrame'
    card_props = '''
custom_minimum_size = Vector2(220, 315)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_7lwn1")
'''
    result = n(name, 'PanelContainer', CARD_PATH, card_props, 685187074 if name == 'ButterCard' else None)
    result += n('CardContent', 'VBoxContainer', p, '''
layout_mode = 2
theme_override_constants/separation = 6
''', 587299702 if name == 'ButterCard' else None)
    result += n('PhotoFrame', 'PanelContainer', content, '''
custom_minimum_size = Vector2(0, 177)
layout_mode = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_collection_photo")
''')
    art_props = '''
custom_minimum_size = Vector2(180, 163)
layout_mode = 2
texture = ExtResource("4_q6r6c")
expand_mode = 1
stretch_mode = 5
'''
    if not unlocked:
        art_props += 'self_modulate = Color(0.17, 0.12, 0.09, 1)\n'
    result += n('ToastImage', 'TextureRect', photo, art_props, 611387413 if name == 'ButterCard' else None)
    if not unlocked:
        result += n('LockIcon', 'TextureRect', photo + '/ToastImage', '''
layout_mode = 1
anchor_left = 0.5
anchor_top = 0.5
anchor_right = 0.5
anchor_bottom = 0.5
offset_left = -38.0
offset_top = -38.0
offset_right = 38.0
offset_bottom = 38.0
mouse_filter = 2
texture = ExtResource("10_collection_lock")
expand_mode = 1
stretch_mode = 5
''')
    result += label('CardName', content, title, 18, 'Color(0.29, 0.15, 0.08, 1)', 26)
    if unlocked:
        result += label('CardInfo', content, 'Dengeli • Orta dönüş', 14, 'Color(0.39, 0.24, 0.14, 1)', 27)
        result += label('CardDescription', content, 'Klasik başlangıç.\nHer zaman güvenilir!', 12, 'Color(0.43, 0.27, 0.15, 1)', 45)
    else:
        result += label('UnlockGoal', content, f'{goal} puana ulaşarak\nkilidini aç!', 13, 'Color(0.43, 0.25, 0.15, 1)', 45)
        result += label('Behavior', content, behavior, 14, 'Color(0.57, 0.29, 0.14, 1)', 27)
    return result


def collection_nodes() -> str:
    out = ''
    out += n('CollectionMenu', 'Control', 'CanvasLayer', '''
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
''', 1912580706)
    out += n('BackdropShade', 'ColorRect', 'CanvasLayer/CollectionMenu', '''
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
mouse_filter = 2
color = Color(0.16, 0.08, 0.03, 0.26)
''')
    out += n('CollectionBoard', 'Panel', 'CanvasLayer/CollectionMenu', '''
layout_mode = 0
offset_left = 67.0
offset_top = 198.0
offset_right = 1085.0
offset_bottom = 563.0
mouse_filter = 2
theme_override_styles/panel = SubResource("StyleBoxFlat_collection_board")
''')
    out += n('CollectionLogo', 'TextureRect', 'CanvasLayer/CollectionMenu', '''
layout_mode = 0
offset_left = 376.0
offset_top = 6.0
offset_right = 776.0
offset_bottom = 132.0
mouse_filter = 2
texture = ExtResource("9_4d7sh")
expand_mode = 1
stretch_mode = 5
''')
    out += n('CollectionTitle', 'Label', 'CanvasLayer/CollectionMenu', '''
layout_mode = 0
offset_left = 276.0
offset_top = 137.0
offset_right = 876.0
offset_bottom = 198.0
mouse_filter = 2
theme_override_colors/font_color = Color(1, 0.88, 0.54, 1)
theme_override_colors/font_outline_color = Color(0.29, 0.145, 0.06, 1)
theme_override_constants/outline_size = 10
theme_override_font_sizes/font_size = 40
text = "KOLEKSİYON"
horizontal_alignment = 1
vertical_alignment = 1
''')
    out += n('CardsContainer', 'HBoxContainer', 'CanvasLayer/CollectionMenu', '''
layout_mode = 0
offset_left = 109.0
offset_top = 219.0
offset_right = 1043.0
offset_bottom = 545.0
theme_override_constants/separation = 18
''', 2042572506)
    out += card('ButterCard', 'Tereyağlı Tost', True)
    out += card('JamCard', 'Reçelli Tost', False, 5, 'Daha hızlı!')
    out += card('SausageCard', 'Sucuklu Tost', False, 10, 'Daha yavaş!')
    out += card('BombCard', 'Bomba Tost', False, 15, 'Hızı sürpriz!')
    out += n('BackButton', 'Button', 'CanvasLayer/CollectionMenu', '''
layout_mode = 0
offset_left = 456.0
offset_top = 567.0
offset_right = 696.0
offset_bottom = 638.0
theme_override_colors/font_color = Color(1, 0.88, 0.54, 1)
theme_override_colors/font_outline_color = Color(0.29, 0.145, 0.06, 1)
theme_override_constants/outline_size = 7
theme_override_font_sizes/font_size = 27
theme_override_styles/normal = SubResource("StyleBoxTexture_rj586")
theme_override_styles/hover = SubResource("StyleBoxTexture_rj586")
theme_override_styles/pressed = SubResource("StyleBoxTexture_kdubu")
theme_override_styles/hover_pressed = SubResource("StyleBoxTexture_d21ai")
text = "GERİ"
''', 400923317)
    return out


def main() -> None:
    if not SCENE.is_file():
        sys.exit(f'HATA: {SCENE} bulunamadi. Betigi Tost-Flip proje klasorune koy.')
    for rel in ['assets/toast_butter.png', 'assets/wood_button.png', 'assets/Toasty_Tost_Flip_Logo-removebg-preview.png']:
        if not (ROOT / rel).is_file():
            sys.exit(f'HATA: {rel} bulunamadi; hicbir sey degistirilmedi.')
    original = SCENE.read_text(encoding='utf-8')
    if 'StyleBoxFlat_collection_board' in original:
        sys.exit('Koleksiyon sahnesi zaten kurulmus. Ikinci kez degisiklik yapilmadi.')
    required = [NODE_START, CONNECTION_START,
                '[node name="ButterCard" type="PanelContainer"',
                '[node name="CardContent" type="VBoxContainer"',
                '[node name="ToastImage" type="TextureRect"',
                '[sub_resource type="StyleBoxFlat" id="StyleBoxFlat_7lwn1"]',
                '[node name="Node2D" type="Node2D"',
                '[sub_resource type="RectangleShape2D"']
    missing = [x for x in required if x not in original]
    if missing:
        sys.exit(f'HATA: Sahne bekledigimiz yapida degil ({missing[0]}). Degisiklik yapilmadi.')
    begin = original.index(NODE_START)
    end = original.index(CONNECTION_START)
    if end <= begin:
        sys.exit('HATA: CollectionMenu sinirlari beklenmiyor. Degisiklik yapilmadi.')

    updated = original[:begin] + collection_nodes() + original[end:]
    updated = updated.replace('[sub_resource type="RectangleShape2D"', EXTRA_EXT + '[sub_resource type="RectangleShape2D"', 1)
    updated = updated.replace('[node name="Node2D" type="Node2D"', EXTRA_SUB + '[node name="Node2D" type="Node2D"', 1)
    # Dosya icindeki node adlari bagli kalacak; mevcut menu ve oyun kodu degismiyor.
    for connection in ['_on_play_button_pressed', '_on_collection_button_pressed', '_on_exit_button_pressed', '_on_back_button_pressed']:
        if connection not in updated:
            sys.exit(f'HATA: {connection} baglantisi kayboluyor. Degisiklik yapilmadi.')

    stamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    backup = ROOT / f'node_2d.autobackup_{stamp}.tscn.bak'
    if backup.exists():
        sys.exit(f'HATA: {backup} zaten mevcut. Degisiklik yapilmadi.')
    shutil.copy2(SCENE, backup)
    if not LOCK.exists():
        LOCK.write_text(LOCK_SVG, encoding='utf-8')
    temp = SCENE.with_suffix('.tscn.new')
    try:
        temp.write_text(updated, encoding='utf-8')
        os.replace(temp, SCENE)
    finally:
        if temp.exists():
            temp.unlink()
    print('BASARILI: Koleksiyon arayuzu node_2d.tscn icinde kuruldu.')
    print('Dort kart: Tereyagli / Recelli / Sucuklu / Bomba.')
    print('Ana menu, node_2d.gd, tost fizigi ve sinyal baglantilari korunuyor.')
    print(f'Yedek: {backup.name}')
    print('Godot acikken dosya degisikligi uyarisi cikarsa Reload from Disk sec.')
    print('NOT: Kilit acma ve farkli tost fizikleri henuz uygulanmadi; kartlar gorsel taslaktir.')


if __name__ == '__main__':
    main()
