"""Hand-made Lottie animations for the game (LottieFiles style: flat vector,
soft gradients, rounded shapes, eased motion). Writes JSON files under
assets/game/anim/. Run: python -I tool/lottie_gen.py .

Each animation is generated from code so it can be tuned and regenerated;
no After Effects needed. Colours are 0..1 RGB(A).
"""
import json, math, os, random, sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
OUT = os.path.join(ROOT, 'assets/game/anim')
os.makedirs(OUT, exist_ok=True)

EASE_IO = {'i': {'x': [0.42], 'y': [1]}, 'o': {'x': [0.58], 'y': [0]}}
EASE_OUT = {'i': {'x': [0.2], 'y': [1]}, 'o': {'x': [0.3], 'y': [0]}}
EASE_IN = {'i': {'x': [0.7], 'y': [1]}, 'o': {'x': [0.8], 'y': [0]}}


def hexc(h, a=1.0):
    h = h.lstrip('#')
    return [int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255, a]


def static(v):
    return {'a': 0, 'k': v}


def anim(keys, ease=EASE_IO):
    """keys: list of (frame, value). Values are lists (or numbers)."""
    out = []
    for n, (t, v) in enumerate(keys):
        k = {'t': t, 's': v if isinstance(v, list) else [v]}
        if n < len(keys) - 1:
            k.update(ease)
        out.append(k)
    return {'a': 1, 'k': out}


def transform(p=(0, 0), a=(0, 0), s=(100, 100), r=0, o=100):
    def val(x, dims):
        if isinstance(x, dict):
            return x
        if isinstance(x, (int, float)):
            return static(x)
        return static(list(x) + [0] * (dims - len(x)))
    return {'o': val(o, 1), 'r': val(r, 1), 'p': val(p, 3), 'a': val(a, 3), 's': val(s, 3)}


def gr_transform(p=(0, 0), s=(100, 100), r=0, o=100):
    t = {'ty': 'tr', 'p': static(list(p)), 'a': static([0, 0]), 's': static(list(s)), 'r': static(r), 'o': static(o),
         'sk': static(0), 'sa': static(0)}
    for k, v in (('p', p), ('s', s), ('r', r), ('o', o)):
        if isinstance(v, dict):
            t[k] = v
    return t


def fill(c, o=100):
    return {'ty': 'fl', 'c': static(c), 'o': static(o) if not isinstance(o, dict) else o, 'r': 1}


def gfill(stops, start, end, radial=False, o=100):
    """stops: list of (pos, [r,g,b,a])."""
    k = []
    for pos, col in stops:
        k += [pos, col[0], col[1], col[2]]
    alpha = []
    for pos, col in stops:
        alpha += [pos, col[3] if len(col) > 3 else 1]
    return {'ty': 'gf', 'o': static(o) if not isinstance(o, dict) else o, 'r': 1, 'g': {'p': len(stops), 'k': static(k + alpha)},
            's': static(list(start)), 'e': static(list(end)), 't': 2 if radial else 1,
            **({'h': static(0), 'a': static(0)} if radial else {})}


def ellipse(p=(0, 0), s=(10, 10)):
    return {'ty': 'el', 'p': static(list(p)) if not isinstance(p, dict) else p,
            's': static(list(s)) if not isinstance(s, dict) else s}


def path_shape(paths):
    """paths: a single path dict (static) or list of (frame, path) for a morph."""
    if isinstance(paths, dict):
        return {'ty': 'sh', 'ks': static(paths)}
    return {'ty': 'sh', 'ks': anim([(t, [p]) for t, p in paths])}


def group(items, tr=None, nm='g'):
    return {'ty': 'gr', 'nm': nm, 'it': items + [tr or gr_transform()]}


def layer(nm, shapes, ip, op, ks=None, ind=1, st=0):
    return {'ddd': 0, 'ind': ind, 'ty': 4, 'nm': nm, 'sr': 1, 'ks': ks or transform(), 'ao': 0,
            'shapes': shapes, 'ip': ip, 'op': op, 'st': st, 'bm': 0}


