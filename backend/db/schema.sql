-- बाबा सिद्धनाथ मंदिर जीर्णोद्धार सेवा फाउंडेशन — डेटाबेस स्कीमा (PostgreSQL)

CREATE TABLE IF NOT EXISTS donations (
  id                SERIAL PRIMARY KEY,
  name              TEXT        NOT NULL,
  phone             TEXT,
  category          TEXT        NOT NULL,
  amount            INTEGER     NOT NULL CHECK (amount > 0),
  method            TEXT        NOT NULL,              -- RAZORPAY | UPI_QR | BANK | CASH
  status            TEXT        NOT NULL DEFAULT 'pending', -- pending | paid | pending_verification | failed
  receipt_no        TEXT        UNIQUE,
  razorpay_order_id TEXT,
  razorpay_payment_id TEXT      UNIQUE,                -- idempotency
  utr               TEXT,
  receipt_token     TEXT,        -- रसीद का सार्वजनिक लिंक (बिना लॉगिन डाउनलोड)
  announced         BOOLEAN     NOT NULL DEFAULT FALSE,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
  paid_at           TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_donations_status ON donations(status);
CREATE INDEX IF NOT EXISTS idx_donations_created ON donations(created_at DESC);

-- रसीद नंबर के लिए वित्त-वर्ष काउंटर (80G/2026-27/1001)
CREATE TABLE IF NOT EXISTS counters (
  fy   TEXT PRIMARY KEY,
  last INTEGER NOT NULL DEFAULT 1000
);

-- पूजा / VIP पास (सीट नंबर + UNIQUE से capacity सुरक्षित)
CREATE TABLE IF NOT EXISTS puja_passes (
  id         SERIAL PRIMARY KEY,
  pass_id    TEXT        NOT NULL UNIQUE,
  name       TEXT        NOT NULL,
  phone      TEXT,
  date       DATE        NOT NULL,
  slot       TEXT        NOT NULL,
  type       TEXT        NOT NULL,
  seat       INTEGER     NOT NULL,
  used       BOOLEAN     NOT NULL DEFAULT FALSE,
  used_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (date, slot, seat)
);

CREATE TABLE IF NOT EXISTS rooms (
  id          TEXT PRIMARY KEY,
  name        TEXT    NOT NULL,
  capacity    INTEGER NOT NULL DEFAULT 2,
  occupied_by TEXT,
  occupied_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS room_bookings (
  id            SERIAL PRIMARY KEY,
  pass_id       TEXT        NOT NULL UNIQUE,
  room_id       TEXT        NOT NULL REFERENCES rooms(id),
  kirtan        TEXT,
  date          DATE        NOT NULL,
  name          TEXT        NOT NULL,
  phone         TEXT,
  aadhaar_last4 TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- अखंड कीर्तन स्लॉट की सीटें (capacity 4)
CREATE TABLE IF NOT EXISTS kirtan_seats (
  id         SERIAL PRIMARY KEY,
  slot       TEXT NOT NULL,
  date       DATE NOT NULL,
  seat       INTEGER NOT NULL,
  booking_id INTEGER,
  UNIQUE (slot, date, seat)
);

-- दान की घोषणा — मंदिर के PA सिस्टम के लिए कतार
CREATE TABLE IF NOT EXISTS announcements (
  id         SERIAL PRIMARY KEY,
  name       TEXT        NOT NULL,
  amount     INTEGER,
  text       TEXT        NOT NULL,
  status     TEXT        NOT NULL DEFAULT 'queued', -- queued | playing | played
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  played_at  TIMESTAMPTZ
);
CREATE INDEX IF NOT EXISTS idx_ann_status ON announcements(status);

-- AI सुरक्षा अलर्ट (YOLOv8 सर्विस से)
CREATE TABLE IF NOT EXISTS alerts (
  id         SERIAL PRIMARY KEY,
  cam        TEXT        NOT NULL,
  label      TEXT        NOT NULL,
  confidence INTEGER,
  photo_url  TEXT,
  clip_url   TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- परियोजनाएँ / स्टाफ / लेखा (डैशबोर्ड)
CREATE TABLE IF NOT EXISTS projects (
  id      SERIAL PRIMARY KEY,
  name    TEXT    NOT NULL,
  spent   INTEGER NOT NULL DEFAULT 0,
  target  INTEGER NOT NULL DEFAULT 0,
  status  TEXT    NOT NULL DEFAULT 'चालू'
);

CREATE TABLE IF NOT EXISTS staff (
  id       SERIAL PRIMARY KEY,
  name     TEXT    NOT NULL,
  dept     TEXT    NOT NULL,
  salary   INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS lekha (
  id      SERIAL PRIMARY KEY,
  month   TEXT    NOT NULL,
  income  INTEGER NOT NULL DEFAULT 0,
  expense INTEGER NOT NULL DEFAULT 0,
  status  TEXT    NOT NULL DEFAULT 'प्रगति में'
);

-- रोज़ का सारांश (nightly function भरता है — कार्यालय सुबह देखता है)
CREATE TABLE IF NOT EXISTS daily_reports (
  report_date              DATE PRIMARY KEY,
  paid_count               INTEGER NOT NULL DEFAULT 0,
  paid_total               INTEGER NOT NULL DEFAULT 0,
  big_donations            INTEGER NOT NULL DEFAULT 0,
  max_donation             INTEGER NOT NULL DEFAULT 0,
  pending_verification_7d  INTEGER NOT NULL DEFAULT 0,
  notes                    TEXT,
  created_at               TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ऑडिट लॉग (कौन क्या बदला)
CREATE TABLE IF NOT EXISTS audit_log (
  id         SERIAL PRIMARY KEY,
  actor      TEXT,
  action     TEXT NOT NULL,
  payload    TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
