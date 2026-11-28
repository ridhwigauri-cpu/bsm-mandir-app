import { getPool } from '../db.js';

const pool = getPool();

const rooms = [
  ['R1', 'कमरा 1', 2], ['R2', 'कमरा 2', 2], ['R3', 'कमरा 3', 3],
  ['R4', 'कमरा 4', 2], ['R5', 'कमरा 5', 4], ['R6', 'कमरा 6', 2],
];
for (const [id, name, cap] of rooms) {
  await pool.query(
    'INSERT INTO rooms (id, name, capacity) VALUES ($1,$2,$3) ON CONFLICT (id) DO NOTHING',
    [id, name, cap],
  );
}

const projects = [
  ['मंदिर जीर्णोद्धार कार्य', 980000, 1580000, 'चालू'],
  ['धर्मशाला मरम्मत', 210000, 600000, 'चालू'],
  ['अन्नदान सेवा', 120000, 250000, 'चालू'],
];
for (const p of projects) {
  await pool.query('INSERT INTO projects (name, spent, target, status) VALUES ($1,$2,$3,$4)', p);
}

const staff = [
  ['पुजारी', 5], ['सुरक्षा', 4], ['प्रबंधन', 3], ['सफ़ाई व अन्य', 6],
];
for (const [dept, count] of staff) {
  for (let i = 1; i <= count; i++) {
    await pool.query('INSERT INTO staff (name, dept, salary) VALUES ($1,$2,$3)', [`${dept} कर्मी ${i}`, dept, 12000]);
  }
}

const lekha = [
  ['जुलाई 2026', 420000, 280000, 'ऑडिट पूर्ण'],
  ['अगस्त 2026', 380000, 310000, 'ऑडिट पूर्ण'],
  ['सितंबर 2026', 510000, 260000, 'ऑडिट पूर्ण'],
  ['अक्टूबर 2026', 620000, 320000, 'ऑडिट पूर्ण'],
  ['नवंबर 2026', 220000, 140000, 'प्रगति में'],
];
for (const l of lekha) {
  await pool.query('INSERT INTO lekha (month, income, expense, status) VALUES ($1,$2,$3,$4)', l);
}

await pool.end();
console.log('✅ प्रारंभिक डेटा डाल दिया (कमरे, परियोजनाएँ, स्टाफ, लेखा)');
