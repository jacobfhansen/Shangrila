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


def _seg_dist(px, py, a, b):
    """Distance from points (px, py) to the segment a-b."""
    ax, ay = a
    bx, by = b
    dx, dy = bx - ax, by - ay
    t = np.clip(((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy), 0, 1)
    return np.hypot(px - (ax + t * dx), py - (ay + t * dy))


def town_lehan():
    """The town plan of Lehan: walls, streets, the market square and rows of houses.
    The places shown on it (gate, market, inn, smith) are listed in Game.TOWNS."""
    w, h = 600, 370
    rng = np.random.default_rng(101)
    yy, xx = np.mgrid[0:h, 0:w]
    paper = tile_noise(w, h, 3, 103, 5)
    rgb = np.array([224, 204, 158]) + ((paper - 0.5) * 34)[..., None]
    cx, cy, rx, ry = 300, 186, 262, 152
    inside = ((xx - cx) / rx) ** 2 + ((yy - cy) / ry) ** 2 < 1
    # Fields outside the walls: a greener tint.
    rgb = np.where(inside[..., None], rgb, rgb + np.array([-14, -4, -22]))
    img = to_img(rgb)
    d = ImageDraw.Draw(img)
    ink = (70, 48, 26)

    # Field furrows outside the walls.
    for _ in range(140):
        x, y = int(rng.integers(0, w)), int(rng.integers(0, h))
        if ((x - cx) / (rx + 14)) ** 2 + ((y - cy) / (ry + 14)) ** 2 < 1:
            continue
        ang = rng.uniform(0, np.pi)
        for k in range(4):
            ox, oy = np.cos(ang + np.pi / 2) * k * 4, np.sin(ang + np.pi / 2) * k * 4
            d.line([(x + ox, y + oy), (x + ox + np.cos(ang) * 22, y + oy + np.sin(ang) * 22)], fill=(150, 140, 96), width=1)

    # Streets: (from, to) in map coordinates. The places sit on them.
    gate, market, inn, smith = (300, 336), (300, 178), (432, 232), (176, 132)
    streets = [(gate, market), (market, inn), (market, smith), (market, (300, 40)), (market, (520, 150)),
               (market, (90, 230)), (inn, (500, 290)), (smith, (130, 70)), ((180, 290), (420, 300)),
               ((120, 160), (210, 260))]
    sdist = np.full((h, w), 999.0)
    for a, b in streets:
        sdist = np.minimum(sdist, _seg_dist(xx, yy, a, b))
    px = np.array(img).astype(float)
    road = (sdist < 6) & inside
    px[road] = px[road] * 0.6 + np.array([236, 222, 186]) * 0.4
    edge = (np.abs(sdist - 6) < 0.8) & inside
    px[edge] = px[edge] * 0.5 + np.array(ink) * 0.5
    img = Image.fromarray(np.clip(px, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)

    # The market square, with a well.
    d.rectangle([market[0] - 38, market[1] - 26, market[0] + 38, market[1] + 26], fill=(232, 216, 176), outline=ink, width=1)
    d.ellipse([market[0] - 5, market[1] - 5, market[0] + 5, market[1] + 5], outline=ink, width=2)

    # Houses: small inked blocks, kept off the streets, the square and the places.
    keep_clear = [gate, market, inn, smith]
    placed = 0
    for _ in range(6000):
        if placed > 260:
            break
        x, y = float(rng.uniform(40, w - 40)), float(rng.uniform(30, h - 30))
        if ((x - cx) / (rx - 16)) ** 2 + ((y - cy) / (ry - 16)) ** 2 > 1:
            continue
        hw, hh = rng.uniform(6, 11), rng.uniform(5, 8)
        if abs(x - market[0]) < 48 + hw and abs(y - market[1]) < 36 + hh:
            continue
        if any(np.hypot(x - p[0], y - p[1]) < 30 for p in keep_clear):
            continue
        if min(_seg_dist(np.array([x]), np.array([y]), a, b)[0] for a, b in streets) < 9 + max(hw, hh):
            continue
        box = [x - hw, y - hh, x + hw, y + hh]
        # Skip if it overlaps an earlier house.
        if np.any(np.array(img.crop([int(box[0]) - 1, int(box[1]) - 1, int(box[2]) + 2, int(box[3]) + 2]))[..., 0] < 120):
            continue
        tone = int(rng.integers(176, 200))
        d.rectangle(box, fill=(tone, tone - 26, tone - 66), outline=ink, width=1)
        d.line([(box[0], y), (box[2], y)], fill=(130, 100, 64), width=1)   # roof ridge
        placed += 1

    # The wall, with towers and the south gate.
    pts = [(cx + rx * np.cos(a), cy + ry * np.sin(a)) for a in np.linspace(0, 2 * np.pi, 120)]
    gate_a = np.pi / 2
    for i in range(len(pts) - 1):
        a = 2 * np.pi * i / (len(pts) - 1)
        if abs(a - gate_a) < 0.05:
            continue
        d.line([pts[i], pts[i + 1]], fill=ink, width=4)
    for a in np.linspace(0, 2 * np.pi, 15)[:-1]:
        if abs(a - gate_a) < 0.15:
            continue
        x, y = cx + rx * np.cos(a), cy + ry * np.sin(a)
        d.ellipse([x - 6, y - 6, x + 6, y + 6], fill=(200, 182, 140), outline=ink, width=2)
    for side in (-1, 1):
        x = gate[0] + side * 14
        d.rectangle([x - 6, cy + ry - 9, x + 6, cy + ry + 7], fill=(200, 182, 140), outline=ink, width=2)

    # Vignette and frame, as on the world map.
    px = np.array(img).astype(float)
    vx, vy = (xx - w / 2) / (w / 2), (yy - h / 2) / (h / 2)
    vig = np.clip((vx * vx + vy * vy - 0.55) * 0.35, 0, 0.35)
    px = px * (1 - vig[..., None]) + np.array([90, 60, 30]) * vig[..., None]
    img = Image.fromarray(np.clip(px, 0, 255).astype(np.uint8), "RGB")
    d = ImageDraw.Draw(img)
    d.rectangle([2, 2, w - 3, h - 3], outline=ink, width=2)
    d.rectangle([7, 7, w - 8, h - 8], outline=ink, width=1)
    img.save(OUT / "town_lehan.png")


# ---------------------------------------------------------------- the market square (3D)

def cobbles():
    """Rounded cobblestones for the market square floor (tileable)."""
    w = h = 256
    rng = np.random.default_rng(301)
    yy, xx = np.mgrid[0:h, 0:w]
    pts = rng.random((70, 2)) * w
    best = np.full((h, w), 1e9)
    second = np.full((h, w), 1e9)
    idx = np.zeros((h, w), int)
    for i, (px_, py_) in enumerate(pts):
        for ox in (-w, 0, w):
            for oy in (-h, 0, h):
                d = np.hypot(xx - px_ - ox, yy - py_ - oy)
                closer = d < best
                second = np.where(closer, best, np.minimum(second, d))
                idx = np.where(closer, i, idx)
                best = np.where(closer, d, best)
    edge = second - best
    tone = rng.normal(0, 1, len(pts))[idx]
    grain = tile_noise(w, h, 8, 302, 4)
    base = 118 + tone * 12 + (grain - 0.5) * 30
    bevel = np.clip(edge / 7.0, 0, 1)
    v = base * (0.35 + 0.65 * bevel)
    rgb = np.stack([v * 1.02, v * 0.96, v * 0.86], -1)
    to_img(rgb).save(OUT / "cobbles.png")


def _plaster(w, h, seed, col):
    n = tile_noise(w, h, 4, seed, 5)
    return np.array(col, float)[None, None, :] + ((n - 0.5) * 40)[..., None]


def _window(d, x0, y0, x1, y1, shutters, beam):
    d.rectangle([x0, y0, x1, y1], fill=(34, 30, 34), outline=beam, width=4)
    mx, my = (x0 + x1) // 2, (y0 + y1) // 2
    d.line([(mx, y0), (mx, y1)], fill=beam, width=3)
    d.line([(x0, my), (x1, my)], fill=beam, width=3)
    # A warm glint behind the glass.
    d.rectangle([x0 + 6, y0 + 6, mx - 4, my - 4], fill=(70, 58, 44))
    if shutters:
        sw = (x1 - x0) // 2
        d.rectangle([x0 - sw - 2, y0, x0 - 2, y1], fill=shutters, outline=beam, width=2)
        d.rectangle([x1 + 2, y0, x1 + sw + 2, y1], fill=shutters, outline=beam, width=2)
        for k in range(1, 4):
            yk = y0 + (y1 - y0) * k // 4
            d.line([(x0 - sw, yk), (x0 - 4, yk)], fill=beam, width=1)
            d.line([(x1 + 4, yk), (x1 + sw, yk)], fill=beam, width=1)


def _door(d, x0, y0, x1, y1, wood, beam):
    d.rectangle([x0, y0, x1, y1], fill=wood, outline=beam, width=4)
    for k in range(1, 4):
        xk = x0 + (x1 - x0) * k // 4
        d.line([(xk, y0 + 4), (xk, y1)], fill=tuple(int(c * 0.75) for c in wood), width=2)
    d.ellipse([x1 - 18, (y0 + y1) // 2, x1 - 10, (y0 + y1) // 2 + 8], fill=(40, 34, 28))
    d.pieslice([x0, y0 - (x1 - x0) // 2, x1, y0 + (x1 - x0) // 2], 180, 360, fill=wood, outline=beam, width=4)


def house_fronts():
    """Ground floors (house_low_N) and upper storeys (house_up_N) for the square's houses."""
    w = h = 256
    plasters = [(214, 200, 168), (196, 176, 140), (222, 214, 196), (186, 160, 122)]
    shutters = [(70, 96, 70), (120, 60, 44), (70, 80, 110), (110, 90, 50)]
    beam = (62, 42, 26)
    for i in range(4):
        rng = np.random.default_rng(400 + i)
        # Ground floor: a stone plinth, plaster, a door and a window, or a shop front.
        rgb = _plaster(w, h, 410 + i, plasters[i])
        img = to_img(rgb)
        d = ImageDraw.Draw(img)
        stone = blocks(w, 60, 2, 6, 420 + i, mortar=2, base=(108, 100, 92), jitter=14)
        img.paste(stone, (0, h - 60))
        d.rectangle([0, 0, w - 1, 10], fill=beam)
        d.line([(0, 0), (0, h)], fill=beam, width=8)
        d.line([(w - 1, 0), (w - 1, h)], fill=beam, width=8)
        if i % 2 == 0:
            _door(d, 30, 96, 104, h - 8, (110, 76, 44), beam)
            _window(d, 150, 80, 220, 160, shutters[i], beam)
        else:
            # A shop front: a wide window under a little awning.
            d.rectangle([24, 70, 232, 170], fill=(40, 34, 30), outline=beam, width=5)
            for k in range(1, 4):
                d.line([(24 + 52 * k, 70), (24 + 52 * k, 170)], fill=beam, width=3)
            d.rectangle([20, 176, 236, 196], fill=(120, 90, 60), outline=beam, width=3)
            for k in range(8):
                d.polygon([(16 + k * 28, 52), (44 + k * 28, 52), (40 + k * 28, 70), (20 + k * 28, 70)],
                          fill=shutters[i] if k % 2 == 0 else (220, 210, 180))
        img.save(OUT / f"house_low_{i}.png")
        # Upper storey: timber framing with windows.
        rgb = _plaster(w, h, 430 + i, plasters[(i + 1) % 4])
        img = to_img(rgb)
        d = ImageDraw.Draw(img)
        for x in (0, 84, 170, w - 1):
            d.line([(x, 0), (x, h)], fill=beam, width=10)
        d.line([(0, 6), (w, 6)], fill=beam, width=12)
        d.line([(0, h - 6), (w, h - 6)], fill=beam, width=12)
        d.line([(0, 128), (w, 128)], fill=beam, width=8)
        if rng.random() < 0.5:
            d.line([(4, 128), (80, 10)], fill=beam, width=8)
            d.line([(252, 128), (176, 10)], fill=beam, width=8)
        else:
            d.line([(4, 250), (80, 130)], fill=beam, width=8)
            d.line([(252, 250), (176, 130)], fill=beam, width=8)
        _window(d, 104, 30, 152, 108, None, beam)
        _window(d, 104, 150, 152, 228, shutters[i], beam)
        img.save(OUT / f"house_up_{i}.png")


def smith_front():
    """The weapon smith's ground floor: a wide door, and a sign with a sword and an anvil."""
    w = h = 256
    img = to_img(_plaster(w, h, 450, (176, 160, 140)))
    d = ImageDraw.Draw(img)
    beam = (52, 36, 24)
    img.paste(blocks(w, 60, 2, 6, 451, mortar=2, base=(96, 90, 84), jitter=14), (0, h - 60))
    d.line([(0, 0), (0, h)], fill=beam, width=8)
    d.line([(w - 1, 0), (w - 1, h)], fill=beam, width=8)
    _door(d, 70, 104, 186, h - 6, (92, 62, 36), beam)
    d.rectangle([20, 14, 236, 60], fill=(60, 44, 30), outline=(180, 140, 70), width=3)
    d.line([(60, 37), (140, 37)], fill=(220, 224, 230), width=6)
    d.polygon([(140, 31), (156, 37), (140, 43)], fill=(220, 224, 230))
    d.line([(64, 27), (64, 47)], fill=(200, 160, 60), width=5)
    d.polygon([(170, 30), (214, 30), (206, 40), (196, 40), (200, 52), (180, 52), (184, 40), (176, 40)], fill=(40, 40, 46))
    img.save(OUT / "smith_front.png")


def archway():
    """A lane leaving the square between two houses: a dark opening under an arch."""
    w = h = 256
    img = blocks(w, h, 8, 4, 460, mortar=3, base=(120, 110, 98), jitter=16)
    d = ImageDraw.Draw(img)
    d.rectangle([48, 90, 208, h], fill=(26, 22, 20))
    d.pieslice([48, 10, 208, 170], 180, 360, fill=(26, 22, 20))
    # A hint of daylight at the end of the lane.
    d.rectangle([108, 140, 148, h - 20], fill=(80, 76, 64))
    d.pieslice([108, 116, 148, 164], 180, 360, fill=(80, 76, 64))
    d.arc([44, 6, 212, 174], 180, 360, fill=(70, 60, 50), width=8)
    img.save(OUT / "archway.png")


def roof_tiles():
    w = h = 256
    rng = np.random.default_rng(470)
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    rows = 10
    for r in range(rows):
        y0 = r * h // rows
        off = (r % 2) * 16
        for c in range(-1, 9):
            x0 = c * 32 + off
            t = int(rng.integers(-16, 16))
            d.rectangle([x0, y0, x0 + 31, y0 + h // rows], fill=(132 + t, 66 + t // 2, 46 + t // 3))
            d.line([(x0, y0), (x0, y0 + h // rows)], fill=(80, 40, 30), width=2)
        d.line([(0, y0), (w, y0)], fill=(70, 34, 26), width=3)
    img.save(OUT / "roof_tiles.png")


def awning():
    w, h = 128, 64
    img = Image.new("RGB", (w, h))
    d = ImageDraw.Draw(img)
    for k in range(8):
        col = (176, 52, 40) if k % 2 == 0 else (226, 214, 186)
        d.rectangle([k * 16, 0, k * 16 + 15, h], fill=col)
    img = Image.fromarray(np.clip(np.array(img) * (0.9 + 0.1 * tile_noise(w, h, 4, 480)[..., None]), 0, 255).astype(np.uint8))
    img.save(OUT / "awning.png")


def planks():
    w = h = 128
    n = tile_noise(w, h, 2, 490, 5)
    rgb = np.stack([120 + n * 40, 84 + n * 30, 52 + n * 20], -1)
    img = to_img(rgb)
    d = ImageDraw.Draw(img)
    for k in range(0, h, 32):
        d.line([(0, k), (w, k)], fill=(60, 40, 24), width=3)
    img.save(OUT / "planks.png")


def inn_front():
    """The inn's ground floor: a wide door, lit windows and a hanging sign with a tankard."""
    w = h = 256
    img = to_img(_plaster(w, h, 500, (200, 178, 136)))
    d = ImageDraw.Draw(img)
    beam = (58, 38, 22)
    img.paste(blocks(w, 60, 2, 6, 501, mortar=2, base=(104, 96, 88), jitter=14), (0, h - 60))
    d.line([(0, 0), (0, h)], fill=beam, width=8)
    d.line([(w - 1, 0), (w - 1, h)], fill=beam, width=8)
    _door(d, 88, 110, 168, h - 6, (120, 78, 40), beam)
    for x0 in (16, 186):
        d.rectangle([x0, 100, x0 + 54, 170], fill=(150, 110, 50), outline=beam, width=4)
        d.line([(x0 + 27, 100), (x0 + 27, 170)], fill=beam, width=3)
        d.line([(x0, 135), (x0 + 54, 135)], fill=beam, width=3)
    # The sign on its bracket.
    d.line([(150, 24), (236, 24)], fill=(40, 30, 20), width=5)
    d.line([(190, 24), (190, 34)], fill=(40, 30, 20), width=2)
    d.line([(226, 24), (226, 34)], fill=(40, 30, 20), width=2)
    d.rectangle([180, 34, 236, 84], fill=(70, 50, 30), outline=(190, 150, 80), width=3)
    d.rectangle([196, 46, 218, 74], fill=(210, 170, 60), outline=(60, 40, 20), width=2)
    d.arc([212, 50, 228, 68], 270, 90, fill=(210, 170, 60), width=4)
    d.rectangle([194, 42, 220, 48], fill=(240, 236, 220))
    img.save(OUT / "inn_front.png")


def town_gate():
    """The inside of the south gate: a tall stone arch with the road beyond."""
    w = h = 256
    img = blocks(w, h, 8, 4, 510, mortar=3, base=(100, 94, 86), jitter=14)
    d = ImageDraw.Draw(img)
    d.rectangle([40, 80, 216, h], fill=(150, 170, 120))
    d.pieslice([40, 0, 216, 170], 180, 360, fill=(150, 170, 120))
    d.polygon([(110, h), (146, h), (136, 120), (120, 120)], fill=(170, 150, 110))
    d.rectangle([40, 120, 216, 130], fill=(120, 140, 100))
    d.arc([36, -4, 220, 174], 180, 360, fill=(60, 54, 46), width=10)
    for x in range(52, 210, 22):
        d.line([(x, 8), (x, 40)], fill=(50, 44, 40), width=4)
    d.line([(46, 40), (210, 40)], fill=(50, 44, 40), width=4)
    img.save(OUT / "town_gate.png")


if __name__ == "__main__":
    floor_tiles()
    dark_stone()
    parchment()
    chain()
    world_map()
    town_lehan()
    cobbles()
    house_fronts()
    smith_front()
    archway()
    roof_tiles()
    awning()
    planks()
    inn_front()
    town_gate()
    print("wrote textures to", OUT)
