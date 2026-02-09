#!/usr/bin/env python3
"""
Generate TGA rune textures and a stone background for RuneMagic Castbars.

Runes are single continuous angular lines (Dwarven style) rendered as
white glyphs on transparent background. WoW colorizes via SetVertexColor.

Output: 256x128 32-bit uncompressed TGA files in Media/
"""

import math
import os
import random
import struct

WIDTH = 256
HEIGHT = 128


def make_image(fill=None):
    """Return a WIDTH x HEIGHT image. fill = [B,G,R,A] or None for transparent."""
    if fill:
        return [[list(fill) for _ in range(WIDTH)] for _ in range(HEIGHT)]
    return [[[0, 0, 0, 0] for _ in range(WIDTH)] for _ in range(HEIGHT)]


def plot(img, x, y, r, g, b, alpha):
    """Plot a pixel with alpha blending."""
    ix, iy = int(round(x)), int(round(y))
    if 0 <= ix < WIDTH and 0 <= iy < HEIGHT:
        old_a = img[iy][ix][3]
        new_a = min(255, int(alpha))
        if new_a > old_a:
            img[iy][ix] = [b, g, r, new_a]


def plot_white(img, x, y, alpha):
    plot(img, x, y, 255, 255, 255, alpha)


def draw_line(img, x0, y0, x1, y1, thickness=4.0, color=None):
    """Draw an antialiased thick line between two points."""
    dx = x1 - x0
    dy = y1 - y0
    length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001:
        return

    steps = int(length * 3) + 1
    half_t = thickness / 2.0

    nx = -dy / length
    ny = dx / length

    cr, cg, cb = color if color else (255, 255, 255)

    for i in range(steps + 1):
        t = i / steps
        cx = x0 + dx * t
        cy = y0 + dy * t

        for j in range(-int(half_t + 2), int(half_t + 3)):
            px = cx + nx * j
            py = cy + ny * j
            dist = abs(j)
            if dist <= half_t - 0.5:
                plot(img, px, py, cr, cg, cb, 255)
            elif dist <= half_t + 0.5:
                aa = 255 * (half_t + 0.5 - dist)
                plot(img, px, py, cr, cg, cb, aa)


def draw_polyline(img, points, thickness=4.0):
    """Draw a single continuous line through a list of (x, y) points."""
    for i in range(len(points) - 1):
        draw_line(img, points[i][0], points[i][1],
                  points[i + 1][0], points[i + 1][1], thickness)


def norm(x_frac, y_frac):
    """Convert normalized (0-1) coords to pixel coords."""
    return x_frac * (WIDTH - 1), y_frac * (HEIGHT - 1)


def write_tga(filepath, img, width=WIDTH, height=HEIGHT):
    """Write a 32-bit uncompressed TGA file."""
    with open(filepath, "wb") as f:
        f.write(struct.pack("<B", 0))       # ID length
        f.write(struct.pack("<B", 0))       # Color map type
        f.write(struct.pack("<B", 2))       # Image type: uncompressed true-color
        f.write(b"\x00" * 5)               # Color map spec
        f.write(struct.pack("<H", 0))       # X origin
        f.write(struct.pack("<H", 0))       # Y origin
        f.write(struct.pack("<H", width))   # Width
        f.write(struct.pack("<H", height))  # Height
        f.write(struct.pack("<B", 32))      # Bits per pixel
        f.write(struct.pack("<B", 0x28))    # Image descriptor

        for row in img:
            for pixel in row:
                f.write(struct.pack("BBBB", pixel[0], pixel[1], pixel[2], pixel[3]))


# =====================================================================
# Stone background texture
# =====================================================================

