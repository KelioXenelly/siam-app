# SIAM Admin Dashboard 💻

Bagian ini adalah **Sistem Manajemen (Web Admin)** dari ekosistem SIAM. 
Dashboard ini digunakan oleh pihak kampus (Admin) untuk mengelola data master akademik, mulai dari pengguna (mahasiswa & dosen), mata kuliah, jadwal kelas, hingga memantau statistik aktivitas sistem.

## 🛠️ Teknologi yang Digunakan
Aplikasi web ini dibangun menggunakan teknologi *frontend* modern:
- **Framework:** React Router 7 (berjalan di atas Vite)
- **Styling:** Tailwind CSS v4
- **Data Fetching:** SWR & Axios
- **Iconography:** Lucide React
- **Komponen UI:** Motion (Framer Motion) untuk animasi mulus.

## 🚀 Panduan Memulai (Development)

1. **Instalasi Dependensi**
   Pastikan Anda sudah menginstal Node.js versi terbaru. Buka terminal di folder `web` dan jalankan:
   ```bash
   npm install
   ```

2. **Konfigurasi Environment**
   Salin file `.env.example` menjadi `.env`.
   ```bash
   cp .env.example .env
   ```
   Pastikan `VITE_API_URL` mengarah ke backend Laravel lokal Anda (secara bawaan: `http://localhost:8000/api`).

3. **Menjalankan Server Pengembangan**
   Jalankan perintah berikut untuk menyalakan Vite *development server*:
   ```bash
   npm run dev
   ```
   Aplikasi dapat diakses melalui browser di `http://localhost:5173`.

## 📦 Build untuk Produksi
Jika Anda ingin men-*deploy* aplikasi ini ke server produksi (misal: Vercel, VPS, atau Netlify), jalankan perintah:
```bash
npm run build
```
Hasil *build* statis akan berada di dalam folder `build/client/`.
