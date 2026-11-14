"""Exhaustive list of every Bangla text/speech line in the Flutter app, level-wise,
for the owner's language review. Read-only on the repo; writes one .xlsx."""
import glob, io, json, os, re, sys
from collections import defaultdict, OrderedDict

sys.stdout.reconfigure(encoding='utf-8')
ROOT = sys.argv[1]
OUT = sys.argv[2]
G = os.path.join(ROOT, 'lib', 'features', 'game')

BN = re.compile(r'[ঀ-৿]')
LIT = re.compile(r"r?'(?:[^'\\\n]|\\.)*'|r?\"(?:[^\"\\\n]|\\.)*\"")
CLS = re.compile(r'^\s*(?:abstract\s+|final\s+|sealed\s+|base\s+)*(?:class|enum|extension|mixin)\s+(\w+)')
FIELD = re.compile(r'^\s*(?:static\s+)?(?:const|final|late\s+final)?\s*(?:[\w<>,?\s]+\s)?(\w+)\s*(?:=|=>)')
FUNC = re.compile(r'^\s*(?:static\s+)?(?:[\w<>,?]+\s+)+(\w+)\s*\(')
CASE = re.compile(r"^\s*(\w+(?:\.\w+)*)\s*=>")

def read(p):
    return io.open(p, encoding='utf-8').read()

# ---------- catalog: rung -> L number, module, lesson, title ----------
cat = json.load(io.open(os.path.join(ROOT, 'assets/game/catalog/content_catalog.json'), encoding='utf-8'))
lessons = {l['id']: l for l in cat['lessons']}
packs = {p['id']: p for p in cat['gamePacks']}
mod_no = lambda m: int(m.lstrip('m'))
rungs = sorted(cat['rungDefs'], key=lambda r: (mod_no(r['moduleId']), r['orderInModule']))
rung_info = OrderedDict()
for i, r in enumerate(rungs):
    p = packs.get(r['packId'], {})
    les = lessons.get(r['lessonId'], {})
    kind = {'learn': 'Learn board', 'do': 'Do level', 'gate': 'Rank gate'}.get(r['kind'], r['kind'])
    rung_info[r['id']] = dict(L=i + 1, module=mod_no(r['moduleId']), lesson=r['lessonId'], kind=kind,
                              engine=p.get('engineType'), status=r.get('status'),
                              title=les.get('titleBn', ''))

# ---------- engine type -> dart files ----------
dg = read(os.path.join(G, 'do_games.dart'))
class_file = {}
for f in glob.glob(os.path.join(ROOT, 'lib', '**', '*.dart'), recursive=True):
    for m in re.finditer(r'^\s*(?:abstract\s+|final\s+)*class\s+(\w+)', read(f), re.M):
        class_file.setdefault(m.group(1), f)
engine_files = defaultdict(set)
for m in re.finditer(r"case '(\w+)':(.*?)(?=\n\s*case '|\n\s*default:|\Z)", dg, re.S):
    eng, body = m.group(1), m.group(2)
    for cm in re.finditer(r'\b([A-Z]\w+Page)\s*\(', body):
        f = class_file.get(cm.group(1))
        if f:
            engine_files[eng].add(f)
    own = os.path.join(G, eng + '.dart')
    if os.path.exists(own):
        engine_files[eng].add(own)
for eng, fs in list(engine_files.items()):
    for f in list(fs):
        w = f[:-5] + '_world.dart'
        if os.path.exists(w):
            fs.add(w)

file_rungs = defaultdict(list)
for rid, info in rung_info.items():
    if info['kind'] == 'Learn board':
        les = info['lesson']
        f = os.path.join(G, 'learn_board_pack' + les.replace('.', '') + '.dart')
        if os.path.exists(f):
            file_rungs[os.path.normpath(f)].append(rid)
        continue
    for f in engine_files.get(info['engine'] or '', ()):
        file_rungs[os.path.normpath(f)].append(rid)

# ---------- recorded voice keys ----------
recorded = set()
for vf in glob.glob(os.path.join(ROOT, 'lib', '**', '*voice*.dart'), recursive=True):
    for m in re.finditer(r'^\s*(["\'])(.*?)\1\s*:', read(vf), re.M):
        recorded.add(m.group(2))

def unq(lit):
    raw = lit.startswith('r')
    s = lit[1:] if raw else lit
    s = s[1:-1]
    if not raw:
        s = s.replace("\\'", "'").replace('\\"', '"').replace('\\n', ' ⏎ ').replace('\\$', '$')
    return s

