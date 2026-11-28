import pg from 'pg';
import { config } from './config.js';

let pool;

export function getPool() {
  if (!pool) {
    if (!config.databaseUrl) throw new Error('DATABASE_URL सेट नहीं है (.env देखें)');
    pool = new pg.Pool({
      connectionString: config.databaseUrl,
      max: config.dbMaxConnections,
      idleTimeoutMillis: config.dbIdleTimeoutMs,
      connectionTimeoutMillis: 8000,
      // Neon को SSL चाहिए
      ssl: /neon\.tech|sslmode=require/.test(config.databaseUrl) ? { rejectUnauthorized: false } : undefined,
    });
  }
  return pool;
}

export function setPool(p) { pool = p; }

export async function q(text, params = []) {
  const res = await getPool().query(text, params);
  return res.rows;
}

export async function tx(fn) {
  const client = await getPool().connect();
  try {
    await client.query('BEGIN');
    const out = await fn(client);
    await client.query('COMMIT');
    return out;
  } catch (e) {
    try { await client.query('ROLLBACK'); } catch { /* ignore */ }
    throw e;
  } finally {
    client.release();
  }
}
