#!/usr/bin/env python3
"""TOST FLIP - collection visual v2 installer.

Run inside the project: python3 koleksiyon_gorsel_kur.py
Only rebuilds CanvasLayer/CollectionMenu nodes in node_2d.tscn.
Existing signal connections, other scene nodes, .gd files and physics are untouched.
Backs up scene before writing. Safe to rerun.
"""
from __future__ import annotations

from datetime import datetime
from pathlib import Path
import os
import re
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parent
SCENE = ROOT / 'node_2d.tscn'
ARTDIR = ROOT / 'assets' / 'collection_ui'

# Accept either the suggested filenames or original filenames from image generation.
ART = {
    'board': ['collection_board.png', 'cozy_kawaii_recipe_board.png'],
    'title': ['collection_title.png', 'koleksiyon_ahşap_oyun_bannerı.png', 'koleksiyon_ahsap_oyun_banneri.png'],
    'card': ['collection_card.png', 'cozy_bakery_recipe_card_frame.png'],
    'lock': ['locked_toast.png', 'locked_toast_emblem.png'],
    'back': ['back_button_collection.png', 'cartoon_wooden_back_button_geri.png'],
}
IDS = {k: 'tf_collection_v2_' + k for k in ART}
PREFIX = 'CanvasLayer/CollectionMenu'
NODE_RE = re.compile(r'^\[node name="([^"]+)"(?:[^\n]*?)parent="([^"]+)"[^\n]*\]$', re.M)


def load_art() -> dict[str, Path]:
    result: dict[str, Path] = {}
    missing = []
    for key, names in ART.items():
        found = next((ARTDIR / name for name in names if (ARTDIR / name).is_file()), None)
        if found is None:
            missing.append(f'  - {key}: ' + ' veya '.join(names))
        else:
            result[key] = found
    if missing:
        sys.exit('HATA: assets/collection_ui klasorunde su dosyalar bulunamadi:\n' +
                 '\n'.join(missing) + '\nSahne degistirilmedi.')
    return result


def node(name: str, type_: str, parent: str, properties: str, uid: int | None = None) -> str:
    suffix = f' unique_id={uid}' if uid else ''
    return f'[node name="{name}" type="{type_}" parent="{parent}"{suffix}]\n{properties.strip()}\n\n'


def rect(left: int, top: int, right: int, bottom: int) -> str:
    return (f'layout_mode = 0\noffset_left = {float(left)}\noffset_top = {float(top)}\n'
            f'offset_right = {float(right)}\noffset_bottom = {float(bottom)}\n')


def color_variant(hex_color: str) -> str:
    h = hex_color.lstrip("#")
    r, g, b = (int(h[i:i+2], 16) / 255.0 for i in (0, 2, 4))
    return f"Color({r:.8f}, {g:.8f}, {b:.8f}, 1)"


def label(name: str, parent: str, txt: str, pos: tuple[int,int,int,int],
          font_size: int, color: str, outline: int = 0, italic: bool = False) -> str:
    del italic
    escaped = txt.replace('\\', '\\\\').replace('"', '\\"').replace('\n', '\\n')
    args = (rect(*pos) + 'mouse_filter = 2\n'
            f'theme_override_colors/font_color = {color_variant(color)}\n'
            f'theme_override_colors/font_outline_color = {color_variant("#fff0cf")}\n'
            f'theme_override_constants/outline_size = {outline}\n'
            f'theme_override_font_sizes/font_size = {font_size}\n'
            f'text = "{escaped}"\n'
            'horizontal_alignment = 1\nvertical_alignment = 1\nautowrap_mode = 3')
    return node(name, 'Label', parent, args)