def speaker(cls, name, path, text):
    n = (cls + ' ' + name).lower()
    base = os.path.basename(path).lower()
    if 'mistake' in n or 'mistakes' in base:
        return 'Mistake card (on screen)'
    if any(k in n for k in ('coworker', 'rival', 'taunt', 'snarl', 'push', 'mate', 'supervisor', 'crewlead', 'crew_lead')):
        return 'Coworker / rival'
    if any(k in n for k in ('why', 'reason', 'myth', 'wrong', 'right', 'option', 'choice', 'refus', 'listen')):
        return 'Answer / reason card'
    if any(k in n for k in ('intro', 'guide', 'hint', 'praise', 'say', 'line', 'tell', 'cue', 'speech')) or 'mascot' in base or 'guide' in base:
        return 'Guide (mascot)'
    if any(k in n for k in ('operator', 'customer', 'neighbour', 'neighbor', 'villager', 'caller', 'consumer')):
        return 'Other character'
    if any(k in n for k in ('title', 'label', 'button', 'head', 'tag', 'chip', 'badge', 'caption', 'sub')):
        return 'UI label / caption'
    return 'Screen text'

def situation(cls, name):
    s = name or ''
    s = re.sub(r'(?<!^)(?=[A-Z])', ' ', s).strip()
    return (cls + ' · ' + s) if cls and s else (cls or s)

def scan(path):
    rows = []
    cls, name = '', ''
    depth_block = 0
    lines = read(path).split('\n')
    for i, line in enumerate(lines, 1):
        st = line.strip()
        if st.startswith('//') or st.startswith('*') or st.startswith('/*'):
            continue
        m = CLS.match(line)
        if m:
            cls, name = m.group(1), ''
        fm = FIELD.match(line)
        if fm and fm.group(1) not in ('return', 'final', 'const', 'var', 'case'):
            name = fm.group(1)
        else:
            fu = FUNC.match(line)
            if fu and fu.group(1) not in ('if', 'for', 'while', 'switch', 'return', 'catch'):
                name = fu.group(1)
        code = line.split(' // ')[0] if ' // ' in line and line.count("'") % 2 == 0 else line
        for lm in LIT.finditer(code):
            t = unq(lm.group(0))
            if not BN.search(t):
                continue
            rows.append(dict(file=os.path.relpath(path, ROOT).replace('\\', '/'), line=i, cls=cls, name=name,
                             text=t, voice='Recorded clip' if t in recorded else ('Device voice / screen' if True else '')))
    return rows

# ---------- collect ----------
all_dart = sorted(glob.glob(os.path.join(ROOT, 'lib', '**', '*.dart'), recursive=True))
level_rows, other_rows = [], defaultdict(list)
for f in all_dart:
    nf = os.path.normpath(f)
    if re.search(r'(learn_voice_map|_voice)\.dart$', f.replace(os.sep, '/')):
        continue
    rows = scan(f)
    if not rows:
        continue
    rel = os.path.relpath(f, ROOT).replace(os.sep, '/')
    rids = file_rungs.get(nf)
    for r in rows:
        r['speaker'] = speaker(r['cls'], r['name'], f, r['text'])
        r['situation'] = situation(r['cls'], r['name'])
    if rel.endswith('learn_board_models.dart'):
        src = read(f).split('\n')
        starts = []
        for i, l in enumerate(src):
            m = re.match(r'const learnBoardPack1(\d) ', l)
            if m:
                starts.append((i + 1, '1.' + m.group(1)))
        for r in rows:
            les = None
            for st, ls in starts:
                if r['line'] >= st:
                    les = ls
            rid = f'{les}/learn' if les else None
            if rid in rung_info:
                i = rung_info[rid]
                r.update(module=i['module'], L=i['L'], Ls='', rungs=rid, kind=i['kind'], title=i['title'])
                level_rows.append(r)
            else:
                other_rows['Shared level kit & frames'].append(r)
        continue
    if rids:
        infos = [rung_info[x] for x in rids]
        first = min(infos, key=lambda x: x['L'])
        lv = ', '.join(f"L{x['L']}" for x in sorted(infos, key=lambda x: x['L']))
        rg = ', '.join(sorted(rids, key=lambda x: rung_info[x]['L']))
        for r in rows:
            r.update(module=first['module'], L=first['L'], Ls=lv, rungs=rg, kind=first['kind'], title=first['title'])
            level_rows.append(r)
    else:
        if '/features/game/' in rel:
            grp = 'Shared level kit & frames'
        elif any(k in rel for k in ('/home/', '/more/', '/shell/', '/startup/', '/auth/', '/rank/', '/training/', '/emergency/', '/identify/', '/sops/', '/life_skills/', '/admin/', '/radio/', '/quizzes/', '/zero_loss/', '/design_preview/')):
            grp = 'Menus, screens & settings'
        elif '/guide/' in rel:
            grp = 'Guide (mascot) library'
        elif '/duty_slip/' in rel:
            grp = 'Ladder map, gift box & duty slip'
        else:
            grp = 'Other'
        for r in rows:
            other_rows[grp].append(r)