def comp(nm, w, h, fr, op, layers):
    for i, l in enumerate(layers):
        l['ind'] = i + 1
    return {'v': '5.7.4', 'fr': fr, 'ip': 0, 'op': op, 'w': w, 'h': h, 'nm': nm, 'ddd': 0, 'assets': [], 'layers': layers}


def save(name, data):
    p = os.path.join(OUT, name)
    with open(p, 'w', encoding='utf-8') as f:
        json.dump(data, f, separators=(',', ':'))
    print('wrote', name, os.path.getsize(p), 'bytes')


# ---------------------------------------------------------------------------
# Shapes
# ---------------------------------------------------------------------------

def flame_path(cx, base, w, h, lean=0.0, bulge=0.0, curl=0.0):
    """A tongue of flame: round bottom, swelling body, a tip that leans/curls.
    Returns a Lottie path (vertices with in/out tangents relative)."""
    hw = w / 2
    tipx = cx + lean * w
    tipy = base - h
    v = [
        [cx, base],                                   # bottom centre
        [cx - hw * (1 + bulge * 0.3), base - h * 0.32],  # left belly
        [tipx - w * 0.06 + curl * w * 0.2, base - h * 0.78],  # left shoulder
        [tipx, tipy],                                 # tip
        [tipx + w * 0.10 + curl * w * 0.15, base - h * 0.72],  # right shoulder
        [cx + hw * (1 + bulge * 0.25), base - h * 0.30],  # right belly
    ]
    i = [
        [hw * 0.55, 0],
        [0, h * 0.18],
        [-w * 0.12, h * 0.10],
        [-w * 0.04, h * 0.10],
        [w * 0.06, -h * 0.12],
        [w * 0.06, -h * 0.20],
    ]
    o = [
        [-hw * 0.55, 0],
        [0, -h * 0.18],
        [w * 0.08, -h * 0.10],
        [w * 0.03, h * 0.08],
        [-w * 0.04, h * 0.12],
        [0, h * 0.18],
    ]
    return {'i': i, 'o': o, 'v': v, 'c': True}


