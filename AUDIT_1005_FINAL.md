# ARN Inventory • Revisi 1005 • Final Repair Audit

## Perubahan dari 1004
- Compatibility candidate matching diperketat: tidak lagi menggunakan substring/partial token yang dapat menghasilkan false positive.
- Matching tetap case-insensitive dan mendukung variasi penulisan dengan prefix brand yang memang ada di master, misalnya `Vivo Y20i` ↔ `Y20i`.
- Stock-out tetap meminta verifikasi model HP dan, bila terdapat lebih dari satu kandidat, pengguna wajib memilih Part fisik.
- Cache service worker dinaikkan ke 1005 untuk membuang cache revisi sebelumnya.

## Data master terverifikasi
- LCD: 63 grup
- LCD models: 488
- Battery: 209 kode
- Tempered Glass: 18 grup
- Inventory items: 34
- Opening stock: 16 movement rows
- Opening stock quantity positif: 121 pcs
- Opening stock date: 2026-09-14

## Database safeguards retained
- RLS transaksi membatasi account_id dan part_id ke akun yang sama.
- Existing account tidak mendapatkan demo baru ketika license disabled/expired.
- Admin role berasal dari profile Supabase, bukan dari registrasi biasa.
- Password reset, Google OAuth, dan email verification memakai redirect ke PWA.

## Verification
- `node --check app.js`: PASS
- JSON parse/master counts: PASS
- ZIP integrity: PASS
- Browser E2E deployment test: not claimed as PASS because no production deployment/browser session was available in this build environment.
