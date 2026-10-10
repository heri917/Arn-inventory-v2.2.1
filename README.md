# ARN Inventory • Stok & Part

ARN Inventory adalah PWA inventory mobile-first untuk stok Part, History, dan Ringkasan.

## Revisi 1005 • Final repair build
Build ini mempertahankan seluruh fitur ARN Inventory yang sudah disepakati dan memasukkan revisi terbaru: login Supabase/self-healing account, master data preload, Part/Kategori manual, sinkronisasi lintas halaman/perangkat, loading logo final, 3D rolling box, UI yang lebih menyatu, bottom navigation yang lebih lega, dan pencegahan double-tap zoom. Build ini tidak mensyaratkan lisensi, demo, atau masa kedaluwarsa untuk menggunakan inventaris.

## Supabase wajib untuk login akun online
Project: **ARN Store Part Stock**.

Isi `supabase-config.js` dengan **Publishable key / anon public key** dari Supabase Project Settings → API. Jangan pernah memakai `service_role` key.

Jalankan `supabase-schema.sql` di SQL Editor. Jangan jalankan ulang SQL setup hanya untuk menerbitkan PWA ini. Pertahankan database dan kebijakan yang sudah ada; perubahan database hanya dilakukan jika memang diperlukan dan setelah dicadangkan.

## Master data
`master-data.json` memuat:
- 63 grup LCD / 488 model
- 209 kode Battery
- 18 grup Tempered Glass
- 13 baris opening stock

Master otomatis dimuat per akun. Part baru dan kategori baru dapat dibuat manual tanpa mengubah master reference.

## PWA
Flat root structure untuk GitHub Pages. Service worker menggunakan cache version baru 1005 dan network-first update agar aset revisi tidak tertahan cache lama.
