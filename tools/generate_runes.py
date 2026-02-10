#!/usr/bin/env python3
"""
Generate TGA rune textures for RuneMagic Castbars.

8 Dwarven runes matching the reference art style: clean lines with
circles, diamonds, and angular strokes. White on transparent — WoW
colorizes at runtime via SetVertexColor.

Output: 256x128 32-bit uncompressed TGA files in Media/
"""

import math
import os
import struct

WIDTH = 256
HEIGHT = 128
T = 4.0  # default stroke thickness


def make_image():
    return [[[0, 0, 0, 0] for _ in range(WIDTH)] for _ in range(HEIGHT)]


def plot(img, x, y, r, g, b, alpha):
    ix, iy = int(round(x)), int(round(y))
    if 0 <= ix < WIDTH and 0 <= iy < HEIGHT:
        old_a = img[iy][ix][3]
        new_a = min(255, int(alpha))
        if new_a > old_a:
            img[iy][ix] = [b, g, r, new_a]


def draw_line(img, x0, y0, x1, y1, thickness=T):
    dx = x1 - x0
    dy = y1 - y0
    length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001:
        return
    steps = int(length * 3) + 1
    half_t = thickness / 2.0
    nx = -dy / length
    ny = dx / length
    for i in range(steps + 1):
        t = i / steps
        cx = x0 + dx * t
        cy = y0 + dy * t
        for j in range(-int(half_t + 2), int(half_t + 3)):
            px = cx + nx * j
            py = cy + ny * j
            dist = abs(j)
            if dist <= half_t - 0.5:
                plot(img, px, py, 255, 255, 255, 255)
            elif dist <= half_t + 0.5:
                aa = 255 * (half_t + 0.5 - dist)
                plot(img, px, py, 255, 255, 255, aa)


def draw_circle(img, cx, cy, radius, thickness=T):
    """Draw a circle outline."""
    circumference = 2 * math.pi * radius
    steps = max(int(circumference * 3), 60)
    half_t = thickness / 2.0
    for i in range(steps + 1):
        angle = 2 * math.pi * i / steps
        x = cx + radius * math.cos(angle)
        y = cy + radius * math.sin(angle)
        for d in range(-int(half_t + 1), int(half_t + 2)):
            px = x + d * math.cos(angle)
            py = y + d * math.sin(angle)
            dist = abs(d)
            if dist <= half_t - 0.5:
                plot(img, px, py, 255, 255, 255, 255)
            elif dist <= half_t + 0.5:
                aa = 255 * (half_t + 0.5 - dist)
                plot(img, px, py, 255, 255, 255, aa)


def draw_diamond(img, cx, cy, size, thickness=T):
    """Draw a diamond (rotated square) outline."""
    top = (cx, cy - size)
    right = (cx + size, cy)
    bottom = (cx, cy + size)
    left = (cx - size, cy)
    draw_line(img, *top, *right, thickness)
    draw_line(img, *right, *bottom, thickness)
    draw_line(img, *bottom, *left, thickness)
    draw_line(img, *left, *top, thickness)


def n(x_frac, y_frac):
    """Normalized coords to pixels. y=0 is top."""
    return x_frac * (WIDTH - 1), y_frac * (HEIGHT - 1)


def write_tga(filepath, img):
    with open(filepath, "wb") as f:
        f.write(struct.pack("<B", 0))
        f.write(struct.pack("<B", 0))
        f.write(struct.pack("<B", 2))
        f.write(b"\x00" * 5)
        f.write(struct.pack("<H", 0))
        f.write(struct.pack("<H", 0))
        f.write(struct.pack("<H", WIDTH))
        f.write(struct.pack("<H", HEIGHT))
        f.write(struct.pack("<B", 32))
        f.write(struct.pack("<B", 0x28))
        for row in img:
            for pixel in row:
                f.write(struct.pack("BBBB", pixel[0], pixel[1], pixel[2], pixel[3]))


# =====================================================================
# 8 Runes matching the reference image
# =====================================================================

def rune_birth():
    """Birth: circle atop a vertical line."""
    img = make_image()
    cx, cy = n(0.50, 0.22)
    draw_circle(img, cx, cy, 14, T)
    # Vertical line from circle down
    draw_line(img, *n(0.50, 0.33), *n(0.50, 0.92), T)
    # Small horizontal bar through circle
    draw_line(img, *n(0.42, 0.22), *n(0.58, 0.22), T)
    return img


def rune_protection():
    """Protection: diamond atop a vertical line with horizontal bar."""
    img = make_image()
    cx, cy = n(0.50, 0.25)
    draw_diamond(img, cx, cy, 16, T)
    # Vertical line below diamond
    draw_line(img, *n(0.50, 0.38), *n(0.50, 0.92), T)
    # Horizontal bar through middle of diamond
    draw_line(img, *n(0.35, 0.25), *n(0.65, 0.25), T)
    return img


