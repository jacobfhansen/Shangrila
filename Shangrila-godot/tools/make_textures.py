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


def _arched_window(d, x0, y0, x1, y1, frame):
    d.rectangle([x0, y0 + (x1 - x0) // 2, x1, y1], fill=(30, 28, 34), outline=frame, width=4)
    d.pieslice([x0, y0, x1, y0 + (x1 - x0)], 180, 360, fill=(30, 28, 34), outline=frame, width=4)
    d.rectangle([x0 + 4, y0 + (x1 - x0) // 2 + 2, x1 - 4, y0 + (x1 - x0) // 2 + 6], fill=frame)
    mx = (x0 + x1) // 2
    d.line([(mx, y0 + 4), (mx, y1)], fill=frame, width=3)


def council_house():
    """The council house on the square: dressed stone, arched windows, a double door under the
    town's banner (a gold tower on blue)."""
    w = h = 256
    stone = (132, 124, 112)
    frame = (84, 76, 68)
    # Ground floor beside the door.
    img = blocks(w, h, 6, 3, 600, mortar=3, base=stone, jitter=12)
    d = ImageDraw.Draw(img)
    d.rectangle([0, h - 24, w, h], fill=(100, 94, 86))
    _arched_window(d, 70, 60, 186, 200, frame)
    img.save(OUT / "council_low.png")
    # The door: steps, a double door in a round arch, the banner above.
    img = blocks(w, h, 6, 3, 601, mortar=3, base=stone, jitter=12)
    d = ImageDraw.Draw(img)
    d.rectangle([0, h - 24, w, h], fill=(100, 94, 86))
    d.rectangle([40, h - 16, 216, h], fill=(150, 144, 134))
    d.rectangle([56, 120, 200, h - 16], fill=(86, 54, 30), outline=frame, width=6)
    d.pieslice([56, 50, 200, 194], 180, 360, fill=(86, 54, 30), outline=frame, width=6)
    d.line([(128, 64), (128, h - 16)], fill=(50, 32, 20), width=4)
    for x in (92, 164):
        d.ellipse([x - 5, 170, x + 5, 180], fill=(190, 160, 80))
    for y in (140, 210):
        d.line([(60, y), (196, y)], fill=(60, 40, 24), width=3)
    # The banner hangs from a pole over the arch.
    d.line([(96, 8), (160, 8)], fill=(50, 40, 30), width=5)
    d.polygon([(100, 10), (156, 10), (156, 52), (128, 62), (100, 52)], fill=(40, 60, 130), outline=(200, 170, 70))
    d.rectangle([120, 24, 136, 48], fill=(220, 180, 60))
    for k in range(3):
        d.rectangle([118 + k * 7, 18, 122 + k * 7, 24], fill=(220, 180, 60))
    d.rectangle([125, 38, 131, 48], fill=(40, 60, 130))
    img.save(OUT / "council_door.png")
    # Upper storey: tall arched windows and a cornice.
    img = blocks(w, h, 6, 3, 602, mortar=3, base=(142, 134, 122), jitter=12)
    d = ImageDraw.Draw(img)
    d.rectangle([0, 0, w, 16], fill=(110, 102, 92))
    d.rectangle([0, 16, w, 22], fill=(160, 152, 140))
    _arched_window(d, 44, 50, 112, 230, frame)
    _arched_window(d, 144, 50, 212, 230, frame)
    d.rectangle([0, h - 10, w, h], fill=(160, 152, 140))
    img.save(OUT / "council_up.png")


def warehouse_front():
    """Gell's warehouse: tarred planks, wide loading doors and a sign with a barrel."""
    w = h = 256
    img = to_img(_plaster(w, h, 700, (120, 100, 76)))
    d = ImageDraw.Draw(img)
    for x in range(0, w, 22):
        d.line([(x, 0), (x, h)], fill=(70, 54, 38), width=3)
    beam = (48, 34, 22)
    d.line([(0, 0), (0, h)], fill=beam, width=8)
    d.line([(w - 1, 0), (w - 1, h)], fill=beam, width=8)
    d.rectangle([40, 70, 216, h - 4], fill=(90, 64, 40), outline=beam, width=6)
    d.line([(128, 70), (128, h - 4)], fill=beam, width=5)
    d.line([(40, 70), (128, h - 4)], fill=beam, width=4)
    d.line([(216, 70), (128, h - 4)], fill=beam, width=4)
    d.rectangle([60, 10, 196, 54], fill=(60, 44, 30), outline=(180, 140, 70), width=3)
    d.ellipse([110, 16, 146, 48], fill=(140, 96, 50), outline=(40, 28, 18), width=3)
    d.line([(112, 26), (144, 26)], fill=(40, 28, 18), width=2)
    d.line([(112, 38), (144, 38)], fill=(40, 28, 18), width=2)
    img.save(OUT / "warehouse_front.png")


def tannery_front():
    """The tannery on Tanners' Row: stained plaster, hides on a rack, a low yard gate."""
    w = h = 256
    img = to_img(_plaster(w, h, 710, (168, 150, 112)))
    d = ImageDraw.Draw(img)
    beam = (56, 40, 26)
    img.paste(blocks(w, 50, 2, 6, 711, mortar=2, base=(96, 88, 78), jitter=14), (0, h - 50))
    d.line([(0, 0), (0, h)], fill=beam, width=8)
    d.line([(w - 1, 0), (w - 1, h)], fill=beam, width=8)
    rng = np.random.default_rng(712)
    for i in range(5):
        x, y = 40 + i * 40 + int(rng.integers(-6, 6)), 30 + int(rng.integers(-8, 8))
        for _ in range(60):
            d.point((x + int(rng.integers(-14, 14)), y + int(rng.integers(0, 40))), fill=(100, 80, 50))
    d.line([(20, 24), (236, 24)], fill=beam, width=5)
    for i in range(4):
        x = 34 + i * 54
        d.polygon([(x, 26), (x + 40, 26), (x + 44, 60), (x + 34, 84), (x + 6, 84), (x - 4, 60)], fill=(150 - i * 12, 100, 60), outline=beam)
    _door(d, 84, 118, 172, h - 6, (96, 70, 44), beam)
    img.save(OUT / "tannery_front.png")


def carved_stone():
    """The ward-stones under Lehan: old blocks carved with lines, circles and a crown."""
    w = h = 256
    img = blocks(w, h, 4, 2, 720, mortar=3, base=(92, 96, 104), jitter=10)
    d = ImageDraw.Draw(img)
    groove = (52, 60, 80)
    glow = (120, 160, 230)
    d.ellipse([58, 58, 198, 198], outline=groove, width=6)
    d.ellipse([70, 70, 186, 186], outline=glow, width=2)
    # The crown.
    crown = [(88, 150), (88, 104), (108, 126), (128, 92), (148, 126), (168, 104), (168, 150)]
    d.polygon(crown, outline=glow, fill=None)
    d.line(crown + [crown[0]], fill=glow, width=4)
    d.line([(88, 160), (168, 160)], fill=glow, width=4)
    for k in range(6):
        y = 20 + k * 6
        d.line([(16, y), (240, y)], fill=groove, width=2)
        d.line([(16, h - y), (240, h - y)], fill=groove, width=2)
    img.save(OUT / "carved_stone.png")


# ---------------------------------------------------------------- the mines (three levels)

def _rough_rock(w, h, seed, base, contrast=70):
    """Rough-hewn rock: big lumps, cracks and grain, tileable."""
    lumps = tile_noise(w, h, 3, seed, 5)
    grain = tile_noise(w, h, 16, seed + 1, 3)
    cracks = np.abs(tile_noise(w, h, 5, seed + 2, 4) - 0.5)
    lum = (lumps - 0.5) * contrast + (grain - 0.5) * 30 - np.clip(0.04 - cracks, 0, 1) * 900
    return np.stack([base[i] + lum for i in range(3)], -1)


def _timber(d, w, h, wood=(96, 64, 36)):
    """Mine timbering: two posts and a cap beam, with a little shading."""
    dark = tuple(max(0, c - 34) for c in wood)
    for x0 in (6, w - 30):
        d.rectangle([x0, 0, x0 + 24, h], fill=wood)
        d.line([(x0 + 2, 0), (x0 + 2, h)], fill=tuple(min(255, c + 22) for c in wood), width=2)
        d.line([(x0 + 22, 0), (x0 + 22, h)], fill=dark, width=3)
        for y in range(18, h, 41):
            d.line([(x0 + 5, y), (x0 + 19, y + 6)], fill=dark, width=1)
    d.rectangle([0, 4, w, 28], fill=wood)
    d.line([(0, 26), (w, 26)], fill=dark, width=3)
    d.line([(0, 6), (w, 6)], fill=tuple(min(255, c + 22) for c in wood), width=2)
    for x in (18, w - 18):
        d.ellipse([x - 3, 13, x + 3, 19], fill=(40, 36, 34))


def mines_textures():
    """Walls and floors for the three levels of the mines, and the special pieces."""
    w = h = 256
    # Level 1, the old workings: brown rough rock, some of it timbered; gravel floor.
    to_img(_rough_rock(w, h, 700, (92, 76, 60))).save(OUT / "mine_rock.png")
    img = to_img(_rough_rock(w, h, 701, (88, 72, 58)))
    _timber(ImageDraw.Draw(img), w, h)
    img.save(OUT / "mine_timber.png")
    n = tile_noise(128, 128, 24, 702, 3)
    pebbles = tile_noise(128, 128, 10, 703, 2)
    lum = (n - 0.5) * 60 + np.where(pebbles > 0.62, 25, 0)
    to_img(np.stack([86 + lum, 74 + lum, 60 + lum], -1)).save(OUT / "mine_floor.png")
    # Level 2, the new diggings: paler, fresher rock with pick marks, and ore veins.
    rgb = _rough_rock(w, h, 710, (128, 120, 108), contrast=50)
    img = to_img(rgb)
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(711)
    for _ in range(90):
        x, y = rng.integers(0, w), rng.integers(0, h)
        L = rng.integers(8, 20)
        d.line([(x, y), (x + L * 0.6, y + L)], fill=(84, 78, 70), width=2)
        d.line([(x + 1, y), (x + 1 + L * 0.6, y + L)], fill=(160, 152, 140), width=1)
    img.save(OUT / "dig_rock.png")
    vein = img.copy()
    d = ImageDraw.Draw(vein)
    pts = [(0, 150), (40, 132), (90, 140), (130, 110), (180, 118), (220, 92), (256, 100)]
    d.line(pts, fill=(70, 62, 70), width=16)
    for k in range(140):
        t = rng.random()
        i = min(int(t * (len(pts) - 1)), len(pts) - 2)
        f = t * (len(pts) - 1) - i
        x = pts[i][0] + (pts[i + 1][0] - pts[i][0]) * f + rng.normal(0, 4)
        y = pts[i][1] + (pts[i + 1][1] - pts[i][1]) * f + rng.normal(0, 5)
        r = rng.integers(1, 4)
        col = (200, 196, 210) if rng.random() < 0.7 else (230, 190, 90)
        d.ellipse([x - r, y - r, x + r, y + r], fill=col)
    vein.save(OUT / "ore_vein.png")
    n = tile_noise(128, 128, 20, 712, 3)
    lum = (n - 0.5) * 50
    to_img(np.stack([118 + lum, 110 + lum, 98 + lum], -1)).save(OUT / "dig_floor.png")
    # Level 3, the sealed galleries: old fitted stone, darker and colder, worn carvings.
    img = blocks(w, h, rows=4, cols_per_row=3, seed=720, mortar=2, base=(64, 66, 74), jitter=10)
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(721)
    for _ in range(5):
        x, y = int(rng.integers(20, w - 60)), int(rng.integers(20, h - 40))
        for k in range(int(rng.integers(3, 6))):
            d.arc([x + k * 9, y, x + k * 9 + 8, y + 12], 0, 300, fill=(48, 50, 58), width=1)
        d.line([(x, y + 18), (x + 44, y + 18)], fill=(50, 52, 60), width=1)
    img.save(OUT / "jail_stone.png")
    blocks(128, 128, rows=2, cols_per_row=2, seed=722, mortar=2, base=(72, 72, 78), jitter=8).save(OUT / "jail_floor.png")
    # The tomb gate: two great leaves of dark bronze with iron bands and a seal across them.
    img = to_img(_rough_rock(w, h, 730, (40, 36, 30), contrast=30))
    d = ImageDraw.Draw(img)
    d.rectangle([20, 16, w - 20, h], fill=(70, 54, 34))
    d.line([(w // 2, 16), (w // 2, h)], fill=(30, 22, 14), width=4)
    for y in (48, 120, 192):
        d.rectangle([20, y, w - 20, y + 10], fill=(46, 44, 46))
        for x in range(30, w - 20, 26):
            d.ellipse([x - 3, y + 2, x + 3, y + 8], fill=(90, 88, 84))
    d.ellipse([w // 2 - 26, 90, w // 2 + 26, 142], fill=(60, 58, 64), outline=(30, 28, 32), width=3)
    d.ellipse([w // 2 - 14, 102, w // 2 + 14, 130], outline=(36, 34, 40), width=2)
    img.save(OUT / "tomb_gate.png")
    # A plank door with iron straps (the foreman's stores).
    n = tile_noise(128, 128, 2, 740, 5)
    img = to_img(np.stack([110 + n * 40, 76 + n * 30, 46 + n * 20], -1))
    d = ImageDraw.Draw(img)
    for x in range(0, 128, 26):
        d.line([(x, 0), (x, 128)], fill=(56, 38, 22), width=3)
    for y in (22, 98):
        d.rectangle([0, y, 128, y + 8], fill=(52, 50, 52))
    d.rectangle([92, 58, 104, 72], fill=(60, 58, 60))
    img.save(OUT / "mine_door.png")

    # Level 3's ward pillars (a chain, a seal, an eye carved in the stone) and the inscription.
    carve, lit = (36, 38, 46), (96, 100, 116)
    def _panel(seed):
        im = blocks(256, 256, rows=1, cols_per_row=1, seed=seed, mortar=3, base=(70, 72, 82), jitter=6)
        return im, ImageDraw.Draw(im)
    im, d = _panel(750)
    for k in range(4):
        y = 52 + k * 42
        d.ellipse([100, y, 156, y + 50], outline=carve, width=7)
        d.ellipse([102, y + 2, 154, y + 48], outline=lit, width=1)
    im.save(OUT / "ward_chain.png")
    im, d = _panel(751)
    d.ellipse([58, 58, 198, 198], outline=carve, width=9)
    d.ellipse([92, 92, 164, 164], outline=carve, width=6)
    d.line([(128, 30), (128, 92)], fill=carve, width=7)
    d.line([(128, 164), (128, 226)], fill=carve, width=7)
    im.save(OUT / "ward_seal.png")
    im, d = _panel(752)
    d.chord([40, 84, 216, 172], 180, 360, outline=carve, width=8)
    d.chord([40, 84, 216, 172], 0, 180, outline=carve, width=8)
    d.ellipse([104, 104, 152, 152], fill=carve)
    d.ellipse([120, 120, 136, 136], fill=lit)
    im.save(OUT / "ward_eye.png")
    im, d = _panel(753)
    rng = np.random.default_rng(754)
    for row in range(7):
        y = 34 + row * 28
        x = 26
        while x < 220:
            g = int(rng.integers(0, 4))
            if g == 0:
                d.line([(x, y), (x + 8, y + 16)], fill=carve, width=3)
            elif g == 1:
                d.arc([x, y, x + 12, y + 16], 0, 270, fill=carve, width=3)
            elif g == 2:
                d.line([(x, y + 8), (x + 10, y + 8)], fill=carve, width=3)
                d.line([(x + 5, y), (x + 5, y + 16)], fill=carve, width=3)
            else:
                d.ellipse([x, y + 4, x + 8, y + 12], outline=carve, width=2)
            x += int(rng.integers(13, 20))
    im.save(OUT / "ward_words.png")


# ---------------------------------------------------------------- the marsh village (Thuug)

def _reeds(w, h, seed, base=(150, 132, 84)):
    """Woven reed walling: upright bundles with a weave of darker binding every so often."""
    rng = np.random.default_rng(seed)
    n = tile_noise(w, h, 6, seed, 3)
    img = to_img(np.stack([base[i] * (0.8 + 0.3 * n) for i in range(3)], -1))
    d = ImageDraw.Draw(img)
    x = 0
    while x < w:
        bw = int(rng.integers(5, 10))
        t = int(rng.integers(-22, 22))
        d.rectangle([x, 0, x + bw - 1, h], fill=(base[0] + t, base[1] + t, base[2] + t // 2))
        d.line([(x, 0), (x, h)], fill=(base[0] - 50, base[1] - 50, base[2] - 40), width=1)
        x += bw
    for y in range(20, h, 64):
        for x in range(0, w, 12):
            d.line([(x, y), (x + 12, y + 4)], fill=(78, 62, 38), width=3)
    # Mud daubed low down, splashed and darker towards the water.
    mud = tile_noise(w, h, 5, seed + 1, 4)
    arr = np.array(img).astype(float)
    ys = np.linspace(0, 1, h)[:, None]
    m = np.clip((ys - 0.72) * 4 + (mud - 0.5) * 0.8, 0, 1)[..., None]
    arr = arr * (1 - m) + np.array([74, 62, 44]) * m
    return to_img(arr)


def marsh_textures():
    w = h = 256
    img = _reeds(w, h, 900)
    img.save(OUT / "reed_wall.png")
    # A door: a hide curtain in a pole frame.
    img = _reeds(w, h, 901)
    d = ImageDraw.Draw(img)
    pole = (82, 60, 36)
    d.rectangle([74, 70, 182, h], fill=(122, 92, 60))
    for x in range(78, 182, 9):
        d.line([(x, 72), (x + 2, h)], fill=(104, 78, 50), width=2)
    d.rectangle([66, 60, 78, h], fill=pole)
    d.rectangle([178, 60, 190, h], fill=pole)
    d.rectangle([60, 56, 196, 70], fill=pole)
    img.save(OUT / "reed_door.png")
    # The trader's: an open front with a counter, dried fish hanging on a line.
    img = _reeds(w, h, 902)
    d = ImageDraw.Draw(img)
    d.rectangle([30, 70, 226, 170], fill=(40, 32, 22))
    d.rectangle([22, 160, 234, 186], fill=(110, 82, 52))
    d.line([(22, 160), (234, 160)], fill=(70, 50, 30), width=3)
    d.line([(30, 84), (226, 84)], fill=(60, 44, 28), width=2)
    for i in range(8):
        x = 42 + i * 24
        d.polygon([(x, 86), (x + 8, 86), (x + 10, 118), (x + 4, 130), (x - 2, 118)], fill=(176, 162, 120), outline=(110, 98, 70))
    for i in range(5):
        x = 50 + i * 36
        d.ellipse([x, 140, x + 22, 158], fill=(150 - i * 10, 110, 70))
    img.save(OUT / "trader_front.png")
    # The guest hut: a door, a lamp, a carved fish over the lintel.
    img = _reeds(w, h, 903)
    d = ImageDraw.Draw(img)
    d.rectangle([90, 80, 166, h], fill=(70, 50, 30))
    d.rectangle([84, 70, 172, 82], fill=pole)
    d.polygon([(100, 46), (150, 46), (162, 56), (150, 66), (100, 66), (90, 56)], fill=(180, 150, 90), outline=pole)
    d.ellipse([186, 96, 206, 118], fill=(250, 210, 120), outline=pole, width=2)
    d.line([(196, 70), (196, 96)], fill=pole, width=2)
    img.save(OUT / "guest_front.png")
    # The causeway gate: a palisade of sharpened stakes with a plank gate.
    img = Image.new("RGB", (w, h), (90, 110, 120))
    d = ImageDraw.Draw(img)
    rng = np.random.default_rng(904)
    for x in range(0, w, 22):
        t = int(rng.integers(-16, 16))
        top = 20 + int(rng.integers(0, 14))
        d.polygon([(x, top + 14), (x + 11, top), (x + 21, top + 14), (x + 21, h), (x, h)], fill=(96 + t, 72 + t, 46 + t // 2))
        d.line([(x, top + 14), (x, h)], fill=(56, 40, 24), width=2)
    d.rectangle([70, 70, 186, h], fill=(110, 84, 54))
    for y in range(80, h, 26):
        d.line([(70, y), (186, y)], fill=(70, 52, 32), width=3)
    d.line([(70, 70), (186, h)], fill=(70, 52, 32), width=6)
    img.save(OUT / "causeway_gate.png")
    # Thatch: layered reed ends.
    n = tile_noise(w, h, 8, 905, 4)
    rgb = np.stack([128 + n * 50, 108 + n * 44, 62 + n * 26], -1)
    img = to_img(rgb)
    d = ImageDraw.Draw(img)
    for y in range(0, h, 18):
        for x in range(0, w, 3):
            ln = int(rng.integers(6, 16))
            c = int(rng.integers(-30, 20))
            d.line([(x, y), (x + 1, y + ln)], fill=(110 + c, 92 + c, 52 + c // 2), width=1)
        d.line([(0, y), (w, y)], fill=(84, 68, 38), width=2)
    img.save(OUT / "thatch.png")
    # Boardwalk: weathered grey planks across the walk, with gaps of dark water between.
    w2 = h2 = 128
    n = tile_noise(w2, h2, 3, 906, 5)
    grain = tile_noise(w2, h2, 24, 907, 2)
    rgb = np.stack([112 + n * 40 + grain * 16, 104 + n * 36 + grain * 14, 88 + n * 28 + grain * 10], -1)
    img = to_img(rgb)
    d = ImageDraw.Draw(img)
    for y in range(0, h2, 21):
        d.rectangle([0, y, w2, y + 2], fill=(28, 34, 30))
        for x in (int(rng.integers(10, 50)), int(rng.integers(70, 118))):
            d.ellipse([x - 2, y + 9, x + 2, y + 13], fill=(60, 54, 46))
    img.save(OUT / "boardwalk.png")
    # Marsh water: dark, greenish-brown, with a little scum and a few lily pads.
    n = tile_noise(w, h, 4, 908, 5)
    scum = tile_noise(w, h, 12, 909, 3)
    rgb = np.stack([34 + n * 30 + np.where(scum > 0.66, 30, 0), 46 + n * 34 + np.where(scum > 0.66, 38, 0), 38 + n * 24], -1)
    img = to_img(rgb)
    d = ImageDraw.Draw(img)
    for _ in range(9):
        x, y, r = int(rng.integers(10, 246)), int(rng.integers(10, 246)), int(rng.integers(6, 12))
        d.pieslice([x - r, y - r, x + r, y + r], 30, 360, fill=(62, 104, 52))
    img.save(OUT / "marsh_water.png")


# ---------------------------------------------------------------- the Drowned Shrine's grounds

def _vines(img, seed, density=1.0):
    """Ivy and creepers trailing down over a wall, thicker towards the top."""
    rng = np.random.default_rng(seed)
    d = ImageDraw.Draw(img)
    w, h = img.size
    for _ in range(int(14 * density)):
        x = float(rng.integers(0, w))
        y = 0.0
        length = int(rng.integers(h // 3, h))
        pts = []
        while y < length:
            pts.append((x, y))
            x += float(rng.normal(0, 3))
            y += 6
        d.line(pts, fill=(54, 70, 34), width=3)
        for (px, py) in pts[::2]:
            for _ in range(2):
                ox, oy = int(rng.integers(-9, 9)), int(rng.integers(-5, 5))
                g = int(rng.integers(-20, 30))
                d.ellipse([px + ox - 5, py + oy - 3, px + ox + 5, py + oy + 3], fill=(62 + g, 98 + g, 44 + g // 2))
    return img


def _sigil(d, kind, cx, cy, r, col, width=5):
    if kind == "crown":
        pts = [(cx - r, cy + r * 0.6), (cx - r, cy - r * 0.2), (cx - r * 0.5, cy + r * 0.2), (cx, cy - r * 0.7),
               (cx + r * 0.5, cy + r * 0.2), (cx + r, cy - r * 0.2), (cx + r, cy + r * 0.6)]
        d.line(pts + [pts[0]], fill=col, width=width)
    elif kind == "chain":
        for k in (-1, 0, 1):
            d.ellipse([cx + k * r * 0.65 - r * 0.45, cy - r * 0.3, cx + k * r * 0.65 + r * 0.45, cy + r * 0.3], outline=col, width=width)
    else:  # wave: the drowning
        for k in (-1, 0, 1):
            yy = cy + k * r * 0.45
            pts = [(cx - r + i * r / 6, yy + np.sin(i * 1.3) * r * 0.15) for i in range(13)]
            d.line(pts, fill=col, width=width)


def shrine_textures():
    w = h = 256
    # Old fitted blocks, green with moss low down, vines from the top.
    base = blocks(w, h, 4, 3, 950, mortar=4, base=(104, 104, 92), jitter=14)
    arr = np.array(base).astype(float)
    moss = tile_noise(w, h, 6, 951, 4)
    ys = np.linspace(0, 1, h)[:, None]
    m = np.clip((moss - 0.45) * 2.5 + (ys - 0.6), 0, 1)[..., None] * 0.7
    arr = arr * (1 - m) + np.array([66, 92, 50]) * m
    wall = _vines(to_img(arr), 952)
    wall.save(OUT / "vine_wall.png")
    # Wet flagstones with mud in the joints and puddles.
    w2 = h2 = 128
    fl = blocks(w2, h2, 3, 3, 953, mortar=5, base=(86, 84, 66), jitter=14)
    arr = np.array(fl).astype(float)
    mud = tile_noise(w2, h2, 5, 954, 4)
    pud = (mud > 0.66)[..., None]
    green = tile_noise(w2, h2, 7, 959, 3)[..., None]
    arr = arr * (1 - 0.35 * green) + np.array([60, 78, 44]) * 0.35 * green
    arr = np.where(pud, arr * 0.5 + np.array([32, 42, 36]) * 0.5, arr * (0.85 + 0.25 * mud[..., None]))
    to_img(arr).save(OUT / "shrine_floor.png")
    # The sunken door: a slab of dark stone in a frame, three empty sockets, water stains.
    img = blocks(w, h, 4, 3, 955, mortar=4, base=(98, 100, 90), jitter=10)
    d = ImageDraw.Draw(img)
    d.rectangle([52, 40, 204, h], fill=(48, 52, 50))
    d.rectangle([52, 40, 204, h], outline=(30, 32, 30), width=6)
    d.line([(128, 40), (128, h)], fill=(30, 32, 30), width=3)
    for i, kind in enumerate(("crown", "chain", "wave")):
        cx = 84 + i * 44
        d.ellipse([cx - 16, 108, cx + 16, 140], fill=(24, 26, 26), outline=(80, 84, 78), width=3)
    _sigil(d, "crown", 128, 70, 18, (84, 90, 84), 3)
    door_closed = _vines(img, 956, 0.5)
    door_closed.save(OUT / "shrine_door.png")
    img = blocks(w, h, 4, 3, 955, mortar=4, base=(98, 100, 90), jitter=10)
    d = ImageDraw.Draw(img)
    d.rectangle([52, 40, 204, h], fill=(8, 10, 12))
    for k in range(5):   # steps going down into the dark
        y = h - 20 - k * 22
        d.rectangle([60 + k * 6, y, 196 - k * 6, y + 10], fill=(70 - k * 10, 72 - k * 10, 66 - k * 10))
    d.rectangle([52, 40, 204, h], outline=(30, 32, 30), width=6)
    _vines(img, 956, 0.5).save(OUT / "shrine_door_open.png")
    # The carving: three panels, the story in order (crown, chain, wave), with little figures.
    img = blocks(w, h, 4, 3, 957, mortar=4, base=(110, 108, 96), jitter=10)
    d = ImageDraw.Draw(img)
    groove = (52, 54, 50)
    for i, kind in enumerate(("crown", "chain", "wave")):
        x0 = 14 + i * 80
        d.rectangle([x0, 60, x0 + 70, 196], outline=groove, width=4)
        _sigil(d, kind, x0 + 35, 96, 22, groove, 5)
        for k in range(3):   # little figures under each sign
            fx = x0 + 14 + k * 21
            d.ellipse([fx - 4, 142, fx + 4, 150], outline=groove, width=2)
            d.line([(fx, 150), (fx, 172)], fill=groove, width=2)
            if kind == "wave":
                d.line([(fx - 8, 166), (fx + 8, 166)], fill=groove, width=2)
    _vines(img, 958, 0.4).save(OUT / "shrine_carving.png")


def _sign(d, kind, cx, cy, r, col, width=5):
    """The signs cut into the flooded hall's stepping stones and the temple's carvings."""
    if kind in ("crown", "chain", "wave"):
        _sigil(d, kind, cx, cy, r, col, width)
    elif kind == "rose":
        for k in range(5):
            a = k * 2 * np.pi / 5
            px, py = cx + np.cos(a) * r * 0.45, cy - r * 0.2 + np.sin(a) * r * 0.45
            d.ellipse([px - r * 0.35, py - r * 0.35, px + r * 0.35, py + r * 0.35], outline=col, width=max(2, width - 2))
        d.ellipse([cx - r * 0.18, cy - r * 0.38, cx + r * 0.18, cy - r * 0.02], outline=col, width=max(2, width - 2))
        d.line([(cx, cy + r * 0.25), (cx, cy + r)], fill=col, width=width)
        d.line([(cx, cy + r * 0.6), (cx + r * 0.4, cy + r * 0.4)], fill=col, width=width - 1)
    elif kind == "fire":
        for k, sc in ((-1, 0.7), (0, 1.0), (1, 0.7)):
            bx = cx + k * r * 0.5
            pts = [(bx - r * 0.3 * sc, cy + r * 0.8), (bx - r * 0.35 * sc, cy + r * 0.1), (bx - r * 0.05, cy - r * 0.4 * sc),
                   (bx + r * 0.05 * sc, cy - r * 0.95 * sc), (bx + r * 0.3 * sc, cy - r * 0.1), (bx + r * 0.3 * sc, cy + r * 0.8)]
            d.line(pts, fill=col, width=width)
        d.line([(cx - r, cy + r * 0.85), (cx + r, cy + r * 0.85)], fill=col, width=width)
    elif kind == "sun":
        d.ellipse([cx - r * 0.45, cy - r * 0.45, cx + r * 0.45, cy + r * 0.45], outline=col, width=width)
        for k in range(8):
            a = k * np.pi / 4
            d.line([(cx + np.cos(a) * r * 0.65, cy + np.sin(a) * r * 0.65), (cx + np.cos(a) * r, cy + np.sin(a) * r)], fill=col, width=width)
    elif kind == "sword":
        d.line([(cx, cy - r), (cx, cy + r * 0.55)], fill=col, width=width + 1)
        d.line([(cx - r * 0.45, cy + r * 0.45), (cx + r * 0.45, cy + r * 0.45)], fill=col, width=width)
        d.line([(cx, cy + r * 0.55), (cx, cy + r)], fill=col, width=width)
    elif kind == "tower":
        d.rectangle([cx - r * 0.4, cy - r * 0.5, cx + r * 0.4, cy + r], outline=col, width=width)
        for k in (-1, 0, 1):
            d.rectangle([cx + k * r * 0.3 - r * 0.1, cy - r * 0.8, cx + k * r * 0.3 + r * 0.1, cy - r * 0.5], outline=col, width=max(2, width - 2))
        d.rectangle([cx - r * 0.12, cy + r * 0.5, cx + r * 0.12, cy + r], fill=col)
    elif kind == "star":
        pts = []
        for k in range(10):
            a = -np.pi / 2 + k * np.pi / 5
            rr = r if k % 2 == 0 else r * 0.42
            pts.append((cx + np.cos(a) * rr, cy + np.sin(a) * rr))
        d.line(pts + [pts[0]], fill=col, width=width)


def temple_textures():
    w = h = 256
    # Dressed blocks, close-fitted, grey-green, stained dark where the water stood higher once.
    base = blocks(w, h, 5, 2, 970, mortar=3, base=(96, 102, 96), jitter=10)
    arr = np.array(base).astype(float)
    ys = np.linspace(0, 1, h)[:, None]
    stain = tile_noise(w, h, 5, 971, 4)
    m = np.clip((ys - 0.55) * 2.2 + (stain - 0.5) * 0.6, 0, 1)[..., None] * 0.55
    arr = arr * (1 - m) + np.array([40, 52, 46]) * m
    line = (np.abs(ys - 0.5) < 0.008)[..., None]   # an old high-water line
    arr = np.where(line, arr * 0.7, arr)
    wall = to_img(arr)
    wall.save(OUT / "temple_wall.png")
    fl = blocks(128, 128, 2, 2, 972, mortar=3, base=(88, 92, 84), jitter=10)
    fa = np.array(fl).astype(float)
    silt = tile_noise(128, 128, 6, 973, 4)[..., None]
    fa = fa * (0.8 + 0.3 * silt) * 0.6 + np.array([52, 58, 46]) * 0.4
    to_img(fa).save(OUT / "temple_floor.png")
    # The steps up to the grounds: a dark doorway, steps rising into grey daylight.
    img = wall.copy()
    d = ImageDraw.Draw(img)
    d.rectangle([56, 30, 200, h], fill=(150, 156, 146))
    for k in range(7):
        y0 = h - (k + 1) * 30
        sh = 20 + k * 18
        d.rectangle([56, y0, 200, y0 + 30], fill=(sh, sh + 4, sh))
        d.line([(56, y0), (200, y0)], fill=(min(255, sh + 50),) * 3, width=2)
    d.rectangle([56, 30, 200, h], outline=(40, 44, 40), width=6)
    img.save(OUT / "temple_steps.png")
    # The carvings of the king's reign. West, his glory: the crown and the rose, a crowd
    # kneeling, a woman turning away. East, his fall: flames over a city, the chain, the water.
    groove = (46, 52, 48)
    for name, panels in (("reign_west", ("crown", "rose")), ("reign_east", ("fire", "chain", "wave"))):
        img = blocks(w, h, 5, 2, 974 if name == "reign_west" else 975, mortar=3, base=(112, 116, 108), jitter=8)
        d = ImageDraw.Draw(img)
        n = len(panels)
        pw = (w - 20) // n
        for i, kind in enumerate(panels):
            x0 = 10 + i * pw
            d.rectangle([x0 + 4, 40, x0 + pw - 4, 214], outline=groove, width=4)
            _sign(d, kind, x0 + pw // 2, 90, 26 if n == 2 else 22, groove, 5)
            for k in range(3 if n == 2 else 2):
                fx = x0 + 22 + k * ((pw - 44) // max(1, (2 if n == 2 else 1)))
                d.ellipse([fx - 5, 150, fx + 5, 160], outline=groove, width=2)
                if kind == "crown":   # bowing
                    d.line([(fx, 160), (fx + 6, 176), (fx + 4, 196)], fill=groove, width=2)
                elif kind == "chain":
                    d.line([(fx, 160), (fx, 194)], fill=groove, width=2)
                    d.line([(fx - 8, 172), (fx + 8, 172)], fill=groove, width=3)
                else:
                    d.line([(fx, 160), (fx, 194)], fill=groove, width=2)
                    if kind == "wave":
                        d.line([(fx - 9, 178), (fx + 9, 178)], fill=groove, width=2)
        img.save(OUT / (name + ".png"))
    # The stepping stones' tops, one for each sign.
    for kind in ("crown", "rose", "fire", "chain", "sun", "sword", "tower", "star"):
        st = blocks(128, 128, 1, 1, 976, mortar=6, base=(104, 108, 100), jitter=4)
        sa = np.array(st).astype(float)
        moss = tile_noise(128, 128, 5, 977, 3)[..., None]
        sa = sa * (1 - 0.3 * moss) + np.array([60, 80, 54]) * 0.3 * moss
        img = to_img(sa)
        d = ImageDraw.Draw(img)
        d.ellipse([18, 18, 110, 110], outline=(58, 62, 56), width=3)
        _sign(d, kind, 64, 64, 30, (34, 38, 34), 6)
        img.save(OUT / ("stone_%s.png" % kind))


# ---------------------------------------------------------------- Aubermont (dark, gothic)

def _gothic(d, x0, y0, x1, y1, fill, frame, width=4, mullion=True):
    """A tall pointed-arch window or door: a rectangle under a pointed top."""
    mx = (x0 + x1) / 2
    top = y0 + (x1 - x0) * 0.75
    pts = [(x0, y1), (x0, top), (x0 + (x1 - x0) * 0.12, y0 + (top - y0) * 0.35), (mx, y0),
           (x1 - (x1 - x0) * 0.12, y0 + (top - y0) * 0.35), (x1, top), (x1, y1)]
    d.polygon(pts, fill=fill)
    d.line(pts + [pts[0]], fill=frame, width=width)
    if mullion:
        d.line([(mx, y0 + 6), (mx, y1)], fill=frame, width=max(2, width - 1))
        for yy in range(int(top), int(y1), 22):
            d.line([(x0, yy), (x1, yy)], fill=frame, width=2)


LIT = (236, 172, 86)
DARK_PANE = (22, 22, 28)


def aubermont_textures():
    w = h = 256
    soot = (50, 48, 50)
    timber = (30, 24, 22)
    for i in range(4):
        rng = np.random.default_rng(1100 + i)
        # Ground floor: soot-black stone, a pointed door, and a leaded window or a dim shop front.
        img = blocks(w, h, 6, 3, 1110 + i, mortar=3, base=soot, jitter=10)
        d = ImageDraw.Draw(img)
        if i % 2 == 0:
            _gothic(d, 26, 70, 104, h, (40, 28, 22), (20, 18, 18), 6, mullion=False)
            d.ellipse([86, 170, 94, 178], fill=(120, 100, 60))
            lit = rng.random() < 0.6
            _gothic(d, 140, 80, 220, 196, LIT if lit else DARK_PANE, (18, 16, 16), 5)
        else:
            d.rectangle([20, 70, 236, 190], fill=(26, 22, 22), outline=(16, 14, 14), width=6)
            for k in range(4):
                _gothic(d, 30 + k * 52, 82, 72 + k * 52, 180, LIT if (k + i) % 3 == 0 else DARK_PANE, (16, 14, 14), 3)
        img.save(OUT / f"aub_low_{i}.png")
        # Upper storey: dark timber framing over grimy plaster, tall gothic windows, some lit.
        rgb = _plaster(w, h, 1130 + i, (66, 62, 58))
        img = to_img(rgb)
        d = ImageDraw.Draw(img)
        for x in (0, 128, w - 1):
            d.line([(x, 0), (x, h)], fill=timber, width=12)
        d.line([(0, 6), (w, 6)], fill=timber, width=14)
        d.line([(0, h - 6), (w, h - 6)], fill=timber, width=14)
        for k in range(2):
            x0 = 10 + k * 128
            d.line([(x0, 250), (x0 + 30, 160)], fill=timber, width=7)
            d.line([(x0 + 108, 250), (x0 + 78, 160)], fill=timber, width=7)
        glow = Image.new("RGB", (w, h), (0, 0, 0))
        g = ImageDraw.Draw(glow)
        for k in range(2):
            x0 = 34 + k * 128
            lit = rng.random() < 0.25
            _gothic(d, x0, 30, x0 + 60, 200, LIT if lit else DARK_PANE, timber, 5)
            if lit:
                _gothic(g, x0, 30, x0 + 60, 200, (255, 200, 120), (0, 0, 0), 5)
        img.save(OUT / f"aub_up_{i}.png")
        glow.save(OUT / f"aub_up_{i}_glow.png")
    # Wet, dark cobbles: rounded stones with a sheen.
    rng = np.random.default_rng(1150)
    yy, xx = np.mgrid[0:h, 0:w]
    pts = rng.random((90, 2)) * w
    best = np.full((h, w), 1e9)
    second = np.full((h, w), 1e9)
    idx = np.zeros((h, w), int)
    for i, (px_, py_) in enumerate(pts):
        for ox in (-w, 0, w):
            for oy in (-h, 0, h):
                dd = np.hypot(xx - px_ - ox, yy - py_ - oy)
                closer = dd < best
                second = np.where(closer, best, np.minimum(second, dd))
                idx = np.where(closer, i, idx)
                best = np.where(closer, dd, best)
    edge = second - best
    tone = rng.normal(0, 1, len(pts))[idx]
    grain = tile_noise(w, h, 8, 1151, 4)
    base = 62 + tone * 8 + (grain - 0.5) * 20
    bevel = np.clip(edge / 6.0, 0, 1)
    v = base * (0.3 + 0.7 * bevel)
    to_img(np.stack([v * 0.98, v, v * 1.06], -1)).save(OUT / "aub_cobbles.png")
    # Dark slate.
    img = Image.new("RGB", (w, h), (34, 36, 42))
    d = ImageDraw.Draw(img)
    for r in range(8):
        y = r * 32
        off = 16 if r % 2 else 0
        for c in range(9):
            x = c * 32 - off
            t = int(rng.integers(-6, 7))
            d.rectangle([x + 1, y + 1, x + 30, y + 30], fill=(40 + t, 42 + t, 50 + t), outline=(22, 22, 26))
    img.save(OUT / "aub_slate.png")
    # A side wall where a taller house stands over a lower one: plain soot-black stone.
    blocks(w, h, 8, 3, 1160, mortar=3, base=(44, 42, 44), jitter=8).save(OUT / "aub_side.png")
    # The river gate: a deep arch with a raised portcullis, grey light beyond.
    img = blocks(w, h, 6, 3, 1170, mortar=3, base=(56, 54, 56), jitter=8)
    d = ImageDraw.Draw(img)
    _gothic(d, 40, 30, 216, h, (120, 124, 128), (24, 22, 22), 10, mullion=False)
    for x in range(56, 210, 18):
        d.line([(x, 40), (x, 92)], fill=(26, 24, 24), width=5)
    d.line([(46, 92), (210, 92)], fill=(26, 24, 24), width=6)
    img.save(OUT / "aub_gate.png")
    # The old town arch: a low, deep passage into darkness.
    img = blocks(w, h, 6, 3, 1171, mortar=3, base=(54, 52, 54), jitter=8)
    d = ImageDraw.Draw(img)
    _gothic(d, 50, 50, 206, h, (12, 12, 14), (24, 22, 22), 10, mullion=False)
    img.save(OUT / "aub_arch.png")
    # The hill gate: tall iron bars in a stone frame, a crest above, grey light beyond.
    img = blocks(w, h, 6, 3, 1172, mortar=3, base=(58, 56, 58), jitter=8)
    d = ImageDraw.Draw(img)
    d.rectangle([44, 60, 212, h], fill=(96, 100, 104))
    for x in range(52, 210, 16):
        d.line([(x, 60), (x, h)], fill=(18, 18, 20), width=5)
        d.polygon([(x - 5, 64), (x + 5, 64), (x, 50)], fill=(18, 18, 20))
    for y in (110, 200):
        d.line([(44, y), (212, y)], fill=(18, 18, 20), width=5)
    d.ellipse([110, 8, 146, 44], fill=(80, 74, 60), outline=(150, 130, 80), width=3)
    img.save(OUT / "aub_hill_gate.png")
    # The inn: a broad door, a lit window, and a hanging lantern sign.
    img = blocks(w, h, 6, 3, 1173, mortar=3, base=soot, jitter=10)
    d = ImageDraw.Draw(img)
    _gothic(d, 30, 90, 120, h, (48, 32, 24), (20, 18, 18), 6, mullion=False)
    _gothic(d, 150, 100, 226, 200, LIT, (18, 16, 16), 5)
    d.line([(150, 30), (230, 30)], fill=(20, 20, 20), width=4)
    d.line([(190, 30), (190, 46)], fill=(20, 20, 20), width=3)
    d.polygon([(178, 46), (202, 46), (198, 80), (182, 80)], fill=LIT, outline=(20, 20, 20))
    d.rectangle([176, 42, 204, 48], fill=(20, 20, 20))
    img.save(OUT / "aub_inn.png")
    inn_glow = Image.new("RGB", (w, h), (0, 0, 0))
    g = ImageDraw.Draw(inn_glow)
    _gothic(g, 150, 100, 226, 200, (255, 200, 120), (0, 0, 0), 5)
    g.polygon([(178, 46), (202, 46), (198, 80), (182, 80)], fill=(255, 210, 130))
    inn_glow.save(OUT / "aub_inn_glow.png")
    # The shop: a dim front of small panes, a sign with a blade and a sack.
    img = blocks(w, h, 6, 3, 1174, mortar=3, base=soot, jitter=10)
    d = ImageDraw.Draw(img)
    d.rectangle([20, 80, 150, 200], fill=(26, 22, 22), outline=(16, 14, 14), width=6)
    for k in range(3):
        _gothic(d, 30 + k * 40, 90, 64 + k * 40, 190, LIT if k == 1 else DARK_PANE, (16, 14, 14), 3)
    _gothic(d, 170, 90, 236, h, (44, 30, 22), (20, 18, 18), 6, mullion=False)
    d.rectangle([40, 20, 216, 62], fill=(40, 30, 22), outline=(140, 110, 60), width=3)
    d.line([(80, 54), (110, 28)], fill=(190, 190, 200), width=5)
    d.ellipse([140, 30, 176, 58], fill=(150, 120, 70))
    img.save(OUT / "aub_shop.png")


# ---------------------------------------------------------------- inn interiors (the inn screen)

FIRE_BOX = (34, 120, 96, 168)   # the hearth opening in the 280x226 picture (the screen animates flames there)


def _inn_interior(name, wall, beam, floor, stone, window, lanterns):
    W, H = 280, 226
    img = Image.new("RGB", (W, H), (0, 0, 0))
    d = ImageDraw.Draw(img)
    horizon = 150   # where the back wall meets the floor
    # Back wall, and the side walls receding.
    rgb = _plaster(W, horizon, 1300 + len(name), wall)
    img.paste(to_img(rgb), (0, 0))
    d.polygon([(0, 0), (40, 24), (40, horizon), (0, H)], fill=tuple(int(c * 0.7) for c in wall))
    d.polygon([(W, 0), (W - 40, 24), (W - 40, horizon), (W, H)], fill=tuple(int(c * 0.6) for c in wall))
    # Floor planks in perspective.
    d.polygon([(0, H), (40, horizon), (W - 40, horizon), (W, H)], fill=floor)
    for k in range(-6, 7):
        d.line([(W / 2 + k * 18, horizon), (W / 2 + k * 60, H)], fill=tuple(int(c * 0.7) for c in floor), width=2)
    for y in (162, 178, 200):
        d.line([(0, y), (W, y)], fill=tuple(int(c * 0.82) for c in floor), width=1)
    # Ceiling beams.
    for y in (6, 18):
        d.rectangle([0, y, W, y + 7], fill=beam)
    for x in (60, 140, 220):
        d.line([(x, 0), (x, horizon)], fill=beam, width=6)
    # A window on the back wall.
    wx = 150
    if window == "gothic":
        _gothic(d, wx, 40, wx + 34, 104, (30, 40, 70), beam, 3)
        d.ellipse([wx + 20, 48, wx + 28, 56], fill=(200, 210, 230))   # the moon
    else:
        d.rectangle([wx, 46, wx + 40, 96], fill=(120, 150, 190), outline=beam, width=4)
        d.line([(wx + 20, 46), (wx + 20, 96)], fill=beam, width=3)
        d.line([(wx, 71), (wx + 40, 71)], fill=beam, width=3)
    # The hearth: a stone chimney breast with a dark opening, logs and a glow (the screen adds flames).
    x0, y0, x1, y1 = FIRE_BOX
    d.rectangle([x0 - 16, 30, x1 + 16, horizon + 4], fill=stone)
    for yy in range(34, horizon, 12):
        off = 0 if (yy // 12) % 2 else 10
        for xx in range(x0 - 16 + off, x1 + 16, 20):
            d.rectangle([xx, yy, xx + 18, yy + 10], outline=tuple(int(c * 0.75) for c in stone))
    d.rectangle([x0 - 22, y0 - 14, x1 + 22, y0 - 6], fill=beam)   # the mantel
    d.rectangle([x0, y0, x1, y1], fill=(20, 12, 8))
    for k in range(3):
        d.rectangle([x0 + 8 + k * 6, y1 - 10 + (k % 2) * 3, x1 - 8 - k * 4, y1 - 4 + (k % 2) * 3], fill=(70, 40, 20))
    glow = Image.new("RGB", (W, H), (0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse([x0 - 60, y0 - 30, x1 + 90, H + 40], fill=(90, 50, 18))
    glow = glow.filter(ImageFilter.GaussianBlur(28))
    img = Image.fromarray(np.clip(np.array(img, float) + np.array(glow, float), 0, 255).astype(np.uint8))
    d = ImageDraw.Draw(img)
    # Things on the mantel.
    d.rectangle([x0 - 8, y0 - 24, x0 - 2, y0 - 14], fill=(170, 150, 120))
    d.ellipse([x1 - 4, y0 - 26, x1 + 8, y0 - 14], fill=(110, 80, 50))
    # The bar: a counter on the right, shelves of bottles and barrels behind it.
    bx = 196
    d.rectangle([bx, 60, W - 44, 64], fill=beam)
    d.rectangle([bx, 84, W - 44, 88], fill=beam)
    for k in range(6):
        col = [(60, 90, 50), (110, 50, 40), (60, 60, 100), (140, 110, 50)][k % 4]
        d.rectangle([bx + 4 + k * 6, 48, bx + 8 + k * 6, 60], fill=col)
        d.rectangle([bx + 6 + k * 6, 72, bx + 10 + k * 6, 84], fill=col)
    for k in range(2):
        d.ellipse([bx + 2 + k * 18, 100, bx + 18 + k * 18, 122], fill=(100, 66, 36), outline=beam)
    d.polygon([(bx - 10, 128), (W - 20, 128), (W - 8, 176), (bx - 26, 176)], fill=tuple(int(c * 1.1) for c in beam))
    d.rectangle([bx - 26, 124, W - 8, 132], fill=tuple(min(255, int(c * 1.5)) for c in beam))
    for k in range(3):
        d.rectangle([bx - 6 + k * 22, 116, bx + 2 + k * 22, 124], fill=(200, 170, 110))   # mugs
    # Tables with candles, and stools.
    for (cx, cy, r) in ((130, 178, 30), (70, 204, 36)):
        d.ellipse([cx - r, cy - r * 0.35, cx + r, cy + r * 0.35], fill=tuple(min(255, int(c * 1.3)) for c in beam))
        d.rectangle([cx - 4, cy, cx + 4, cy + r * 0.9], fill=beam)
        d.rectangle([cx - 1, cy - 16, cx + 1, cy - 6], fill=(230, 220, 190))
        d.ellipse([cx - 3, cy - 22, cx + 3, cy - 15], fill=(255, 210, 110))
        for sx in (-r - 10, r + 4):
            d.rectangle([cx + sx, cy + 4, cx + sx + 8, cy + 8], fill=beam)
            d.line([(cx + sx + 4, cy + 8), (cx + sx + 4, cy + 26)], fill=beam, width=2)
    # Hanging lanterns.
    for lx in lanterns:
        d.line([(lx, 25), (lx, 40)], fill=(20, 20, 20), width=1)
        d.rectangle([lx - 4, 40, lx + 4, 50], fill=(255, 200, 110), outline=(30, 26, 20))
    img.save(OUT / (name + ".png"))


def inn_interiors():
    _inn_interior("inn_lehan", wall=(196, 170, 130), beam=(70, 46, 26), floor=(120, 84, 50), stone=(130, 120, 108),
                  window="square", lanterns=[100, 250])
    _inn_interior("inn_lamplighter", wall=(70, 64, 60), beam=(34, 26, 22), floor=(64, 48, 36), stone=(66, 64, 66),
                  window="gothic", lanterns=[100, 180, 250])


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
    council_house()
    warehouse_front()
    tannery_front()
    carved_stone()
    print("wrote textures to", OUT)
    mines_textures()
    marsh_textures()
    shrine_textures()
    temple_textures()
    aubermont_textures()
    inn_interiors()
