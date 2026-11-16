"""Mistake-card art for m6_meter_swap_proof (lesson 6.10, do_6_10_b).

Each card: the wrong way on the left (red cross), the right way on the right
(green tick). Gradient SVGs, no words except what a worker reads on a meter
screen. Writes into assets/game/art/m6_meter_swap_proof/.

    python -I tool/m6_meter_swap_proof_art.py
"""
from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / 'assets' / 'game' / 'art' / 'm6_meter_swap_proof'

HEAD = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">
  <defs>
    <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#cfe3f3"/><stop offset="1" stop-color="#fdf8ec"/></linearGradient>
    <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#ead9b8"/><stop offset="1" stop-color="#d6c19a"/></linearGradient>
    <linearGradient id="meter" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#3d4650"/><stop offset="1" stop-color="#242a31"/></linearGradient>
    <linearGradient id="lcd" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#b7d3a2"/><stop offset="1" stop-color="#9ebe88"/></linearGradient>
    <linearGradient id="porc" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ffffff"/><stop offset="1" stop-color="#d9d6cf"/></linearGradient>
    <linearGradient id="skin" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#e2a87c"/><stop offset="1" stop-color="#b97a52"/></linearGradient>
    <linearGradient id="steel" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9aa3ab"/><stop offset="0.5" stop-color="#e9edf0"/><stop offset="1" stop-color="#7b848c"/></linearGradient>
    <radialGradient id="spark"><stop offset="0" stop-color="#ffffff"/><stop offset="0.5" stop-color="#ffe066"/><stop offset="1" stop-color="#ff8a00" stop-opacity="0"/></radialGradient>
  </defs>
  <rect x="4" y="4" width="312" height="192" rx="12" fill="url(#sky)" stroke="#c48a2e" stroke-width="3"/>
  <rect x="12" y="14" width="140" height="150" rx="6" fill="url(#wall)"/>
  <rect x="168" y="14" width="140" height="150" rx="6" fill="url(#wall)"/>
  <line x1="160" y1="16" x2="160" y2="184" stroke="#e1d4b8" stroke-width="2" stroke-dasharray="5 4"/>
'''
TAIL = '''  <g transform="translate(80 178)"><circle r="12" fill="#c0392b"/><path d="M-6 -6 L6 6 M6 -6 L-6 6" stroke="#fff" stroke-width="3.5" stroke-linecap="round"/></g>
  <g transform="translate(240 178)"><circle r="12" fill="#2e8b45"/><path d="M-7 0 l5 5 l9 -10" fill="none" stroke="#fff" stroke-width="3.5" stroke-linecap="round" stroke-linejoin="round"/></g>
