<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Absensi extends Model
{

    protected $table = 'absensis';
    
    protected $fillable = [
        'sesi_absensi_id',
        'mahasiswa_id',
        'latitude_mahasiswa',
        'longitude_mahasiswa',
        'selfie_photo',
        'status',
        'waktu_absen',
    ];

    public function sesiAbsensi() {
        return $this->belongsTo(SesiAbsensi::class);
    }

    public function mahasiswa() {
        return $this->belongsTo(Mahasiswa::class);
    }   
}
