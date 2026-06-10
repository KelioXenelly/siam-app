<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Absensi;
use App\Models\SesiAbsensi;
use Carbon\Carbon;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use OpenApi\Attributes as OA;

class AbsensiController extends Controller
{

    #[OA\Post(
        path: "/api/absensi/scan",
        summary: "Scan QR code for attendance",
        description: "Allows students to record their attendance by scanning a valid QR token within the required radius.",
        security: [["bearerAuth" => []]],
        tags: ["Absensi"],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\MediaType(
                mediaType: "multipart/form-data",
                schema: new OA\Schema(
                    required: ["token", "latitude_mahasiswa", "longitude_mahasiswa", "selfie_photo"],
                    properties: [
                        new OA\Property(property: "token", type: "string", description: "QR token from session"),
                        new OA\Property(property: "latitude_mahasiswa", type: "number", format: "float", example: -6.17511),
                        new OA\Property(property: "longitude_mahasiswa", type: "number", format: "float", example: 106.86503),
                        new OA\Property(property: "selfie_photo", type: "string", format: "binary", description: "Student's selfie photo")
                    ]
                )
            )
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: "Absensi berhasil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Absensi berhasil"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 17),
                                new OA\Property(property: "sesi_absensi_id", type: "integer", example: 3),
                                new OA\Property(property: "mahasiswa_id", type: "integer", example: 1),
                                new OA\Property(property: "latitude_mahasiswa", type: "string", example: "-6.17511"),
                                new OA\Property(property: "longitude_mahasiswa", type: "string", example: "106.86503"),
                                new OA\Property(property: "selfie_photo", type: "string", example: "selfies/1776925219_image.png"),
                                new OA\Property(property: "status", type: "string", example: "hadir"),
                                new OA\Property(property: "waktu_absen", type: "string", format: "date-time", example: "2026-04-23T06:20:19.915402Z"),
                                new OA\Property(property: "created_at", type: "string", format: "date-time", example: "2026-04-23T06:20:19.000000Z"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time", example: "2026-04-23T06:20:19.000000Z")
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 400,
                description: "Bad Request (QR Invalid/Expired/Closed/Already Absent/Out of Radius)",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "QR sudah expired")
                    ]
                )
            ),
            new OA\Response(
                response: 403,
                description: "Forbidden (Not registered in class)",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Anda tidak terdaftar di kelas ini")
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Selfie photo is required")
                    ]
                )
            )
        ]
    )]
    public function scan(Request $request)
    {
        $validated = $request->validate([
            'token' => 'required',
            'latitude_mahasiswa' => 'required',
            'longitude_mahasiswa' => 'required',
            'selfie_photo' => 'required|image|file:jpg,jpeg,png|max:20000'
        ]);

        $user = $request->user();
        $mahasiswa = $user->mahasiswa;

        // 1. cek sesi (validasi token)
        $sesi = SesiAbsensi::with('pertemuan.kelas')->where('qr_token', $validated['token'])->first();

        if (!$sesi) {
            return response()->json([
                'success' => false,
                'message' => 'QR tidak valid'
            ], 400);
        }

        // 2. cek expired & status closed
        if ($sesi->is_closed) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi absensi sudah ditutup oleh dosen'
            ], 400);
        }

        if (Carbon::now()->greaterThan($sesi->expired_at)) {
            return response()->json([
                'success' => false,
                'message' => 'QR sudah expired'
            ], 400);
        }

        // 3. cek mahasiswa terdaftar di kelas (validasi mahasiswa terdaftar di kelas)
        $kelas = $sesi->pertemuan->kelas;

        $terdaftar = $kelas->mahasiswas()
            ->where('mahasiswa_id', $mahasiswa->id)
            ->exists();

        if (!$terdaftar) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak terdaftar di kelas ini'
            ], 403);
        }

        return DB::transaction(function () use ($request, $sesi, $mahasiswa, $validated) {
            // 4. cek sudah absen?
            $already = Absensi::where('sesi_absensi_id', $sesi->id)
                ->where('mahasiswa_id', $mahasiswa->id)
                ->lockForUpdate()
                ->first();

            // Jika sudah absen DAN statusnya bukan 'alfa', tolak.
            // Jika statusnya 'alfa' (karena sesi dibuka ulang), izinkan untuk ditimpa.
            if ($already && strtolower(trim($already->status)) !== 'alfa') {
                return response()->json([
                    'success' => false,
                    'message' => 'Anda sudah absensi (Status: ' . $already->status . ')',
                ], 400);
            }

            // 5. cek jarak (Haversine) -> validasi GPS
            $distance = $this->distance(
                $validated['latitude_mahasiswa'],
                $validated['longitude_mahasiswa'],
                $sesi->latitude_dosen,
                $sesi->longitude_dosen,
            );

            if ($distance > $sesi->radius_validasi) {
                return response()->json([
                    'success' => false,
                    'message' => 'Di luar radius',
                    'distance' => round($distance, 2) . ' meter',
                ], 400);
            }

            // 6. tentukan status (hadir / terlambat)
            $status = 'hadir';

            // jika lebih dari 10 menit = terlambat
            if (Carbon::now()->diffInMinutes($sesi->created_at) > 10) {
                $status = 'terlambat';
            }

            // 7. upload selfie
            if ($request->hasFile('selfie_photo')) {
                $file = $request->file('selfie_photo');
                $absensiTemp = new Absensi();
                $path = $absensiTemp->uploadToCloudinary($file, 'siam/selfies');
            } else {
                throw new \Exception('Selfie wajib diupload');
            }

            // 8. simpan atau perbarui absensi (menimpa status alfa jika ada)
            $absensi = Absensi::updateOrCreate(
                [
                    'sesi_absensi_id' => $sesi->id,
                    'mahasiswa_id' => $mahasiswa->id,
                ],
                [
                    'latitude_mahasiswa' => $validated['latitude_mahasiswa'],
                    'longitude_mahasiswa' => $validated['longitude_mahasiswa'],
                    'selfie_photo' => $path,
                    'status' => $status,
                    'waktu_absen' => Carbon::now(),
                ]
            );

            return response()->json([
                'success' => true,
                'message' => 'Absensi berhasil',
                'data' => $absensi
            ], 201);
        });
    }

    // fungsi hitung jarak (meter)
    private function distance($lat1, $lon1, $lat2, $lon2)
    {
        $earth = 6371000;

        $dLat = deg2rad($lat2 - $lat1);
        $dLon = deg2rad($lon2 - $lon1);

        $a = sin($dLat / 2) * sin($dLat / 2) +
            cos(deg2rad($lat1)) * cos(deg2rad($lat2)) *
            sin($dLon / 2) * sin($dLon / 2);

        $c = 2 * atan2(sqrt($a), sqrt(1 - $a));

        return $earth * $c;
    }

    #[OA\Get(
        path: "/api/absensi/riwayat",
        summary: "Get attendance history for logged-in student",
        security: [["bearerAuth" => []]],
        tags: ["Absensi"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Riwayat absensi ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Riwayat absensi berhasil diambil"),
                        new OA\Property(property: "data", type: "array", items: new OA\Items(type: "object"))
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Tidak ada riwayat",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Tidak ada riwayat absensi")
                    ]
                )
            )
        ]
    )]
    public function riwayat(Request $request)
    {
        $mahasiswa = $request->user()->mahasiswa;

        if (!$mahasiswa) {
            return response()->json([
                'success' => false,
                'message' => 'Data mahasiswa tidak ditemukan',
            ], 404);
        }

        $absensi = Absensi::with(['sesiAbsensi.pertemuan.kelas.mataKuliah'])
            ->where('mahasiswa_id', $mahasiswa->id)
            ->latest()
            ->get();

        if ($absensi->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada riwayat absensi',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Riwayat absensi berhasil diambil',
            'data' => $absensi
        ], 200);
    }


    #[OA\Get(
        path: "/api/sesi/{sesi_id}/absensi",
        summary: "Get all attendance records for a specific session",
        security: [["bearerAuth" => []]],
        tags: ["Absensi"],
        parameters: [
            new OA\Parameter(
                name: "sesi_id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Sesi Absensi"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data absensi per sesi berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data absensi per sesi berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "array",
                            items: new OA\Items(type: "object")
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Tidak ada riwayat absensi",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Tidak ada riwayat absensi")
                    ]
                )
            )
        ]
    )]
    public function bySesi($sesi_id)
    {
        $absensi = Absensi::with('mahasiswa.user')
            ->where('sesi_absensi_id', $sesi_id)
            ->get();

        if ($absensi->isEmpty()) {
            return response()->json([
                'success' => false,
                'errors' => 'Tidak ada riwayat absensi',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data absensi per sesi berhasil diambil',
            'data' => $absensi
        ], 200);
    }

    #[OA\Put(
        path: "/api/absensi/{absensi_id}/manual",
        summary: "Update attendance status manually by Dosen",
        security: [["bearerAuth" => []]],
        tags: ["Absensi"],
        parameters: [
            new OA\Parameter(
                name: "absensi_id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Absensi"
            )
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["status"],
                properties: [
                    new OA\Property(property: "status", type: "string", enum: ["hadir", "terlambat", "izin", "sakit", "alfa"], example: "hadir"),
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: "Status absensi berhasil diperbarui",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Status absensi berhasil diperbarui"),
                        new OA\Property(property: "data", type: "object")
                    ]
                )
            ),
            new OA\Response(
                response: 403,
                description: "Anda tidak memiliki akses untuk mengubah absensi ini",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Anda tidak memiliki akses untuk mengubah absensi ini")
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Data absensi tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Data absensi tidak ditemukan")
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "The selected status is invalid.")
                    ]
                )
            )
        ]
    )]
    public function updateStatusManual(Request $request, $absensi_id)
    {
        $validated = $request->validate([
            'status' => 'required|in:hadir,terlambat,izin,sakit,alfa'
        ]);

        $dosen = $request->user()->dosen;
        $absensi = Absensi::with('sesiAbsensi.pertemuan.kelas')->find($absensi_id);

        if (!$absensi) {
            return response()->json([
                'success' => false,
                'message' => 'Data absensi tidak ditemukan'
            ], 404);
        }

        // Cek apakah dosen pengampu kelas tersebut
        if ($absensi->sesiAbsensi->pertemuan->kelas->dosen_id !== $dosen->id) {
            return response()->json([
                'success' => false,
                'message' => 'Anda tidak memiliki akses untuk mengubah absensi ini'
            ], 403);
        }

        $absensi->update([
            'status' => $validated['status']
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Status absensi berhasil diperbarui',
            'data' => $absensi
        ], 200);
    }

    #[OA\Get(
        path: "/api/pertemuan/{pertemuan_id}/absensi",
        summary: "Get attendance for a specific Pertemuan (Admin)",
        security: [["bearerAuth" => []]],
        tags: ["Absensi"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data absensi berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "data", type: "array", items: new OA\Items(type: "object"))
                    ]
                )
            )
        ]
    )]
    public function byPertemuanForAdmin($pertemuan_id)
    {
        $sesi = SesiAbsensi::where('pertemuan_id', $pertemuan_id)->first();

        if (!$sesi) {
            return response()->json([
                'success' => true,
                'data' => []
            ], 200);
        }

        $absensi = Absensi::with('mahasiswa.user')
            ->where('sesi_absensi_id', $sesi->id)
            ->get();

        return response()->json([
            'success' => true,
            'data' => $absensi
        ], 200);
    }
}
