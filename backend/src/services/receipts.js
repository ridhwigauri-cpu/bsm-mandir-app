import { config } from '../config.js';

/** भारतीय वित्त वर्ष: 2026-27 */
export function financialYear(date = new Date()) {
  const m = date.getMonth() + 1;
  const y = date.getFullYear();
  const startYear = m >= config.fyStartMonth ? y : y - 1;
  const endYear = (startYear + 1) % 100;
  return `${startYear}-${String(endYear).padStart(2, '0')}`;
}

/** अगला रसीद नंबर — 80G/2026-27/1001 (काउंटर DB में, एक ही लेन-देन में) */
export async function nextReceiptNo(client, date = new Date()) {
  const fy = financialYear(date);
  const upd = await client.query(
    'UPDATE counters SET last = last + 1 WHERE fy = $1 RETURNING last',
    [fy],
  );
  let last;
  if (upd.rows.length > 0) {
    last = upd.rows[0].last;
  } else {
    const ins = await client.query(
      'INSERT INTO counters (fy, last) VALUES ($1, $2) RETURNING last',
      [fy, 1001],
    );
    last = ins.rows[0].last;
  }
  return `80G/${fy}/${last}`;
}

/** घोषणा का टेक्स्ट */
export function announcementText(name, amount) {
  const inr = `₹${Number(amount).toLocaleString('en-IN')}`;
  return `जय बाबा सिद्धनाथ! श्री ${name} जी ने ${inr} का दान दिया। बाबा सिद्धनाथ आपका कल्याण करें।`;
}
