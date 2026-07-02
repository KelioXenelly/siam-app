# SIAM (Sistem Informasi Akademik Mahasiswa) Ecosystem 🎓

Selamat datang di repositori utama **SIAM**, sebuah ekosistem aplikasi perkuliahan modern yang dirancang untuk memfasilitasi kegiatan akademik antara Mahasiswa, Dosen, dan Admin kampus.

Sistem ini mengadopsi arsitektur *Monorepo* yang membagi proyek menjadi 3 bagian utama (Backend, Mobile Frontend, dan Web Admin).

## 📂 Struktur Proyek

Repositori ini terdiri dari 3 folder utama, masing-masing dengan peran dan teknologi spesifik:

### 1. ⚙️ `/backend` (API & Database)
*   **Peran:** Jantung dari sistem SIAM. Menyediakan REST API, autentikasi, serta berinteraksi langsung dengan database.
*   **Teknologi:** Laravel 12 (PHP), MySQL, Sanctum (Token Auth).
*   **Fitur Utama:** Endpoint absensi, manajemen kelas, CRUD pengguna.

### 2. 📱 `/mobile` (Aplikasi Mahasiswa & Dosen)
*   **Peran:** Aplikasi yang diinstal di HP Mahasiswa dan Dosen untuk aktivitas perkuliahan sehari-hari.
*   **Teknologi:** Flutter (Dart).
*   **Fitur Utama:** Absensi dengan pemindai QR Code, validasi lokasi GPS (Radius Kelas), dan pemantauan ringkasan kehadiran.

### 3. 💻 `/web` (Dashboard Admin)
*   **Peran:** Panel kontrol untuk Admin kampus mengelola seluruh data akademik.
*   **Teknologi:** React Router 7, Vite, Tailwind CSS 4, dan Lucide Icons.
*   **Fitur Utama:** Manajemen Pengguna (Admin/Dosen/Mahasiswa), Pembuatan Kelas, Penugasan Dosen, dan Statistik Dashboard.

---

## 🚀 Panduan Menjalankan Sistem (Local Development)

Untuk menjalankan seluruh ekosistem SIAM secara lokal, Anda perlu menjalankan ketiga *service* di atas secara bersamaan di terminal yang berbeda.

### Tahap 1: Menjalankan Backend (Laravel)
Pastikan Anda sudah memiliki PHP dan Composer terinstal, serta database MySQL menyala.
```bash
cd backend
composer install
cp .env.example .env
php artisan key:generate
php artisan migrate --seed  # Membuat tabel dan mengisi data dummy
php artisan serve --host=0.0.0.0 --port=8000
```
> **Catatan:** Backend akan berjalan di `http://localhost:8000`.

### Tahap 2: Menjalankan Web Admin (React)
Buka tab terminal baru. Pastikan Node.js sudah terinstal.
```bash
cd web
npm install
npm run dev
```
> **Catatan:** Web Admin biasanya berjalan di `http://localhost:5173`.

### Tahap 3: Menjalankan Mobile App (Flutter)
Buka tab terminal baru. Pastikan Flutter SDK terinstal dan Emulator (Android/iOS) sudah menyala.
```bash
cd mobile
flutter pub get
```
*Pastikan Anda membuat file `.env` di dalam folder `mobile` berisi `API_URL=http://10.0.2.2:8000/api` (jika menggunakan Android Emulator).*
```bash
flutter run
```

---

## 🔒 Catatan Keamanan
Jangan pernah melakukan *commit* pada file `.env` yang berisi kredensial asli ke repositori publik ini. Selalu gunakan `.env.example` sebagai referensi struktur konfigurasi.
