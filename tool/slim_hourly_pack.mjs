import { readFile, writeFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const packPath = path.join(here, '../assets/data/hourly_quiz_pack.json');
const keyPath = path.join(here, 'hourly_answer_keys.json');
const pack = JSON.parse(await readFile(packPath, 'utf8'));
const visual = pack.questions.filter((question) => question.visual);
const text = pack.questions.filter((question) => !question.visual).slice(0, 600);
const questions = [...visual, ...text].sort((a, b) => a.id.localeCompare(b.id));
const raw = JSON.stringify({ version: 1, questions });
if (/correctChoice|correct_index|correct_answer/.test(raw)) throw new Error('answer leaked');
await writeFile(packPath, raw);
const keys = JSON.parse(await readFile(keyPath, 'utf8'));
const ids = new Set(questions.map((question) => question.id));
const kept = keys.filter((row) => ids.has(row.id));
await writeFile(keyPath, JSON.stringify(kept));
console.log(`kept ${questions.length} visual ${visual.length}`);
