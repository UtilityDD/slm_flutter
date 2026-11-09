"""Picture cards for ladder step 28 (lesson 1.10 শেখা, "১০ সেকেন্ডের মেন্টাল চেকলিস্ট").

python -I tool/scan_board_art.py .

Writes assets/game/art/scan_board/*.svg in canonical vector style matching
tool/harness_board_art.py, tool/pole_board_art.py and tool/ptw_board_art.py
(200 x 220 scene cards, drawn edge to edge).

Every card features macro, high-contrast, field-authentic electrical utility
equipment and inspection checks. Defect items (such as nails in boot soles,
unbuckled chin straps, loose harness buckles, rusted pole bases) are rendered
as large, unmistakable macro visual elements that players can easily spot and recognize.
No words or text tags in the art.
"""

import math
import os
import sys

ROOT = sys.argv[1] if len(sys.argv) > 1 else '.'
if __name__ == '__main__' and (len(sys.argv) > 2 or not os.path.isfile(os.path.join(ROOT, 'pubspec.yaml'))):
    print('usage: python -I tool/scan_board_art.py <repo root>')
    sys.exit(2)
OUT = os.path.join(ROOT, 'assets', 'game', 'art', 'scan_board')
W, H = 200, 220

# Canonical project palette
SHIRT = '#1F5F8F'
SHIRT_D = '#174A70'
PANTS = '#2A3442'
PANTS_D = '#222B37'
SKIN = '#A86E48'
SKIN_D = '#8C5A3A'
HAIR = '#2A1E16'
HELMET = '#FFD34E'
HELMET_D = '#E5B92E'
BOOT = '#1C1F24'
BOOT_D = '#121418'
WIRE = '#2B3138'
RAIL = '#B0B7BD'
RED = '#D32F2F'
YELLOW = '#FBC02D'
WOOD = '#8A6A3E'
WOOD_D = '#5E4626'
METAL = '#B0B7BD'
WHITE = '#FFFFFF'
LADDER = '#D4A359'
CONE_O = '#E65100'

DEFS = """<defs>
  <linearGradient id="sky" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8EC3EA"/><stop offset="1" stop-color="#E9F2F7"/></linearGradient>
  <linearGradient id="ground" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#CDBB93"/><stop offset="1" stop-color="#AF9C74"/></linearGradient>
  <linearGradient id="pole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#9E9B93"/><stop offset="0.5" stop-color="#D3D0C8"/><stop offset="1" stop-color="#97948C"/></linearGradient>
  <linearGradient id="steelArm" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A939B"/><stop offset="1" stop-color="#4F575F"/></linearGradient>
  <linearGradient id="porcelain" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#C9D2D8"/><stop offset="0.5" stop-color="#FFFFFF"/><stop offset="1" stop-color="#B8C2C9"/></linearGradient>
  <linearGradient id="shirt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#1A5280"/><stop offset="0.5" stop-color="#2A6EA3"/><stop offset="1" stop-color="#184B75"/></linearGradient>
  <linearGradient id="webO" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FF9F45"/><stop offset="0.5" stop-color="#F7811F"/><stop offset="1" stop-color="#D9640C"/></linearGradient>
  <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#F4F7F9"/><stop offset="0.45" stop-color="#C3CBD1"/><stop offset="1" stop-color="#7D868E"/></linearGradient>
  <linearGradient id="board" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#9A6A3C"/><stop offset="1" stop-color="#6E4524"/></linearGradient>
  <linearGradient id="paper" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FFFFFF"/><stop offset="1" stop-color="#ECEFF2"/></linearGradient>
  <linearGradient id="bench" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#C9965E"/><stop offset="1" stop-color="#9E6B38"/></linearGradient>
  <linearGradient id="rust" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#C46A2B"/><stop offset="0.5" stop-color="#9A4517"/><stop offset="1" stop-color="#6E2E0E"/></linearGradient>
  <linearGradient id="cone" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#E65100"/><stop offset="0.5" stop-color="#FF7A29"/><stop offset="1" stop-color="#D84315"/></linearGradient>
  <linearGradient id="bootSole" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#111827"/><stop offset="0.4" stop-color="#1F2937"/><stop offset="1" stop-color="#0F172A"/></linearGradient>
  <linearGradient id="bootLug" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#374151"/><stop offset="1" stop-color="#111827"/></linearGradient>
  <linearGradient id="helmetDome" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#FEF08A"/><stop offset="0.25" stop-color="#FACC15"/><stop offset="1" stop-color="#CA8A04"/></linearGradient>
  <radialGradient id="wireGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFE38A" stop-opacity="0.6"/><stop offset="1" stop-color="#FFE38A" stop-opacity="0"/></radialGradient>
  <radialGradient id="flash" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#FFFFFF" stop-opacity="0.85"/><stop offset="0.4" stop-color="#FFF4B0" stop-opacity="0.45"/><stop offset="1" stop-color="#FFF4B0" stop-opacity="0"/></radialGradient>
  <radialGradient id="hazardGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#EF4444" stop-opacity="0.55"/><stop offset="0.7" stop-color="#EF4444" stop-opacity="0.15"/><stop offset="1" stop-color="#EF4444" stop-opacity="0"/></radialGradient>
  <radialGradient id="safeGlow" cx="0.5" cy="0.5" r="0.5"><stop offset="0" stop-color="#10B981" stop-opacity="0.4"/><stop offset="1" stop-color="#10B981" stop-opacity="0"/></radialGradient>
  <clipPath id="card"><rect x="0" y="0" width="200" height="220" rx="18"/></clipPath>
</defs>"""


def make_card(body_svg, back='sky'):
    return '\n'.join([
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" width="{W}" height="{H}">',
        DEFS,
        '<g clip-path="url(#card)">',
        f'<rect width="{W}" height="{H}" fill="url(#{back})"/>',
        body_svg,
        '</g>',
        '<rect x="0.75" y="0.75" width="198.5" height="218.5" rx="17.5" fill="none" stroke="#FFFFFF" stroke-opacity="0.55" stroke-width="1.5"/>',
        '</svg>'
    ])


# -----------------------------------------------------------------------------
# MACRO DRAWING HELPERS
# -----------------------------------------------------------------------------

