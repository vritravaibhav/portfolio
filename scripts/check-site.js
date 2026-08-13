#!/usr/bin/env node
/**
 * Pre-deploy checks for site/.
 *
 *     npm run check
 *
 * The site has no build step, which means nothing would otherwise catch a
 * renamed asset, a dropped meta tag, or a font quietly doubling the page
 * weight. These checks stand in for the compiler:
 *
 *   structure   — tags balance, so a stray </div> can't reflow the page
 *   assets      — every local href/src resolves on disk
 *   metadata    — the SEO contract that makes the page shareable and indexable
 *   content     — the page still carries real text, not an empty shell
 *   weight      — a cold load stays inside its byte budget
 *
 * Exits non-zero on the first failing category so CI blocks the deploy.
 */

import { gzipSync } from 'node:zlib';
import { readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import path from 'node:path';

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const SITE = path.join(ROOT, 'site');
const ORIGIN = 'https://vritravaibhav.github.io/portfolio/';

/**
 * Byte ceiling for one cold, uncached load: markup, styles, scripts, the
 * avatar, and the three preloaded faces. Raise it deliberately, never
 * incidentally — the whole point of leaving Flutter was the payload.
 */
const WEIGHT_BUDGET = 200 * 1024;

const CRITICAL_FONTS = [
  'fonts/syne-700.woff2',
  'fonts/ibm-plex-sans-400.woff2',
  'fonts/ibm-plex-mono-400.woff2',
];

const html = readFileSync(path.join(SITE, 'index.html'), 'utf8');

const failures = [];
const notes = [];

/** @param {string} label @param {() => string|void} body */
function check(label, body) {
  try {
    const note = body();
    notes.push(`  ✓ ${label}${note ? ` — ${note}` : ''}`);
  } catch (error) {
    failures.push(`  ✗ ${label}\n      ${error.message.replace(/\n/g, '\n      ')}`);
  }
}

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

// ─── Structure ───────────────────────────────────────────────────────────────

const VOID_ELEMENTS = new Set([
  'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta',
  'param', 'source', 'track', 'wbr', 'use', 'path', 'circle', 'rect',
]);

check('markup is balanced', () => {
  // Comments, then <script>/<style> bodies, which may contain tag-like text.
  const stripped = html
    .replace(/<!--[\s\S]*?-->/g, '')
    .replace(/<(script|style)\b[^>]*>[\s\S]*?<\/\1>/gi, '');

  const stack = [];
  const tag = /<(\/?)([a-zA-Z][\w-]*)\b[^>]*?(\/?)>/g;

  for (const [, closing, name, selfClosing] of stripped.matchAll(tag)) {
    const element = name.toLowerCase();
    if (VOID_ELEMENTS.has(element) || selfClosing === '/') continue;

    if (closing) {
      const open = stack.pop();
      assert(open === element, `</${element}> closes <${open ?? 'nothing'}>`);
    } else {
      stack.push(element);
    }
  }

  assert(stack.length === 0, `unclosed: ${stack.join(', ')}`);
  return 'no unclosed or crossed tags';
});

check('every input is labelled', () => {
  const ids = [...html.matchAll(/<(?:input|textarea)\b[^>]*\bid="([^"]+)"/g)]
    .map(([, id]) => id);
  assert(ids.length > 0, 'no form fields found at all');

  for (const id of ids) {
    assert(
      html.includes(`<label for="${id}"`),
      `#${id} has no <label for="${id}">`
    );
  }
  return `${ids.length} fields`;
});

// ─── Assets ──────────────────────────────────────────────────────────────────

check('local assets resolve', () => {
  const refs = new Set();

  for (const [, ref] of html.matchAll(/(?:href|src)="([^"]+)"/g)) refs.add(ref);
  for (const file of ['styles.css', 'fonts.css']) {
    const css = readFileSync(path.join(SITE, file), 'utf8');
    for (const [, ref] of css.matchAll(/url\(['"]?([^'")]+)['"]?\)/g)) refs.add(ref);
  }

  const local = [...refs].filter(
    (ref) => !/^(https?:|mailto:|tel:|data:|#)/.test(ref)
  );
  assert(local.length > 0, 'found no local references, which cannot be right');

  const missing = local.filter((ref) => !existsSync(path.join(SITE, ref.split('?')[0])));
  assert(missing.length === 0, `missing: ${missing.join(', ')}`);

  return `${local.length} references`;
});

check('module graph resolves', () => {
  const entry = readFileSync(path.join(SITE, 'main.js'), 'utf8');
  const imports = [...entry.matchAll(/from\s+'(\.[^']+)'/g)].map(([, ref]) => ref);

  assert(imports.length > 0, 'main.js imports nothing — did the refactor survive?');
  for (const ref of imports) {
    assert(existsSync(path.join(SITE, ref)), `main.js imports missing ${ref}`);
  }
  assert(
    /<script\s+type="module"/.test(html),
    'main.js uses import but index.html loads it as a classic script'
  );
  return imports.join(', ');
});

// ─── Metadata ────────────────────────────────────────────────────────────────

check('SEO and share tags present', () => {
  // Attributes wrap across lines in the source, so every pattern that spans
  // more than one attribute has to tolerate arbitrary whitespace.
  const required = [
    [/<title>[^<]{10,}<\/title>/, '<title>'],
    [/<meta name="description"\s+content="[^"]{50,}"/, 'meta description (50+ chars)'],
    [/<link rel="canonical"\s+href="[^"]+"/, 'canonical link'],
    [/<meta property="og:title"/, 'og:title'],
    [/<meta property="og:description"/, 'og:description'],
    [/<meta property="og:image"/, 'og:image'],
    [/<meta property="og:url"/, 'og:url'],
    [/<meta name="twitter:card"/, 'twitter:card'],
    [/<meta name="viewport"/, 'viewport'],
    [/<html lang="[a-z]{2}"/, 'html lang'],
  ];

  const missing = required.filter(([pattern]) => !pattern.test(html)).map(([, name]) => name);
  assert(missing.length === 0, `missing: ${missing.join(', ')}`);
  return `${required.length} tags`;
});

check('absolute URLs point at the deployed origin', () => {
  // og:image and canonical must be absolute; relative ones break link unfurls.
  for (const property of ['og:image', 'og:url']) {
    const match = html.match(new RegExp(`<meta property="${property}"\\s+content="([^"]+)"`));
    assert(match, `${property} not found`);
    assert(
      match[1].startsWith(ORIGIN),
      `${property} is "${match[1]}", expected it under ${ORIGIN}`
    );
  }

  const canonical = html.match(/<link rel="canonical"\s+href="([^"]+)"/);
  assert(canonical, 'no canonical link to compare against');
  assert(canonical[1] === ORIGIN, `canonical is "${canonical[1]}", expected ${ORIGIN}`);
  return ORIGIN;
});

check('Person structured data is valid', () => {
  const match = html.match(
    /<script type="application\/ld\+json">([\s\S]*?)<\/script>/
  );
  assert(match, 'no JSON-LD block');

  const data = JSON.parse(match[1]);
  assert(data['@type'] === 'Person', `@type is ${data['@type']}, expected Person`);

  for (const field of ['name', 'jobTitle', 'url', 'image', 'sameAs', 'worksFor']) {
    assert(data[field], `Person.${field} missing`);
  }
  assert(Array.isArray(data.sameAs) && data.sameAs.length >= 2,
    'sameAs should list at least two profiles');

  return `${data.name}, ${data.sameAs.length} profiles`;
});

check('robots and sitemap agree with the canonical origin', () => {
  const robots = readFileSync(path.join(SITE, 'robots.txt'), 'utf8');
  const sitemap = readFileSync(path.join(SITE, 'sitemap.xml'), 'utf8');

  assert(/^User-agent:/m.test(robots), 'robots.txt has no User-agent line');
  assert(robots.includes(`${ORIGIN}sitemap.xml`), 'robots.txt does not advertise the sitemap');
  assert(sitemap.includes(`<loc>${ORIGIN}</loc>`), 'sitemap does not list the canonical URL');
  assert(!/Disallow: \/\s*$/m.test(robots), 'robots.txt disallows the whole site');

  return 'aligned';
});

// ─── Content ─────────────────────────────────────────────────────────────────

check('page ships real indexable text', () => {
  const text = html
    .replace(/<(script|style|svg)\b[^>]*>[\s\S]*?<\/\1>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&[a-z]+;/gi, ' ');

  const words = text.split(/\s+/).filter(Boolean);
  assert(words.length >= 500,
    `only ${words.length} words of body text — the content may have been dropped`);

  // Spot-check the load-bearing terms: if these vanish, the page is a shell.
  for (const term of ['Spring Boot', 'Flutter', 'NDK/JNI', 'Panjab University']) {
    assert(text.includes(term), `"${term}" missing from the rendered text`);
  }

  return `${words.length} words`;
});

// ─── Weight ──────────────────────────────────────────────────────────────────

check('cold load fits the byte budget', () => {
  const rows = [];
  let total = 0;

  // Text assets are served compressed; binaries are already compressed.
  for (const file of ['index.html', 'styles.css', 'fonts.css', 'main.js', 'contact.js']) {
    const size = gzipSync(readFileSync(path.join(SITE, file)), { level: 9 }).length;
    rows.push([`${file} (gz)`, size]);
    total += size;
  }
  for (const file of ['assets/profilepic.jpeg', ...CRITICAL_FONTS]) {
    const size = statSync(path.join(SITE, file)).size;
    rows.push([file, size]);
    total += size;
  }

  const detail = rows
    .map(([name, size]) => `        ${name.padEnd(32)} ${String(size).padStart(7)} B`)
    .join('\n');

  assert(
    total <= WEIGHT_BUDGET,
    `cold load is ${(total / 1024).toFixed(1)} KB, over the ` +
    `${(WEIGHT_BUDGET / 1024).toFixed(0)} KB budget:\n${detail}`
  );

  const headroom = ((1 - total / WEIGHT_BUDGET) * 100).toFixed(0);
  return `${(total / 1024).toFixed(1)} KB of ${(WEIGHT_BUDGET / 1024).toFixed(0)} KB (${headroom}% headroom)`;
});

check('no dead weight in fonts/', () => {
  const css = readFileSync(path.join(SITE, 'fonts.css'), 'utf8');
  const declared = new Set(
    [...css.matchAll(/url\('fonts\/([^']+)'\)/g)].map(([, name]) => name)
  );
  const onDisk = readdirSync(path.join(SITE, 'fonts')).filter((f) => f.endsWith('.woff2'));

  const orphaned = onDisk.filter((file) => !declared.has(file));
  assert(orphaned.length === 0,
    `shipped but never declared in fonts.css: ${orphaned.join(', ')}\n` +
    'delete them, or add the weight to site/fonts/regenerate.py');

  // A face declared but absent would already fail the asset check; this catches
  // the opposite drift, where regenerate.py is edited but never re-run.
  const undeclared = [...declared].filter((file) => !onDisk.includes(file));
  assert(undeclared.length === 0, `declared but not on disk: ${undeclared.join(', ')}`);

  return `${onDisk.length} faces, all referenced`;
});

check('stylesheet uses only the weights that are shipped', () => {
  const css = readFileSync(path.join(SITE, 'fonts.css'), 'utf8');
  const styles = readFileSync(path.join(SITE, 'styles.css'), 'utf8');

  // family -> set of available weights, from the @font-face blocks
  const available = new Map();
  for (const [, block] of css.matchAll(/@font-face\s*\{([^}]+)\}/g)) {
    const family = block.match(/font-family:\s*'([^']+)'/)[1];
    const weight = block.match(/font-weight:\s*(\d+)/)[1];
    if (!available.has(family)) available.set(family, new Set());
    available.get(family).add(weight);
  }

  const used = new Set(
    [...styles.matchAll(/font-weight:\s*(\d+)/g)].map(([, weight]) => weight)
  );
  // 400 is the implicit default for every rule that never states a weight.
  used.add('400');

  const everyWeight = new Set([...available.values()].flatMap((set) => [...set]));
  const unsupported = [...used].filter((weight) => !everyWeight.has(weight));

  assert(unsupported.length === 0,
    `styles.css asks for weight ${unsupported.join(', ')}, which no @font-face ` +
    'provides — the browser will synthesise it and it will look wrong');

  return `weights ${[...everyWeight].sort().join(', ')}`;
});

// ─── Report ──────────────────────────────────────────────────────────────────

console.log('\nsite/ checks\n');
console.log(notes.join('\n'));

if (failures.length > 0) {
  console.error(`\n${failures.length} failed:\n`);
  console.error(failures.join('\n'));
  console.error('');
  process.exit(1);
}

console.log(`\n${notes.length} checks passed.\n`);
