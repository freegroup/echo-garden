"""Draws the ground tiles of the mountains (height areas), 64x64 pixels.

Usage: python3 tools/terrain_sprite.py assets/images

Writes two variants per height area:
  height-low-01.png, height-low-02.png         green hill with small stones
  height-medium-01.png, height-medium-02.png   brown-grey rock with cracks
  height-high-01.png, height-high-02.png       light rock with patches of snow

The style follows the existing ground tiles (soil, beach): a flat base color
with small lighter and darker speckles. Drawn on a 32x32 grid, scaled 2x.
"""
import random
import sys
from PIL import Image

N = 32


def shift(color, amount):
    return tuple(max(0, min(255, c + amount)) for c in color[:3]) + (255,)


def speckles(img, rnd, base, count, amount):
    for _ in range(count):
        x, y = rnd.randrange(N), rnd.randrange(N)
        size = rnd.choice([1, 1, 2])
        sign = rnd.choice([-1, 1])
        for dx in range(size):
            for dy in range(size):
                img.putpixel(((x + dx) % N, (y + dy) % N), shift(base, sign * amount))


def stones(img, rnd, count, color, outline):
    for _ in range(count):
        x, y = rnd.randrange(1, N - 3), rnd.randrange(1, N - 3)
        w, h = rnd.choice([(2, 1), (2, 2), (3, 2)])
        for dx in range(-1, w + 1):
            for dy in range(-1, h + 1):
                inside = 0 <= dx < w and 0 <= dy < h
                img.putpixel((x + dx, y + dy), color if inside else outline)
        img.putpixel((x, y), shift(color, 25))  # light from the top left


def cracks(img, rnd, count, color):
    for _ in range(count):
        x, y = rnd.randrange(N), rnd.randrange(N)
        for _ in range(rnd.randint(3, 6)):
            img.putpixel((x % N, y % N), color)
            x += rnd.choice([0, 1, 1])
            y += rnd.choice([-1, 0, 1])


def snow(img, rnd, count, color, shade):
    for _ in range(count):
        rx, ry = rnd.uniform(3.5, 6.0), rnd.uniform(2.5, 4.0)
        # keep the patch inside the tile, so it is not cut off at the border
        cx = rnd.uniform(rx + 1, N - rx - 1)
        cy = rnd.uniform(ry + 1, N - ry - 1)
        for x in range(N):
            for y in range(N):
                dx, dy = x + 0.5 - cx, y + 0.5 - cy
                d = (dx / rx) ** 2 + (dy / ry) ** 2
                if d <= 1.0:
                    # the lower edge of a snow patch is a bit darker
                    lower_edge = d > 0.6 and dy > 0
                    img.putpixel((x, y), shade if lower_edge else color)


def low(rnd):
    base = (122, 150, 96, 255)
    img = Image.new('RGBA', (N, N), base)
    speckles(img, rnd, base, 70, 10)
    stones(img, rnd, 3, (150, 146, 134, 255), (92, 104, 76, 255))
    return img


def medium(rnd):
    base = (140, 124, 106, 255)
    img = Image.new('RGBA', (N, N), base)
    speckles(img, rnd, base, 80, 12)
    cracks(img, rnd, 4, (100, 86, 72, 255))
    stones(img, rnd, 2, (168, 156, 140, 255), (100, 86, 72, 255))
    return img


def high(rnd):
    base = (170, 168, 172, 255)
    img = Image.new('RGBA', (N, N), base)
    speckles(img, rnd, base, 80, 12)
    cracks(img, rnd, 3, (128, 126, 134, 255))
    snow(img, rnd, 3, (244, 246, 250, 255), (214, 222, 234, 255))
    return img


AREAS = {'low': low, 'medium': medium, 'high': high}

if __name__ == '__main__':
    out_dir = sys.argv[1]
    for name, draw in AREAS.items():
        for variant in (1, 2):
            # fixed seed, so running the tool again gives the same images
            rnd = random.Random(f'{name}-{variant}')
            image = draw(rnd).resize((N * 2, N * 2), Image.NEAREST)
            image.save(f'{out_dir}/height-{name}-0{variant}.png')
