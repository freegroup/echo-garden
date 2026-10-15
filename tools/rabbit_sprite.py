"""Draws the pixel-art rabbits on a 32x32 grid and scales them 2x to 64x64.

Usage: python3 tools/rabbit_sprite.py assets/images

Writes one image per fur color and view:
  rabbit-<color>-front.png       the rabbit comes towards the viewer
  rabbit-<color>-back.png        the rabbit hops away
  rabbit-<color>-side.png        the rabbit looks to the right
  rabbit-<color>-front-side.png  towards the viewer and to the right
  rabbit-<color>-back-side.png   away from the viewer and to the right
The game mirrors the side views for the left directions.

The style follows the player sprite: dark outline, base color with a shaded
and a lit side (light comes from the top left) and a soft shadow on the ground.
"""
import math
import sys
from PIL import Image

N = 32

# All shapes are drawn in "design" coordinates and then shrunk around the
# ground point, so the rabbit stays small next to the player but keeps
# 2x pixels like the rest of the game.
SCALE = 0.74
GROUND = (15.0, 30.0)


def scaled(cx, cy):
    return (GROUND[0] + (cx - GROUND[0]) * SCALE, GROUND[1] + (cy - GROUND[1]) * SCALE)


def ellipse(cx, cy, rx, ry, angle=0.0):
    cx, cy = scaled(cx, cy)
    rx, ry = rx * SCALE, ry * SCALE
    a = math.radians(angle)
    ca, sa = math.cos(a), math.sin(a)
    cells = set()
    for y in range(N):
        for x in range(N):
            dx, dy = x + 0.5 - cx, y + 0.5 - cy
            u = dx * ca + dy * sa
            v = -dx * sa + dy * ca
            if (u / rx) ** 2 + (v / ry) ** 2 <= 1.0:
                cells.add((x, y))
    return cells


class Drawing:
    def __init__(self):
        self.grid = {}  # (x, y) -> color name; later paint wins
        self.inner_lines = set()

    def paint(self, cells, color):
        for cell in cells:
            self.grid[cell] = color

    def paint_inside(self, cells, part, color):
        self.paint({cell for cell in cells if cell in part}, color)

    def shade(self, part, cx, cy, rx, ry):
        """Darkens the bottom right and lightens the top left of a part."""
        cx, cy = scaled(cx, cy)
        rx, ry = rx * SCALE, ry * SCALE
        for (x, y) in part:
            if self.grid.get((x, y)) != 'fur':
                continue
            nx, ny = (x + 0.5 - cx) / rx, (y + 0.5 - cy) / ry
            if nx * 0.45 + ny * 0.9 > 0.55:
                self.grid[(x, y)] = 'shade'
            elif nx * 0.6 + ny * 0.8 < -0.62:
                self.grid[(x, y)] = 'light'

    def render(self, palette):
        filled = set(self.grid)
        outline = set()
        for (x, y) in filled:
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                neighbor = (x + dx, y + dy)
                if neighbor not in filled and 0 <= neighbor[0] < N and 0 <= neighbor[1] < N:
                    outline.add(neighbor)

        img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
        for cell in ellipse(15.0, 29.6, 9.0, 1.6):
            img.putpixel(cell, (0, 0, 0, 70))
        for cell in outline:
            img.putpixel(cell, palette['outline'])
        for cell, name in self.grid.items():
            img.putpixel(cell, palette[name])
        for cell in self.inner_lines:
            img.putpixel(cell, palette['outline'])
        return img.resize((N * 2, N * 2), Image.NEAREST)


