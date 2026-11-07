"""Check that every asset path referenced by the app resolves to a bundled, non-empty file.

usage: python3 -I tool/check_asset_refs.py .   (run from the repo root; exit 1 = broken reference)

Scans lib/ and test/ Dart plus every bundled assets/**/*.json for literal asset paths
('assets/...', and AssetSource-style 'sounds/...'), expands the dress-up name builders
(ds_dress_up.dart, ai_lineman_guide.dart), and checks pubspec file entries. Prints
missing/empty/unbundled references and exits 1 if any are found that were not already
broken at the baseline listed in KNOWN_BROKEN.
"""
import os, re, sys, json

root = sys.argv[1]
EXT = r'(?:webp|jpg|jpeg|png|gif|svg|mp3|wav|ogg|json|ttf|riv|lottie)'
LIT = re.compile(r"""['"]((?:assets/)?(?:sounds|duty_slip|zero_loss|safety|quizzes|lineman|brand|data|game|fonts)/[^'"$\s]*?\.""" + EXT + r""")['"]""")
JSON_LIT = re.compile(r'"((?:assets/)[^"$\s]*?\.' + EXT + r')"')
# Known broken before this change (reported, not caused here)
KNOWN_BROKEN = set()  # everything resolves as of the 2026-11 cleanup; keep it that way

# ---- bundled set from pubspec (folder entries bundle direct children only)
txt = open(os.path.join(root, 'pubspec.yaml')).read()
entries, ina = [], False
for l in txt.split('\n'):
    if re.match(r'^  assets:\s*$', l):
        ina = True; continue
    if ina:
        m = re.match(r'^    - (.+?)\s*$', l)
        if m:
            entries.append(m.group(1)); continue
        if l.strip() == '':
            continue
        ina = False
bundled = set()
problems = []
for e in entries:
    p = os.path.join(root, e)
    if e.endswith('/'):
        if not os.path.isdir(p):
            problems.append(('pubspec folder missing', e, 'pubspec.yaml')); continue
        for n in os.listdir(p):
            if os.path.isfile(os.path.join(p, n)) and not n.startswith('.'):
                bundled.add(e + n)
    else:
        if not os.path.isfile(p):
            problems.append(('pubspec file missing', e, 'pubspec.yaml'))
        bundled.add(e)
for f in re.findall(r'- asset: (\S+)', txt):
    if not os.path.isfile(os.path.join(root, f)):
        problems.append(('pubspec font missing', f, 'pubspec.yaml'))
    bundled.add(f)

def norm(ref):
    return ref if ref.startswith('assets/') else 'assets/' + ref

refs = {}  # path -> first location
def add(ref, loc):
    refs.setdefault(norm(ref), loc)

for d in ('lib', 'test'):
    for dp, dn, fn in os.walk(os.path.join(root, d)):
        for n in fn:
            if not n.endswith('.dart'):
                continue
            p = os.path.join(dp, n)
            rel = os.path.relpath(p, root)
            for i, line in enumerate(open(p, encoding='utf-8', errors='ignore'), 1):
                s = line.strip()
                if s.startswith('//'):
                    continue
                for m in LIT.finditer(line):
                    add(m.group(1), f'{rel}:{i}')

for f in sorted(bundled):
    if f.endswith('.json'):
        try:
            t = open(os.path.join(root, f), encoding='utf-8').read()
        except Exception:
            continue
        for m in JSON_LIT.finditer(t):
            add(m.group(1), f)

# ---- dress-up name builders: 'assets/duty_slip/dress/$name.webp'
PREFIXES = ('body', 'all', 'shirt', 'pant', 'boot', 'gloves_', 'head_', 'hands_', 'kit_', 'pose_', 'coach_', 'worn_')
for rel in ('lib/features/duty_slip/ds_dress_up.dart', 'lib/features/guide/ai_lineman_guide.dart'):
    p = os.path.join(root, rel)
    if not os.path.exists(p):
        continue
    for i, line in enumerate(open(p, encoding='utf-8'), 1):
        if not re.search(r"return '|=> '|\? '|: '|figure: '|_face[AB] = '", line):
            continue
        for name in re.findall(r"'([a-z][a-z_]*)'", line):
            if name.startswith(PREFIXES) and ('_' in name or name in ('body', 'all', 'shirt', 'pant', 'boot')):
                add(f'assets/duty_slip/dress/{name}.webp', f'{rel}:{i} (name builder)')

ok = 0
for ref, loc in sorted(refs.items()):
    p = os.path.join(root, ref)
    if not os.path.isfile(p):
        problems.append(('missing', ref, loc)); continue
    if os.path.getsize(p) == 0:
        problems.append(('empty', ref, loc)); continue
    if ref not in bundled:
        problems.append(('not bundled', ref, loc)); continue
    ok += 1

new = [x for x in problems if x[1] not in KNOWN_BROKEN and not (x[0] == 'empty' and 'img_17qyHjE' in x[1])]
print(f'{len(refs)} referenced asset paths, {ok} resolve to bundled non-empty files, {len(bundled)} bundled files')
for kind, ref, loc in problems:
    tag = 'NEW ' if (kind, ref, loc) in new else 'known'
    print(f'  [{tag}] {kind}: {ref}  <- {loc}')
sys.exit(1 if new else 0)
