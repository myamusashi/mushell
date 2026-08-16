#!/usr/bin/env python3

# Copyright (C) 2026 end-4
#
#     This program is free software: you can redistribute it and/or modify
#     it under the terms of the GNU General Public License as published by
#     the Free Software Foundation, either version 3 of the License, or
#     (at your option) any later version.
#
#     This program is distributed in the hope that it will be useful,
#     but WITHOUT ANY WARRANTY; without even the implied warranty of
#     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#     GNU General Public License for more details.
#
#     You should have received a copy of the GNU General Public License
#     along with this program.  If not, see <https://www.gnu.org/licenses/>.

import argparse
import math
import os
import json
from PIL import Image
from materialyoucolor.quantize import QuantizeCelebi
from materialyoucolor.score.score import Score
from materialyoucolor.hct import Hct
from materialyoucolor.dynamiccolor.material_dynamic_colors import MaterialDynamicColors
from materialyoucolor.utils.color_utils import (rgba_from_argb, argb_from_rgb, argb_from_rgba)
from materialyoucolor.utils.math_utils import (sanitize_degrees_double, difference_degrees, rotation_direction)

parser = argparse.ArgumentParser(description='Color generation script')
parser.add_argument('--path', type=str, default=None, help='generate colorscheme from image')
parser.add_argument('--size', type=int , default=128 , help='bitmap image size')
parser.add_argument('--color', type=str, default=None, help='generate colorscheme from color')
parser.add_argument('--mode', type=str, choices=['dark', 'light'], default='dark', help='dark or light mode')
parser.add_argument('--scheme', type=str, default='tonal-spot', help='material scheme to use')
parser.add_argument('--smart', action='store_true', default=False, help='decide scheme type based on image color')
parser.add_argument('--transparency', type=str, choices=['opaque', 'transparent'], default='opaque', help='enable transparency')
parser.add_argument('--termscheme', type=str, default=None, help='JSON file containg the terminal scheme for generating term colors')
parser.add_argument('--harmony', type=float , default=0.8, help='(0-1) Color hue shift towards accent')
parser.add_argument('--harmonize_threshold', type=float , default=100, help='(0-180) Max threshold angle to limit color hue shift')
parser.add_argument('--term_fg_boost', type=float , default=0.35, help='Make terminal foreground more different from the background')
parser.add_argument('--blend_bg_fg', action='store_true', default=False, help='Shift terminal background or foreground towards accent')
parser.add_argument('--cache', type=str, default=None, help='file path to store the generated color')
parser.add_argument('--json-out', type=str, default=None, help='write the generated material colors as JSON to this path')
parser.add_argument('--debug', action='store_true', default=False, help='debug mode')
args = parser.parse_args()

rgba_to_hex = lambda rgba: "#{:02X}{:02X}{:02X}".format(rgba[0], rgba[1], rgba[2])
argb_to_hex = lambda argb: "#{:02X}{:02X}{:02X}".format(*map(round, rgba_from_argb(argb)))
hex_to_argb = lambda hex_code: argb_from_rgb(int(hex_code[1:3], 16), int(hex_code[3:5], 16), int(hex_code[5:], 16))
display_color = lambda rgba : "\x1B[38;2;{};{};{}m{}\x1B[0m".format(rgba[0], rgba[1], rgba[2], "\x1b[7m   \x1b[7m")

def calculate_optimal_size (width: int, height: int, bitmap_size: int) -> (int, int):
    image_area = width * height;
    bitmap_area = bitmap_size ** 2
    scale = math.sqrt(bitmap_area/image_area) if image_area > bitmap_area else 1
    new_width = round(width * scale)
    new_height = round(height * scale)
    if new_width == 0:
        new_width = 1
    if new_height == 0:
        new_height = 1
    return new_width, new_height

def harmonize (design_color: int, source_color: int, threshold: float = 35, harmony: float = 0.5) -> int:
    from_hct = Hct.from_int(design_color)
    to_hct = Hct.from_int(source_color)
    difference_degrees_ = difference_degrees(from_hct.hue, to_hct.hue)
    rotation_degrees = min(difference_degrees_ * harmony, threshold)
    output_hue = sanitize_degrees_double(
        from_hct.hue + rotation_degrees * rotation_direction(from_hct.hue, to_hct.hue)
    )
    return Hct.from_hct(output_hue, from_hct.chroma, from_hct.tone).to_int()

def boost_chroma_tone (argb: int, chroma: float = 1, tone: float = 1) -> int:
    hct = Hct.from_int(argb)
    return Hct.from_hct(hct.hue, hct.chroma * chroma, hct.tone * tone).to_int()

darkmode = (args.mode == 'dark')
transparent = (args.transparency == 'transparent')

