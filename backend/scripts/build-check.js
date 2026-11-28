#!/usr/bin/env node
/**
 * `npm run build` — plain Node प्रोजेक्ट के लिए "build" का मतलब:
 * हर सोर्स फ़ाइल का सिंटैक्स जाँचें + ज़रूरी assets और config मौजूद हों।
 * (कोई transpile नहीं — Lambda/Docker पर सीधे यही फ़ाइलें जाती हैं)
 */
import { execFileSync } from 'node:child_process';
import { readdirSync, statSync, existsSync } from 'node:fs';
import path from 'node:path';

const root = path.resolve(import.meta.dirname, '..');
const walk = (dir, out = []) => {
  for (const entry of readdirSync(dir)) {
    const p = path.join(dir, entry);
    if (statSync(p).isDirectory()) walk(p, out);
    else if (p.endsWith('.js')) out.push(p);
  }
  return out;
};

let failed = 0;
const files = [...walk(path.join(root, 'src')), ...walk(path.join(root, 'functions'))];
for (const file of files) {
  try {
    execFileSync(process.execPath, ['--check', file], { stdio: 'pipe' });
  } catch (e) {
    failed++;
    console.error(`✗ ${path.relative(root, file)}\n${e.stderr?.toString() ?? e.message}`);
  }
}
console.log(`सिंटैक्स जाँच: ${files.length - failed}/${files.length} फ़ाइलें ठीक`);

const required = [
  'db/schema.sql',
  'assets/fonts/NotoSansDevanagari-Regular.ttf',
  'assets/fonts/NotoSansDevanagari-Bold.ttf',
  'assets/images/foundation_logo.jpg',
  'template.yaml',
  'neon.ts',
  'functions/api.js',
  'functions/razorpay.js',
  'functions/nightly.js',
];
for (const rel of required) {
  if (!existsSync(path.join(root, rel))) {
    failed++;
    console.error(`✗ गुम फ़ाइल: ${rel}`);
  }
}

if (failed > 0) {
  console.error(`\nबिल्ड फेल — ${failed} समस्या`);
  process.exit(1);
}
console.log('✓ बिल्ड पास — सभी सोर्स और assets ठीक');
