# SIAM Mobile 📱

Sistem Informasi Akademik Mahasiswa (SIAM) Mobile adalah aplikasi perkuliahan modern berbasis **Flutter** yang dirancang khusus untuk memfasilitasi kegiatan akademik antara Mahasiswa dan Dosen. 

Aplikasi ini merupakan bagian *frontend mobile* dari ekosistem SIAM yang terhubung dengan backend REST API (Laravel).

## ✨ Fitur Utama

Aplikasi ini memiliki antarmuka yang modern (mengusung gaya *Glassmorphism* dan palet warna *Royal Blue*) serta fitur-fitur pintar yang mempermudah perkuliahan:

*   **Sistem Peran Ganda (Role-Based Access):**
    *   🧑‍🎓 **Mahasiswa:** Melihat jadwal kuliah, riwayat pertemuan, tingkat kehadiran, dan melakukan absensi.
    *   👨‍🏫 **Dosen:** Membuka sesi kelas, memantau kehadiran mahasiswa, dan mengelola kelas.
*   **Absensi Pintar Berbasis Lokasi (GPS):** Memastikan mahasiswa berada di dalam radius kelas saat melakukan absensi.
*   **Pemindai QR Code:** Mahasiswa dapat melakukan absensi dengan cepat dengan memindai QR Code yang ditampilkan oleh dosen.
*   **Indikator Kehadiran Visual:** Dilengkapi dengan ring progres interaktif (*Progress Ring*) untuk melihat persentase kehadiran.

## 🛠️ Teknologi yang Digunakan

*   **Framework:** Flutter (Dart)
*   **Desain UI:** Custom Widget dengan dukungan animasi dan gradien warna.
*   **Manajemen Environment:** `flutter_dotenv` (Konfigurasi URL API dinamis)
*   **Ikon Aplikasi:** Menggunakan `flutter_launcher_icons` dengan resolusi tinggi (iOS & Android).

## 🚀 Panduan Menjalankan Aplikasi Lokal

Ikuti langkah-langkah berikut untuk menjalankan SIAM Mobile di komputer Anda:

### 1. Persyaratan Sistem
Pastikan Anda sudah menginstal:
*   [Flutter SDK](https://docs.flutter.dev/get-started/install)
*   Android Studio (untuk Android Emulator) atau Xcode (untuk iOS Simulator)

### 2. Instalasi
1. Kloning repositori ini dan masuk ke direktori `mobile`:
   ```bash
   cd siam-mobile-app/mobile
   ```
2. Unduh semua dependensi paket Flutter:
   ```bash
   flutter pub get
   ```
3. Siapkan konfigurasi API. Buat file `.env` di *root* folder `mobile` berdasarkan contoh berikut:
   ```env
   # Ganti dengan IP lokal Anda jika menguji di perangkat fisik
   # Gunakan 10.0.2.2 jika menggunakan Android Emulator yang terhubung ke localhost (Laravel 127.0.0.1:8000)
   API_URL=http://10.0.2.2:8000/api
   ```

### 3. Menjalankan Aplikasi
Jalankan aplikasi di perangkat emulator/fisik Anda:
```bash
flutter run
```

---
*Catatan: Pastikan Backend Laravel SIAM sudah berjalan di komputer lokal Anda (menggunakan `php artisan serve`) agar aplikasi dapat melakukan otentikasi login dan mengambil data.*