# catalog JSON texts
cat_rows = []
for l in cat['lessons']:
    if l.get('titleBn'):
        cat_rows.append(dict(file='assets/game/catalog/content_catalog.json', line='', cls='lesson title',
                             name=l['id'], text=l['titleBn'], speaker='UI label / caption', situation=f"Lesson {l['id']} title",
                             voice='Recorded clip' if l['titleBn'] in recorded else 'Device voice / screen'))
for g in cat.get('guideLines', []):
    if g.get('bnText'):
        cat_rows.append(dict(file='assets/game/catalog/content_catalog.json', line='', cls='guideLines',
                             name=g.get('id', ''), text=g['bnText'], speaker='Guide (mascot)',
                             situation=f"Guide line · {g.get('when', '')}",
                             voice='Recorded clip' if g['bnText'] in recorded else 'Device voice / screen'))
other_rows['Catalog: lesson titles & guide lines'] = cat_rows

# life skills (copied from slm_web) — titles, descriptions, section titles and points
ls_rows = []
ls_dir = os.path.join(ROOT, 'assets', 'life_skills')
def walk(o, path, fname):
    if isinstance(o, dict):
        for k, v in o.items():
            walk(v, path + [str(k)], fname)
    elif isinstance(o, list):
        for i, v in enumerate(o):
            walk(v, path + [str(i)], fname)
    elif isinstance(o, str) and BN.search(o):
        ls_rows.append(dict(file=os.path.relpath(fname, ROOT).replace('\\', '/'), line='', cls='life skill',
                            name='.'.join(path), text=o, speaker='Life skill content', situation='.'.join(path[-3:]),
                            voice='Screen text'))
for jf in sorted(glob.glob(os.path.join(ls_dir, '**', '*.json'), recursive=True)):
    try:
        walk(json.load(io.open(jf, encoding='utf-8')), [], jf)
    except Exception:
        pass

# ---------- workbook ----------
from openpyxl import Workbook
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter
from openpyxl.worksheet.datavalidation import DataValidation

wb = Workbook()
F = 'Arial'
HEAD = PatternFill('solid', fgColor='1F3A5F')
EDIT = PatternFill('solid', fgColor='FFF2CC')
hdr_font = Font(name=F, bold=True, color='FFFFFF')
body = Font(name=F, size=10)
bn_font = Font(name='Nirmala UI', size=11)

COLS = ['ID', 'Module', 'Level', 'Also used in', 'Rung', 'Kind', 'Lesson title', 'Situation (code group · name)',
        'Speaker / type', 'Voice', 'Current Bangla text', 'Your revision', 'Status', 'Notes', 'File', 'Line']
WIDTH = [9, 7, 7, 14, 16, 11, 26, 34, 20, 18, 60, 60, 12, 28, 40, 6]

ws = wb.active
ws.title = 'How to review'
guide = [
    ['Bangla text review — SmartLineman (Flutter app)'],
    [''],
    ['What this is', 'Every Bangla line the app shows or speaks, taken from the code. One row per occurrence.'],
    ['Where to write', 'Yellow columns only: "Your revision" (the new wording), "Status" (pick from the list), "Notes".'],
    ['Leave unchanged', 'Leave "Your revision" empty if the line is fine. Do not edit the other columns: File + Line + ID let the change be applied back exactly.'],
    ['Voice column', '"Recorded clip" = a recorded mp3 exists; changing the words means re-recording. "Device voice / screen" = shown on screen or read by the phone voice; free to change.'],
    ['Placeholders', 'Keep ${...} or $name parts exactly as they are — the app fills them with numbers or names. ⏎ marks a line break.'],
    ['Sheets', 'M1–M5: level-wise (sorted by L number, then by code line). Then shared kit, menus, ladder map/gift box, guide library, catalog, life skills.'],
    ['Example', 'Current: "আরে, লাইন তো ট্রিপ করেই আছে! কাগজের ঝামেলা কেন?" → Your revision: "আরে ভাই, লাইন তো ট্রিপ করেই আছে! কাগজ লাগবে কেন?" · Status: Changed'],
    [''],
    ['Totals (rows)'],
]
for r in guide:
    ws.append(r)
