#!/usr/bin/env python3
"""
Generate TGA rune textures for RuneMagic Castbars.

Each rune is rendered as a white glyph (with antialiased edges) on a
transparent background. WoW colorizes them at runtime via SetVertexColor.

Output: 256x64 32-bit uncompressed TGA files in Media/
"""

import math
import os
import struct

WIDTH = 256
HEIGHT = 64


def make_image():
    """Return a WIDTH x HEIGHT image as a list of rows, each row a list of [B,G,R,A]."""
    return [[[0, 0, 0, 0] for _ in range(WIDTH)] for _ in range(HEIGHT)]


def plot(img, x, y, alpha):
    """Plot a pixel with alpha blending (white color, variable alpha)."""
    ix, iy = int(round(x)), int(round(y))
    if 0 <= ix < WIDTH and 0 <= iy < HEIGHT:
        old_a = img[iy][ix][3]
        new_a = min(255, int(alpha))
        if new_a > old_a:
            img[iy][ix] = [255, 255, 255, new_a]


def draw_line(img, x0, y0, x1, y1, thickness=3.0):
    """Draw an antialiased thick line between two points."""
    dx = x1 - x0
    dy = y1 - y0
    length = math.sqrt(dx * dx + dy * dy)
    if length < 0.001:
        return

    steps = int(length * 2) + 1
    half_t = thickness / 2.0

    # Normal perpendicular to line direction
    nx = -dy / length
    ny = dx / length

    for i in range(steps + 1):
        t = i / steps
        cx = x0 + dx * t
        cy = y0 + dy * t

        # Fill across the thickness
        for j in range(-int(half_t + 2), int(half_t + 3)):
            px = cx + nx * j
            py = cy + ny * j
            dist = abs(j)
            if dist <= half_t - 0.5:
                plot(img, px, py, 255)
            elif dist <= half_t + 0.5:
                # Antialias the edge
                aa = 255 * (half_t + 0.5 - dist)
                plot(img, px, py, aa)


def draw_circle_arc(img, cx, cy, radius, start_angle, end_angle, thickness=3.0):
    """Draw an arc (angles in radians)."""
    circumference = abs(end_angle - start_angle) * radius
    steps = max(int(circumference * 2), 20)
    for i in range(steps + 1):
        t = i / steps
        angle = start_angle + (end_angle - start_angle) * t
        x = cx + radius * math.cos(angle)
        y = cy + radius * math.sin(angle)
        # Draw a small filled circle at each point
        half_t = thickness / 2.0
        for dy in range(-int(half_t + 1), int(half_t + 2)):
            for ddx in range(-int(half_t + 1), int(half_t + 2)):
                dist = math.sqrt(ddx * ddx + dy * dy)
                if dist <= half_t - 0.5:
                    plot(img, x + ddx, y + dy, 255)
                elif dist <= half_t + 0.5:
                    aa = 255 * (half_t + 0.5 - dist)
                    plot(img, x + ddx, y + dy, aa)


def norm(x_frac, y_frac):
    """Convert normalized (0-1) coordinates to pixel coordinates.
    y is flipped: 0 = top of image, 1 = bottom."""
    return x_frac * (WIDTH - 1), y_frac * (HEIGHT - 1)


def write_tga(filepath, img):
    """Write a 32-bit uncompressed TGA file."""
    with open(filepath, "wb") as f:
        # TGA header (18 bytes)
        f.write(struct.pack("<B", 0))       # ID length
        f.write(struct.pack("<B", 0))       # Color map type
        f.write(struct.pack("<B", 2))       # Image type: uncompressed true-color
        f.write(b"\x00" * 5)               # Color map spec
        f.write(struct.pack("<H", 0))       # X origin
        f.write(struct.pack("<H", 0))       # Y origin
        f.write(struct.pack("<H", WIDTH))   # Width
        f.write(struct.pack("<H", HEIGHT))  # Height
        f.write(struct.pack("<B", 32))      # Bits per pixel
        f.write(struct.pack("<B", 0x28))    # Image descriptor (top-left origin + 8 alpha bits)

        # Pixel data: BGRA, top-to-bottom
        for row in img:
            for pixel in row:
                f.write(struct.pack("BBBB", pixel[0], pixel[1], pixel[2], pixel[3]))


# =====================================================================
# Rune definitions
# =====================================================================

def rune_thurisaz():
    """Thurisaz (thorn) - angular rune with vertical spine and diamond branch."""
    img = make_image()
    t = 3.0

    # Vertical spine on the left
    draw_line(img, *norm(0.08, 0.10), *norm(0.08, 0.90), t)

    # Diamond/thorn shape branching right
    draw_line(img, *norm(0.08, 0.20), *norm(0.35, 0.50), t)
    draw_line(img, *norm(0.35, 0.50), *norm(0.08, 0.80), t)

    # Horizontal bar extending right from diamond tip
    draw_line(img, *norm(0.35, 0.50), *norm(0.65, 0.50), t)

    # Right-side vertical with angled serifs
    draw_line(img, *norm(0.65, 0.15), *norm(0.65, 0.85), t)
    draw_line(img, *norm(0.65, 0.15), *norm(0.75, 0.08), t)
    draw_line(img, *norm(0.65, 0.85), *norm(0.75, 0.92), t)

    # Decorative dots (small circles)
    draw_circle_arc(img, *norm(0.82, 0.30), 2, 0, 2 * math.pi, 2.5)
    draw_circle_arc(img, *norm(0.82, 0.70), 2, 0, 2 * math.pi, 2.5)

    # Top and bottom bars (binding lines)
    draw_line(img, *norm(0.03, 0.05), *norm(0.92, 0.05), 1.5)
    draw_line(img, *norm(0.03, 0.95), *norm(0.92, 0.95), 1.5)

    return img


