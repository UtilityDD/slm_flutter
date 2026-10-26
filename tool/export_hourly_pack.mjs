/**
 * Build the Flutter hourly pack from the live bank.
 * The asset file has questions and pictures. It does not contain the right answer.
 * Answer keys are written beside this script and are not shipped in the app.
 */
import { mkdir, readFile, writeFile, copyFile, access } from 'fs/promises';
import path from 'path';
import { fileURLToPath } from 'url';
import { parseVisualQuizCSV, rowsToVisualQuestions } from '../../slm_web/src/utils/visualQuizCsv.js';
import { VISUAL_QUIZ_LIVE_CSV_URL } from '../../slm_web/src/utils/visualQuizCsv.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const flutterRoot = path.resolve(here, '..');
const webImageDir = path.resolve(here, '../../slm_web/public/images/quizzes');
const assetImageDir = path.join(flutterRoot, 'assets', 'quizzes');
const packPath = path.join(flutterRoot, 'assets', 'data', 'hourly_quiz_pack.json');
const keyPath = path.join(here, 'hourly_answer_keys.json');

const imageName = (value) => {
  const raw = String(value || '').trim();
  if (!raw) return '';
  const lower = raw.toLowerCase();
  const looksImage = lower.startsWith('http') || lower.startsWith('/') || /\.(png|jpe?g|webp|gif)(\?|$)/i.test(raw);
  if (!looksImage) return '';
  const base = raw.split('?')[0].split('/').pop() || '';
  return base.replace(/[^a-zA-Z0-9._-]/g, '');
};

async function exists(file) {
  try {
    await access(file);
    return true;
  } catch {
    return false;
  }
}

async function supabaseConfig() {
  const source = await readFile(path.join(flutterRoot, 'lib', 'core', 'config', 'app_config.dart'), 'utf8');
  const url = source.match(/supabaseUrl[\s\S]*?defaultValue:\s*'([^']+)'/);
  const key = source.match(/supabaseAnonKey[\s\S]*?defaultValue:\s*'([^']+)'/);
  if (!url || !key) throw new Error('Could not read Supabase settings from app_config.dart');
  return { url: url[1], key: key[1] };
}

async function fetchTextQuestions(url, key) {
  const rows = [];
  const page = 1000;
  for (let from = 0; ; from += page) {
    const endpoint = new URL('/rest/v1/hourly_questions', url);
    endpoint.searchParams.set('language', 'eq.bn');
    endpoint.searchParams.set('select', 'id,question_text,options,correct_answer_index,category,tags');
    const response = await fetch(endpoint, {
      headers: {
        apikey: key,
        Authorization: `Bearer ${key}`,
        Range: `${from}-${from + page - 1}`,
      },
    });
    if (!response.ok) throw new Error(`hourly_questions ${response.status}`);
    const batch = await response.json();
    if (!Array.isArray(batch) || batch.length === 0) break;
    rows.push(...batch);
    if (batch.length < page) break;
  }
  return rows;
}

function asOptions(value) {
  if (Array.isArray(value)) return value.map((item) => String(item ?? '').trim());
  if (typeof value === 'string') {
    try {
      const parsed = JSON.parse(value);
      if (Array.isArray(parsed)) return parsed.map((item) => String(item ?? '').trim());
    } catch {
      return [];
    }
  }
  return [];
}

function asTags(value) {
  if (Array.isArray(value)) return value.map((item) => String(item).trim()).filter(Boolean);
  return [];
}

async function main() {
  const { url, key } = await supabaseConfig();
  const [dbRows, csvResponse] = await Promise.all([
    fetchTextQuestions(url, key),
    fetch(VISUAL_QUIZ_LIVE_CSV_URL),
  ]);
  if (!csvResponse.ok) throw new Error(`visual sheet ${csvResponse.status}`);
  const visualRows = rowsToVisualQuestions(parseVisualQuizCSV(await csvResponse.text()), { language: 'bn' });

  const merged = new Map();
  for (const row of dbRows) {
    const options = asOptions(row.options);
    const index = Number(row.correct_answer_index);
    if (!row.id || options.filter(Boolean).length < 2 || !Number.isInteger(index) || !options[index]) continue;
    merged.set(String(row.id), {
      id: String(row.id),
      text: String(row.question_text || '').trim(),
      imageName: '',
      options,
      tags: asTags(row.tags),
      correctChoice: options[index],
      visual: false,
    });
  }
  for (const row of visualRows) {
    const options = asOptions(row.options);
    const index = Number(row.correct_option_index);
    if (!row.id || options.filter(Boolean).length < 2 || !options[index]) continue;
    const picture = imageName(row.question_image_url);
    const optionPictures = options.some((option) => imageName(option));
    merged.set(String(row.id), {
      id: String(row.id),
      text: String(row.question_text || '').trim(),
      imageName: picture,
      options,
      tags: asTags(row.tags),
      correctChoice: options[index],
      visual: Boolean(picture || optionPictures),
    });
  }

  await mkdir(assetImageDir, { recursive: true });
  const questions = [];
  const keys = [];
  let copied = 0;
  let missing = 0;
  const seenImages = new Set();

  async function assetFor(name) {
    if (!name) return '';
    const source = path.join(webImageDir, name);
    const target = path.join(assetImageDir, name);
    if (!(await exists(source))) {
      missing += 1;
      return '';
    }
    if (!seenImages.has(name)) {
      await copyFile(source, target);
      seenImages.add(name);
      copied += 1;
    }
    return `assets/quizzes/${name}`;
  }

  for (const row of merged.values()) {
    if (!row.text) continue;
    const image = await assetFor(row.imageName);
    const options = [];
    for (const option of row.options) {
      if (!option) continue;
      const pictureName = imageName(option);
      const picture = pictureName ? await assetFor(pictureName) : '';
      options.push({
        value: option,
        image: picture,
      });
    }
    if (options.length < 2) continue;
    questions.push({
      id: row.id,
      text: row.text,
      image,
      options,
      tags: row.tags,
      visual: Boolean(image) || options.some((option) => option.image),
    });
    keys.push({ id: row.id, correctChoice: row.correctChoice });
  }

  const visualRows = questions.filter((row) => row.visual);
  const textRows = questions.filter((row) => !row.visual).slice(0, 600);
  const shipped = [...visualRows, ...textRows];
  const shippedIds = new Set(shipped.map((row) => row.id));
  const shippedKeys = keys.filter((row) => shippedIds.has(row.id));
  shipped.sort((a, b) => a.id.localeCompare(b.id));
  shippedKeys.sort((a, b) => a.id.localeCompare(b.id));

  const pack = JSON.stringify({ version: 1, questions: shipped });
  if (/"correctChoice"|"correct_index"|"correct_answer"/.test(pack)) {
    throw new Error('Pack unexpectedly contains an answer field');
  }
  await writeFile(packPath, pack);
  await writeFile(keyPath, JSON.stringify(shippedKeys));
  console.log(`questions ${shipped.length}`);
  console.log(`visual ${shipped.filter((row) => row.visual).length}`);
  console.log(`images copied ${copied}`);
  console.log(`images missing ${missing}`);
  console.log(`keys ${shippedKeys.length} (not in the app asset)`);
}

main().catch((error) => {
  console.error(error.message || error);
  process.exit(1);
});