def draw_side():
    d = Drawing()
    body = ellipse(13.5, 22.0, 8.5, 6.5)
    hind_foot = ellipse(15.0, 27.6, 4.5, 1.6)
    head = ellipse(21.0, 15.0, 5.8, 5.0)
    back_ear = ellipse(16.2, 6.5, 1.9, 5.6, angle=-18)
    front_ear = ellipse(19.6, 5.6, 2.1, 6.0, angle=-8)
    front_paw = ellipse(21.8, 27.4, 2.0, 1.5)
    tail = ellipse(5.2, 20.5, 2.6, 2.4)

    # back parts first, they are in the shade
    d.paint(back_ear, 'shade')
    d.paint(body, 'fur')
    d.paint(hind_foot, 'fur')
    d.paint(front_paw, 'fur')
    d.paint(head, 'fur')
    d.paint(front_ear, 'fur')
    d.paint(tail, 'white')

    d.shade(body, 13.5, 22.0, 8.5, 6.5)
    d.shade(head, 21.0, 15.0, 5.8, 5.0)
    d.shade(front_ear, 19.6, 5.6, 2.1, 6.0)
    d.paint(hind_foot | front_paw, 'shade')

    d.paint_inside(ellipse(23.0, 18.6, 2.6, 2.0), head, 'belly')
    d.paint_inside(ellipse(20.5, 21.5, 2.4, 3.0), body - head, 'belly')
    d.paint_inside(ellipse(19.8, 6.2, 0.9, 4.2, angle=-8), front_ear, 'pink')

    # eye with a glint, and the nose
    d.paint({(20, 18), (20, 19), (21, 18), (21, 19)}, 'eye')
    d.paint({(20, 18)}, 'white')
    d.paint({(23, 20)}, 'pink')

    # thigh: a shade line that shows the hind leg
    d.paint_inside(ellipse(11.5, 24.5, 4.6, 3.8) - ellipse(11.0, 24.0, 3.6, 2.9), body, 'shade')

    # line between the ears, for depth
    d.inner_lines = {c for c in back_ear if c not in front_ear and
                     any((c[0] + 1, c[1] + dy) in front_ear for dy in (-1, 0, 1))}
    return d


def _front_and_back_shapes():
    body = ellipse(15.0, 23.0, 7.4, 6.2)
    left_foot = ellipse(10.8, 28.0, 2.8, 1.6)
    right_foot = ellipse(19.2, 28.0, 2.8, 1.6)
    head = ellipse(15.0, 14.5, 6.4, 5.4)
    left_ear = ellipse(10.8, 5.8, 1.9, 6.0, angle=16)
    right_ear = ellipse(19.2, 5.8, 1.9, 6.0, angle=-16)
    return body, left_foot, right_foot, head, left_ear, right_ear


def draw_front():
    d = Drawing()
    body, left_foot, right_foot, head, left_ear, right_ear = _front_and_back_shapes()

    d.paint(left_ear | right_ear, 'fur')
    d.paint(body, 'fur')
    d.paint(left_foot | right_foot, 'shade')
    d.paint(head, 'fur')

    d.shade(body, 15.0, 23.0, 7.4, 6.2)
    d.shade(head, 15.0, 14.5, 6.4, 5.4)
    d.shade(left_ear, 10.8, 5.8, 1.9, 6.0)
    d.shade(right_ear, 19.2, 5.8, 1.9, 6.0)

    d.paint_inside(ellipse(15.0, 24.0, 3.8, 4.4), body - head, 'belly')
    d.paint_inside(ellipse(15.0, 17.6, 3.0, 2.0), head, 'belly')
    d.paint_inside(ellipse(10.8, 6.4, 0.9, 4.2, angle=16), left_ear, 'pink')
    d.paint_inside(ellipse(19.2, 6.4, 0.9, 4.2, angle=-16), right_ear, 'pink')

    # two eyes with a glint, the nose in the middle
    d.paint({(12, 17), (13, 17), (12, 18), (13, 18)}, 'eye')
    d.paint({(16, 17), (17, 17), (16, 18), (17, 18)}, 'eye')
    d.paint({(12, 17), (16, 17)}, 'white')
    d.paint({(14, 19), (15, 19)}, 'pink')

    return d


def draw_back():
    d = Drawing()
    body, left_foot, right_foot, head, left_ear, right_ear = _front_and_back_shapes()

    d.paint(left_ear | right_ear, 'fur')
    d.paint(body, 'fur')
    d.paint(left_foot | right_foot, 'shade')
    d.paint(head, 'fur')

    d.shade(body, 15.0, 23.0, 7.4, 6.2)
    d.shade(head, 15.0, 14.5, 6.4, 5.4)
    d.shade(left_ear, 10.8, 5.8, 1.9, 6.0)
    d.shade(right_ear, 19.2, 5.8, 1.9, 6.0)

    # the back of the ears is fur, only a shaded middle line
    d.paint_inside(ellipse(10.8, 6.4, 0.7, 4.0, angle=16), left_ear, 'shade')
    d.paint_inside(ellipse(19.2, 6.4, 0.7, 4.0, angle=-16), right_ear, 'shade')

    # fluffy tail
    d.paint(ellipse(15.0, 25.6, 2.8, 2.5), 'white')

    # line below the head, so it stands out from the body
    d.inner_lines = {(x, y) for (x, y) in body - head if (x, y - 1) in head}
    return d


