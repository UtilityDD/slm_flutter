"""Mistake-card pictures for lesson 8.5 do_8_5_a (m8_clearance_gauge).

python -I tool/m8_gauge_art.py assets/game/art/m8_clearance_gauge

six 320 x 200 SVGs, no words: a low 11 kV span with a truck under it, a sound span
with a tick, the same for an LT house span, the covered-conductor myth and the
"seen from the van" shortcut. Content from lesson 8.5 (live text) only.
"""
import io, os, sys
out = sys.argv[1]
os.makedirs(out, exist_ok=True)
HEAD = '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200" width="320" height="200">
<defs>
<linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#bfe0f2"/><stop offset="1" stop-color="#eef7fb"/></linearGradient>
<linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#b8b4aa"/><stop offset="1" stop-color="#8d887e"/></linearGradient>
<linearGradient id="lane" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#7a7e85"/><stop offset="1" stop-color="#5b5f66"/></linearGradient>
</defs>
<rect x="4" y="4" width="312" height="192" rx="12" fill="url(#sky)" stroke="#c48a2e" stroke-width="3"/>
'''
TAIL = '</svg>\n'

def road(wire_d, truck=False, tag=None, cover=False):
    s = '<rect x="6" y="168" width="308" height="26" fill="#8c8577"/><rect x="6" y="166" width="308" height="8" fill="#3d4047"/>'
    s += '<path d="M30 168 L34 46 L40 46 L44 168 Z" fill="url(#pole)"/><path d="M276 168 L280 46 L286 46 L290 168 Z" fill="url(#pole)"/>'
    s += '<rect x="26" y="44" width="22" height="4" fill="#4b4b4b"/><rect x="272" y="44" width="22" height="4" fill="#4b4b4b"/>'
    w = 'M37 46 Q160 %d 283 46' % wire_d
    if cover:
        s += '<path d="%s" fill="none" stroke="#1e2228" stroke-width="7"/><path d="%s" fill="none" stroke="#6f7c86" stroke-width="4.5"/>' % (w, w)
    else:
        s += '<path d="%s" fill="none" stroke="#1e2228" stroke-width="3"/>' % w
    if truck:
        s += '<rect x="108" y="122" width="96" height="42" rx="4" fill="#8a6a35"/><rect x="112" y="126" width="30" height="14" fill="#cfe4ef"/><circle cx="128" cy="166" r="7" fill="#1a1a1a"/><circle cx="184" cy="166" r="7" fill="#1a1a1a"/>'
    if tag == 'ok':
        s += '<circle cx="256" cy="86" r="22" fill="#2f8f4e"/><path d="M245 86 l8 9 l15 -18" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
    if tag == 'x':
        s += '<circle cx="256" cy="86" r="22" fill="#d94a3a"/><path d="M246 76 l20 20 M266 76 l-20 20" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
    return s

def lt(gap, ok=True, tag=None):
    s = '<rect x="6" y="6" width="308" height="188" rx="10" fill="url(#lane)"/>'
    s += '<rect x="6" y="%d" width="308" height="%d" fill="#c9906b"/>' % (110, 84)
    s += '<rect x="130" y="%d" width="86" height="%d" fill="#e2b894" stroke="#5b3a2a" stroke-width="3"/>' % (110 - 22, 22)
    ly = 110 - 22 - gap
    s += '<line x1="6" y1="%d" x2="314" y2="%d" stroke="#1e2228" stroke-width="3"/>' % (ly, ly)
    s += '<circle cx="40" cy="%d" r="9" fill="#b8b4aa" stroke="#4b4b4b" stroke-width="2"/><circle cx="280" cy="%d" r="9" fill="#b8b4aa" stroke="#4b4b4b" stroke-width="2"/>' % (ly, ly)
    s += '<line x1="173" y1="%d" x2="173" y2="%d" stroke="#fff" stroke-width="2" stroke-dasharray="5 4"/>' % (ly, 110 - 22)
    if tag == 'ok':
        s += '<circle cx="256" cy="150" r="20" fill="#2f8f4e"/><path d="M246 150 l7 8 l13 -16" fill="none" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
    if tag == 'x':
        s += '<circle cx="256" cy="150" r="20" fill="#d94a3a"/><path d="M247 141 l18 18 M265 141 l-18 18" stroke="#fff" stroke-width="5" stroke-linecap="round"/>'
    return s

def write(name, body):
    with io.open(os.path.join(out, name), 'w', encoding='utf-8', newline='\n') as f:
        f.write(HEAD + body + TAIL)

write('missed_road.svg', road(96, truck=True, tag='x'))
write('false_road.svg', road(40, tag='ok'))
write('missed_lt.svg', lt(26, tag='x'))
write('false_lt.svg', lt(62, tag='ok'))
# listen: a covered wire with a pin-hole crack (myth) and a van seen only from afar (shortcut)
write('listen_myth.svg', road(70, cover=True) + '<circle cx="160" cy="75" r="6" fill="#f7d046" stroke="#d94a3a" stroke-width="2"/><path d="M160 66 l-4 -10 l8 4 l-4 -10" stroke="#f7d046" stroke-width="2.5" fill="none"/>')
write('listen_shortcut.svg', road(88) + '<rect x="30" y="140" width="64" height="30" rx="5" fill="#ededed" stroke="#1c2e4a" stroke-width="2"/><circle cx="46" cy="172" r="6" fill="#222"/><circle cx="80" cy="172" r="6" fill="#222"/><line x1="160" y1="90" x2="160" y2="166" stroke="#fff" stroke-width="2.5" stroke-dasharray="6 4"/>')
