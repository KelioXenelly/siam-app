<?php

namespace App\Services;

use App\Models\SesiAbsensi;
use App\Models\Absensi;
use Illuminate\Support\Facades\DB;

class AbsensiService
{
    /**
     * Close an attendance session and generate 'alfa' records for missing students.
     *
     * @param int $sesiId
     * @return SesiAbsensi
     */
    public function closeSession($sesiId)
    {
        return DB::transaction(function () use ($sesiId) {
            $sesi = SesiAbsensi::with('pertemuan.kelas.mahasiswas')->findOrFail($sesiId);

            // Skip if already closed
            if ($sesi->is_closed) {
                return $sesi;
            }

            $kelas = $sesi->pertemuan->kelas;
            $mahasiswaIdsInKelas = $kelas->mahasiswas->pluck('id');

            // Find students who have already recorded attendance for this session
            $alreadyAbsenIds = Absensi::where('sesi_absensi_id', $sesi->id)
                ->pluck('mahasiswa_id')
                ->toArray();

            // Identify students who are missing (haven't scanned)
            $missingMahasiswaIds = $mahasiswaIdsInKelas->diff($alreadyAbsenIds);

            // Generate 'alfa' records for missing students
            $records = collect($missingMahasiswaIds)->map(function ($mhsId) use ($sesi) {
                return [
                    'sesi_absensi_id' => $sesi->id,
                    'mahasiswa_id' => $mhsId,
                    'latitude_mahasiswa' => 0,
                    'longitude_mahasiswa' => 0,
                    'selfie_photo' => '-',
                    'status' => 'alfa',
                    'waktu_absen' => now(),
                    'created_at' => now(),
                    'updated_at' => now(),
                ];
            })->toArray();

            if (!empty($records)) {
                Absensi::insert($records);
            }

            // Mark session as closed
            $sesi->update([
                'is_closed' => true,
            ]);

            return $sesi;
        });
    }
}