if args.path is not None:
    image = Image.open(args.path)

    if image.format == "GIF":
        image.seek(1)

    if image.mode in ["L", "P"]:
        image = image.convert('RGB')
    wsize, hsize = image.size
    wsize_new, hsize_new = calculate_optimal_size(wsize, hsize, args.size)
    if wsize_new < wsize or hsize_new < hsize:
        image = image.resize((wsize_new, hsize_new), Image.Resampling.BICUBIC)
    colors = QuantizeCelebi(list(image.get_flattened_data()), 128)
    argb = Score.score(colors)[0]

    if args.cache is not None:
        with open(args.cache, 'w') as file:
            file.write(argb_to_hex(argb))
    hct = Hct.from_int(argb)
    if(args.smart):
        if(hct.chroma < 20):
            args.scheme = 'neutral'
elif args.color is not None:
    argb = hex_to_argb(args.color)
    hct = Hct.from_int(argb)

scheme = args.scheme if args.scheme.startswith('scheme-') else 'scheme-' + args.scheme

if scheme == 'scheme-fruit-salad':
    from materialyoucolor.scheme.scheme_fruit_salad import SchemeFruitSalad as Scheme
elif scheme == 'scheme-expressive':
    from materialyoucolor.scheme.scheme_expressive import SchemeExpressive as Scheme
elif scheme == 'scheme-monochrome':
    from materialyoucolor.scheme.scheme_monochrome import SchemeMonochrome as Scheme
elif scheme == 'scheme-rainbow':
    from materialyoucolor.scheme.scheme_rainbow import SchemeRainbow as Scheme
elif scheme == 'scheme-tonal-spot':
    from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme
elif scheme == 'scheme-neutral':
    from materialyoucolor.scheme.scheme_neutral import SchemeNeutral as Scheme
elif scheme == 'scheme-fidelity':
    from materialyoucolor.scheme.scheme_fidelity import SchemeFidelity as Scheme
elif scheme == 'scheme-content':
    from materialyoucolor.scheme.scheme_content import SchemeContent as Scheme
elif scheme == 'scheme-vibrant':
    from materialyoucolor.scheme.scheme_vibrant import SchemeVibrant as Scheme
else:
    from materialyoucolor.scheme.scheme_tonal_spot import SchemeTonalSpot as Scheme
# Generate
scheme = Scheme(hct, darkmode, 0.0)

def material_colors_for(scheme, dark: bool) -> dict:
    colors = {}
    for color in vars(MaterialDynamicColors).keys():
        color_name = getattr(MaterialDynamicColors, color)
        if hasattr(color_name, "get_hct"):
            rgba = color_name.get_hct(scheme).to_rgba()
            colors[color] = rgba_to_hex(rgba)

    if dark:
        colors['success'] = '#B5CCBA'
        colors['onSuccess'] = '#213528'
        colors['successContainer'] = '#374B3E'
        colors['onSuccessContainer'] = '#D1E9D6'
    else:
        colors['success'] = '#4F6354'
        colors['onSuccess'] = '#FFFFFF'
        colors['successContainer'] = '#D1E8D5'
        colors['onSuccessContainer'] = '#0C1F13'
    return colors

# Roles consumers resolve through Colours.qml — both modes must always contain these.
REQUIRED_ROLES = [
    'background', 'onBackground', 'surface', 'surfaceDim', 'surfaceBright',
    'surfaceContainerLowest', 'surfaceContainerLow', 'surfaceContainer',
    'surfaceContainerHigh', 'surfaceContainerHighest',
    'onSurface', 'surfaceVariant', 'onSurfaceVariant',
    'outline', 'outlineVariant', 'shadow', 'scrim', 'surfaceTint',
    'primary', 'onPrimary', 'primaryContainer', 'onPrimaryContainer',
    'error', 'onError', 'errorContainer', 'onErrorContainer',
]
SURFACE_ROLES = [r for r in REQUIRED_ROLES if 'surface' in r]

def fix_surface_extremes(colors: dict) -> None:
    # M3 emits pure #000000 / #FFFFFF for surfaceContainerLowest at its default
    # tones 4/100. Clamp those to near-black tone 5 / near-white tone 99 so
    # surfaces never hit pure black or white (they clip badly with the shell's
    # blur/vibrancy), while keeping the container tone ordering intact.
    key = colors.get('neutralPaletteKeyColor')
    neutral = Hct.from_int(hex_to_argb(key)) if key else Hct.from_hct(50, 8, 50)
    for role in SURFACE_ROLES:
        if colors[role].upper() == '#000000':
            colors[role] = argb_to_hex(Hct.from_hct(neutral.hue, neutral.chroma * 0.25, 5.0).to_int())
        elif colors[role].upper() == '#FFFFFF':
            colors[role] = argb_to_hex(Hct.from_hct(neutral.hue, neutral.chroma * 0.25, 99.0).to_int())

