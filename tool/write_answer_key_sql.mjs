import { readFile, writeFile } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';

const here = path.dirname(fileURLToPath(import.meta.url));
const keys = JSON.parse(await readFile(path.join(here, 'hourly_answer_keys.json'), 'utf8'));
const quote = (value) => `'${String(value).replaceAll("'", "''")}'`;
const lines = [
  '-- Local only. Do not commit. Run after supabase/submit_flutter_hourly_quiz.sql',
  'INSERT INTO public.flutter_hourly_answer_keys (question_id, correct_choice) VALUES',
];
keys.forEach((row, index) => {
  const comma = index === keys.length - 1 ? '' : ',';
  lines.push(`(${quote(row.id)}, ${quote(row.correctChoice)})${comma}`);
});
lines.push('ON CONFLICT (question_id) DO UPDATE SET correct_choice = EXCLUDED.correct_choice;');
await writeFile(path.join(here, 'hourly_answer_keys.sql'), lines.join('\n'));
console.log(`rows ${keys.length}`);