def make_card(name: str, title: str, goal: int, behavior: str,
              unlocked: bool) -> str:
    card = PREFIX + '/CardsContainer/' + name
    # Custom min X/Y is respected by parent HBoxContainer; children are placed within each card.
    out = node(name, 'Control', PREFIX + '/CardsContainer', '''
custom_minimum_size = Vector2(208, 292)
layout_mode = 2
mouse_filter = 2
''')
    out += node('PaperFrame', 'TextureRect', card, rect(0, 0, 208, 292) + '''
mouse_filter = 2
texture = ExtResource("tf_collection_v2_card")
expand_mode = 1
stretch_mode = 0
''')
    # The parchment frame is the bottom layer; art and labels are independent overlays.
    pic = 'ExtResource("4_q6r6c")' if unlocked else 'ExtResource("tf_collection_v2_lock")'
    out += node('ToastArt', 'TextureRect', card, rect(25, 40, 183, 189) + f'''
mouse_filter = 2
texture = {pic}
expand_mode = 1
stretch_mode = 5
''')
    out += label('CardName', card, title, (6, 211, 202, 238), 18, '#58311e', 0)
    if unlocked:
        out += label('CardInfo', card, 'Dengeli  •  Orta dönüş', (5, 238, 203, 258), 12, '#774322')
        out += label('CardDetail', card, 'Klasik başlangıç!\nDengeli ve güvenilir.', (7, 257, 201, 289), 11, '#774322')
    else:
        out += label('UnlockGoal', card, f'{goal} puana ulaşarak\nkilidini aç!', (8, 238, 200, 268), 12, '#774322')
        out += label('CardDetail', card, behavior, (8, 268, 200, 290), 11, '#a34a26')
    return out


def make_collection() -> str:
    out = node('CollectionMenu', 'Control', 'CanvasLayer', '''
visible = false
layout_mode = 3
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
''', 1912580706)
    out += node('BackdropShade', 'ColorRect', PREFIX, '''
layout_mode = 1
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
mouse_filter = 2
color = Color(0.20, 0.10, 0.05, 0.17)
''')
    out += node('CollectionBoard', 'TextureRect', PREFIX, rect(20, 104, 1132, 604) + '''
mouse_filter = 2
texture = ExtResource("tf_collection_v2_board")
expand_mode = 1
stretch_mode = 0
''')
    # Keep the existing game logo that players already recognize.
    out += node('CollectionLogo', 'TextureRect', PREFIX, rect(382, 0, 770, 120) + '''
mouse_filter = 2
texture = ExtResource("9_4d7sh")
expand_mode = 1
stretch_mode = 5
''')
    out += node('CollectionTitle', 'TextureRect', PREFIX, rect(360, 129, 792, 218) + '''
mouse_filter = 2
texture = ExtResource("tf_collection_v2_title")
expand_mode = 1
stretch_mode = 0
''')
    out += node('CardsContainer', 'HBoxContainer', PREFIX, rect(140, 242, 1012, 534) + '''
mouse_filter = 2
theme_override_constants/separation = 13
''', 2042572506)
    out += make_card('ButterCard', 'Tereyağlı Tost', 0, 'Dengeli', True)
    out += make_card('JamCard', 'Reçelli Tost', 5, 'Daha hızlı!', False)
    out += make_card('SausageCard', 'Sucuklu Tost', 10, 'Daha yavaş!', False)
    out += make_card('BombCard', 'Bomba Tost', 15, 'Bazen hızlı, bazen yavaş!', False)
    # Keep exact BackButton node path for original signal and script.
    out += node('BackButton', 'TextureButton', PREFIX, rect(444, 548, 708, 632) + '''
mouse_filter = 0
ignore_texture_size = true
stretch_mode = 0
texture_normal = ExtResource("tf_collection_v2_back")
texture_hover = ExtResource("tf_collection_v2_back")
texture_pressed = ExtResource("tf_collection_v2_back")
''', 400923317)
    return out