ws['A1'].font = Font(name=F, bold=True, size=14)
for row in ws.iter_rows(min_row=3, max_row=12):
    row[0].font = Font(name=F, bold=True)
    for c in row[1:]:
        c.font = Font(name=F)
        c.alignment = Alignment(wrap_text=True, vertical='top')
ws.column_dimensions['A'].width = 18
ws.column_dimensions['B'].width = 110

status_dv_formula = '"OK,Changed,Discuss,Wrong fact"'

def add_sheet(title, rows, levelwise):
    s = wb.create_sheet(title[:31])
    s.append(COLS)
    for c in s[1]:
        c.font, c.fill, c.alignment = hdr_font, HEAD, Alignment(wrap_text=True, vertical='center')
    dv = DataValidation(type='list', formula1=status_dv_formula, allow_blank=True)
    s.add_data_validation(dv)
    key = (lambda r: (r.get('L', 0), r['file'], r['line'] or 0)) if levelwise else (lambda r: (r['file'], r['line'] or 0))
    n = 0
    for r in sorted(rows, key=key):
        n += 1
        rid = f"{title.split()[0][:3].upper()}-{n:04d}"
        s.append([rid, r.get('module', ''), (f"L{r['L']}" if r.get('L') else ''), r.get('Ls', '') if r.get('Ls', '').count(',') else '',
                  r.get('rungs', ''), r.get('kind', ''), r.get('title', ''), r['situation'], r['speaker'], r['voice'],
                  r['text'], '', '', '', r['file'], r['line']])
        row = s.max_row
        for ci in range(1, len(COLS) + 1):
            c = s.cell(row=row, column=ci)
            c.font = body
            c.alignment = Alignment(wrap_text=ci in (7, 8, 11, 12, 14), vertical='top')
        s.cell(row=row, column=11).font = bn_font
        for ci in (12, 13, 14):
            s.cell(row=row, column=ci).fill = EDIT
        s.cell(row=row, column=12).font = bn_font
        dv.add(s.cell(row=row, column=13))
    for i, w in enumerate(WIDTH, 1):
        s.column_dimensions[get_column_letter(i)].width = w
    s.freeze_panes = 'A2'
    s.auto_filter.ref = f"A1:{get_column_letter(len(COLS))}{max(s.max_row, 2)}"
    return n

totals = []
by_mod = defaultdict(list)
for r in level_rows:
    by_mod[r['module']].append(r)
for m in sorted(by_mod):
    totals.append((f'M{m} levels', add_sheet(f'M{m} levels', by_mod[m], True)))
for grp in ['Shared level kit & frames', 'Ladder map, gift box & duty slip', 'Menus, screens & settings',
            'Guide (mascot) library', 'Catalog: lesson titles & guide lines', 'Other']:
    if other_rows.get(grp):
        short = {'Shared level kit & frames': 'Kit & frames', 'Ladder map, gift box & duty slip': 'Ladder & gift box',
                 'Menus, screens & settings': 'Menus & screens', 'Guide (mascot) library': 'Guide library',
                 'Catalog: lesson titles & guide lines': 'Catalog', 'Other': 'Other'}[grp]
        totals.append((short, add_sheet(short, other_rows[grp], False)))
if ls_rows:
    totals.append(('Life skills', add_sheet('Life skills', ls_rows, False)))

r0 = ws.max_row + 1
for name, n in totals:
    ws.append([name, n])
    ws.cell(row=ws.max_row, column=1).font = Font(name=F)
    ws.cell(row=ws.max_row, column=2).font = Font(name=F)
    ws.cell(row=ws.max_row, column=2).alignment = Alignment(horizontal='left')
ws.append(['All sheets', f'=SUM(B{r0}:B{ws.max_row})'])
ws.cell(row=ws.max_row, column=1).font = Font(name=F, bold=True)
ws.cell(row=ws.max_row, column=2).font = Font(name=F, bold=True)
ws.cell(row=ws.max_row, column=2).alignment = Alignment(horizontal='left')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
wb.calculation.fullCalcOnLoad = True
wb.save(OUT)
print('saved', OUT)
for name, n in totals:
    print(f'{name}: {n}')
unmapped = sorted({r['file'] for r in other_rows.get('Shared level kit & frames', [])})
print('kit files (not tied to one level):', len(unmapped))
print('rungs with no mapped file:', sorted({rid for rid, i in rung_info.items() if i['status'] == 'playable' and not any(rid in v for v in file_rungs.values())})[:40])
