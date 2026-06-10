<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use App\Traits\HasCloudinaryImage;

class Absensi extends Model
{
    use HasCloudinaryImage;

    public $cloudinaryField = 'selfie_photo';

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
