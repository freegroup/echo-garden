"""Draws the pine, a dark alpine conifer for the mountains, 64x64 pixels.

Usage: python3 tools/pine_sprite.py assets/images

Writes four growth stages pine-01.png .. pine-04.png, in the style of the
other trees: dark outline, two green tones, a brown trunk and a soft shadow.
The pine is darker and narrower than the fir, so it reads as a high, windy
mountain tree.
"""
import sys
from PIL import Image, ImageDraw

N = 64

OUTLINE = (28, 44, 40, 255)
DARK = (44, 92, 74, 255)
LIGHT = (70, 124, 96, 255)
TRUNK = (104, 74, 48, 255)
SHADOW = (0, 0, 0, 60)


def pine(draw, cx, baseY, scale):
    """One pine, its trunk centered at cx, standing on baseY."""
    height = int(34 * scale)
    halfWidth = 9 * scale
    top = baseY - height

    # trunk
    draw.rectangle([cx - 1, baseY - int(5 * scale), cx + 1, baseY], fill=TRUNK)

    # three stacked branch layers, widest at the bottom
    layers = 3
    for i in range(layers):
        t = i / layers
        y0 = top + (height * i) // layers
        y1 = top + (height * (i + 1)) // layers + int(3 * scale)
        w = halfWidth * (0.45 + 0.55 * t)
        # outline triangle, then a slightly smaller filled one on top
        draw.polygon([(cx, y0 - int(2 * scale)), (cx - w - 1, y1), (cx + w + 1, y1)], fill=OUTLINE)
        draw.polygon([(cx, y0), (cx - w, y1 - 1), (cx + w, y1 - 1)], fill=DARK)
        # light on the left side (light from the top left)
        draw.polygon([(cx, y0), (cx - w, y1 - 1), (cx - w * 0.2, y1 - 1)], fill=LIGHT)


def stage(count, scale):
    img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # ground shadow under the trees
    for cx in _positions(count):
        draw.ellipse([cx - 9 * scale, N - 10, cx + 9 * scale, N - 4], fill=SHADOW)
    for cx in _positions(count):
        pine(draw, int(cx), N - 6, scale)
    return img


def _positions(count):
    if count == 1:
        return [N / 2]
    if count == 2:
        return [N / 2 - 13, N / 2 + 13]
    return [N / 2 - 17, N / 2 + 2, N / 2 + 18]


# sapling, young, grown, small group
STAGES = [(1, 0.5), (1, 0.85), (1, 1.1), (3, 0.9)]

if __name__ == '__main__':
    out_dir = sys.argv[1]
    for i, (count, scale) in enumerate(STAGES, start=1):
        stage(count, scale).save(f'{out_dir}/pine-0{i}.png')
