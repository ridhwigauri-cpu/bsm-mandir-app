import ExcelJS from 'exceljs';
import { foundation } from './foundation.js';
import { inr, hiDate } from './receiptPdf.js';

/** 80G दान रजिस्टर — Excel (.xlsx) */
export async function donationsXlsx(rows, { from, to }) {
  const wb = new ExcelJS.Workbook();
  wb.creator = foundation.legalName;
  const ws = wb.addWorksheet('80G Register', {
    views: [{ state: 'frozen', ySplit: 5 }],
    pageSetup: { paperSize: 9, orientation: 'landscape', fitToPage: true },
  });

  ws.mergeCells('A1:I1');
  ws.getCell('A1').value = `${foundation.name} — 80G दान रजिस्टर`;
  ws.getCell('A1').font = { bold: true, size: 14, color: { argb: 'FFB34700' } };
  ws.getCell('A1').alignment = { horizontal: 'center' };

  ws.mergeCells('A2:I2');
  ws.getCell('A2').value = `अवधि: ${from} से ${to}   ·   CIN: ${foundation.cin}   ·   PAN: ${foundation.pan}   ·   Section 8: ${foundation.section8}`;
  ws.getCell('A2').font = { size: 9, color: { argb: 'FF6B4A33' } };
  ws.getCell('A2').alignment = { horizontal: 'center' };

  const headers = ['क्र.', 'रसीद संख्या', 'दिनांक', 'दाता', 'मोबाइल', 'श्रेणी', 'राशि (₹)', 'माध्यम', 'भुगतान/UTR'];
  const headerRow = ws.addRow([]);
  ws.addRow(headers);
  headerRow.height = 6;

  const hRow = ws.getRow(4);
  hRow.font = { bold: true, color: { argb: 'FFFFF6E4' }, size: 10 };
  hRow.alignment = { vertical: 'middle', horizontal: 'left' };
  hRow.eachCell((cell) => {
    cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFB34700' } };
    cell.border = { bottom: { style: 'thin', color: { argb: 'FFB9862A' } } };
  });

  let total = 0;
  rows.forEach((r, i) => {
    total += Number(r.amount);
    const row = ws.addRow([
      i + 1,
      r.receipt_no ?? '-',
      hiDate(r.paid_at ?? r.created_at),
      r.name,
      r.phone ?? '-',
      r.category,
      Number(r.amount),
      r.method,
      r.razorpay_payment_id ?? r.utr ?? '-',
    ]);
    row.getCell(7).numFmt = '#,##0';
    row.alignment = { vertical: 'middle' };
    if (i % 2 === 1) {
      row.eachCell((c) => {
        c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFFF7EA' } };
      });
    }
  });

  const totalRow = ws.addRow(['', '', '', '', '', 'कुल', total, '', '']);
  totalRow.font = { bold: true, size: 11 };
  totalRow.getCell(7).numFmt = '#,##0';
  totalRow.eachCell((c) => {
    c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFFCEBD2' } };
    c.border = { top: { style: 'medium', color: { argb: 'FFB9862A' } } };
  });

  ws.columns = [
    { width: 6 }, { width: 20 }, { width: 16 }, { width: 26 }, { width: 14 },
    { width: 16 }, { width: 14 }, { width: 14 }, { width: 26 },
  ];
  ws.autoFilter = { from: 'A4', to: 'I4' };

  return Buffer.from(await wb.xlsx.writeBuffer());
}

/** लेखा (माह-वार) — Excel */
export async function lekhaXlsx(rows) {
  const wb = new ExcelJS.Workbook();
  const ws = wb.addWorksheet('लेखा');
  ws.addRow([`${foundation.name} — माह-वार लेखा`]).font = { bold: true, size: 13, color: { argb: 'FFB34700' } };
  ws.addRow([]);
  const h = ws.addRow(['माह', 'दान/आय (₹)', 'खर्च (₹)', 'शेष (₹)', 'स्थिति']);
  h.font = { bold: true, color: { argb: 'FFFFF6E4' } };
  h.eachCell((c) => { c.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FFB34700' } }; });
  rows.forEach((r) => {
    const row = ws.addRow([r.month, Number(r.income), Number(r.expense), Number(r.income) - Number(r.expense), r.status]);
    row.getCell(2).numFmt = '#,##0';
    row.getCell(3).numFmt = '#,##0';
    row.getCell(4).numFmt = '#,##0';
  });
  ws.columns = [{ width: 18 }, { width: 16 }, { width: 14 }, { width: 14 }, { width: 18 }];
  return Buffer.from(await wb.xlsx.writeBuffer());
}

export { inr };
