#!/usr/bin/env python3
"""Rebuilds HuatLui's icon files in any colour.

    pip install pillow numpy scipy
    python tool/make_icon.py --color "#2F4FD6"

Reads tool/icon_source.png (the glass chart icon), shifts its hue to the given
colour, and writes into assets/icons/:
    app_icon.png          full-bleed square, no transparency  -> launcher icons
    app_icon_tran.png     the artwork on a transparent canvas -> splash screen
    app_icon_splash.png   same, with padding                   -> Android 12 splash

Afterwards run:
    dart run flutter_launcher_icons
    dart run flutter_native_splash:create
"""
import argparse, colorsys, os
import numpy as np
from PIL import Image
from scipy import ndimage

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'assets', 'icons')


def hue_of(hex_color: str) -> float:
    h = hex_color.lstrip('#')
    r, g, b = (int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))
    return colorsys.rgb_to_hsv(r, g, b)[0]  # 0..1


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--color', default='#2F4FD6', help='target colour, e.g. "#2F4FD6"')
    ap.add_argument('--source', default=os.path.join(HERE, 'icon_source.png'))
    args = ap.parse_args()

    src = Image.open(args.source).convert('RGB')
    a = np.asarray(src).astype(np.int32)

    # 1. find the artwork: everything that is not the off-white background
    bg = np.median(a[:24, :24].reshape(-1, 3), axis=0)
    dist = np.abs(a - bg).sum(-1)
    fg = ndimage.binary_fill_holes(dist > 40)
    lab, n = ndimage.label(fg)
    if n > 1:
        sizes = ndimage.sum(fg, lab, range(1, n + 1))
        fg = lab == (1 + int(np.argmax(sizes)))
    ys, xs = np.where(fg)
    x0, x1, y0, y1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    side = max(x1 - x0, y1 - y0)
    cx, cy = (x0 + x1) // 2, (y0 + y1) // 2
    box = (cx - side // 2, cy - side // 2, cx - side // 2 + side, cy - side // 2 + side)

    # 2. recolour: rotate hue of the coloured pixels only (whites stay white)
    hsv = np.asarray(src.convert('HSV')).astype(np.int32)
    coloured = hsv[..., 1] > 25
    strong = hsv[..., 1] > 100
    src_h = int(np.median(hsv[..., 0][strong & fg]))
    shift = int(round(hue_of(args.color) * 255)) - src_h
    hsv[..., 0] = np.where(coloured, (hsv[..., 0] + shift) % 256, hsv[..., 0])
    rgb = np.asarray(Image.fromarray(hsv.astype(np.uint8), 'HSV').convert('RGB')).astype(np.float32)

    # 3. full-bleed launcher icon: push the artwork's own colours out into the corners
    core = ndimage.binary_erosion(fg, iterations=8)
    idx = ndimage.distance_transform_edt(~core, return_indices=True)[1]
    filled = rgb[idx[0], idx[1]]
    full = np.where(core[..., None], rgb, filled)
    Image.fromarray(full.astype(np.uint8)).crop(box).resize((1024, 1024), Image.LANCZOS).save(
        os.path.join(OUT, 'app_icon.png'))

    # 4. transparent artwork (splash screen)
    alpha = ndimage.gaussian_filter(ndimage.binary_erosion(fg, iterations=2).astype(np.float32), 1.0)
    rgba = np.dstack([rgb, alpha * 255]).astype(np.uint8)
    tran = Image.fromarray(rgba, 'RGBA').crop(box).resize((1024, 1024), Image.LANCZOS)
    tran.save(os.path.join(OUT, 'app_icon_tran.png'))

    # 5. padded version for the Android 12 splash (its circle crops the edges)
    canvas = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
    small = tran.resize((600, 600), Image.LANCZOS)
    canvas.paste(small, (212, 212), small)
    canvas.save(os.path.join(OUT, 'app_icon_splash.png'))
    print('written to', os.path.normpath(OUT), '- hue shift', shift)


if __name__ == '__main__':
    main()