def rune_kenaz():
    """Kenaz (torch/flame) - angular < with extensions."""
    img = make_image()
    t = 3.0

    # Main chevron
    draw_line(img, *norm(0.35, 0.10), *norm(0.10, 0.50), t)
    draw_line(img, *norm(0.10, 0.50), *norm(0.35, 0.90), t)

    # Extension bar to the right
    draw_line(img, *norm(0.10, 0.50), *norm(0.55, 0.50), t)

    # Right vertical with serifs
    draw_line(img, *norm(0.55, 0.20), *norm(0.55, 0.80), t)
    draw_line(img, *norm(0.55, 0.20), *norm(0.65, 0.15), t)
    draw_line(img, *norm(0.55, 0.80), *norm(0.65, 0.85), t)

    # Far-right accent strokes
    draw_line(img, *norm(0.72, 0.30), *norm(0.85, 0.50), t * 0.8)
    draw_line(img, *norm(0.85, 0.50), *norm(0.72, 0.70), t * 0.8)

    # Binding lines
    draw_line(img, *norm(0.03, 0.05), *norm(0.92, 0.05), 1.5)
    draw_line(img, *norm(0.03, 0.95), *norm(0.92, 0.95), 1.5)

    return img


def rune_dagaz():
    """Dagaz (day/dawn) - hourglass/butterfly, the most ornate."""
    img = make_image()
    t = 3.0

    # Left vertical
    draw_line(img, *norm(0.08, 0.10), *norm(0.08, 0.90), t)

    # X crossover through center
    draw_line(img, *norm(0.08, 0.10), *norm(0.45, 0.50), t)
    draw_line(img, *norm(0.08, 0.90), *norm(0.45, 0.50), t)

    # Center to right
    draw_line(img, *norm(0.45, 0.50), *norm(0.70, 0.10), t)
    draw_line(img, *norm(0.45, 0.50), *norm(0.70, 0.90), t)

    # Right vertical
    draw_line(img, *norm(0.70, 0.10), *norm(0.70, 0.90), t)

    # Decorative serifs on verticals
    draw_line(img, *norm(0.08, 0.10), *norm(0.03, 0.06), 2.0)
    draw_line(img, *norm(0.08, 0.90), *norm(0.03, 0.94), 2.0)
    draw_line(img, *norm(0.70, 0.10), *norm(0.75, 0.06), 2.0)
    draw_line(img, *norm(0.70, 0.90), *norm(0.75, 0.94), 2.0)

    # Accent dot at center
    draw_circle_arc(img, *norm(0.45, 0.50), 3, 0, 2 * math.pi, 2.5)

    # Far-right vertical accent
    draw_line(img, *norm(0.85, 0.25), *norm(0.85, 0.75), 2.0)
    draw_line(img, *norm(0.82, 0.25), *norm(0.88, 0.25), 1.5)
    draw_line(img, *norm(0.82, 0.75), *norm(0.88, 0.75), 1.5)

    # Binding lines
    draw_line(img, *norm(0.03, 0.05), *norm(0.92, 0.05), 1.5)
    draw_line(img, *norm(0.03, 0.95), *norm(0.92, 0.95), 1.5)

    return img


def rune_algiz():
    """Algiz (protection/shield) - upward fork with base."""
    img = make_image()
    t = 3.0

    # Central vertical spine
    draw_line(img, *norm(0.35, 0.85), *norm(0.35, 0.15), t)

    # Three upward branches
    draw_line(img, *norm(0.35, 0.30), *norm(0.12, 0.10), t)
    draw_line(img, *norm(0.35, 0.20), *norm(0.35, 0.10), t)
    draw_line(img, *norm(0.35, 0.30), *norm(0.58, 0.10), t)

    # Base cross-bar
    draw_line(img, *norm(0.20, 0.85), *norm(0.50, 0.85), t)

    # Right-side accent: vertical line with hash marks
    draw_line(img, *norm(0.70, 0.20), *norm(0.70, 0.80), 2.5)
    draw_line(img, *norm(0.65, 0.35), *norm(0.75, 0.35), 2.0)
    draw_line(img, *norm(0.65, 0.50), *norm(0.75, 0.50), 2.0)
    draw_line(img, *norm(0.65, 0.65), *norm(0.75, 0.65), 2.0)

    # Small decorative dots
    draw_circle_arc(img, *norm(0.85, 0.50), 2, 0, 2 * math.pi, 2.5)

    # Binding lines
    draw_line(img, *norm(0.03, 0.05), *norm(0.92, 0.05), 1.5)
    draw_line(img, *norm(0.03, 0.95), *norm(0.92, 0.95), 1.5)

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

    print("Done.")