def rune_war():
    """War: upward arrow / arrowhead atop a vertical line."""
    img = make_image()
    # Vertical shaft
    draw_line(img, *n(0.50, 0.92), *n(0.50, 0.25), T)
    # Arrowhead left
    draw_line(img, *n(0.50, 0.25), *n(0.32, 0.42), T)
    # Arrowhead right
    draw_line(img, *n(0.50, 0.25), *n(0.68, 0.42), T)
    # Horizontal bar connecting arrowhead bases
    draw_line(img, *n(0.35, 0.40), *n(0.65, 0.40), T)
    return img


def rune_healing():
    """Healing: T-fork / trident top with vertical line, crescent."""
    img = make_image()
    # Vertical line
    draw_line(img, *n(0.50, 0.30), *n(0.50, 0.92), T)
    # Top horizontal bar
    draw_line(img, *n(0.32, 0.18), *n(0.68, 0.18), T)
    # Left prong up
    draw_line(img, *n(0.35, 0.18), *n(0.35, 0.10), T)
    # Right prong up
    draw_line(img, *n(0.65, 0.18), *n(0.65, 0.10), T)
    # Small crescent/arc at top center
    for i in range(40):
        angle = math.pi + math.pi * i / 39
        x = n(0.50, 0)[0] + 10 * math.cos(angle)
        y = n(0, 0.10)[1] + 10 * math.sin(angle)
        plot(img, x, y, 255, 255, 255, 255)
        plot(img, x, y - 1, 255, 255, 255, 200)
        plot(img, x, y + 1, 255, 255, 255, 200)
    return img


def rune_love():
    """Love: two small circles as eyes, vertical line, horizontal bar."""
    img = make_image()
    # Left eye circle
    draw_circle(img, *n(0.38, 0.22), 8, 3.0)
    # Right eye circle
    draw_circle(img, *n(0.62, 0.22), 8, 3.0)
    # Dots inside eyes
    draw_circle(img, *n(0.38, 0.22), 2, 2.5)
    draw_circle(img, *n(0.62, 0.22), 2, 2.5)
    # Vertical line down center
    draw_line(img, *n(0.50, 0.32), *n(0.50, 0.92), T)
    # Horizontal bar
    draw_line(img, *n(0.38, 0.38), *n(0.62, 0.38), T)
    return img


def rune_strength():
    """Strength: X cross with vertical line, like a star/asterisk."""
    img = make_image()
    cx, cy = n(0.50, 0.35)
    size = 18
    # Vertical line full height
    draw_line(img, *n(0.50, 0.10), *n(0.50, 0.92), T)
    # X through center
    draw_line(img, cx - size, cy - size, cx + size, cy + size, T)
    draw_line(img, cx - size, cy + size, cx + size, cy - size, T)
    # Horizontal through center
    draw_line(img, cx - size, cy, cx + size, cy, T)
    return img


def rune_return():
    """Return: trident / three prongs spreading upward from base."""
    img = make_image()
    # Center vertical (full)
    draw_line(img, *n(0.50, 0.92), *n(0.50, 0.10), T)
    # Left prong curving out
    draw_line(img, *n(0.50, 0.50), *n(0.30, 0.10), T)
    # Right prong curving out
    draw_line(img, *n(0.50, 0.50), *n(0.70, 0.10), T)
    return img


def rune_death():
    """Death: vertical line with horizontal bars / cross marks."""
    img = make_image()
    # Vertical line
    draw_line(img, *n(0.50, 0.10), *n(0.50, 0.92), T)
    # Top horizontal bar
    draw_line(img, *n(0.35, 0.22), *n(0.65, 0.22), T)
    # Three short horizontal marks on right side
    draw_line(img, *n(0.55, 0.42), *n(0.70, 0.42), 3.0)
    draw_line(img, *n(0.55, 0.52), *n(0.70, 0.52), 3.0)
    draw_line(img, *n(0.55, 0.62), *n(0.70, 0.62), 3.0)
    # Small circle near top
    draw_circle(img, *n(0.50, 0.15), 6, 3.0)
    return img


# =====================================================================
# Main
# =====================================================================

if __name__ == "__main__":
    out_dir = os.path.join(os.path.dirname(__file__), "..", "Media")
    os.makedirs(out_dir, exist_ok=True)

    runes = [
        ("Rune_Birth", rune_birth),
        ("Rune_Protection", rune_protection),
        ("Rune_War", rune_war),
        ("Rune_Healing", rune_healing),
        ("Rune_Love", rune_love),
        ("Rune_Strength", rune_strength),
        ("Rune_Return", rune_return),
        ("Rune_Death", rune_death),
    ]

    for name, func in runes:
        img = func()
        path = os.path.join(out_dir, name + ".tga")
        write_tga(path, img)
        print(f"Wrote {path}")

    print("Done.")