def validate_palette(colors: dict) -> None:
    missing = [r for r in REQUIRED_ROLES if r not in colors]
    if missing:
        raise ValueError('missing roles: ' + ', '.join(missing))
    for role in REQUIRED_ROLES:
        value = str(colors[role]).upper()
        if not (len(value) == 7 and value.startswith('#')):
            raise ValueError('role {} is not a hex color: {}'.format(role, colors[role]))
    for role in SURFACE_ROLES:
        if colors[role].upper() in ('#000000', '#FFFFFF'):
            raise ValueError('surface role {} is pure {}'.format(role, colors[role]))
    for fg, bg in [('onSurface', 'surface'), ('onPrimary', 'primary'), ('onError', 'error'),
                   ('onSurfaceVariant', 'surfaceVariant'), ('onPrimaryContainer', 'primaryContainer')]:
        fg_tone = Hct.from_int(hex_to_argb(colors[fg])).tone
        bg_tone = Hct.from_int(hex_to_argb(colors[bg])).tone
        if abs(fg_tone - bg_tone) < 40:
            raise ValueError('low contrast: {} vs {} tone gap {}'.format(fg, bg, abs(fg_tone - bg_tone)))

material_colors = material_colors_for(scheme, darkmode)
term_colors = {}

# JSON output: write current mode's scheme in the format vast-shell reads
if args.json_out is not None:
    out = dict(material_colors)
    if args.path is not None or args.color is not None:
        out['sourceColor'] = argb_to_hex(argb)
    fix_surface_extremes(out)
    validate_palette(out)
    tmp_path = args.json_out + '.tmp'
    try:
        with open(tmp_path, 'w') as f:
            json.dump({'colors': out}, f, indent=4)
        os.replace(tmp_path, args.json_out)
    except BaseException:
        if os.path.exists(tmp_path):
            os.remove(tmp_path)
        raise
    raise SystemExit(0)

# Terminal Colors
if args.termscheme is not None:
    with open(args.termscheme, 'r') as f:
        json_termscheme = f.read()
    term_source_colors = json.loads(json_termscheme)['dark' if darkmode else 'light']

    primary_color_argb = hex_to_argb(material_colors['primary_paletteKeyColor'])
    for color, val in term_source_colors.items():
        if(args.scheme == 'monochrome') :
            term_colors[color] = val
            continue
        if args.blend_bg_fg and color == "term0":
            harmonized = boost_chroma_tone(hex_to_argb(material_colors['surfaceContainerLow']), 1.2, 0.95)
        elif args.blend_bg_fg and color == "term15":
            harmonized = boost_chroma_tone(hex_to_argb(material_colors['onSurface']), 3, 1)
        else:
            harmonized = harmonize(hex_to_argb(val), primary_color_argb, args.harmonize_threshold, args.harmony)
            harmonized = boost_chroma_tone(harmonized, 1, 1 + (args.term_fg_boost * (1 if darkmode else -1)))
        term_colors[color] = argb_to_hex(harmonized)

if args.debug == False:
    print(f"$darkmode: {darkmode};")
    print(f"$transparent: {transparent};")
    for color, code in material_colors.items():
        print(f"${color}: {code};")
    for color, code in term_colors.items():
        print(f"${color}: {code};")
else:
    if args.path is not None:
        print('\n--------------Image properties-----------------')
        print(f"Image size: {wsize} x {hsize}")
        print(f"Resized image: {wsize_new} x {hsize_new}")
    print('\n---------------Selected color------------------')
    print(f"Dark mode: {darkmode}")
    print(f"Scheme: {args.scheme}")
    print(f"Accent color: {display_color(rgba_from_argb(argb))} {argb_to_hex(argb)}")
    print(f"HCT: {hct.hue:.2f}  {hct.chroma:.2f}  {hct.tone:.2f}")
    print('\n---------------Material colors-----------------')
    for color, code in material_colors.items():
        rgba = rgba_from_argb(hex_to_argb(code))
        print(f"{color.ljust(32)} : {display_color(rgba)}  {code}")
    print('\n----------Harmonize terminal colors------------')
    for color, code in term_colors.items():
        rgba = rgba_from_argb(hex_to_argb(code))
        code_source = term_source_colors[color]
        rgba_source = rgba_from_argb(hex_to_argb(code_source))
        print(f"{color.ljust(6)} : {display_color(rgba_source)} {code_source} --> {display_color(rgba)} {code}")
    print('-----------------------------------------------')
