<?php

use App\Http\Controllers\Api\AbsensiController;
use App\Http\Controllers\Api\ActivityLogController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\DosenController;
use App\Http\Controllers\Api\KelasController;
use App\Http\Controllers\Api\MahasiswaController;
use App\Http\Controllers\Api\MataKuliahController;
use App\Http\Controllers\Api\PertemuanController;
use App\Http\Controllers\Api\ProdiController;
use App\Http\Controllers\Api\RuanganController;
use App\Http\Controllers\Api\SesiAbsensiController;
use Illuminate\Support\Facades\Route;

Route::post('/login', [AuthController::class, 'login']); // Done

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']); // Done
    Route::get('/me', [AuthController::class, 'me']); // Done
    Route::post('/change-password', [AuthController::class, 'changePassword']); // Done
    Route::post('/update-avatar', [AuthController::class, 'updateAvatar']); // Done
});

Route::middleware(['auth:sanctum', 'role:dosen'])->group(function () {
    Route::post('/generate-qr', [SesiAbsensiController::class, 'generateQR']); // Done
    Route::post('/sesi/{sesi_id}/close', [SesiAbsensiController::class, 'closeSesi']); // Done
    Route::get('/sesi/{sesi_id}', [SesiAbsensiController::class, 'show']); // Done
    Route::get('/sesi/{sesi_id}/absensi', [AbsensiController::class, 'bySesi']); // Done
    Route::get('/pertemuan/{pertemuan_id}/sesi', [SesiAbsensiController::class, 'byPertemuan']); // Done
    Route::get('/pertemuan/{pertemuan_id}/sesi-aktif', [SesiAbsensiController::class, 'aktif']); // Done
    Route::get('/dosen/kelas-saya', [KelasController::class, 'kelasDosen']); // Done
    Route::get('/kelas/{kelas_id}/pertemuan', [PertemuanController::class, 'byKelas']); // Done
    Route::post('/pertemuan/{pertemuan_id}/start', [PertemuanController::class, 'start']); // Done
    Route::post('/pertemuan/{pertemuan_id}/end', [PertemuanController::class, 'end']); // Done
    Route::get('/kelas/{kelas_id}/mahasiswa', [KelasController::class, 'listMahasiswa']); // Done
    Route::put('/absensi/{absensi_id}/manual', [AbsensiController::class, 'updateStatusManual']); // Done
});

Route::middleware(['auth:sanctum', 'role:mahasiswa'])->group(function () {
    Route::post('/absensi/scan', [AbsensiController::class, 'scan']); // Done
    Route::get('/absensi/riwayat', [AbsensiController::class, 'riwayat']); // Done
    Route::get('/mahasiswa/kelas-saya', [KelasController::class, 'kelasMahasiswa']); // Done
});

Route::middleware(['auth:sanctum', 'role:admin'])->group(function () {
    Route::post('/register', [AuthController::class, 'register']); // Done

    Route::get('/users', [AuthController::class, 'users']); // Done
    Route::put('/users/{user_id}', [AuthController::class, 'updateUser']); // Done
    Route::post('/users/{user_id}/avatar', [AuthController::class, 'updateUserAvatar']); // Done
    Route::delete('/users/{user_id}', [AuthController::class, 'deleteUser']); // Done

    Route::apiResource('/program-studi', ProdiController::class); // Done

    Route::apiResource('/ruangan', RuanganController::class); // Done

    Route::apiResource('/mata-kuliah', MataKuliahController::class); // Done

    Route::get('/mahasiswa', [MahasiswaController::class, 'index']); // Done
    Route::get('/mahasiswa/{id}', [MahasiswaController::class, 'show']); // Done

    Route::get('/dosen', [DosenController::class, 'index']); // Done
    Route::get('/dosen/{id}', [DosenController::class, 'show']); // Done

    Route::apiResource('/kelas', KelasController::class); // Done
    Route::post('/kelas/{kelas_id}/assign-mahasiswa', [KelasController::class, 'assignMahasiswa']); // Done

    Route::apiResource('/pertemuan', PertemuanController::class); // Done

    Route::get('/dashboard-stats', [AuthController::class, 'dashboardStats']); // Done

    Route::get('/activity-logs', [ActivityLogController::class, 'index']); // Done
});
