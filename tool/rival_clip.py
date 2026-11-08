"""Make one clip in the careless coworker's / rival's recorded voice and
register it in lib/features/game/learn_voice_map.dart (learnRivalVoice).

    python -I tool/rival_clip.py . <say-file>

say-file (UTF-8): line 1 = the exact key text as in the code (English digits,
as enDigits makes it); line 2 = the spoken form (usually the same; spell
digits and Latin words the way they should be said, e.g. "পাঁচ", "এলটি").
Voice: bn-BD-PradeepNeural, rate -6 %, pitch -14 Hz (level 1's rival). An
existing clip is reused (the file name is the key's SHA-1). Also list the
line in tool/dump_learn_voice_lines_test.dart so a voice regeneration keeps
it. Never rerun tool/make_learn_voice.py wholesale.
"""
import asyncio
import hashlib
import io
import json
import os
import re
import sys

import edge_tts

root, say_file = sys.argv[1], sys.argv[2]
sys.stdout.reconfigure(encoding='utf-8')
key, say = io.open(say_file, encoding='utf-8').read().split('\n')[:2]
name = 'r_' + hashlib.sha1(key.encode('utf-8')).hexdigest()[:10] + '.mp3'
path = os.path.join(root, 'assets', 'sounds', 'learn_voice', name)
if not os.path.exists(path):
    asyncio.run(edge_tts.Communicate(say, 'bn-BD-PradeepNeural', rate='-6%', pitch='-14Hz').save(path))
print(name, os.path.getsize(path), '|', say)
p = os.path.join(root, 'lib', 'features', 'game', 'learn_voice_map.dart')
s = io.open(p, encoding='utf-8').read()
head = 'const learnRivalVoice = <String, String>{\n'
i = s.index(head) + len(head)
j = s.index('};', i)
d = {}
for line in [x for x in s[i:j].split('\n') if x.strip()]:
    m = re.match(r'\s*(".*"): \'(.*)\',$', line)
    d[json.loads(m.group(1))] = m.group(2)
d[key] = 'sounds/learn_voice/' + name
out = ''.join('  ' + json.dumps(k, ensure_ascii=False).replace('$', '\\$') + ": '" + d[k] + "',\n" for k in sorted(d))
io.open(p, 'w', encoding='utf-8', newline='\n').write(s[:i] + out + s[j:])
print('registered', len(d))