def main() -> None:
    if not SCENE.is_file():
        sys.exit('HATA: node_2d.tscn bulunamadi. Dosyayi ~/Tost-Flip klasorunde calistir.')
    if not (ROOT / 'project.godot').is_file():
        sys.exit('HATA: project.godot yok. Bu klasor Godot proje koku degil.')
    try:
        branch = subprocess.run(['git','branch','--show-current'],cwd=ROOT,
                                capture_output=True,text=True,check=False).stdout.strip()
    except FileNotFoundError:
        branch = ''
    if branch in ('main', 'master'):
        sys.exit('HATA: main uzerindesin. Once git switch feature/collection yap.')
    art = load_art()
    original = SCENE.read_text(encoding='utf-8')
    required = ('[node name="CollectionMenu" type="Control"',
                '[node name="MainMenu" type="Control"',
                '[node name="Node2D" type="Node2D"',
                'method="_on_back_button_pressed"',
                'from="CanvasLayer/CollectionMenu/BackButton"',
                'id="4_q6r6c"', 'id="9_4d7sh"')
    for needle in required:
        if needle not in original:
            sys.exit(f'HATA: Beklenen sahne ogesi bulunamadi: {needle}. Hicbir sey degistirilmedi.')

    start = original.index('[node name="CollectionMenu" type="Control"')
    end_match = re.search(r'^\[connection ', original[start:], flags=re.M)
    if not end_match:
        sys.exit('HATA: CollectionMenu sonrasi signal baglantilari yok. Degisiklik yapilmadi.')
    end = start + end_match.start()
    old_slice = original[start:end]
    # Do not destroy any node unrelated to CollectionMenu even if the user added new ones.
    headers = re.findall(r'^\[node [^\n]+$', old_slice, flags=re.M)
    for h in headers[1:]:
        parent = re.search(r'parent="([^"]+)"', h)
        if not parent or not parent.group(1).startswith(PREFIX):
            sys.exit('HATA: Koleksiyon disinda bir node var, guvenlik icin islem iptal: ' + h)

    updated = original[:start] + make_collection() + original[end:]
    existing_ids = set(re.findall(r'^\[ext_resource [^\n]*?id="([^"]+)"', original, flags=re.M))
    ext_lines = []
    for key, path in art.items():
        rid = IDS[key]
        rel = path.relative_to(ROOT).as_posix()
        declaration = f'[ext_resource type="Texture2D" path="res://{rel}" id="{rid}"]'
        if rid in existing_ids:
            # Verify an existing id isn't mapped to another path.
            item = re.search(r'^\[ext_resource [^\n]*?id="' + re.escape(rid) + r'"\]$', original, re.M)
            if not item or f'path="res://{rel}"' not in item.group(0):
                sys.exit(f'HATA: Kaynak ID catismasi: {rid}. Degisiklik yapilmadi.')
        else:
            ext_lines.append(declaration)
    if ext_lines:
        first_sub = re.search(r'^\[sub_resource ', updated, flags=re.M)
        if not first_sub:
            sys.exit('HATA: Subresource siniri bulunamadi. Degisiklik yapilmadi.')
        idx = first_sub.start()
        updated = updated[:idx] + '\n'.join(ext_lines) + '\n\n' + updated[idx:]
    if updated == original:
        print('Zaten guncel, degisiklik yapilmadi.')
        return
    for method in ['_on_play_button_pressed','_on_collection_button_pressed',
                   '_on_exit_button_pressed','_on_back_button_pressed']:
        if original.count('method="' + method + '"') != updated.count('method="' + method + '"'):
            sys.exit('HATA: Sinyal koruma denetimi basarisiz: ' + method)

    stamp = datetime.now().strftime('%Y%m%d_%H%M%S_%f')
    backup = ROOT / f'node_2d.collection_v2_backup_{stamp}.tscn.bak'
    shutil.copy2(SCENE, backup)
    temp = SCENE.with_name('.node_2d.tscn.tmp')
    try:
        temp.write_text(updated, encoding='utf-8')
        os.replace(temp, SCENE)
    finally:
        if temp.exists(): temp.unlink()
    print('BASARILI: Dört polaroid kart, pano, tabela ve GERİ butonu yerlestirildi.')
    print('Yedek:', backup.name)
    print('Korunanlar: MainMenu, tost.gd, node_2d.gd, skor/rekor sistemi, signal baglantilari.')
    print('Not: Kartlar simdilik görsel. Kalici kilit ve farkli fizik daha sonra eklenecek.')
    print('Godot icinde Reload from Disk, ardindan F6/F5 ile KOLEKSIYON ekranini test et.')


if __name__ == '__main__':
    main()