def draw_boot_sole_macro(nail=False, cracked=False, eh_shield=True):
    """Macro close-up of heavy-duty Electrical Hazard (EH) safety boot sole."""
    g = []
    # Workshop bench backdrop with wooden planks
    g.append('<rect width="200" height="220" fill="url(#bench)"/>')
    for y in (42, 96, 150, 204):
        g.append(f'<line x1="0" y1="{y}" x2="200" y2="{y}" stroke="#7E5229" stroke-width="1.2" opacity="0.6"/>')

    # Soft drop shadow beneath sole
    g.append('<path d="M62 48 C57 24 82 18 102 18 C122 18 147 24 142 48 C140 68 147 98 147 113 C147 128 130 138 127 148 L140 161 C144 178 140 203 102 203 C64 203 60 178 64 161 L77 148 C74 138 57 128 57 113 C57 98 64 68 62 48 Z" fill="#000000" opacity="0.32"/>')

    # Heavy rubber boot sole contour
    sole_d = "M60 45 C55 20 80 14 100 14 C120 14 145 20 140 45 C138 65 145 95 145 110 C145 125 128 135 125 145 L138 158 C142 175 138 200 100 200 C62 200 58 175 62 158 L75 145 C72 135 55 125 55 110 C55 95 62 65 60 45 Z"
    g.append(f'<path d="{sole_d}" fill="url(#bootSole)" stroke="#090D14" stroke-width="2.6"/>')

    # Inset welt bevel
    welt_d = "M64 47 C60 25 82 20 100 20 C118 20 140 25 136 47 C134 65 140 93 140 108 C140 121 125 131 122 142 L134 155 C137 170 134 194 100 194 C66 194 63 170 66 155 L78 142 C75 131 60 121 60 108 C60 93 66 65 64 47 Z"
    g.append(f'<path d="{welt_d}" fill="none" stroke="#374151" stroke-width="1.4" opacity="0.8"/>')

    # Deep traction lugs on forefoot & ball (Left & Right perimeter teeth)
    for y in [34, 52, 70, 88, 106]:
        g.append(f'<path d="M60 {y} L76 {y+4} L76 {y+14} L58 {y+10} Z" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="1.2"/>')
        g.append(f'<path d="M140 {y} L124 {y+4} L124 {y+14} L142 {y+10} Z" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="1.2"/>')

    # Central Chevron traction treads down the ball of the foot
    for cy in [32, 50, 68, 86, 104]:
        g.append(f'<path d="M82 {cy+6} L100 {cy} L118 {cy+6} L115 {cy+14} L100 {cy+8} L85 {cy+14} Z" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="1.2"/>')
        g.append(f'<path d="M84 {cy+7} L100 {cy+2} L116 {cy+7}" stroke="#4B5563" stroke-width="1" fill="none" opacity="0.6"/>')

    # Arch / Shank area
    g.append('<rect x="84" y="126" width="32" height="20" rx="3" fill="#1F2937" stroke="#0B0E14" stroke-width="1.5"/>')
    for sy in [131, 136, 141]:
        g.append(f'<line x1="88" y1="{sy}" x2="112" y2="{sy}" stroke="#4B5563" stroke-width="1.4"/>')

    # Heel Lugs (4 corner blocks and center heel cup)
    g.append('<rect x="68" y="162" width="18" height="15" rx="3" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="1.4"/>')
    g.append('<rect x="114" y="162" width="18" height="15" rx="3" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="1.4"/>')
    g.append('<path d="M70 182 C70 194 84 195 100 195 C116 195 130 194 130 182 L126 174 C116 182 84 182 74 174 Z" fill="url(#bootLug)" stroke="#0B0E14" stroke-width="1.4"/>')
    g.append('<ellipse cx="100" cy="172" rx="12" ry="7" fill="#111827" stroke="#374151" stroke-width="1.2"/>')

    # EH (Electrical Hazard) Safety Shield Emblem in Arch
    if eh_shield and not nail and not cracked:
        g.append('<circle cx="100" cy="136" r="16" fill="url(#safeGlow)"/>')
        g.append('<polygon points="100 126 109 130 109 138 100 144 91 138 91 130" fill="url(#steel)" stroke="#CA8A04" stroke-width="1.2"/>')
        g.append('<polygon points="101 129 97 135 100 135 99 141 104 134 101 134" fill="#EAB308"/>')

    # CRACKED SOLE / NAIL HAZARDS
    if nail:
        nx, ny = 100, 75
        # Danger warning glow halo
        g.append(f'<circle cx="{nx}" cy="{ny}" r="28" fill="url(#hazardGlow)"/>')
        g.append(f'<circle cx="{nx}" cy="{ny}" r="22" fill="none" stroke="{RED}" stroke-width="2" stroke-dasharray="4 2.5"/>')
        # Stress fracture cracks radiating from puncture point
        g.append(f'<path d="M{nx-8} {ny-4} L{nx-18} {ny-10} M{nx+6} {ny-5} L{nx+16} {ny-12} M{nx-4} {ny+8} L{nx-12} {ny+18} M{nx+8} {ny+6} L{nx+20} {ny+14}" stroke="{RED}" stroke-width="2.2" stroke-linecap="round"/>')
        g.append(f'<path d="M{nx-18} {ny-10} L{nx-24} {ny-8} M{nx+16} {ny-12} L{nx+22} {ny-16}" stroke="{YELLOW}" stroke-width="1.4" stroke-linecap="round"/>')
        # Sharp metallic construction nail driven into the tread
        # Nail shank angled into rubber
        g.append('<polygon points="97 86 103 86 101 99 99 99" fill="url(#steel)" stroke="#475569" stroke-width="0.8"/>')
        # Large steel nail head (angled perspective)
        g.append(f'<ellipse cx="{nx}" cy="{ny}" rx="10" ry="7.5" fill="url(#steel)" stroke="#334155" stroke-width="1.6"/>')
        g.append(f'<ellipse cx="{nx-1.5}" cy="{ny-1.2}" rx="7.5" ry="5.5" fill="none" stroke="#FFFFFF" stroke-width="1.2" opacity="0.9"/>')
        g.append(f'<circle cx="{nx}" cy="{ny}" r="2.5" fill="#1E293B"/>')
        # Jagged fracture split in the rubber lug
        g.append(f'<path d="M{nx-14} {ny+2} Q{nx} {ny+5} {nx+14} {ny+1}" stroke="#000000" stroke-width="2.8" fill="none"/>')

    if cracked:
        # Deep jagged split across the ball of the sole rubber
        g.append(f'<path d="M58 84 L76 88 L92 82 L108 90 L126 84 L142 88" stroke="#000000" stroke-width="5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
        g.append(f'<path d="M58 84 L76 88 L92 82 L108 90 L126 84 L142 88" stroke="url(#rust)" stroke-width="3" fill="none" stroke-linecap="round" stroke-linejoin="round"/>')
        g.append(f'<path d="M58 84 L76 88 L92 82 L108 90 L126 84 L142 88" stroke="{RED}" stroke-width="1.4" stroke-dasharray="3 3" fill="none"/>')

    return ''.join(g)


def draw_helmet_macro(buckled=True):
    """Macro close-up of safety helmet (hard hat) and chin strap."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    # Soft clouds
    g.append('<ellipse cx="40" cy="35" rx="30" ry="10" fill="#FFFFFF" opacity="0.6"/>')
    g.append('<ellipse cx="160" cy="45" rx="25" ry="9" fill="#FFFFFF" opacity="0.6"/>')

    # Lineman neck & jaw
    g.append('<path d="M68 120 Q68 185 100 188 Q132 185 132 120 Z" fill="#9C643E"/>')
    g.append('<path d="M74 120 Q74 180 100 183 Q126 180 126 120 Z" fill="url(#shirt)" opacity="0.15"/>')

    # Hard hat shell shadow
    g.append('<ellipse cx="100" cy="118" rx="72" ry="14" fill="#000000" opacity="0.25"/>')

    # Dome contour
    dome = "M32 98 Q36 28 100 24 Q164 28 168 98 Z"
    g.append(f'<path d="{dome}" fill="url(#helmetDome)" stroke="#B45309" stroke-width="2.4"/>')
    # Dome strengthening ribs
    g.append('<path d="M60 88 Q70 42 100 38 Q130 42 140 88" fill="none" stroke="#FDE047" stroke-width="4.5" stroke-linecap="round" opacity="0.6"/>')
    g.append('<path d="M85 75 Q92 36 100 34 Q108 36 115 75" fill="none" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round" opacity="0.75"/>')

    # Rolled brim
    brim = "M22 96 Q100 114 178 96 L174 108 Q100 126 26 108 Z"
    g.append(f'<path d="{brim}" fill="#EAB308" stroke="#A16207" stroke-width="2.2"/>')
    g.append('<path d="M26 100 Q100 116 174 100" stroke="#FEF08A" stroke-width="2" fill="none" opacity="0.8"/>')

    # Quality mark badge on front crown
    g.append('<rect x="91" y="68" width="18" height="14" rx="2.5" fill="#1E293B" stroke="#CA8A04" stroke-width="1.2"/>')
    g.append('<polygon points="100 70 106 74 100 80 94 74" fill="#22C55E"/>')

    # Chin strap anchors at sides
    g.append('<rect x="42" y="104" width="9" height="7" rx="2" fill="url(#steel)"/>')
    g.append('<rect x="149" y="104" width="9" height="7" rx="2" fill="url(#steel)"/>')

    # Chin Straps
    if buckled:
        # Tightly buckled under jaw with locking snap buckle
        g.append('<path d="M46 109 Q56 156 94 158" stroke="#1F2937" stroke-width="6.5" fill="none" stroke-linecap="round"/>')
        g.append('<path d="M46 109 Q56 156 94 158" stroke="#4B5563" stroke-width="1" stroke-dasharray="2.5 2" fill="none"/>')
        g.append('<path d="M154 109 Q144 156 106 158" stroke="#1F2937" stroke-width="6.5" fill="none" stroke-linecap="round"/>')
        g.append('<path d="M154 109 Q144 156 106 158" stroke="#4B5563" stroke-width="1" stroke-dasharray="2.5 2" fill="none"/>')
        # Snap buckle clicked together
        g.append('<rect x="88" y="150" width="24" height="16" rx="4" fill="#111827" stroke="url(#steel)" stroke-width="1.8"/>')
        g.append('<circle cx="100" cy="158" r="3" fill="#22C55E"/>')
        # Chin cup
        g.append('<path d="M84 164 Q100 174 116 164" stroke="#1F2937" stroke-width="4.5" fill="none" stroke-linecap="round"/>')
    else:
        # UNBUCKLED: Straps dangling wide apart loosely
        g.append('<circle cx="100" cy="165" r="32" fill="url(#hazardGlow)"/>')
        g.append('<path d="M46 109 Q42 145 36 178" stroke="#1F2937" stroke-width="6.5" fill="none" stroke-linecap="round"/>')
        g.append(f'<path d="M46 109 Q42 145 36 178" stroke="{RED}" stroke-width="1.2" stroke-dasharray="3 2" fill="none"/>')
        g.append('<rect x="28" y="174" width="16" height="12" rx="3" fill="#111827" stroke="url(#steel)" stroke-width="1.5"/>')

        g.append('<path d="M154 109 Q158 145 164 178" stroke="#1F2937" stroke-width="6.5" fill="none" stroke-linecap="round"/>')
        g.append(f'<path d="M154 109 Q158 145 164 178" stroke="{RED}" stroke-width="1.2" stroke-dasharray="3 2" fill="none"/>')
        g.append('<rect x="156" y="174" width="16" height="12" rx="3" fill="#111827" stroke="url(#steel)" stroke-width="1.5"/>')
        # Red warning dashed arc showing unfastened open space
        g.append(f'<path d="M46 178 Q100 195 154 178" stroke="{RED}" stroke-width="2.5" stroke-dasharray="5 3" fill="none"/>')

    return ''.join(g)


def draw_gloves_macro(punctured=False):
    """Macro close-up of Class-2 Electrical Insulating Rubber Glove Air Test."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#bench)"/>')
    for y in (42, 96, 150, 204):
        g.append(f'<line x1="0" y1="{y}" x2="200" y2="{y}" stroke="#7E5229" stroke-width="1.2" opacity="0.6"/>')

    # Glove balloon shape
    g.append('<ellipse cx="100" cy="115" rx="55" ry="60" fill="#000000" opacity="0.25"/>')
    g.append('<path d="M60 145 C45 110 50 65 72 45 C80 38 90 35 100 35 C110 35 120 38 128 45 C150 65 155 110 140 145 Z" fill="#EA580C" stroke="#9A3412" stroke-width="2.5"/>')
    # Fingers curved
    g.append('<path d="M72 45 Q75 18 84 16 Q92 18 90 42" fill="#EA580C" stroke="#9A3412" stroke-width="2"/>')
    g.append('<path d="M90 40 Q95 12 104 12 Q112 14 110 40" fill="#EA580C" stroke="#9A3412" stroke-width="2"/>')
    g.append('<path d="M110 40 Q118 16 126 18 Q132 24 128 46" fill="#EA580C" stroke="#9A3412" stroke-width="2"/>')
    # Highlights
    g.append('<path d="M72 65 Q100 50 128 65 Q135 105 100 120 Q65 105 72 65 Z" fill="#F97316" opacity="0.6"/>')
    g.append('<ellipse cx="88" cy="75" rx="14" ry="26" fill="#FDBA74" opacity="0.55"/>')

    # Rolled tight cuff at bottom
    g.append('<ellipse cx="100" cy="148" rx="42" ry="12" fill="#C2410C" stroke="#7C2D12" stroke-width="2"/>')
    g.append('<ellipse cx="100" cy="154" rx="46" ry="14" fill="#1E293B" stroke="#0F172A" stroke-width="2"/>')
    g.append('<ellipse cx="100" cy="158" rx="44" ry="12" fill="#C2410C" stroke="#7C2D12" stroke-width="1.8"/>')

    # Two gloved hands gripping cuff
    g.append('<rect x="36" y="142" width="24" height="32" rx="8" fill="#A86E48" stroke="#7C4A2D" stroke-width="1.5"/>')
    g.append('<rect x="140" y="142" width="24" height="32" rx="8" fill="#A86E48" stroke="#7C4A2D" stroke-width="1.5"/>')

    if punctured:
        px, py = 100, 85
        g.append(f'<circle cx="{px}" cy="{py}" r="26" fill="url(#hazardGlow)"/>')
        g.append(f'<circle cx="{px}" cy="{py}" r="18" fill="none" stroke="{RED}" stroke-width="2" stroke-dasharray="3 2"/>')
        # Escaping air hiss sound waves
        for r in (8, 14, 20):
            g.append(f'<path d="M{px-r} {py-r*0.6} Q{px} {py-r*1.3} {px+r} {py-r*0.6}" fill="none" stroke="#FFFFFF" stroke-width="2" stroke-linecap="round"/>')
        g.append(f'<circle cx="{px}" cy="{py}" r="3.5" fill="#1E293B" stroke="{RED}" stroke-width="1.5"/>')
        g.append(f'<path d="M{px-16} {py+6} Q{px} {py+2} {px+16} {py+6}" stroke="#9A3412" stroke-width="2" fill="none"/>')
    else:
        g.append('<circle cx="100" cy="90" r="16" fill="url(#safeGlow)"/>')
        g.append('<polygon points="100 80 109 84 109 92 100 98 91 92 91 84" fill="url(#steel)" stroke="#10B981" stroke-width="1.2"/>')
        g.append('<path d="M96 89 L99 92 L105 86" stroke="#10B981" stroke-width="2" fill="none" stroke-linecap="round"/>')

    return ''.join(g)


def draw_shirt_macro(torn_polyester=False):
    """Macro close-up of lineman torso and shirt fabric."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    # Lineman chest & shoulder filling frame
    g.append('<path d="M20 220 L20 90 Q100 65 180 90 L180 220 Z" fill="url(#shirt)"/>')
    g.append('<path d="M85 78 L100 102 L115 78" stroke="#0E3352" stroke-width="2" fill="none"/>')
    g.append('<line x1="100" y1="102" x2="100" y2="220" stroke="#0E3352" stroke-width="1.5" opacity="0.6"/>')

    for by in (122, 154, 186):
        g.append(f'<circle cx="100" cy="{by}" r="3.5" fill="url(#steel)"/>')

    if torn_polyester:
        g.append('<path d="M30 110 Q70 100 80 140 Q40 150 30 110 Z" fill="#60A5FA" opacity="0.25"/>')
        g.append('<circle cx="145" cy="145" r="28" fill="url(#hazardGlow)"/>')
        g.append('<path d="M125 125 Q165 130 155 165 Q125 170 125 125 Z" fill="#A86E48" stroke="#7C4A2D" stroke-width="1.5"/>')
        g.append(f'<path d="M124 124 Q135 135 130 148 Q140 140 152 145 Q158 155 152 166" stroke="#1E293B" stroke-width="3.5" fill="none" stroke-linecap="round"/>')
        g.append(f'<path d="M125 125 Q136 136 131 149 Q141 141 153 146" stroke="{RED}" stroke-width="1.8" fill="none"/>')
        g.append('<ellipse cx="65" cy="165" rx="16" ry="22" fill="#0B132B" opacity="0.7"/>')
        g.append('<ellipse cx="75" cy="180" rx="10" ry="14" fill="#0B132B" opacity="0.8"/>')
    else:
        g.append('<rect x="42" y="125" width="44" height="48" rx="4" fill="#184B75" stroke="#0E3352" stroke-width="1.5"/>')
        g.append('<path d="M42 138 L86 138" stroke="#0E3352" stroke-width="1.2"/>')
        g.append('<circle cx="64" cy="132" r="2.5" fill="url(#steel)"/>')
        g.append('<rect x="52" y="145" width="24" height="12" rx="2" fill="url(#steel)" opacity="0.85"/>')

    return ''.join(g)


def draw_harness_chest_macro(chest_fit='ok'):
    """Macro close-up of Full Body Harness chest strap."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<path d="M10 220 L10 80 Q100 55 190 80 L190 220 Z" fill="url(#shirt)"/>')

    for sx in (45, 135):
        g.append(f'<rect x="{sx}" y="70" width="20" height="150" fill="url(#webO)" stroke="#9A3412" stroke-width="1.8"/>')
        g.append(f'<line x1="{sx+10}" y1="70" x2="{sx+10}" y2="220" stroke="#FFFFFF" stroke-width="1.5" stroke-dasharray="4 2.5" opacity="0.8"/>')

    if chest_fit == 'ok':
        g.append('<rect x="45" y="115" width="110" height="18" fill="url(#webO)" stroke="#9A3412" stroke-width="1.8"/>')
        g.append('<line x1="45" y1="124" x2="155" y2="124" stroke="#FFFFFF" stroke-width="1.2" stroke-dasharray="3 2" opacity="0.8"/>')
        g.append('<rect x="90" y="110" width="20" height="28" rx="3.5" fill="url(#steel)" stroke="#334155" stroke-width="1.8"/>')
        g.append('<rect x="96" y="116" width="8" height="16" rx="2" fill="#1E293B"/>')
        # 4 fingers testing snug fit under chest strap
        g.append('<rect x="85" y="138" width="30" height="36" rx="6" fill="#A86E48" stroke="#7C4A2D" stroke-width="1.5"/>')
        for fy in (144, 151, 158, 165):
            g.append(f'<line x1="88" y1="{fy}" x2="112" y2="{fy}" stroke="#7C4A2D" stroke-width="1.5"/>')
        g.append('<circle cx="100" cy="92" r="14" fill="url(#safeGlow)"/>')
        g.append('<path d="M94 92 L98 96 L106 88" stroke="#10B981" stroke-width="2.2" fill="none" stroke-linecap="round"/>')
    else:
        g.append('<circle cx="100" cy="135" r="34" fill="url(#hazardGlow)"/>')
        g.append('<path d="M55 118 Q45 155 35 185" stroke="url(#webO)" stroke-width="18" fill="none" stroke-linecap="round"/>')
        g.append('<rect x="24" y="180" width="22" height="18" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="1.6"/>')
        g.append('<path d="M145 118 Q155 155 165 185" stroke="url(#webO)" stroke-width="18" fill="none" stroke-linecap="round"/>')
        g.append('<rect x="154" y="180" width="22" height="18" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="1.6"/>')
        g.append(f'<path d="M46 188 Q100 205 154 188" stroke="{RED}" stroke-width="2.5" stroke-dasharray="5 3" fill="none"/>')

    return ''.join(g)


def draw_harness_expired_macro():
    """Macro close-up of harness webbing: frayed cut fibers & expired tag."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#bench)"/>')
    for y in (42, 96, 150, 204):
        g.append(f'<line x1="0" y1="{y}" x2="200" y2="{y}" stroke="#7E5229" stroke-width="1.2" opacity="0.6"/>')

    g.append('<rect x="15" y="70" width="170" height="55" rx="4" fill="url(#webO)" stroke="#9A3412" stroke-width="2"/>')
    g.append('<line x1="15" y1="84" x2="185" y2="84" stroke="#FFFFFF" stroke-width="1.5" stroke-dasharray="4 2" opacity="0.8"/>')
    g.append('<line x1="15" y1="111" x2="185" y2="111" stroke="#FFFFFF" stroke-width="1.5" stroke-dasharray="4 2" opacity="0.8"/>')

    # Severely frayed, cut strands
    g.append('<path d="M80 68 Q95 95 110 68 Z" fill="url(#bench)"/>')
    for fx, fy in ((82, 70), (86, 76), (90, 82), (95, 78), (100, 84), (105, 74), (108, 69)):
        g.append(f'<line x1="{fx}" y1="{fy}" x2="{fx+2}" y2="{fy-8}" stroke="#FFFFFF" stroke-width="1.6" stroke-linecap="round"/>')
        g.append(f'<line x1="{fx}" y1="{fy}" x2="{fx-3}" y2="{fy-7}" stroke="#F97316" stroke-width="1.4" stroke-linecap="round"/>')

    g.append('<rect x="35" y="80" width="35" height="35" fill="none" stroke="#1E293B" stroke-width="1.5" stroke-dasharray="3 2"/>')
    g.append(f'<line x1="35" y1="80" x2="70" y2="115" stroke="{RED}" stroke-width="2"/>')

    # White inspection tag showing EXPIRED red slash
    g.append('<rect x="115" y="115" width="55" height="70" rx="3" fill="url(#paper)" stroke="#94A3B8" stroke-width="1.5"/>')
    g.append('<line x1="120" y1="125" x2="165" y2="125" stroke="#1E293B" stroke-width="2"/>')
    g.append('<line x1="120" y1="135" x2="155" y2="135" stroke="#64748B" stroke-width="1.2"/>')
    g.append('<line x1="120" y1="145" x2="160" y2="145" stroke="#64748B" stroke-width="1.2"/>')
    g.append(f'<circle cx="142" cy="160" r="14" fill="none" stroke="{RED}" stroke-width="2.5"/>')
    g.append(f'<line x1="132" y1="170" x2="152" y2="150" stroke="{RED}" stroke-width="3"/>')

    return ''.join(g)


def draw_tool_bag_macro():
    """Macro close-up of heavy-duty canvas lineman tool bag & 3-point contact."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect x="25" y="0" width="12" height="220" fill="url(#steel)"/>')
    g.append('<rect x="163" y="0" width="12" height="220" fill="url(#steel)"/>')
    for ry in (40, 100, 160):
        g.append(f'<rect x="25" y="{ry}" width="150" height="10" rx="2" fill="url(#steel)"/>')

    g.append('<rect x="20" y="88" width="22" height="34" rx="6" fill="#A86E48" stroke="#7C4A2D" stroke-width="1.5"/>')
    g.append('<rect x="158" y="88" width="22" height="34" rx="6" fill="#A86E48" stroke="#7C4A2D" stroke-width="1.5"/>')

    g.append('<line x1="100" y1="0" x2="100" y2="85" stroke="#D97706" stroke-width="3.5"/>')
    g.append('<rect x="94" y="80" width="12" height="16" rx="4" fill="url(#steel)"/>')
    g.append('<path d="M65 95 L135 95 L128 175 L72 175 Z" fill="#D97706" stroke="#92400E" stroke-width="2.5"/>')
    g.append('<ellipse cx="100" cy="95" rx="35" ry="9" fill="#B45309" stroke="#92400E" stroke-width="2"/>')
    g.append('<rect x="70" y="165" width="60" height="14" rx="3" fill="#1E293B"/>')
    g.append('<rect x="80" y="72" width="8" height="26" rx="2" fill="url(#steel)"/>')
    g.append('<rect x="92" y="65" width="7" height="33" rx="2" fill="#EAB308"/>')
    g.append('<rect x="103" y="70" width="9" height="28" rx="2" fill="url(#steel)"/>')

    return ''.join(g)


def draw_tool_hand_macro():
    """Macro close-up of hand dangerously holding heavy wrench while climbing."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect x="40" y="0" width="18" height="220" fill="url(#steel)"/>')
    g.append('<rect x="40" y="110" width="130" height="12" rx="3" fill="url(#steel)"/>')

    g.append('<circle cx="100" cy="115" r="42" fill="url(#hazardGlow)"/>')

    g.append('<rect x="88" y="45" width="16" height="135" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="2"/>')
    g.append('<rect x="80" y="42" width="32" height="22" rx="4" fill="#DC2626" stroke="#991B1B" stroke-width="1.8"/>')
    g.append('<rect x="84" y="32" width="24" height="14" rx="2" fill="url(#steel)" stroke="#334155" stroke-width="1.5"/>')

    g.append('<rect x="36" y="98" width="65" height="32" rx="8" fill="#A86E48" stroke="#7C4A2D" stroke-width="2"/>')
    for fy in (102, 109, 116, 123):
        g.append(f'<line x1="42" y1="{fy}" x2="95" y2="{fy}" stroke="#7C4A2D" stroke-width="1.5"/>')
    g.append(f'<path d="M30 92 L20 86 M30 115 L18 115 M30 138 L20 144" stroke="{RED}" stroke-width="2.5" stroke-linecap="round"/>')

    return ''.join(g)


def draw_tool_overload_macro():
    """Macro close-up of pants pockets overflowing with heavy tools."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<path d="M40 0 L160 0 L170 220 L30 220 Z" fill="url(#ground)"/>')
    g.append('<rect x="30" y="20" width="140" height="24" rx="3" fill="#1E293B" stroke="#0F172A" stroke-width="2"/>')
    g.append('<rect x="85" y="16" width="30" height="32" rx="4" fill="url(#steel)" stroke="#334155" stroke-width="2"/>')

    g.append('<circle cx="100" cy="130" r="40" fill="url(#hazardGlow)"/>')
    g.append('<path d="M55 70 Q50 160 115 160 Q135 155 140 70 Z" fill="#2A3442" stroke="#1E293B" stroke-width="2.5"/>')

    g.append('<rect x="70" y="55" width="12" height="75" rx="3" fill="url(#steel)" transform="rotate(-15 70 55)"/>')
    g.append('<rect x="105" y="50" width="14" height="80" rx="3" fill="#EAB308" transform="rotate(22 105 50)"/>')
    g.append('<circle cx="120" cy="165" r="7" fill="url(#steel)" stroke="#334155" stroke-width="1.2"/>')
    g.append('<line x1="120" y1="172" x2="120" y2="195" stroke="url(#steel)" stroke-width="4.5"/>')
    g.append(f'<line x1="135" y1="140" x2="135" y2="190" stroke="{RED}" stroke-width="2" stroke-dasharray="4 3"/>')

    return ''.join(g)


def draw_pole_sound_macro():
    """Macro close-up of hammer sound resonance test on solid PCC pole base."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect y="165" width="200" height="55" fill="url(#ground)"/>')
    g.append('<line x1="0" y1="165" x2="200" y2="165" stroke="#78350F" stroke-width="2"/>')

    g.append('<rect x="45" y="0" width="60" height="165" fill="url(#pole)" stroke="#6B7280" stroke-width="2"/>')
    g.append('<rect x="35" y="145" width="80" height="24" rx="3" fill="#9CA3AF" stroke="#4B5563" stroke-width="2"/>')

    g.append('<line x1="175" y1="95" x2="112" y2="95" stroke="#B45309" stroke-width="7" stroke-linecap="round"/>')
    g.append('<rect x="102" y="84" width="16" height="22" rx="3" fill="url(#steel)" stroke="#334155" stroke-width="1.8"/>')

    for r in (18, 32, 48, 64):
        g.append(f'<path d="M102 {95-r} A{r} {r} 0 0 0 102 {95+r}" stroke="{YELLOW}" stroke-width="3" fill="none" stroke-linecap="round"/>')

    g.append('<circle cx="75" cy="45" r="16" fill="url(#safeGlow)"/>')
    g.append('<path d="M69 45 L73 49 L81 41" stroke="#10B981" stroke-width="2.5" fill="none" stroke-linecap="round"/>')

    return ''.join(g)


def draw_pole_rusted_macro():
    """Macro close-up of stepped tubular steel pole corroded with flaking rust."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect y="165" width="200" height="55" fill="url(#ground)"/>')
    g.append('<line x1="0" y1="165" x2="200" y2="165" stroke="#78350F" stroke-width="2"/>')

    g.append('<rect x="50" y="0" width="65" height="165" fill="url(#steel)" stroke="#475569" stroke-width="2"/>')

    g.append('<circle cx="82" cy="140" r="38" fill="url(#hazardGlow)"/>')
    g.append('<path d="M48 100 Q82 90 117 100 L117 165 L48 165 Z" fill="url(#rust)" stroke="#78350F" stroke-width="2"/>')

    g.append('<ellipse cx="78" cy="138" rx="14" ry="20" fill="#1E1610" stroke="#451A03" stroke-width="2"/>')
    g.append('<ellipse cx="96" cy="146" rx="11" ry="14" fill="#1E1610" stroke="#451A03" stroke-width="2"/>')
    for rx, ry in ((70, 155), (85, 160), (102, 158), (62, 168), (92, 172)):
        g.append(f'<circle cx="{rx}" cy="{ry}" r="2.5" fill="#9A3412"/>')

    return ''.join(g)


def draw_pole_lean_macro():
    """Macro close-up of dangerously leaning pole with cracked concrete base."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect y="165" width="200" height="55" fill="url(#ground)"/>')

    g.append('<g transform="rotate(-12 85 165)">')
    g.append('<rect x="55" y="-10" width="60" height="175" fill="url(#pole)" stroke="#4B5563" stroke-width="2"/>')
    g.append('<rect x="45" y="135" width="80" height="30" rx="3" fill="#9CA3AF" stroke="#4B5563" stroke-width="2"/>')
    g.append(f'<path d="M45 142 L65 148 L58 156 L78 162 L68 168" stroke="{RED}" stroke-width="3" fill="none"/>')
    g.append(f'<path d="M85 138 L95 152 L118 158" stroke="{RED}" stroke-width="2.5" fill="none"/>')
    g.append('</g>')

    g.append('<path d="M30 168 Q75 160 120 172" stroke="#451A03" stroke-width="4" fill="none"/>')

    return ''.join(g)


def draw_clearance_macro(inside=False):
    """Macro close-up of 11kV conductor Lakshman Rekha clearance zone."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect x="0" y="110" width="200" height="14" rx="2" fill="url(#steelArm)"/>')
    g.append('<rect x="85" y="70" width="30" height="40" rx="4" fill="url(#porcelain)" stroke="#94A3B8" stroke-width="1.5"/>')
    g.append(f'<path d="M0 65 Q100 70 200 65" stroke="{WIRE}" stroke-width="4.5" fill="none"/>')

    if inside:
        g.append('<circle cx="100" cy="65" r="55" fill="url(#hazardGlow)"/>')
        g.append(f'<circle cx="100" cy="65" r="48" fill="none" stroke="{RED}" stroke-width="3" stroke-dasharray="5 3"/>')
        g.append('<line x1="170" y1="120" x2="115" y2="78" stroke="url(#steel)" stroke-width="6" stroke-linecap="round"/>')
        g.append('<path d="M100 68 L106 72 L102 75 L112 78" stroke="#38BDF8" stroke-width="3.5" fill="none"/>')
        g.append('<circle cx="114" cy="78" r="8" fill="url(#flash)"/>')
    else:
        g.append('<circle cx="100" cy="65" r="52" fill="url(#wireGlow)"/>')
        g.append(f'<circle cx="100" cy="65" r="48" fill="none" stroke="{YELLOW}" stroke-width="2.5" stroke-dasharray="6 4"/>')
        g.append('<line x1="190" y1="150" x2="155" y2="120" stroke="#D97706" stroke-width="6" stroke-linecap="round"/>')
        g.append('<circle cx="155" cy="120" r="14" fill="url(#safeGlow)"/>')

    return ''.join(g)


def draw_ptw_clipboard_macro(signed=True):
    """Macro close-up of official WBSEDCL Permit To Work (PTW) document."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#bench)"/>')
    g.append('<rect x="20" y="12" width="160" height="196" rx="8" fill="url(#board)" stroke="#451A03" stroke-width="2"/>')
    g.append('<rect x="28" y="24" width="144" height="176" rx="4" fill="url(#paper)"/>')
    g.append('<rect x="75" y="8" width="50" height="18" rx="4" fill="url(#steel)" stroke="#334155" stroke-width="1.8"/>')
    g.append('<circle cx="100" cy="17" r="3" fill="#1E293B"/>')

    g.append('<rect x="38" y="34" width="124" height="10" rx="2" fill="url(#shirt)"/>')
    for ry in (52, 68, 84, 100, 116):
        g.append(f'<rect x="38" y="{ry}" width="34" height="7" rx="1.5" fill="#334155" opacity="0.6"/>')
        g.append(f'<rect x="78" y="{ry}" width="84" height="7" rx="1.5" fill="url(#steel)" opacity="0.7"/>')

    if signed:
        g.append('<path d="M42 145 Q60 130 80 148 Q100 132 120 146" stroke="#1D4ED8" stroke-width="2.6" fill="none" stroke-linecap="round"/>')
        g.append(f'<circle cx="138" cy="155" r="18" fill="{RED}" fill-opacity="0.85"/>')
        g.append('<circle cx="138" cy="155" r="14" fill="none" stroke="#FFFFFF" stroke-width="1.8"/>')
        g.append('<polygon points="138 145 142 153 150 153 144 158 146 166 138 161 130 166 132 158 126 153 134 153" fill="#FFFFFF"/>')
    else:
        g.append(f'<line x1="38" y1="130" x2="160" y2="180" stroke="{RED}" stroke-width="3"/>')
        g.append(f'<line x1="38" y1="180" x2="160" y2="130" stroke="{RED}" stroke-width="3"/>')

    return ''.join(g)


def draw_ptw_verbal_macro():
    """Macro close-up of lineman on phone with no written PTW."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<path d="M40 220 L40 120 Q100 95 160 120 L160 220 Z" fill="url(#shirt)"/>')
    g.append('<circle cx="100" cy="70" r="28" fill="#A86E48"/>')
    g.append('<path d="M68 64 Q70 25 100 22 Q130 25 132 64 Z" fill="url(#helmetDome)"/>')
    g.append('<rect x="62" y="62" width="76" height="8" rx="3" fill="#EAB308"/>')

    g.append('<path d="M140 160 L145 90 L125 70" stroke="url(#shirt)" stroke-width="20" stroke-linecap="round" stroke-linejoin="round" fill="none"/>')
    g.append('<circle cx="122" cy="70" r="10" fill="#A86E48"/>')
    g.append('<rect x="115" y="55" width="16" height="28" rx="3" fill="#0F172A" stroke="url(#steel)" stroke-width="1.5"/>')
    g.append('<rect x="117" y="58" width="12" height="22" rx="1" fill="#38BDF8" opacity="0.8"/>')

    for r in (18, 28):
        g.append(f'<path d="M136 {68-r*0.6} Q{136+r} 68 136 {68+r*0.6}" stroke="{RED}" stroke-width="2" fill="none"/>')

    g.append('<circle cx="50" cy="160" r="24" fill="#000000" opacity="0.6"/>')
    g.append('<rect x="36" y="145" width="28" height="32" rx="3" fill="#FFFFFF"/>')
    g.append(f'<line x1="32" y1="138" x2="68" y2="182" stroke="{RED}" stroke-width="4"/>')

    return ''.join(g)


def draw_ptw_pocket_macro():
    """Macro close-up of crumpled permit crammed unread in back pocket."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#ground)"/>')
    g.append('<path d="M20 0 L180 0 L180 220 L20 220 Z" fill="#1E293B"/>')
    g.append('<path d="M50 60 L150 60 L140 180 L60 180 Z" fill="#0F172A" stroke="#334155" stroke-width="2.5"/>')
    g.append('<path d="M55 75 L145 75" stroke="#475569" stroke-width="1.5" stroke-dasharray="3 2"/>')

    g.append('<path d="M68 85 L60 30 L105 18 L138 32 L130 85 Z" fill="url(#paper)" stroke="#94A3B8" stroke-width="2"/>')
    g.append('<line x1="72" y1="42" x2="128" y2="48" stroke="#1E293B" stroke-width="2.5"/>')
    g.append('<line x1="68" y1="58" x2="124" y2="64" stroke="#64748B" stroke-width="1.8"/>')
    g.append(f'<circle cx="118" cy="68" r="8" fill="{RED}" fill-opacity="0.8"/>')

    g.append('<circle cx="100" cy="120" r="24" fill="url(#hazardGlow)"/>')
    g.append(f'<line x1="90" y1="110" x2="110" y2="130" stroke="{RED}" stroke-width="3"/>')
    g.append(f'<line x1="90" y1="130" x2="110" y2="110" stroke="{RED}" stroke-width="3"/>')

    return ''.join(g)


def draw_mind_rushed_macro():
    """Macro close-up of wristwatch showing frantic hurry and ticking time."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect x="0" y="85" width="200" height="50" rx="4" fill="url(#shirt)"/>')
    g.append('<rect x="65" y="80" width="70" height="60" rx="10" fill="#A86E48"/>')

    g.append('<rect x="86" y="55" width="28" height="110" rx="4" fill="#0F172A" stroke="#334155" stroke-width="2"/>')
    g.append('<circle cx="100" cy="110" r="34" fill="url(#steel)" stroke="#1E293B" stroke-width="3"/>')
    g.append('<circle cx="100" cy="110" r="28" fill="#FFFFFF"/>')

    for h in range(12):
        rad = h * math.pi / 6
        x1, y1 = 100 + 22 * math.sin(rad), 110 - 22 * math.cos(rad)
        x2, y2 = 100 + 26 * math.sin(rad), 110 - 26 * math.cos(rad)
        g.append(f'<line x1="{x1:.1f}" y1="{y1:.1f}" x2="{x2:.1f}" y2="{y2:.1f}" stroke="#1E293B" stroke-width="2"/>')

    g.append('<line x1="100" y1="110" x2="114" y2="96" stroke="#0F172A" stroke-width="3.5" stroke-linecap="round"/>')
    g.append(f'<line x1="100" y1="110" x2="84" y2="100" stroke="{RED}" stroke-width="2" stroke-linecap="round"/>')
    g.append(f'<circle cx="100" cy="110" r="3" fill="{RED}"/>')

    for sx, sy in ((30, 60), (45, 45), (155, 60), (170, 45)):
        g.append(f'<line x1="{sx}" y1="{sy}" x2="{sx+20}" y2="{sy}" stroke="{RED}" stroke-width="2.5" stroke-linecap="round"/>')

    return ''.join(g)


def draw_mind_tired_macro():
    """Macro close-up of exhausted lineman rubbing temple with fatigue."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<path d="M40 220 L40 130 Q100 100 160 130 L160 220 Z" fill="url(#shirt)"/>')
    g.append('<circle cx="100" cy="85" r="32" fill="#A86E48"/>')
    g.append('<path d="M64 70 Q68 25 100 22 Q132 25 136 70 Z" fill="url(#helmetDome)"/>')
    g.append('<rect x="58" y="68" width="84" height="8" rx="3" fill="#EAB308"/>')

    g.append('<path d="M82 85 Q88 90 94 85" stroke="#3E2723" stroke-width="2.2" fill="none"/>')
    g.append('<path d="M106 85 Q112 90 118 85" stroke="#3E2723" stroke-width="2.2" fill="none"/>')

    g.append('<path d="M145 160 L140 100 L120 80" stroke="url(#shirt)" stroke-width="20" stroke-linecap="round" fill="none"/>')
    g.append('<circle cx="120" cy="80" r="12" fill="#A86E48"/>')

    g.append(f'<path d="M70 45 Q80 35 90 45 Q100 55 110 45" stroke="{RED}" stroke-width="2" fill="none"/>')
    g.append('<circle cx="135" cy="50" r="3" fill="#38BDF8"/>')
    g.append('<circle cx="65" cy="60" r="2.5" fill="#38BDF8"/>')

    return ''.join(g)


def draw_site_barricade_macro():
    """Macro close-up of high-vis traffic cones and caution barrier tape."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#ground)"/>')
    g.append('<rect y="130" width="200" height="90" fill="#334155"/>')
    g.append('<line x1="0" y1="175" x2="200" y2="175" stroke="#FFFFFF" stroke-width="4" stroke-dasharray="16 12"/>')

    for cx in (60, 140):
        g.append(f'<polygon points="{cx-36} 190 {cx+36} 190 {cx+28} 178 {cx-28} 178" fill="#C2410C"/>')
        g.append(f'<polygon points="{cx-24} 180 {cx} 90 {cx+24} 180" fill="url(#cone)"/>')
        g.append(f'<polygon points="{cx-15} 145 {cx-9} 122 {cx+9} 122 {cx+15} 145" fill="#FFFFFF"/>')

    g.append(f'<polygon points="20 120 180 120 180 135 20 135" fill="{YELLOW}"/>')
    for tx in range(25, 175, 18):
        g.append(f'<polygon points="{tx} 120 {tx+8} 120 {tx} 135 {tx-8} 135" fill="#000000"/>')

    return ''.join(g)


def draw_traffic_hazard_macro():
    """Macro close-up of car speeding within inches of unguarded ladder foot."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#ground)"/>')
    g.append('<rect y="120" width="200" height="100" fill="#1E293B"/>')

    g.append('<rect x="15" y="0" width="10" height="190" fill="url(#steel)"/>')
    g.append('<rect x="35" y="0" width="10" height="190" fill="url(#steel)"/>')
    for ry in (40, 90, 140):
        g.append(f'<rect x="15" y="{ry}" width="30" height="8" rx="2" fill="url(#steel)"/>')

    g.append(f'<path d="M55 175 L80 145 L150 145 L180 160 L195 180 L55 180 Z" fill="{RED}" stroke="#991B1B" stroke-width="2"/>')
    g.append('<rect x="85" y="148" width="28" height="14" rx="2" fill="url(#steel)"/>')
    g.append('<rect x="118" y="148" width="30" height="14" rx="2" fill="url(#steel)"/>')
    g.append('<circle cx="85" cy="182" r="12" fill="#0F172A" stroke="#334155" stroke-width="2"/>')
    g.append('<circle cx="165" cy="182" r="12" fill="#0F172A" stroke="#334155" stroke-width="2"/>')

    g.append(f'<polygon points="55 172 20 162 20 186" fill="{YELLOW}" fill-opacity="0.6"/>')
    for lx, ly in ((90, 138), (115, 135), (140, 138)):
        g.append(f'<line x1="{lx}" y1="{ly}" x2="{lx+30}" y2="{ly}" stroke="#FFFFFF" stroke-width="2.5" stroke-linecap="round"/>')

    return ''.join(g)


def draw_beehive_macro():
    """Macro close-up of pole cross-arm with large wasp/beehive nest and swarm."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect x="80" y="0" width="40" height="220" fill="url(#pole)"/>')
    g.append('<rect x="10" y="55" width="180" height="16" rx="2" fill="url(#steelArm)"/>')
    g.append('<rect x="30" y="30" width="22" height="26" rx="4" fill="url(#porcelain)"/>')
    g.append('<rect x="150" y="30" width="22" height="26" rx="4" fill="url(#porcelain)"/>')
    g.append(f'<line x1="0" y1="36" x2="200" y2="36" stroke="{WIRE}" stroke-width="3.5"/>')

    g.append('<circle cx="100" cy="115" r="38" fill="url(#hazardGlow)"/>')
    g.append('<path d="M75 71 Q60 105 75 135 Q100 155 125 135 Q140 105 125 71 Z" fill="url(#board)" stroke="#451A03" stroke-width="2.5"/>')
    for hy in (88, 104, 120):
        g.append(f'<path d="M78 {hy} Q100 {hy+6} 122 {hy}" stroke="{YELLOW}" stroke-width="2.5" fill="none"/>')

    for bx, by in ((55, 90), (62, 135), (135, 85), (145, 120), (100, 160), (115, 145)):
        g.append(f'<ellipse cx="{bx}" cy="{by}" rx="4" ry="2.5" fill="#0F172A"/>')
        g.append(f'<circle cx="{bx+2}" cy="{by-2}" r="2" fill="#FFFFFF" opacity="0.8"/>')
        g.append(f'<line x1="{bx-2}" y1="{by}" x2="{bx+2}" y2="{by}" stroke="{YELLOW}" stroke-width="1"/>')

    return ''.join(g)


def draw_storm_macro():
    """Macro close-up of dark storm clouds and lightning striking power line."""
    g = []
    g.append('<rect width="200" height="220" fill="#0F172A"/>')
    g.append('<ellipse cx="60" cy="45" rx="55" ry="32" fill="#1E293B"/>')
    g.append('<ellipse cx="130" cy="40" rx="60" ry="36" fill="#334155"/>')
    g.append('<ellipse cx="180" cy="55" rx="45" ry="28" fill="#1E293B"/>')

    g.append('<rect x="90" y="110" width="20" height="110" fill="url(#pole)"/>')
    g.append('<rect x="20" y="130" width="160" height="12" rx="2" fill="url(#steelArm)"/>')
    g.append(f'<line x1="0" y1="125" x2="200" y2="125" stroke="{WIRE}" stroke-width="3"/>')

    g.append('<circle cx="100" cy="90" r="45" fill="url(#flash)"/>')
    bolt = "M105 15 L80 75 L102 75 L75 140 L125 70 L102 70 Z"
    g.append(f'<polygon points="{bolt}" fill="{YELLOW}" stroke="#FFFFFF" stroke-width="2"/>')
    g.append('<polygon points="103 20 83 73 100 73 80 130 118 72 101 72" fill="#FFFFFF"/>')

    return ''.join(g)


def draw_rescue_ready_macro():
    """Macro close-up of coiled yellow rescue lifeline & First Aid kit."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#ground)"/>')
    g.append('<rect x="20" y="0" width="12" height="200" fill="url(#steel)"/>')
    g.append('<rect x="60" y="0" width="12" height="200" fill="url(#steel)"/>')
    for ry in (40, 100, 160):
        g.append(f'<rect x="20" y="{ry}" width="52" height="8" rx="2" fill="url(#steel)"/>')

    for r in (34, 26, 18, 10):
        g.append(f'<ellipse cx="130" cy="165" rx="{r}" ry="{int(r*0.55)}" stroke="{YELLOW}" stroke-width="5" fill="none"/>')
    g.append('<rect x="145" y="152" width="16" height="24" rx="5" fill="url(#steel)" stroke="#334155" stroke-width="2"/>')

    g.append('<rect x="85" y="90" width="60" height="45" rx="5" fill="#16A34A" stroke="#14532D" stroke-width="2"/>')
    g.append('<rect x="105" y="82" width="20" height="10" rx="3" fill="none" stroke="#FFFFFF" stroke-width="2"/>')
    g.append('<rect x="110" y="98" width="10" height="28" fill="#FFFFFF"/>')
    g.append('<rect x="101" y="107" width="28" height="10" fill="#FFFFFF"/>')

    return ''.join(g)


def draw_rescue_blocked_macro():
    """Macro close-up of ladder base choked by barbed wire and broken rubble."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#ground)"/>')
    g.append('<rect x="40" y="0" width="12" height="190" fill="url(#steel)"/>')
    g.append('<rect x="100" y="0" width="12" height="190" fill="url(#steel)"/>')
    for ry in (40, 100, 160):
        g.append(f'<rect x="40" y="{ry}" width="72" height="8" rx="2" fill="url(#steel)"/>')

    g.append('<polygon points="20 160 50 145 65 175 30 190" fill="#64748B" stroke="#334155" stroke-width="2"/>')
    g.append('<polygon points="90 150 140 140 155 180 105 195" fill="#475569" stroke="#1E293B" stroke-width="2"/>')

    for cy in (155, 175):
        g.append(f'<path d="M10 {cy} Q70 {cy-15} 130 {cy} Q170 {cy+15} 190 {cy}" stroke="url(#steel)" stroke-width="3.5" fill="none"/>')
        for bx in (35, 75, 115, 155):
            g.append(f'<line x1="{bx-4}" y1="{cy-4}" x2="{bx+4}" y2="{cy+4}" stroke="{RED}" stroke-width="2.5"/>')
            g.append(f'<line x1="{bx+4}" y1="{cy-4}" x2="{bx-4}" y2="{cy+4}" stroke="{RED}" stroke-width="2.5"/>')

    return ''.join(g)


def draw_skip_scan_macro():
    """Macro close-up of worker boot stepping onto ladder without checking pole."""
    g = []
    g.append('<rect width="200" height="220" fill="url(#sky)"/>')
    g.append('<rect x="25" y="0" width="45" height="200" fill="url(#pole)"/>')
    g.append(f'<path d="M30 140 L50 155 L40 175 L60 190" stroke="{RED}" stroke-width="3" fill="none"/>')

    g.append('<rect x="95" y="0" width="14" height="200" fill="url(#steel)"/>')
    g.append('<rect x="95" y="145" width="85" height="10" rx="2" fill="url(#steel)"/>')

    g.append('<rect x="110" y="130" width="55" height="22" rx="6" fill="#1E293B" stroke="#0F172A" stroke-width="2"/>')
    g.append('<rect x="120" y="80" width="35" height="55" fill="url(#shirt)"/>')

    g.append('<circle cx="50" cy="110" r="18" fill="url(#hazardGlow)"/>')
    g.append(f'<circle cx="50" cy="110" r="14" fill="{RED}"/>')
    g.append('<rect x="48" y="102" width="4" height="10" rx="1.5" fill="#FFFFFF"/>')
    g.append('<circle cx="50" cy="117" r="2" fill="#FFFFFF"/>')

    return ''.join(g)


# ==============================================================================
# CARDS MAP
# ==============================================================================

CARDS = {
    # Round 1: Personal PPE Check
    'ppe_strap_sole': make_card(draw_helmet_macro(buckled=True), back='sky'),
    'ppe_head_toe': make_card(draw_boot_sole_macro(nail=False, cracked=False, eh_shield=True), back='bench'),
    'ppe_unstrapped': make_card(draw_helmet_macro(buckled=False), back='sky'),
    'ppe_dirty_cut': make_card(draw_shirt_macro(torn_polyester=True), back='sky'),
    'ppe_nail_sole': make_card(draw_boot_sole_macro(nail=True, cracked=True, eh_shield=False), back='bench'),
    'ppe_no_check': make_card(draw_gloves_macro(punctured=True), back='bench'),

    # Round 2: Harness & Tools
    'harness_snug': make_card(draw_harness_chest_macro(chest_fit='ok'), back='sky'),
    'tool_bagged': make_card(draw_tool_bag_macro(), back='sky'),
    'harness_loose_chest': make_card(draw_harness_chest_macro(chest_fit='loose'), back='sky'),
    'tool_hand_climb': make_card(draw_tool_hand_macro(), back='sky'),
    'tool_overload': make_card(draw_tool_overload_macro(), back='sky'),
    'harness_expired': make_card(draw_harness_expired_macro(), back='bench'),

    # Round 3: PTW & Mindset
    'ptw_signed': make_card(draw_ptw_clipboard_macro(signed=True), back='bench'),
    'ptw_calm_team': make_card(draw_ptw_clipboard_macro(signed=True), back='bench'),
    'ptw_verbal_phone': make_card(draw_ptw_verbal_macro(), back='sky'),
    'mind_rushed': make_card(draw_mind_rushed_macro(), back='sky'),
    'mind_tired': make_card(draw_mind_tired_macro(), back='sky'),
    'ptw_no_read': make_card(draw_ptw_pocket_macro(), back='ground'),

    # Round 4: Pole & Distance
    'pole_sound': make_card(draw_pole_sound_macro(), back='sky'),
    'clearance_spot': make_card(draw_clearance_macro(inside=False), back='sky'),
    'pole_hug_lean': make_card(draw_pole_lean_macro(), back='sky'),
    'clearance_inside': make_card(draw_clearance_macro(inside=True), back='sky'),
    'pole_skip_scan': make_card(draw_skip_scan_macro(), back='sky'),
    'pole_rusted_base': make_card(draw_pole_rusted_macro(), back='sky'),

    # Round 5: Hazard & Rescue
    'rescue_ready': make_card(draw_rescue_ready_macro(), back='ground'),
    'site_barricade': make_card(draw_site_barricade_macro(), back='ground'),
    'hazard_beehive': make_card(draw_beehive_macro(), back='sky'),
    'hazard_traffic': make_card(draw_traffic_hazard_macro(), back='ground'),
    'hazard_storm_sky': make_card(draw_storm_macro(), back='sky'),
    'rescue_blocked': make_card(draw_rescue_blocked_macro(), back='ground'),
}

if __name__ == '__main__':
    os.makedirs(OUT, exist_ok=True)
    keep = {name + '.svg' for name in CARDS}
    for old in os.listdir(OUT):
        if old.endswith('.svg') and old not in keep:
            os.remove(os.path.join(OUT, old))
    for name, svg in CARDS.items():
        with open(os.path.join(OUT, name + '.svg'), 'w', encoding='utf-8', newline='\n') as fh:
            fh.write(svg)
    print(f'wrote {len(CARDS)} macro inspection cards to {OUT}')
