# ARN Inventory • Supabase setup

Project: **ARN Store Part Stock**

## 1. Public browser key
Project URL yang digunakan build ini:

`https://bflyuzgxhqdovrahycgg.supabase.co`

Build ini sudah dikonfigurasi menggunakan **public `anon` key** dari project tersebut karena project menyediakan legacy public key. Key ini aman untuk aplikasi browser selama RLS/policies tetap aktif.

**Jangan pernah** memasukkan `service_role` atau secret key ke PWA.

## 2. Apply the SQL
Untuk PWA free build ini, jangan menjalankan ulang schema hanya untuk menerbitkan kode GitHub. PWA tetap memakai proyek Supabase yang sudah dikonfigurasi. Backup database sebelum perubahan backend apa pun. File schema di repositori adalah bahan migrasi, bukan langkah deploy GitHub Pages.

## 3. Owner Admin
PWA ini tidak menggunakan status lisensi sebagai syarat akses inventaris. Role backend yang mungkin masih ada di proyek lama tidak perlu diubah hanya untuk menerbitkan PWA. Jangan menjalankan `ADMIN_SETUP.sql` untuk membuat akses pengguna biasa.


### Email verification redirect
Aplikasi mengirim `emailRedirectTo` ke URL PWA yang sedang dibuka, sehingga tautan verifikasi tidak berhenti di halaman project Supabase. Pada Supabase Dashboard, buka **Authentication → URL Configuration** dan tambahkan URL produksi PWA ke **Redirect URLs**. Untuk deployment GitHub Pages ARN Inventory, gunakan URL halaman PWA yang sebenarnya, misalnya `https://<username>.github.io/<repo>/`. Site URL juga sebaiknya diarahkan ke URL produksi PWA. Supabase mewajibkan URL redirect yang digunakan aplikasi masuk ke allow-list.

### Email verification redirect
Aplikasi mengirim `emailRedirectTo` ke URL PWA yang sedang dibuka, sehingga tautan verifikasi tidak berhenti di halaman project Supabase. Pada Supabase Dashboard, buka **Authentication → URL Configuration** dan tambahkan URL produksi PWA ke **Redirect URLs**. Untuk deployment GitHub Pages ARN Inventory, gunakan URL halaman PWA yang sebenarnya, misalnya `https://<username>.github.io/<repo>/`. Site URL juga sebaiknya diarahkan ke URL produksi PWA. Supabase mewajibkan URL redirect yang digunakan aplikasi masuk ke allow-list.

## Revisi 1002 • backend additions

Untuk build Revisi 1002, jalankan `supabase-schema.sql` terbaru di SQL Editor project **ARN Store Part Stock**. Revisi ini mempertahankan Auth/license/admin sebelumnya dan menambahkan/menegaskan:

- master reference tables `arn_master_parts` dan `arn_master_compatibilities`
- reconciliation-friendly stock transaction flow
- server-side guard agar hasil stok tidak menjadi negatif, termasuk konkurensi antar-device
- admin license disable/renew tetap aktif
- kolom movement time/job reference yang sudah ada di schema tetap dipertahankan agar data lama tidak hilang saat sync

Jangan memasukkan service-role key ke PWA. Gunakan publishable/anon key pada `supabase-config.js`.

## Free-access build
- Login Supabase tetap digunakan.
- Akses inventaris tidak mensyaratkan kode lisensi, demo, atau masa kedaluwarsa.
- Satu akun dapat login pada beberapa perangkat; sinkronisasi menggunakan akun Supabase yang sama.
- Tabel/fungsi lisensi lama tidak dihapus dari database. Jangan menjalankan migrasi backend tanpa backup dan pemeriksaan terlebih dahulu.
