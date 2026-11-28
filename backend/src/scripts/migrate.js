import fs from 'node:fs/promises';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import pg from 'pg';
import { config } from '../config.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const schemaPath = path.join(here, '../../db/schema.sql');

const sql = await fs.readFile(schemaPath, 'utf8');

// Neon: स्कीमा बदलने के लिए **direct** (unpooled) connection चाहिए।
// Pooled (-pooler) पर DDL चलाना भरोसेमंद नहीं होता।
const url = process.env.DATABASE_URL_UNPOOLED || config.databaseUrl;
if (!url) {
  console.error('✗ DATABASE_URL या DATABASE_URL_UNPOOLED सेट नहीं है (.env देखें)');
  process.exit(1);
}
const pool = new pg.Pool({
  connectionString: url,
  ssl: /neon\.tech|sslmode=require/.test(url) ? { rejectUnauthorized: false } : undefined,
  max: 1,
});
await pool.query(sql);
await pool.end();
console.log('   (कनेक्शन: ' + (process.env.DATABASE_URL_UNPOOLED ? 'direct / unpooled' : 'DATABASE_URL') + ')');
console.log('✅ स्कीमा लागू हो गया (db/schema.sql)');