def flame_layers(n_frames, tongues, seed=1):
    """A cluster of flame tongues, each morphing between shapes in a loop:
    outer orange → inner yellow → white-hot core, with gradients."""
    rnd = random.Random(seed)
    layers = []
    for (cx, base, w, h, phase) in tongues:
        keys = [0, n_frames // 3, 2 * n_frames // 3, n_frames]
        shapes = []
        for tier, (scale, top, bot) in enumerate([
            (1.0, hexc('#E8590C'), hexc('#F28C28')),
            (0.68, hexc('#F7B32B'), hexc('#FFD54A')),
            (0.38, hexc('#FFF2B0'), hexc('#FFFFFF')),
        ]):
            ww, hh = w * scale, h * (0.55 + 0.45 * scale)
            frames = []
            for n, t in enumerate(keys):
                k = (n + phase) % 3 if n < 3 else phase % 3
                lean = [-0.10, 0.12, 0.02][k] + rnd.uniform(-0.03, 0.03)
                bulge = [0.0, 0.25, 0.1][k]
                curl = [0.3, -0.25, 0.1][k]
                hj = hh * [1.0, 0.86, 1.08][k]
                frames.append((t, flame_path(cx, base, ww, hj, lean, bulge, curl)))
            frames[-1] = (n_frames, frames[0][1])  # seamless loop
            shapes.append(group([
                path_shape(frames),
                gfill([(0, bot), (1, top)], (cx, base), (cx, base - hh), o=96 if tier else 92),
            ], nm=f'tier{tier}'))
        # Paint outer first (bottom of the list draws first in Lottie groups → reverse).
        layers.append(layer('tongue', list(reversed(shapes)), 0, n_frames))
    return layers


def embers(n_frames, cx, base, spread, count=10, rise=90, seed=3):
    rnd = random.Random(seed)
    out = []
    for e in range(count):
        start = rnd.randint(0, n_frames - 1)
        x0 = cx + rnd.uniform(-spread, spread)
        dx = rnd.uniform(-14, 14)
        r = rnd.uniform(2.0, 3.6)
        life = rnd.randint(int(n_frames * 0.5), n_frames)
        # Position over one life, repeated so the loop is seamless.
        pk, ok = [], []
        for rep in (-1, 0, 1):
            t0 = start + rep * n_frames
            pk += [(t0, [x0, base, 0]), (t0 + life, [x0 + dx, base - rise * rnd.uniform(0.7, 1.1), 0])]
            ok += [(t0, 0), (t0 + 3, 100), (t0 + life - 4, 70), (t0 + life, 0)]
        pk = [(t, v) for t, v in pk if -life <= t <= n_frames + life]
        ok = [(t, v) for t, v in ok if -life <= t <= n_frames + life]
        out.append(layer('ember', [group([ellipse((0, 0), (r, r)), fill(hexc('#FFC24A'))])], 0, n_frames,
                         ks=transform(p=anim(pk, EASE_OUT), o=anim(ok, EASE_IO))))
    return out


def glow(n_frames, cx, cy, w, h, col='#FF8A1F'):
    """A soft warm pool of light on the ground, breathing gently."""
    return layer('glow', [group([
        ellipse((cx, cy), (w, h)),
        gfill([(0, hexc(col, 0.55)), (1, hexc(col, 0.0))], (cx, cy), (cx + w / 2, cy), radial=True),
    ])], 0, n_frames, ks=transform(o=anim([(0, 85), (n_frames // 2, 100), (n_frames, 85)])))


def puffs(n_frames, origin, target, count, colour, r0, r1, spread, seed, life=None, alpha=0.85):
    """Soft round puffs travelling from origin to target, growing and fading
    (used for spray, smoke and clouds). Staggered so the loop is continuous."""
    rnd = random.Random(seed)
    out = []
    life = life or n_frames
    for k in range(count):
        start = int(k * n_frames / count)
        ox, oy = origin
        tx, ty = target[0] + rnd.uniform(-spread, spread), target[1] + rnd.uniform(-spread, spread)
        pk, sk, okk = [], [], []
        for rep in (-1, 0, 1):
            t0 = start + rep * n_frames
            pk += [(t0, [ox, oy, 0]), (t0 + life, [tx, ty, 0])]
            sk += [(t0, [r0, r0, 100]), (t0 + life, [r1, r1, 100])]
            okk += [(t0, 0), (t0 + max(2, life // 8), alpha * 100), (t0 + life, 0)]
        clip = lambda L: [(t, v) for t, v in L if -life <= t <= n_frames + life]
        out.append(layer('puff', [group([
            ellipse((0, 0), (100, 100)),
            gfill([(0, hexc(colour, 1)), (1, hexc(colour, 0.0))], (0, 0), (50, 0), radial=True),
        ])], 0, n_frames, ks=transform(p=anim(clip(pk), EASE_OUT), s=anim(clip(sk), EASE_OUT), o=anim(clip(okk)))))
    return out


def star(cx, cy, r, colour):
    return group([
        {'ty': 'sr', 'sy': 1, 'd': 1, 'pt': static(5), 'p': static([0, 0]), 'r': static(0),
         'ir': static(r * 0.45), 'is': static(0), 'or': static(r), 'os': static(0)},
        fill(hexc(colour)),
    ], tr=gr_transform(p=(cx, cy)))


# ---------------------------------------------------------------------------
# The fire set (lesson 1.8)
# ---------------------------------------------------------------------------

def fire_loop():
    """A wide fire: five tongues + embers + ground glow; 2 s loop at 24 fps."""
    n = 48
    tongues = [(70, 190, 70, 120, 0), (115, 192, 84, 160, 1), (160, 194, 92, 190, 2), (205, 192, 84, 150, 1), (248, 190, 66, 112, 0)]
    layers = embers(n, 160, 120, 90, count=12) + flame_layers(n, tongues) + [glow(n, 160, 192, 340, 70)]
    save('fire_loop.json', comp('fire_loop', 320, 210, 24, n, layers))


def smoke_loop():
    n = 72
    layers = puffs(n, (160, 150), (205, 0), 11, '#5F666E', 36, 130, 34, seed=5, alpha=0.78)
    save('smoke_loop.json', comp('smoke_loop', 320, 210, 24, n, layers))


def spray_dcp():
    """Pale powder cone from the nozzle (left) to the right; 1 s loop."""
    n = 24
    layers = puffs(n, (10, 60), (300, 60), 16, '#F4EEF2', 12, 120, 34, seed=7, life=n, alpha=0.95)
    layers += puffs(n, (10, 60), (260, 60), 10, '#E6D9E2', 8, 80, 22, seed=8, life=n, alpha=0.9)
    save('spray_dcp.json', comp('spray_dcp', 320, 120, 24, n, layers))


def spray_co2():
    """A hard white jet with frost at the nozzle; 1 s loop."""
    n = 24
    layers = puffs(n, (10, 60), (310, 60), 30, '#FFFFFF', 12, 70, 9, seed=9, life=n, alpha=0.95)
    layers += puffs(n, (10, 60), (300, 60), 16, '#DDF1FF', 8, 46, 5, seed=10, life=n, alpha=0.9)
    layers += [layer('frost', [group([ellipse((18, 60), (26, 20)), gfill([(0, hexc('#E8F6FF', 0.95)), (1, hexc('#E8F6FF', 0))], (18, 60), (31, 60), radial=True)])], 0, n,
                     ks=transform(o=anim([(0, 70), (12, 100), (24, 70)])))]
    save('spray_co2.json', comp('spray_co2', 320, 120, 24, n, layers))


def sand_throw():
    """A handful of sand thrown in an arc, landing in a dust puff; one shot."""
    n = 26
    rnd = random.Random(11)
    layers = []
    for k in range(26):
        x1 = 250 + rnd.uniform(-40, 40)
        y1 = 100 + rnd.uniform(-6, 6)
        apex = (130 + rnd.uniform(-20, 20), 10 + rnd.uniform(0, 20))
        r = rnd.uniform(5, 9)
        t0 = rnd.randint(0, 4)
        layers.append(layer('grain', [group([ellipse((0, 0), (r, r)), fill(hexc(rnd.choice(['#C9A55A', '#B88A3E', '#D8BE7A'])))])], 0, n,
                            ks=transform(p=anim([(t0, [20, 100, 0]), (t0 + 9, [apex[0], apex[1], 0]), (t0 + 18, [x1, y1, 0])], EASE_IO),
                                         o=anim([(t0, 0), (t0 + 2, 100), (t0 + 19, 100), (t0 + 22, 0)]))))
    layers += puffs(n, (250, 100), (250, 70), 5, '#CDBA90', 10, 70, 30, seed=12, life=12, alpha=0.7)
    save('sand_throw.json', comp('sand_throw', 320, 120, 24, n, layers))


def water_throw():
    """A bucket of water: a sheet of drops flying right, splashing; one shot."""
    n = 26
    rnd = random.Random(13)
    layers = []
    for k in range(30):
        x1 = 250 + rnd.uniform(-50, 50)
        apex = (140 + rnd.uniform(-30, 30), 20 + rnd.uniform(-10, 20))
        r = rnd.uniform(7, 13)
        t0 = rnd.randint(0, 5)
        layers.append(layer('drop', [group([ellipse((0, 0), (r * 0.8, r)), gfill([(0, hexc('#BFE3FF')), (1, hexc('#4A9BE0'))], (0, -r / 2), (0, r / 2))])], 0, n,
                            ks=transform(p=anim([(t0, [20, 90, 0]), (t0 + 9, [apex[0], apex[1], 0]), (t0 + 17, [x1, 104, 0])], EASE_IO),
                                         o=anim([(t0, 0), (t0 + 2, 100), (t0 + 17, 100), (t0 + 20, 0)]))))
    layers += puffs(n, (250, 104), (250, 80), 6, '#D6EEFF', 8, 60, 34, seed=14, life=10, alpha=0.8)
    save('water_throw.json', comp('water_throw', 320, 120, 24, n, layers))


def weak_puff():
    """An empty extinguisher: two thin grey puffs that die at once; one shot."""
    n = 18
    layers = puffs(n, (10, 60), (90, 52), 6, '#C9CED3', 14, 64, 10, seed=15, life=14, alpha=0.9)
    save('weak_puff.json', comp('weak_puff', 320, 120, 24, n, layers))


def rescue_bloom():
    """The fire is out: a white cloud blooms and settles, stars pop; one shot."""
    n = 40
    layers = []
    rnd = random.Random(17)
    for k in range(14):
        a = rnd.uniform(0, math.tau)
        d = rnd.uniform(30, 120)
        x1, y1 = 160 + math.cos(a) * d, 120 + math.sin(a) * d * 0.55
        r1 = rnd.uniform(50, 100)
        t0 = rnd.randint(0, 6)
        layers.append(layer('cloud', [group([ellipse((0, 0), (100, 100)), gfill([(0, hexc('#FFFFFF', 1)), (1, hexc('#F2F5F8', 0))], (0, 0), (50, 0), radial=True)])], 0, n,
                            ks=transform(p=anim([(t0, [160, 130, 0]), (t0 + 22, [x1, y1, 0])], EASE_OUT),
                                         s=anim([(t0, [10, 10, 100]), (t0 + 22, [r1, r1, 100])], EASE_OUT),
                                         o=anim([(t0, 0), (t0 + 4, 95), (t0 + 26, 70), (n, 0)]))))
    for k in range(6):
        a = k * math.tau / 6 + 0.3
        x1, y1 = 160 + math.cos(a) * 120, 110 + math.sin(a) * 70
        t0 = 10 + k * 2
        layers.append(layer('star', [star(0, 0, 9, '#F2B632')], 0, n,
                            ks=transform(p=anim([(t0, [160, 115, 0]), (t0 + 12, [x1, y1, 0])], EASE_OUT),
                                         s=anim([(t0, [0, 0, 100]), (t0 + 6, [130, 130, 100]), (t0 + 12, [80, 80, 100])]),
                                         r=anim([(t0, 0), (t0 + 16, 120)]),
                                         o=anim([(t0, 0), (t0 + 2, 100), (t0 + 14, 100), (t0 + 20, 0)]))))
    save('rescue_bloom.json', comp('rescue_bloom', 320, 240, 24, n, layers))


def flare_up():
    """Water on burning oil: the fire leaps up and spreads; one shot (2 s)."""
    n = 48
    tongues = [(40 + k * 48, 356, 70, 110 + (k % 3) * 40, k % 3) for k in range(6)]
    fl = flame_layers(24, tongues, seed=21)
    # Grow the whole fire from small to huge and wide (it fits the tall box).
    for l in fl:
        l['op'] = n
        l['ks'] = transform(p=(160, 356), a=(160, 356), s=anim([(0, [60, 50, 100]), (14, [150, 170, 100]), (n, [170, 200, 100])], EASE_OUT))
    flash = layer('flash', [group([ellipse((160, 250), (420, 420)), gfill([(0, hexc('#FF8A1F', 0.7)), (1, hexc('#FF8A1F', 0.0))], (160, 250), (370, 250), radial=True)])], 0, n,
                  ks=transform(o=anim([(0, 0), (6, 100), (n, 45)])))
    splash = puffs(n, (160, 350), (160, 290), 8, '#D6EEFF', 10, 70, 80, seed=22, life=12, alpha=0.8)
    save('flare_up.json', comp('flare_up', 320, 360, 24, n, splash + fl + [flash]))


if __name__ == '__main__':
    fire_loop()
    smoke_loop()
    spray_dcp()
    spray_co2()
    sand_throw()
    water_throw()
    weak_puff()
    rescue_bloom()
    flare_up()
