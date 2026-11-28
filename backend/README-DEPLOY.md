# GitHub se Neon par deploy (backend ka alag repo)

Ek baar set kar lein, uske baad **har push par deploy apne aap** ho jayega — laptop par terminal chalane ki zaroorat nahi.

```
GitHub (bsm-backend repo)  ──push──►  GitHub Actions
                                        │ npm ci → build → 33 tests
                                        ▼
                                  neon deploy
                                        │
                                        ▼
                        Neon Functions (production branch)
                        api · razorpay · nightly (+ nightly trigger)
```

---

## 1. Naya repo banayein

1. GitHub → **New repository** → naam **`bsm-backend`** → **Private** (Razorpay ki logic hai, private behtar)
2. `README`/`.gitignore`/license — kuch bhi add na karein (repo khaali rakhein)
3. Is zip ka **poora content** upload karein: **Add file → Upload files** → saare folders/files drag karein (`.github`, `src`, `functions`, `db`, `assets`, `scripts`, `test`, `tools`, `neon.ts`, `package.json`, `package-lock.json`, `README.md`, `CHANGELOG` etc.)
4. **Commit changes**

> `.github/workflows/deploy-functions.yaml` bhi isi upload me chala jayega — usi se deploy hoga.

## 2. Neon ko repo se jodein

Neon Console → project `bsm-mandir` → **Integrations → GitHub → Add** → **Install GitHub App** → repo **`bsm-backend`** select → **Connect**.

Ye khud aapke repo me bana deta hai:
- secret **`NEON_API_KEY`**
- variable **`NEON_PROJECT_ID`**

**Agar integration na dikhe (manual raasta):**
- Neon Console → Account settings → **API keys** → create → copy
- GitHub repo → Settings → Secrets and variables → Actions → **New repository secret** → naam `NEON_API_KEY`
- Usi page par **Variables** tab → **New repository variable** → naam `NEON_PROJECT_ID`, value `soft-fire-58337300`

## 3. Function secrets daalein

GitHub repo → **Settings → Secrets and variables → Actions → Secrets** → ye add karein:

| Secret | Kya hai |
|---|---|
| `JWT_SECRET` | `openssl rand -hex 32` |
| `ADMIN_PIN` | `1088` (ya apna) |
| `SERVICE_KEY` | `openssl rand -hex 24` — AI सुरक्षा + PA डिवाइस |
| `RAZORPAY_KEY_ID` | rzp_live_… |
| `RAZORPAY_KEY_SECRET` | Razorpay Dashboard se |
| `RAZORPAY_WEBHOOK_SECRET` | apni lambi key (wahi webhook me daalenge) |
| `FIREBASE_SERVICE_ACCOUNT` | (optional) service-account JSON ek line me |

Optional **Variables** tab me: `AARTI_TIMES` = `06:30,12:00,19:00`

> `neon.ts` me `JWT_SECRET`, `SERVICE_KEY`, `RAZORPAY_WEBHOOK_SECRET` **required** hain — inme se koi missing hua to deploy **kuch badalne se pehle** fail ho jayega (safe).

## 4. Pehla deploy

`main` par koi bhi commit (ya Actions → **Deploy to Neon Functions** → **Run workflow**).

Actions → run kholein → **Summary** me aapko teen URLs milenge:

```
- api      -> https://br-xxxx-api.compute.c-2.us-east-2.aws.neon.tech
- razorpay -> https://br-xxxx-razorpay.compute...
- nightly  -> https://br-xxxx-nightly.compute...
```

## 5. Ek baar schema lagayein (sirf pehli baar)

Functions migration nahi chalate. Apne laptop se **ek command**:

```bash
psql "<Neon ka DATABASE_URL_UNPOOLED>" -f db/schema.sql
```

(`DATABASE_URL_UNPOOLED` Neon Console → **Connect** → *Unpooled* tab me milta hai.)

Ya Neon Console → **SQL Editor** me `db/schema.sql` ka content paste karke Run.

## 6. Aage ke 2 kaam

**Razorpay** → Settings → Webhooks → Add:
- URL: `https://br-xxxx-razorpay.compute.../`
- Event: `payment.captured` (+ `order.paid`)
- Secret: wahi jo `RAZORPAY_WEBHOOK_SECRET` me hai

**Flutter app** → `lib/config/app_config.dart`:
```dart
static const String apiBaseUrl  = 'https://br-xxxx-api.compute...';
static const String paSystemUrl = 'https://br-xxxx-api.compute...';
```
→ push → CI naya APK bana dega.

---

## Roz ka kaam

```bash
git add . && git commit -m "..." && git push
```
Bas. Actions khud test chalakar deploy kar dega. URLs Summary me har baar milenge.

## Gड़बड़ी ho to

| लक्षण | कारण | हल |
|---|---|---|
| `Not signed in` / `401` | `NEON_API_KEY` galat/expired | naya API key banakar secret update karein |
| `project not found` | `NEON_PROJECT_ID` galat | variable me `soft-fire-58337300` |
| `functions are not available in this region` | project ka region support me nahi | Singapore / Ohio / N.Virginia / Frankfurt me project banayein |
| `required environment variable ... missing` | secret add nahi hua | step 3 dobara dekhein |
| `protected branch` error | branch protected hai | workflow me `--allow-protected` pehle se hai — phir bhi aaye to Neon Console me branch protection hatayein |
| deploy pass, par app se connect nahi | `apiBaseUrl` galat/purana | Summary wala naya `api` URL daalein |
| `nightly` nahi chala | trigger deploy nahi hua | `neon triggers list` dekhein; `neon deploy` dobara chalayein |

## Dhyan rakhein

- **Secrets sirf GitHub me** — `.env` kabhi commit na karein (`.gitignore` me pehle se hai)
- **Purani API key revoke** kar dein jo chat me di thi
- Neon Functions **branch-scoped** hain: `production` branch ka URL hi app me daalein, dev branch ka nahi