def generate_stone():
    """Generate a dark stone/granite background texture."""
    img = make_image()
    rng = random.Random(42)  # deterministic

    # Base: dark gray stone
    for y in range(HEIGHT):
        for x in range(WIDTH):
            # Base gray with subtle variation
            base = rng.randint(28, 42)
            # Add larger-scale variation (simulate stone grain)
            grain = int(8 * math.sin(x * 0.05 + y * 0.03))
            grain += int(5 * math.sin(x * 0.12 - y * 0.07))
            v = max(0, min(255, base + grain))
            img[y][x] = [v, v, v, 255]

    # Add some lighter speckles (mineral flecks)
    for _ in range(600):
        sx = rng.randint(0, WIDTH - 1)
        sy = rng.randint(0, HEIGHT - 1)
        brightness = rng.randint(50, 70)
        img[sy][sx] = [brightness, brightness, brightness, 255]

    # Add subtle cracks / darker lines
    for _ in range(8):
        cx = rng.randint(0, WIDTH - 1)
        cy = rng.randint(0, HEIGHT - 1)
        angle = rng.uniform(0, math.pi)
        crack_len = rng.randint(15, 50)
        for step in range(crack_len):
            px = int(cx + step * math.cos(angle))
            py = int(cy + step * math.sin(angle))
            if 0 <= px < WIDTH and 0 <= py < HEIGHT:
                v = max(0, img[py][px][0] - rng.randint(8, 18))
                img[py][px] = [v, v, v, 255]
            # Slight angle drift
            angle += rng.uniform(-0.15, 0.15)

    # Chisel edges: lighter top/left pixel row, darker bottom/right
    for x in range(WIDTH):
        v = min(255, img[0][x][0] + 12)
        img[0][x] = [v, v, v, 255]
        v = max(0, img[HEIGHT - 1][x][0] - 10)
        img[HEIGHT - 1][x] = [v, v, v, 255]
    for y in range(HEIGHT):
        v = min(255, img[y][0][0] + 10)
        img[y][0] = [v, v, v, 255]
        v = max(0, img[y][WIDTH - 1][0] - 8)
        img[y][WIDTH - 1] = [v, v, v, 255]

    return img


# =====================================================================
# Rune definitions — single continuous angular polylines
# Matching reference: simple angular strokes, no decorations
# =====================================================================

def rune_thurisaz():
    """Rune 1: diagonal up-right, flat across top, diagonal down — angular arch."""
    img = make_image()
    t = 5.0
    points = [
        norm(0.05, 0.85),   # start bottom-left
        norm(0.20, 0.15),   # up to top
        norm(0.55, 0.15),   # across the top
        norm(0.55, 0.50),   # down to mid
        norm(0.75, 0.50),   # right along middle
        norm(0.90, 0.15),   # up-right diagonal
    ]
    draw_polyline(img, points, t)
    return img


def rune_kenaz():
    """Rune 2: gate/doorway shape — up, across, down, with step."""
    img = make_image()
    t = 5.0
    points = [
        norm(0.05, 0.85),   # start bottom-left
        norm(0.05, 0.15),   # up left side
        norm(0.45, 0.15),   # across the top
        norm(0.45, 0.55),   # down to mid
        norm(0.55, 0.55),   # small step right
        norm(0.55, 0.85),   # down to bottom
        norm(0.90, 0.85),   # extend right along bottom
    ]
    draw_polyline(img, points, t)
    return img


def rune_dagaz():
    """Rune 3: angular zigzag / stepped shape."""
    img = make_image()
    t = 5.0
    points = [
        norm(0.05, 0.85),   # start bottom-left
        norm(0.25, 0.15),   # diagonal up-right
        norm(0.50, 0.15),   # flat across top
        norm(0.50, 0.55),   # down to middle
        norm(0.65, 0.55),   # step right
        norm(0.90, 0.15),   # diagonal up-right to end
    ]
    draw_polyline(img, points, t)
    return img


def rune_algiz():
    """Rune 4: sharp angled check / arrow shape."""
    img = make_image()
    t = 5.0
    points = [
        norm(0.05, 0.15),   # start top-left
        norm(0.30, 0.85),   # diagonal down to bottom
        norm(0.55, 0.85),   # flat along bottom
        norm(0.90, 0.15),   # long diagonal up-right
    ]
    draw_polyline(img, points, t)
    return img


# =====================================================================
# Main
# =====================================================================

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "..", "Media")
    os.makedirs(out_dir, exist_ok=True)

    runes = [
        ("Rune_Thurisaz", rune_thurisaz),
        ("Rune_Kenaz", rune_kenaz),
        ("Rune_Dagaz", rune_dagaz),
        ("Rune_Algiz", rune_algiz),
    ]

    for name, func in runes:
        img = func()
        path = os.path.join(out_dir, name + ".tga")
        write_tga(path, img)
        print(f"Wrote {path}")

    # Stone background
    stone = generate_stone()
    path = os.path.join(out_dir, "StoneBg.tga")
    write_tga(path, stone)
    print(f"Wrote {path}")

    print("Done.")
