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


def world_map():
    """The world map: an inked parchment chart of an invented land."""
    w, h = 600, 370
    rng = np.random.default_rng(71)
    yy, xx = np.mgrid[0:h, 0:w]
    # Height: noise plus a broad falloff so the middle is land and the edges are sea.
    n = tile_noise(w, h, 4, 73, 6)
    dx, dy = (xx - w * 0.47) / (w * 0.55), (yy - h * 0.52) / (h * 0.62)
    fall = 1 - np.sqrt(dx * dx + dy * dy)
    height = n * 0.75 + fall * 0.55
    # A mountain range curving across the north-east.
    ridge = np.exp(-(((yy - (h * 0.30 + 0.0009 * (xx - w * 0.6) ** 2)) / 26.0) ** 2)) * np.clip((xx - w * 0.3) / (w * 0.15), 0, 1)
    height += ridge * 0.25 * tile_noise(w, h, 6, 79, 3)
    sea = height < 0.52
    paper = tile_noise(w, h, 3, 83, 5)

    base_land = np.array([222, 200, 152])
    base_sea = np.array([170, 178, 160])
    rgb = np.where(sea[..., None], base_sea, base_land).astype(float)
    rgb += ((paper - 0.5) * 36)[..., None]
    # Gentle relief shading on land (light from the north-west).
    gy, gx = np.gradient(height)
    relief = np.clip((gx + gy) * -900, -25, 25)
    rgb += np.where(sea, 0, relief)[..., None]
    # Lowlands a little greener, highlands a little browner.
    rgb += np.where(sea, 0, np.clip((height - 0.62) * 120, -10, 25))[..., None] * np.array([0.3, -0.2, -0.6])

    img = to_img(rgb)
    d = ImageDraw.Draw(img)
    ink = (70, 48, 26)

    # Coastline: ink where land touches sea, plus offset ripple lines out at sea.
    land = ~sea
    edge = land & (np.roll(sea, 1, 0) | np.roll(sea, -1, 0) | np.roll(sea, 1, 1) | np.roll(sea, -1, 1))
    dist = np.zeros((h, w))  # rough distance from the coast, out at sea
    ring = edge.copy()
    seen = land.copy()
    for k in range(1, 15):
        grow = (np.roll(ring, 1, 0) | np.roll(ring, -1, 0) | np.roll(ring, 1, 1) | np.roll(ring, -1, 1)) & ~seen
        dist[grow] = k
        seen |= grow
        ring = grow
    px = np.array(img).astype(float)
    for k, a in ((4, 0.35), (8, 0.22), (13, 0.12)):
        m = dist == k
        px[m] = px[m] * (1 - a) + np.array(ink) * a
    px[edge] = ink
    img = Image.fromarray(px.astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)

    # Mountains: little inked peaks on the high ground.
    for _ in range(2600):
        x, y = int(rng.integers(8, w - 8)), int(rng.integers(10, h - 6))
        if sea[y, x] or height[y, x] < 0.80:
            continue
        s = 4 + int((height[y, x] - 0.80) * 30) + int(rng.integers(0, 3))
        s = min(s, 10)
        if rng.random() < 0.88:
            continue
        d.polygon([(x - s, y), (x, y - s - 2), (x + s, y)], fill=(196, 172, 128))
        d.line([(x - s, y), (x, y - s - 2), (x + s, y)], fill=ink, width=1)
        d.line([(x, y - s - 2), (x + s // 3, y)], fill=(120, 96, 64), width=1)

    # Forests: clusters of small tree rings on the lowlands.
    forest = tile_noise(w, h, 5, 89, 4)
    for _ in range(9000):
        x, y = int(rng.integers(6, w - 6)), int(rng.integers(6, h - 6))
        if sea[y, x] or not (0.56 < height[y, x] < 0.76) or forest[y, x] < 0.6:
            continue
        if rng.random() < 0.8:
            continue
        d.ellipse([x - 3, y - 3, x + 3, y + 2], fill=(150, 150, 96), outline=(80, 74, 40))
        d.line([(x, y + 2), (x, y + 4)], fill=(80, 74, 40))

    # Compass rose in the north-west sea.
    cx, cy, r = 52, 52, 26
    for ang, ln in ((0, r), (90, r), (180, r), (270, r), (45, r * 0.55), (135, r * 0.55), (225, r * 0.55), (315, r * 0.55)):
        t = np.radians(ang)
        tip = (cx + np.sin(t) * ln, cy - np.cos(t) * ln)
        side = 5
        l = (cx + np.sin(t - np.pi / 2) * side, cy - np.cos(t - np.pi / 2) * side)
        rr = (cx + np.sin(t + np.pi / 2) * side, cy - np.cos(t + np.pi / 2) * side)
        d.polygon([l, tip, rr], fill=(236, 220, 180) if ang % 90 else ink, outline=ink)
    d.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(236, 220, 180), outline=ink)

    # Vignette and a double frame.
    px = np.array(img).astype(float)
    vx, vy = (xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2)
    vig = np.clip((vx * vx + vy * vy - 0.55) * 0.35, 0, 0.35)
    px = px * (1 - vig[..., None]) + np.array([90, 60, 30]) * vig[..., None]
    img = Image.fromarray(np.clip(px, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, w - 3, h - 3], outline=ink, width=2)
    d.rectangle([7, 7, w - 8, h - 8], outline=ink, width=1)
    img.save(OUT / "world_map.png")


if __name__ == "__main__":
    floor_tiles()
    dark_stone()
    parchment()
    chain()
    world_map()
    print("wrote textures to", OUT)