def draw_front_side():
    """Half profile: the rabbit hops towards the viewer and to the right."""
    d = Drawing()
    body = ellipse(14.0, 23.0, 7.8, 6.2)
    back_foot = ellipse(10.5, 28.0, 2.8, 1.6)
    front_foot = ellipse(18.0, 28.2, 2.8, 1.6)
    head = ellipse(17.6, 14.8, 6.0, 5.2)
    back_ear = ellipse(14.4, 6.0, 1.8, 5.8, angle=6)
    front_ear = ellipse(20.0, 5.8, 1.9, 6.0, angle=-14)
    tail = ellipse(7.0, 22.5, 2.2, 2.2)

    # back parts first, they are partly hidden
    d.paint(tail, 'white')
    d.paint(back_ear, 'shade')
    d.paint(body, 'fur')
    d.paint(back_foot | front_foot, 'shade')
    d.paint(head, 'fur')
    d.paint(front_ear, 'fur')

    d.shade(body, 14.0, 23.0, 7.8, 6.2)
    d.shade(head, 17.6, 14.8, 6.0, 5.2)
    d.shade(front_ear, 20.0, 5.8, 1.9, 6.0)

    d.paint_inside(ellipse(17.2, 24.0, 3.4, 4.2), body - head, 'belly')
    d.paint_inside(ellipse(19.6, 17.8, 2.8, 2.0), head, 'belly')
    d.paint_inside(ellipse(20.0, 6.6, 0.9, 4.2, angle=-14), front_ear, 'pink')

    # the near eye is full, the far eye only a narrow line; nose to the right
    d.paint({(17, 17), (18, 17), (17, 18), (18, 18)}, 'eye')
    d.paint({(17, 17)}, 'white')
    d.paint({(14, 17), (14, 18)}, 'eye')
    d.paint({(19, 19), (20, 19)}, 'pink')

    d.inner_lines = {c for c in back_ear if c not in front_ear and c not in head and
                     any((c[0] + 1, c[1] + dy) in front_ear | head for dy in (-1, 0, 1))}
    return d


def draw_back_side():
    """Half profile: the rabbit hops away from the viewer and to the right."""
    d = Drawing()
    body = ellipse(14.0, 23.0, 7.8, 6.2)
    back_foot = ellipse(10.0, 28.0, 2.8, 1.6)
    front_foot = ellipse(17.5, 28.0, 2.6, 1.5)
    head = ellipse(17.0, 14.6, 6.0, 5.2)
    near_ear = ellipse(13.8, 6.0, 1.9, 6.0, angle=12)
    far_ear = ellipse(19.4, 5.8, 1.8, 5.8, angle=-10)
    tail = ellipse(10.5, 25.2, 2.7, 2.5)

    d.paint(far_ear, 'shade')
    d.paint(body, 'fur')
    d.paint(back_foot | front_foot, 'shade')
    d.paint(head, 'fur')
    d.paint(near_ear, 'fur')

    d.shade(body, 14.0, 23.0, 7.8, 6.2)
    d.shade(head, 17.0, 14.6, 6.0, 5.2)
    d.shade(near_ear, 13.8, 6.0, 1.9, 6.0)
    d.paint_inside(ellipse(13.8, 6.6, 0.7, 4.0, angle=12), near_ear, 'shade')

    d.paint(tail, 'white')

    # line below the head, so it stands out from the body
    d.inner_lines = {(x, y) for (x, y) in body - head if (x, y - 1) in head}
    return d


PALETTES = {
    'brown': {
        'outline': (52, 30, 20, 255),
        'fur': (176, 120, 72, 255),
        'shade': (128, 82, 50, 255),
        'light': (212, 162, 108, 255),
        'belly': (236, 214, 178, 255),
        'white': (246, 242, 234, 255),
        'pink': (232, 140, 150, 255),
        'eye': (30, 20, 20, 255),
    },
    'grey': {
        'outline': (40, 40, 52, 255),
        'fur': (150, 150, 158, 255),
        'shade': (106, 106, 118, 255),
        'light': (194, 194, 200, 255),
        'belly': (232, 230, 226, 255),
        'white': (248, 248, 246, 255),
        'pink': (232, 140, 150, 255),
        'eye': (24, 20, 28, 255),
    },
}

VIEWS = {
    'front': draw_front,
    'back': draw_back,
    'side': draw_side,
    'front-side': draw_front_side,
    'back-side': draw_back_side,
}

if __name__ == '__main__':
    out_dir = sys.argv[1]
    for color, palette in PALETTES.items():
        for view, draw in VIEWS.items():
            draw().render(palette).save(f'{out_dir}/rabbit-{color}-{view}.png')
