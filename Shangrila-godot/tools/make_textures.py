#!/usr/bin/env python3
"""Generate the procedural textures in assets/ (floor_tiles, dark_stone, parchment, chain).

Run from the Shangrila-godot folder:  python3 tools/make_textures.py
Requires numpy and Pillow. Output is deterministic (fixed seeds).
"""
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

OUT = Path(__file__).resolve().parent.parent / "assets"


def tile_noise(w, h, cells, seed, octaves=4):
    """Seamlessly tiling value noise in [0, 1]."""
    rng = np.random.default_rng(seed)
    total = np.zeros((h, w))
    amp, norm = 1.0, 0.0
    for o in range(octaves):
        cx, cy = cells * 2**o, max(1, round(cells * h / w)) * 2**o
        grid = rng.random((cy, cx))
        ys = np.arange(h) * cy / h
        xs = np.arange(w) * cx / w
        y0, x0 = np.floor(ys).astype(int), np.floor(xs).astype(int)
        fy, fx = ys - y0, xs - x0
        fy, fx = fy * fy * (3 - 2 * fy), fx * fx * (3 - 2 * fx)
        y1, x1 = (y0 + 1) % cy, (x0 + 1) % cx
        a = grid[np.ix_(y0, x0)] * (1 - fx) + grid[np.ix_(y0, x1)] * fx
        b = grid[np.ix_(y1, x0)] * (1 - fx) + grid[np.ix_(y1, x1)] * fx
        total += amp * (a * (1 - fy[:, None]) + b * fy[:, None])
        norm += amp
        amp *= 0.5
    return total / norm


def to_img(rgb):
    return Image.fromarray(np.clip(rgb, 0, 255).astype(np.uint8), "RGB")


def blocks(w, h, rows, cols_per_row, seed, mortar=3, base=(70, 66, 62), jitter=18):
    """Tileable masonry: per-block shade, mortar lines, bevel and grain."""
    rng = np.random.default_rng(seed)
    shade = np.zeros((h, w))
    edge = np.full((h, w), 99.0)  # distance to nearest mortar line
    row_h = h / rows
    yy, xx = np.mgrid[0:h, 0:w]
    for r in range(rows):
        n = cols_per_row
        bw = w / n
        off = (bw / 2) * (r % 2)
        y0, y1 = r * row_h, (r + 1) * row_h
        in_row = (yy >= y0) & (yy < y1)
        for c in range(n):
            x0 = (c * bw + off) % w
            rel = (xx - x0) % w
            m = in_row & (rel < bw)
            shade[m] = rng.normal(0, 1)
            d = np.minimum.reduce([rel, bw - rel, yy - y0, y1 - yy])
            edge[m] = d[m]
    grain = tile_noise(w, h, 8, seed + 1, 5)
    v = (grain - 0.5) * 50 + shade[..., None].squeeze() * jitter
    bevel = np.clip((edge - mortar) / 4.0, 0, 1)
    lum = np.where(edge < mortar, -45 + (grain - 0.5) * 20, v * bevel + (bevel - 1) * 25)
    rgb = np.stack([base[i] + lum for i in range(3)], -1)
    return to_img(rgb)


def floor_tiles():
    img = blocks(128, 128, rows=2, cols_per_row=2, seed=11, mortar=2, base=(112, 100, 86), jitter=14)
    img.save(OUT / "floor_tiles.png")


def dark_stone():
    img = blocks(256, 256, rows=6, cols_per_row=4, seed=23, mortar=3, base=(58, 56, 60), jitter=16)
    img.save(OUT / "dark_stone.png")


def parchment():
    w, h = 136, 147
    n = tile_noise(w, h, 3, 37, 5)
    fibre = tile_noise(w, h, 16, 41, 2)
    stain = np.clip((tile_noise(w, h, 2, 43, 3) - 0.55) * 4, 0, 1)
    base = np.array([226, 204, 160])
    lum = (n - 0.5) * 40 + (fibre - 0.5) * 14 - stain * 35
    rgb = base + lum[..., None] * np.array([1.0, 1.0, 1.15])
    to_img(rgb).save(OUT / "parchment.png")


def chain():
    """Metal chain on black (the game draws it with additive blending)."""
    w, h, s = 696, 36, 4  # supersample
    img = Image.new("RGB", (w * s, h * s), (0, 0, 0))
    d = ImageDraw.Draw(img)
    pitch = 29 * s
    cy = h * s // 2
    x = -pitch // 2
    i = 0
    while x < w * s + pitch:
        if i % 2 == 0:  # link seen face-on: an open oval
            box = [x - 20 * s, cy - 11 * s, x + 20 * s, cy + 11 * s]
            d.ellipse(box, fill=(150, 150, 158))
            d.ellipse([box[0] + 5 * s, box[1] + 5 * s, box[2] - 5 * s, box[3] - 5 * s], fill=(0, 0, 0))
            d.arc([box[0] + 2 * s, box[1] + 2 * s, box[2] - 2 * s, box[3] - 2 * s], 200, 320, fill=(225, 225, 235), width=2 * s)
        else:  # link seen edge-on: a flat bar
            d.rounded_rectangle([x - 21 * s, cy - 3 * s, x + 21 * s, cy + 3 * s], 3 * s, fill=(120, 120, 128))
            d.line([x - 18 * s, cy - 1 * s, x + 18 * s, cy - 1 * s], fill=(210, 210, 220), width=s)
        x += pitch
        i += 1
    img = img.filter(ImageFilter.GaussianBlur(s * 0.4)).resize((w, h), Image.LANCZOS)
    img.save(OUT / "chain.png")


if __name__ == "__main__":
    floor_tiles()
    dark_stone()
    parchment()
    chain()
    print("wrote textures to", OUT)
