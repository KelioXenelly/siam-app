# SIAM API Backend ⚙️

Ini adalah *core system* atau **Backend API** untuk seluruh ekosistem Sistem Informasi Akademik Mahasiswa (SIAM). 
Backend ini bertugas melayani permintaan data (REST API) dari aplikasi Mobile (Flutter) dan Dashboard Web Admin (React).

## 🛠️ Teknologi yang Digunakan
- **Framework:** Laravel 12 (PHP ^8.2)
- **Database:** MySQL / SQLite
- **Autentikasi:** Laravel Sanctum (Token-based Auth)
- **QR Code:** Simple Qrcode (simplesoftwareio)

## 🚀 Panduan Memulai (Development)

Ikuti langkah-langkah berikut untuk menjalankan server API di komputer lokal Anda:

### 1. Instalasi Dependensi
Pastikan Composer dan PHP sudah terinstal. Masuk ke folder `backend` dan jalankan:
```bash
composer install
```

### 2. Konfigurasi Environment
Buat file konfigurasi rahasia Anda berdasarkan file contoh yang disediakan:
```bash
cp .env.example .env
```
Generate Application Key Laravel:
```bash
php artisan key:generate
```
*(Jangan lupa sesuaikan kredensial database `DB_CONNECTION`, `DB_HOST`, `DB_DATABASE` di dalam file `.env` dengan server MySQL lokal Anda).*

### 3. Migrasi Database & Seeder
Buat struktur tabel ke dalam database Anda beserta data *dummy* awal (jika tersedia):
```bash
php artisan migrate --seed
```

### 4. Menjalankan Server
Nyalakan server *development* Laravel. Kami menyarankan untuk menjalankannya di `0.0.0.0` agar bisa diakses oleh Android Emulator:
```bash
php artisan serve --host=0.0.0.0 --port=8000
```
API sekarang dapat diakses di `http://localhost:8000/api`.

---
**Catatan:** Pastikan server ini selalu menyala ketika Anda sedang menguji coba aplikasi Mobile maupun Web Admin secara lokal.
