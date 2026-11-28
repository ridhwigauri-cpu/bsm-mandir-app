/**
 * Neon Function — `nightly` : रोज़ का हिसाब + सफ़ाई
 *
 * Neon का **Function Trigger** (`schedule`) रोज़ रात को इस रास्ते POST करता है।
 * हर delivery `parseTriggerDelivery` से जाँची जाती है — बिना trigger के आया
 * कोई भी request 401 पाता है।
 *
 *  GET  /health  → जाँच
 *  POST /cron    → trigger delivery (नीचे का काम करता है)
 *
 * काम:
 *  1. कल के भुगतान वाले दान का सारांश `daily_reports` में लिखना (कार्यालय सुबह देखे)
 *  2. 7 दिन से लंबित (pending_verification) दान की गिनती
 *  3. पुराने `alerts` (90 दिन) और `audit_log` (180 दिन) हटाना
 */
import { parseTriggerDelivery } from '@neon/functions/triggers';
import { q, tx } from '../src/db.js';

const json = (body, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json; charset=utf-8' },
  });

/**
 * असली काम — किसी भी दिन के लिए चलाया जा सकता है (टेस्ट भी यही बुलाता है)
 * @param {Date} day  जिस दिन का सारांश बनाना है (डिफ़ॉल्ट: कल)
 */
export async function runNightly(day = new Date(Date.now() - 24 * 60 * 60 * 1000)) {
  const dateKey = day.toISOString().slice(0, 10);

  // तारीख़ों की तुलना JS में बनी range से — हर Postgres (और pg-mem) पर एक जैसी
  const dayStart = new Date(`${dateKey}T00:00:00.000Z`);
  const dayEnd = new Date(dayStart.getTime() + 24 * 60 * 60 * 1000);
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
  const ninetyDaysAgo = new Date(Date.now() - 90 * 24 * 60 * 60 * 1000);
  const sixMonthsAgo = new Date(Date.now() - 180 * 24 * 60 * 60 * 1000);

  return tx(async (client) => {
    // 1. उस दिन का सारांश
    const sum = await client.query(
      `SELECT COALESCE(SUM(amount), 0)::int              AS total,
              COUNT(*)::int                              AS count,
              COUNT(*) FILTER (WHERE amount > 5000)::int AS big_count,
              COALESCE(MAX(amount), 0)::int              AS max_amount
         FROM donations
        WHERE status = 'paid'
          AND COALESCE(paid_at, created_at) >= $1
          AND COALESCE(paid_at, created_at) <  $2`,
      [dayStart.toISOString(), dayEnd.toISOString()],
    );
    const s = sum.rows[0];

    // 2. लंबित सत्यापन (7 दिन से पुराने)
    const pend = await client.query(
      `SELECT COUNT(*)::int AS count FROM donations
        WHERE status = 'pending_verification' AND created_at < $1`,
      [sevenDaysAgo.toISOString()],
    );

    // 3. सफ़ाई
    const oldAlerts = await client.query('DELETE FROM alerts WHERE created_at < $1', [ninetyDaysAgo.toISOString()]);
    const oldAudit = await client.query('DELETE FROM audit_log WHERE created_at < $1', [sixMonthsAgo.toISOString()]);

    const summary = {
      date: dateKey,
      paid_count: s.count,
      paid_total: s.total,
      big_donations: s.big_count,
      max_donation: s.max_amount,
      pending_verification_7d: pend.rows[0].count,
      alerts_deleted: oldAlerts.rowCount ?? 0,
      audit_deleted: oldAudit.rowCount ?? 0,
    };

    const notes = `alerts हटाए: ${summary.alerts_deleted}, audit हटाए: ${summary.audit_deleted}`;
    const existing = await client.query(
      'SELECT report_date FROM daily_reports WHERE report_date = $1',
      [dateKey],
    );

    if (existing.rows.length > 0) {
      await client.query(
        `UPDATE daily_reports
            SET paid_count = $2, paid_total = $3, big_donations = $4, max_donation = $5,
                pending_verification_7d = $6, notes = $7, created_at = now()
          WHERE report_date = $1`,
        [dateKey, s.count, s.total, s.big_count, s.max_amount, summary.pending_verification_7d, notes],
      );
    } else {
      await client.query(
        `INSERT INTO daily_reports (report_date, paid_count, paid_total, big_donations,
                                    max_donation, pending_verification_7d, notes)
         VALUES ($1, $2, $3, $4, $5, $6, $7)`,
        [dateKey, s.count, s.total, s.big_count, s.max_amount, summary.pending_verification_7d, notes],
      );
    }

    return summary;
  });
}

export default {
  async fetch(request) {
    const url = new URL(request.url);
    const path = url.pathname.replace(/\/+$/, '') || '/';

    if (request.method === 'GET' && (path === '/health' || path === '/')) {
      const last = await q('SELECT report_date, paid_count, paid_total FROM daily_reports ORDER BY report_date DESC LIMIT 1').catch(() => []);
      return json({
        ok: true,
        function: 'nightly-report',
        branch: process.env.NEON_BRANCH ?? null,
        lastReport: last[0] ?? null,
      });
    }

    if (request.method === 'POST' && (path === '/cron' || path === '/')) {
      // असली trigger delivery है या नहीं (x-neon-trigger-invocation-id ↔ body)
      const parsed = await parseTriggerDelivery(request);
      if (!parsed.ok) {
        return json({ error: 'यह request Neon trigger से नहीं आई', reason: parsed.error }, 401);
      }

      const scheduledAt = parsed.invocation.data?.scheduledAt;
      const day = scheduledAt
        ? new Date(new Date(scheduledAt).getTime() - 24 * 60 * 60 * 1000)
        : new Date(Date.now() - 24 * 60 * 60 * 1000);

      const summary = await runNightly(day);
      return json({ ok: true, trigger: parsed.invocation.trigger.name, ...summary });
    }

    return json({ error: 'रास्ता नहीं मिला' }, 404);
  },
};
