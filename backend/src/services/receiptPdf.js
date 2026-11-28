import fs from 'node:fs/promises';
import { existsSync as fsStatSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import puppeteer from 'puppeteer-core';
import { config } from '../config.js';

const here = path.dirname(fileURLToPath(import.meta.url));
const fontDir = path.join(here, '../../assets/fonts');

let sparticuzChromium = null;

/** Lambda के लिए @sparticuz/chromium (install हो तो) */
async function serverlessChromium() {
  if (sparticuzChromium) return sparticuzChromium;
  try {
    const mod = await import('@sparticuz/chromium');
    sparticuzChromium = mod.default;
    return sparticuzChromium;
  } catch {
    return null;
  }
}

/** Chromium कहाँ है — कई जगह खोजें */
function resolveChromium() {
  const candidates = [
    config.chromiumPath,
    process.env.CHROME_PATH,
    '/usr/bin/chromium',
    '/usr/bin/chromium-browser',
    '/usr/bin/google-chrome',
    '/usr/local/bin/chromium',
    '/usr/local/bin/google-chrome',
    '/snap/bin/chromium',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  ].filter(Boolean);
  for (const c of candidates) {
    try {
      if (fsStatSync(c)) return c;
    } catch { /* next */ }
  }
  throw Object.assign(
    new Error('Chromium नहीं मिला — सर्वर पर `apt install chromium` करें या CHROMIUM_PATH सेट करें'),
    { status: 503 },
  );
}

let browserPromise = null;
let fontCssCache = null;

/** फ़ॉन्ट को base64 में — हर जगह एक जैसी देवनागरी रेंडर हो */
async function devanagariFontCss() {
  if (fontCssCache) return fontCssCache;
  const read = async (f) => (await fs.readFile(path.join(fontDir, f))).toString('base64');
  const [reg, bold] = await Promise.all([
    read('NotoSansDevanagari-Regular.ttf'),
    read('NotoSansDevanagari-Bold.ttf'),
  ]);
  fontCssCache = `
@font-face{font-family:'NotoDev';src:url(data:font/ttf;base64,${reg}) format('truetype');font-weight:400;font-display:block}
@font-face{font-family:'NotoDev';src:url(data:font/ttf;base64,${bold}) format('truetype');font-weight:700;font-display:block}
*{font-family:'NotoDev','Noto Sans Devanagari',sans-serif}`;
  return fontCssCache;
}

async function getBrowser() {
  if (!browserPromise) {
    const sls = await serverlessChromium();
    if (sls) {
      browserPromise = puppeteer.launch({
        args: sls.args,
        defaultViewport: sls.defaultViewport,
        executablePath: await sls.executablePath(),
        headless: sls.headless,
      });
    } else {
      browserPromise = puppeteer.launch({
        executablePath: resolveChromium(),
        headless: 'new',
        args: ['--no-sandbox', '--disable-dev-shm-usage', '--disable-gpu', '--font-render-hinting=none'],
      });
    }
  }
  return browserPromise;
}

/** HTML → PDF बफ़र */
export async function htmlToPdf(html, { landscape = false, format = 'A4' } = {}) {
  const browser = await getBrowser();
  const page = await browser.newPage();
  try {
    const css = await devanagariFontCss();
    const withCss = html.replace('</style>', `${css}</style>`).replace(
      '<head>',
      `<head><meta charset="utf-8">`,
    );
    await page.setContent(withCss, { waitUntil: 'load' });
    // फ़ॉन्ट लोड होने दें
    await page.evaluate(() => document.fonts.ready);
    const pdf = await page.pdf({
      format,
      landscape,
      printBackground: true,
      margin: { top: '10mm', right: '10mm', bottom: '10mm', left: '10mm' },
    });
    // puppeteer Uint8Array देता है — Express को Buffer चाहिए
    return Buffer.from(pdf);
  } finally {
    await page.close();
  }
}

/** Lambda के बाहर (server) PDF नहीं बन सकती तो साफ़ संदेश */
export function pdfUnavailableError() {
  return Object.assign(
    new Error('इस सर्वर पर PDF नहीं बन सकती — Chromium उपलब्ध नहीं। ऐप में रसीद का PDF बन जाता है।'),
    { status: 503 },
  );
}

export async function closeBrowser() {
  if (browserPromise) {
    const b = await browserPromise;
    await b.close();
    browserPromise = null;
  }
}

/* ---------------- रसीद (दान प्रशस्ति पत्र शैली) ---------------- */

const inr = (n) => '₹' + Number(n).toLocaleString('en-IN');

const amountWords = (n) => {
  const ones = ['', 'एक', 'दो', 'तीन', 'चार', 'पाँच', 'छह', 'सात', 'आठ', 'नौ', 'दस',
    'ग्यारह', 'बारह', 'तेरह', 'चौदह', 'पंद्रह', 'सोलह', 'सत्रह', 'अठारह', 'उन्नीस'];
  const tens = ['', '', 'बीस', 'तीस', 'चालीस', 'पचास', 'साठ', 'सत्तर', 'अस्सी', 'नब्बे'];
  const two = (x) => (x < 20 ? ones[x] : `${tens[Math.floor(x / 10)]}${x % 10 ? ' ' + ones[x % 10] : ''}`);
  const parts = [];
  const crore = Math.floor(n / 10000000);
  const lakh = Math.floor((n % 10000000) / 100000);
  const thousand = Math.floor((n % 100000) / 1000);
  const hundred = Math.floor((n % 1000) / 100);
  const rest = n % 100;
  if (crore) parts.push(`${two(crore)} करोड़`);
  if (lakh) parts.push(`${two(lakh)} लाख`);
  if (thousand) parts.push(`${two(thousand)} हज़ार`);
  if (hundred) parts.push(`${ones[hundred]} सौ`);
  if (rest) parts.push(two(rest));
  return `${parts.join(' ') || 'शून्य'} रुपये मात्र`;
};

const hiDate = (d) => {
  const months = ['जनवरी', 'फरवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'];
  const dt = new Date(d);
  return `${dt.getDate()} ${months[dt.getMonth()]} ${dt.getFullYear()}`;
};

/** दान रसीद का HTML (प्रशस्ति पत्र शैली) */
export function receiptHtml(d, { foundation }) {
  const commendation = d.amount > 5000;
  const title = commendation ? 'दान प्रशस्ति पत्र' : 'दान रसीद';
  const titleEn = commendation ? 'Certificate of Commendation' : 'Donation Receipt';
  const body = commendation
    ? `यह विशेष प्रशस्ति पत्र आदरणीय <b>${d.name}</b> को श्री बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन की ओर से
       आपके बहुमूल्य एवं पुनीत योगदान के लिए अत्यंत आभार प्रकट करने हेतु प्रदान किया जाता है। आपके उदार सहयोग ने
       मंदिर के पुनर्निर्माण और सौंदर्यकरण कार्यों को गति प्रदान की है।`
    : `यह रसीद आदरणीय <b>${d.name}</b> को श्री बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन की ओर से
       प्राप्त दान राशि के लिए प्रदान की जाती है। आपके सहयोग हेतु हार्दिक आभार — बाबा सिद्धनाथ आपका कल्याण करें।`;
  const note = commendation
    ? '(यह विशेष प्रशस्ति पत्र ₹5,000/- से अधिक की दान राशि के लिए है)'
    : '(यह रसीद 80G कर छूट हेतु मान्य है)';

  return `<!doctype html><html lang="hi"><head><style>
body{margin:0;padding:6mm;background:#fff;color:#3A2416}
.frame{padding:3px;border-radius:16px;background:linear-gradient(135deg,#E8B54A,#B9862A,#E8B54A)}
.inner{background:#FFF9EE;border:1px solid rgba(185,134,42,.85);border-radius:14px;padding:16px}
.top{display:flex;justify-content:space-between;align-items:center}
.chip{background:#B34700;color:#FFE9B8;font-size:10px;font-weight:700;padding:4px 8px;border-radius:6px}
.logo{width:64px;height:64px;border-radius:50%;border:2px solid #B9862A;object-fit:cover}
.mid{text-align:center;margin:10px 0 4px}
.pill{display:inline-block;background:#1B2A6B;color:#FFF3DC;font-size:16px;font-weight:700;padding:6px 22px;border-radius:50px}
.en{color:#B01B2E;font-style:italic;font-size:17px;margin-top:4px;font-weight:700}
.body{font-size:12.5px;line-height:1.7;text-align:center;margin:12px 4px 0}
.body b{color:#B34700}
.note{color:#B01B2E;font-style:italic;font-weight:700;font-size:10.5px;text-align:center;margin-top:6px}
.bottom{display:flex;justify-content:space-between;align-items:flex-end;margin-top:16px;gap:10px}
.lbl{font-size:8px;letter-spacing:.5px;font-weight:700;color:#6B4A33}
.val{font-size:11.5px;font-weight:700;color:#B34700;margin-bottom:7px}
.amt{display:inline-block;border:1.5px solid #B9862A;border-radius:50px;background:#fff;padding:6px 18px;font-size:14px;font-weight:700;color:#B34700}
.amtpill{display:inline-block;background:#1B2A6B;color:#FFF3DC;font-size:9.5px;padding:2px 12px;border-radius:50px}
.seal{width:92px;height:92px;border-radius:50%;border:1.5px solid #1B2A6B;background:#F3F6FF;color:#1B2A6B;
  font-size:6px;text-align:center;display:flex;flex-direction:column;align-items:center;justify-content:center;line-height:1.35}
.words{text-align:center;font-size:10px;color:#6B4A33;margin-top:8px}
.foot{border-top:1px solid rgba(185,134,42,.4);margin-top:10px;padding-top:7px;font-size:8px;color:#9A7A5F;text-align:center;line-height:1.6}
</style></head><body>
<div class="frame"><div class="inner">
  <div class="top">
    <div class="chip">CIN : ${foundation.cin}</div>
    <img class="logo" src="${foundation.logoDataUri}" alt="">
    <div class="chip">PAN : ${foundation.pan}</div>
  </div>
  <div class="mid">
    <div class="pill">${title}</div>
    <div class="en">${titleEn}</div>
  </div>
  <div class="body">${body}</div>
  <div class="note">${note}</div>
  <div class="bottom">
    <div>
      <div class="lbl">CERTIFICATE NUMBER</div><div class="val">${d.receipt_no}</div>
      <div class="lbl">DATE</div><div class="val">${hiDate(d.paid_at ?? d.created_at)}</div>
      <div class="lbl">माध्यम</div><div class="val" style="font-size:10.5px">${d.method} · ${d.category}</div>
    </div>
    <div style="text-align:center">
      <div class="amtpill">सहयोग राशि</div><br>
      <div class="amt">${inr(d.amount)}</div>
    </div>
    <div class="seal">
      <div style="font-size:13px">ॐ</div>
      <div><b>बाबा सिद्धनाथ मंदिर</b></div>
      <div>जीर्णोद्धार सेवा फाउंडेशन</div>
      <div style="width:60%;border-top:1px solid #1B2A6B;margin:2px 0"></div>
      <div>CIN: ${foundation.cin}</div>
      <div><b>Auth. Signatory</b></div>
    </div>
  </div>
  <div class="words">${amountWords(d.amount)}</div>
  <div class="foot">
    बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन · श्री बजरंगबली धर्मशाला, तेलहाड़ा का अंग<br>
    Section 8 कंपनी · पंजीयन 25 जून 2026 · तेलहारा (नालंदा), बिहार
  </div>
</div></div>
</body></html>`;
}

/** 80G रजिस्टर का HTML (A4 landscape) */
export function registerHtml(rows, { from, to, foundation, total }) {
  const body = rows
    .map((r, i) => `<tr>
      <td>${i + 1}</td><td>${r.receipt_no ?? '-'}</td><td>${hiDate(r.paid_at ?? r.created_at)}</td>
      <td>${r.name}</td><td>${r.phone ?? '-'}</td><td>${r.category}</td>
      <td class="num">${inr(r.amount)}</td><td>${r.method}</td><td>${r.razorpay_payment_id ?? r.utr ?? '-'}</td>
    </tr>`)
    .join('');

  return `<!doctype html><html lang="hi"><head><style>
body{margin:0;padding:4mm;color:#3A2416}
h1{font-size:16px;margin:0 0 2px;color:#B34700}
.sub{font-size:10px;color:#6B4A33;margin-bottom:8px}
table{width:100%;border-collapse:collapse;font-size:9px}
th{background:#B34700;color:#FFF6E4;padding:5px 4px;text-align:left;font-size:8.5px}
td{padding:4px;border-bottom:1px solid #EADFCB}
tr:nth-child(even) td{background:#FFF7EA}
.num{text-align:right;white-space:nowrap}
tfoot td{font-weight:700;background:#FCEBD2;border-top:2px solid #B9862A}
.foot{margin-top:8px;font-size:8px;color:#9A7A5F;text-align:center}
</style></head><body>
<h1>${foundation.name} — 80G दान रजिस्टर</h1>
<div class="sub">अवधि: ${from} से ${to} · दिनांक: ${hiDate(new Date())} · प्रविष्टियाँ: ${rows.length}</div>
<table>
  <thead><tr>
    <th>क्र.</th><th>रसीद संख्या</th><th>दिनांक</th><th>दाता</th><th>मोबाइल</th>
    <th>श्रेणी</th><th>राशि</th><th>माध्यम</th><th>भुगतान/UTR</th>
  </tr></thead>
  <tbody>${body || '<tr><td colspan="9">इस अवधि में कोई दान दर्ज नहीं</td></tr>'}</tbody>
  <tfoot><tr><td colspan="6">कुल</td><td class="num">${inr(total)}</td><td colspan="2"></td></tr></tfoot>
</table>
<div class="foot">CIN ${foundation.cin} · PAN ${foundation.pan} · Section 8 कंपनी · पंजीयन 25 जून 2026</div>
</body></html>`;
}

export { inr, amountWords, hiDate };
