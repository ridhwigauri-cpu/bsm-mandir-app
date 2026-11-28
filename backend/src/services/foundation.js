import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));

export const foundation = {
  name: 'बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन',
  legalName: 'BABA SIDHHNATH MANDIR JIRNODHAR SEVA FOUNDATION',
  cin: 'U94910BR2026NPL085916',
  pan: 'AAOCB8762B',
  tan: 'PTNB10218F',
  section8: '187252',
  address: 'तेलहारा (नालंदा), बिहार – 801306',
  upi: '6203051369m@pnb',
  accountNo: '1573002100004142',
  ifsc: 'PUNB157300',
  bank: 'पंजाब नेशनल बैंक (PNB), तेलहारा',

  /** लोगो base64 में (PDF/Excel के लिए) */
  get logoDataUri() {
    try {
      const p = path.join(here, '../../assets/images/foundation_logo.jpg');
      const b = fs.readFileSync(p).toString('base64');
      return `data:image/jpeg;base64,${b}`;
    } catch {
      return '';
    }
  },
};
