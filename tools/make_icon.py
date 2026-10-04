#!/usr/bin/env python3
"""Generate the TAPAK NUSA window/project icon (icon.png, 256x256).

The icon is drawn procedurally (dusk sky, rice terraces, a winding path with
footprints) so the repository needs no external art files. Run:

    python3 tools/make_icon.py
"""
from __future__ import annotations

import struct
import zlib
from pathlib import Path

W = H = 256
SS = 2  # supersampling factor

ROOT = Path(__file__).resolve().parents[1]

SKY_TOP = (0x2F, 0x48, 0x58)
SKY_MID = (0xC2, 0x6B, 0x4A)
SKY_LOW = (0xE0, 0x8A, 0x4B)
SUN = (0xF2, 0xB1, 0x34)
HILL_FAR = (0x4A, 0x5B, 0x3F)
HILL_NEAR = (0x33, 0x42, 0x2E)
TERRACE = (0x8F, 0xB1, 0x5A)
TERRACE_DARK = (0x2C, 0x3A, 0x28)
PATH = (0xE8, 0xC9, 0x8F)
PATH_EDGE = (0xC9, 0xA0, 0x6A)
FOOT = (0x5A, 0x3A, 0x24)
MOON = (0xF7, 0xD6, 0x8A)


def mix(a, b, t):
    t = max(0.0, min(1.0, t))
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def add(c, amount):
    return tuple(min(255.0, c[i] + amount) for i in range(3))


def bezier(p0, p1, p2, t):
    mt = 1.0 - t
    return (
        mt * mt * p0[0] + 2 * mt * t * p1[0] + t * t * p2[0],
        mt * mt * p0[1] + 2 * mt * t * p1[1] + t * t * p2[1],
    )


def dist_to_path(u, v):
    """Rough distance from (u, v) to the path curve, plus the curve parameter."""
    best_d = 9.9
    best_t = 0.0
    for i in range(61):
        t = i / 60.0
        px, py = bezier((0.02, 1.06), (0.48, 0.80), (1.02, 0.62), t)
        d = ((px - u) ** 2 + (py - v) ** 2) ** 0.5
        if d < best_d:
            best_d = d
            best_t = t
    return best_d, best_t


def sample(u, v):
    """Return (r, g, b, a) for normalised coordinates."""
    # rounded-square mask
    r = 0.19
    cx = min(max(u, r), 1.0 - r)
    cy = min(max(v, r), 1.0 - r)
    outside = ((u - cx) ** 2 + (v - cy) ** 2) ** 0.5
    if outside > r:
        return (0, 0, 0, 0)

    # sky
    if v < 0.62:
        col = mix(SKY_TOP, SKY_MID, (v / 0.62) ** 0.9)
    else:
        col = mix(SKY_MID, SKY_LOW, min(1.0, (v - 0.62) / 0.30))

    # sun + glow
    sun_d = ((u - 0.72) ** 2 + (v - 0.29) ** 2) ** 0.5
    if sun_d < 0.075:
        col = SUN
    elif sun_d < 0.26:
        col = add(col, 90.0 * (1.0 - (sun_d - 0.075) / 0.185) ** 2)

    # far hills
    hill_line = 0.60 + 0.035 * __import__("math").sin(u * 6.0)
    if v > hill_line:
        col = mix(HILL_FAR, HILL_NEAR, min(1.0, (v - hill_line) / 0.35))

    # rice terraces (striped rows)
    terrace_line = 0.70 + 0.025 * __import__("math").sin(u * 4.0 + 1.2)
    if v > terrace_line:
        row = int((v - terrace_line) * 90.0) % 7
        col = TERRACE if row < 3 else TERRACE_DARK

    # winding path
    d, _t = dist_to_path(u, v)
    width = 0.012 + 0.055 * u
    if d < width + 0.012 and v > 0.58:
        col = PATH_EDGE if d > width - 0.010 else PATH

    # footprints along the path
    import math

    for i in range(3):
        t = 0.30 + i * 0.22
        px, py = bezier((0.02, 1.06), (0.48, 0.80), (1.02, 0.62), t)
        for side in (-1, 1):
            fx = px + side * 0.030
            fy = py + side * 0.036
            dx = (u - fx) / 0.026
            dy = (v - fy) / 0.038
            if dx * dx + dy * dy <= 1.0:
                col = FOOT

    # moonlight rim on the top-left for cohesion
    rim = max(0.0, 1.0 - ((u - 0.30) ** 2 + (v - 0.18) ** 2) ** 0.5 / 0.55)
    col = add(col, 16.0 * rim)

    return (int(col[0]), int(col[1]), int(col[2]), 255)


def main() -> None:
    pixels = []
    for y in range(H):
        row = bytearray()
        for x in range(W):
            # akumulasi premultiplied: warna * alpha, lalu dirata-rata
            sum_r = sum_g = sum_b = sum_a = 0.0
            for sy in range(SS):
                for sx in range(SS):
                    u = (x + (sx + 0.5) / SS) / W
                    v = (y + (sy + 0.5) / SS) / H
                    r, g, b, a = sample(u, v)
                    weight = a / 255.0
                    sum_r += r * weight
                    sum_g += g * weight
                    sum_b += b * weight
                    sum_a += weight
            n = float(SS * SS)
            alpha = sum_a / n
            if sum_a <= 0.0:
                row += bytes((0, 0, 0, 0))
            else:
                row += bytes(
                    (
                        min(255, max(0, int(sum_r / sum_a + 0.5))),
                        min(255, max(0, int(sum_g / sum_a + 0.5))),
                        min(255, max(0, int(sum_b / sum_a + 0.5))),
                        min(255, max(0, int(alpha * 255.0 + 0.5))),
                    )
                )
        pixels.append(bytes(row))

    raw = b"".join(b"\x00" + r for r in pixels)

    def chunk(tag: bytes, data: bytes) -> bytes:
        return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

    png = b"\x89PNG\r\n\x1a\n"
    png += chunk(b"IHDR", struct.pack(">IIBBBBB", W, H, 8, 6, 0, 0, 0))
    png += chunk(b"IDAT", zlib.compress(raw, 9))
    png += chunk(b"IEND", b"")

    out = ROOT / "icon.png"
    out.write_bytes(png)
    print(f"wrote {out} ({len(png)} bytes)")


if __name__ == "__main__":
    main()