</svg>
'''


def meter(x, y, screen='04127.6', unit='kWh', seal_ok=True, blank=False):
    """An electronic meter at (x, y) (top-left), 56 × 84."""
    lcd = '#4c5a48' if blank else 'url(#lcd)'
    txt = '' if blank else (
        f'<text x="{x + 24}" y="{y + 25}" font-family="monospace" font-size="9" font-weight="bold" text-anchor="middle" fill="#1c2a16">{screen}</text>'
        f'<text x="{x + 45}" y="{y + 28}" font-family="sans-serif" font-size="5" font-weight="bold" text-anchor="middle" fill="#1c2a16">{unit}</text>')
    seal = (f'<line x1="{x + 22}" y1="{y + 78}" x2="{x + 28}" y2="{y + 86}" stroke="#9aa0a6" stroke-width="1.2"/>'
            f'<circle cx="{x + 28}" cy="{y + 87}" r="3.4" fill="#a7adb2"/>') if seal_ok else (
            f'<line x1="{x + 22}" y1="{y + 78}" x2="{x + 20}" y2="{y + 92}" stroke="#9aa0a6" stroke-width="1.2"/>'
            f'<circle cx="{x + 18}" cy="{y + 96}" r="3.4" fill="#a7adb2"/>')
    return (f'<rect x="{x}" y="{y}" width="56" height="84" rx="6" fill="url(#meter)" stroke="#15191c" stroke-width="1.4"/>'
            f'<rect x="{x + 6}" y="{y + 14}" width="44" height="18" rx="2" fill="{lcd}" stroke="#1a1e22"/>' + txt +
            f'<circle cx="{x + 46}" cy="{y + 42}" r="4" fill="#2c4560" stroke="#1a1e22"/>'
            f'<rect x="{x + 6}" y="{y + 58}" width="44" height="20" rx="3" fill="#2e353c" stroke="#15191c"/>' + seal)


def cutout(x, y, carrier_in=True):
    """The cut-out base at (x, y), 22 × 44; the carrier in or out (lower)."""
    cy = y + 9 if carrier_in else y + 52
    return (f'<rect x="{x}" y="{y}" width="22" height="44" rx="4" fill="url(#porc)" stroke="#9a968c"/>'
            f'<rect x="{x + 5}" y="{y + 2}" width="12" height="4" fill="#b8862e"/><rect x="{x + 5}" y="{y + 38}" width="12" height="4" fill="#b8862e"/>'
            f'<rect x="{x + 2}" y="{cy}" width="18" height="26" rx="3" fill="url(#porc)" stroke="#8f8a80"/>'
            f'<line x1="{x + 11}" y1="{cy + 4}" x2="{x + 11}" y2="{cy + 22}" stroke="#b8862e" stroke-width="2"/>')


def hand(x, y, rot=0):
    return (f'<g transform="translate({x} {y}) rotate({rot})"><path d="M0 0 q10 -8 22 -4 l10 2 q4 2 0 6 l-10 0 l10 4 q3 3 -1 5 l-14 -2 q-12 2 -17 -5 z" fill="url(#skin)" stroke="#8a5a3a" stroke-width="1"/></g>')


def spark(x, y, r=16):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="url(#spark)"/>'


def clipboard(x, y):
    return (f'<rect x="{x}" y="{y}" width="34" height="44" rx="3" fill="#8b5e34"/>'
            f'<rect x="{x + 4}" y="{y + 6}" width="26" height="34" fill="#fdf8ec"/>'
            f'<rect x="{x + 11}" y="{y - 3}" width="12" height="7" rx="2" fill="#7d858c"/>'
            + ''.join(f'<line x1="{x + 8}" y1="{y + 14 + i * 7}" x2="{x + 26}" y2="{y + 14 + i * 7}" stroke="#7d858c" stroke-width="1.6"/>' for i in range(3)))


def wrench(x, y, rot=-30):
    return (f'<g transform="translate({x} {y}) rotate({rot})"><rect x="-3" y="0" width="6" height="34" rx="2" fill="url(#steel)" stroke="#5e666d"/>'
            f'<path d="M-8 0 a8 8 0 1 1 16 0 l-4 0 l0 -5 l-8 0 l0 5 z" fill="url(#steel)" stroke="#5e666d"/></g>')


def tester(x, y, lit):
    lamp = '#ff5a3c' if lit else '#3a4452'
    return (f'<g transform="translate({x} {y}) rotate(-35)"><rect x="-4" y="0" width="8" height="30" rx="3" fill="#e0b13a" stroke="#7a5a10"/>'
            f'<rect x="-1" y="-10" width="2" height="10" fill="#9aa3ab"/><circle cx="0" cy="8" r="2.6" fill="{lamp}"/></g>')


def phone(x, y, frames):
    """A phone at (x, y) (52 × 86) with photo frames: list of (text, unit) or None."""
    out = [f'<rect x="{x}" y="{y}" width="52" height="86" rx="7" fill="#1a1e22" stroke="#0b0e10" stroke-width="1.4"/>',
           f'<rect x="{x + 4}" y="{y + 8}" width="44" height="68" rx="2" fill="#2a3240"/>']
    for i, f in enumerate(frames):
        fy = y + 12 + i * 32
        if f is None:
            out.append(f'<rect x="{x + 7}" y="{fy}" width="38" height="26" rx="2" fill="#2a3240" stroke="#55627a" stroke-dasharray="3 2"/>')
        else:
            out.append(f'<rect x="{x + 7}" y="{fy}" width="38" height="26" rx="2" fill="#1a1e22"/>'
                       f'<rect x="{x + 9}" y="{fy + 5}" width="34" height="16" rx="1" fill="url(#lcd)"/>'
                       f'<text x="{x + 22}" y="{fy + 16}" font-family="monospace" font-size="7" font-weight="bold" text-anchor="middle" fill="#1c2a16">{f[0]}</text>'
                       f'<text x="{x + 38}" y="{fy + 19}" font-family="sans-serif" font-size="4.5" font-weight="bold" text-anchor="middle" fill="#1c2a16">{f[1]}</text>')
    return ''.join(out)


def magnet(x, y):
    return (f'<rect x="{x}" y="{y}" width="20" height="13" rx="2" fill="url(#steel)" stroke="#5e666d"/>'
            f'<rect x="{x + 3}" y="{y + 3}" width="14" height="7" rx="1" fill="#30353a"/>'
            f'<line x1="{x + 6}" y1="{y + 6.5}" x2="{x + 14}" y2="{y + 6.5}" stroke="#b03a2e" stroke-width="1.6"/>')


def svc(x1, y1, x2, y2, w=4):
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="#1b1d20" stroke-width="{w}" stroke-linecap="round"/>'


CARDS = {
    # Pulling a bypass by hand (deadly) | report and keep away.
    'bypass_pull': (
        svc(14, 40, 70, 60) + svc(70, 60, 130, 70) + svc(70, 60, 92, 120, 3) + meter(90, 70)[:0] +
        f'<rect x="64" y="55" width="12" height="9" rx="2" fill="#111214"/>' + hand(78, 98, -60) + spark(76, 66, 20),
        svc(170, 40, 226, 60) + svc(226, 60, 286, 70) + svc(226, 60, 248, 120, 3) + '<rect x="220" y="55" width="12" height="9" rx="2" fill="#111214"/>' + clipboard(258, 100)),
    # The box opened with the cut-out in (deadly) | cut-out out, tester 0 V.
    'live_swap': (
        cutout(24, 40, True) + meter(70, 40) + wrench(110, 110, -150) + spark(98, 110, 18),
        cutout(180, 40, False) + meter(226, 40, blank=True) + tester(196, 30, False)),
    # A change started on a tampered meter | report.
    'start_tamper': (
        meter(40, 40, seal_ok=False) + wrench(118, 70, 30),
        meter(196, 40, seal_ok=False) + clipboard(262, 70)),
    # A clean meter reported | the change made.
    'false_report': (
        meter(40, 40) + clipboard(104, 70),
        meter(196, 40) + wrench(274, 70, 30)),
    # The magnet taken off by hand | left as it is, reported.
    'magnet': (
        meter(40, 40) + magnet(104, 70) + hand(122, 86, 200),
        meter(196, 40) + magnet(254, 70) + clipboard(270, 100)),
    # A reseal by hand | the cut seal left, reported.
    'reseal': (
        meter(40, 40, seal_ok=False) + '<circle cx="70" cy="128" r="4" fill="#e9edf0" stroke="#7d858c"/>' + hand(78, 136, -20),
        meter(196, 40, seal_ok=False) + clipboard(262, 70)),
    # No photo of a reading | both photos.
    'photo_missing': (
        meter(28, 40) + phone(92, 40, [None, None]),
        meter(184, 40) + phone(248, 40, [('04127.6', 'kWh'), ('00001.2', 'kWh')])),
    # A photo of another screen | the kWh screen.
    'photo_screen': (
        meter(28, 40, '231', 'V') + phone(92, 40, [('231', 'V'), None]),
        meter(184, 40) + phone(248, 40, [('04127.6', 'kWh'), None])),
    # The cut-out out but no 0 V seen | the tester on the load contact.
    'no_test': (
        cutout(24, 40, False) + meter(70, 40, blank=True) + hand(112, 120, 200) + '<text x="44" y="30" font-family="sans-serif" font-size="18" font-weight="bold" fill="#c0392b">?</text>',
        cutout(180, 40, False) + meter(226, 40, blank=True) + tester(196, 88, False)),
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (left, right) in CARDS.items():
        (OUT / f'{name}.svg').write_text(HEAD + '  ' + left + '\n  ' + right + '\n' + TAIL, encoding='utf-8')
    gk = OUT / '.gitkeep'
    if gk.exists():
        gk.unlink()
    print(f'wrote {len(CARDS)} cards to {OUT}')


if __name__ == '__main__':
    main()
