<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Absensi;
use App\Models\SesiAbsensi;
use App\Models\Pertemuan;
use App\Services\AbsensiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Carbon\Carbon;
use OpenApi\Attributes as OA;

class SesiAbsensiController extends Controller
{
    #[OA\Post(
        path: "/api/generate-qr",
        summary: "Generate a new QR token for attendance sesssion",
        security: [["bearerAuth" => []]],
        tags: ["Sesi Absensi"],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["pertemuan_id", "latitude_dosen", "longitude_dosen"],
                properties: [
                    new OA\Property(property: "pertemuan_id", type: "integer", example: 5),
                    new OA\Property(property: "latitude_dosen", type: "number", format: "float", example: -6.17511),
                    new OA\Property(property: "longitude_dosen", type: "number", format: "float", example: 106.86503)
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: "QR berhasil dibuat",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "QR berhasil dibuat"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "qr_data", type: "string", example: "{\"token\":\"abcde12345...\"}"),
                                new OA\Property(property: "expired_at", type: "string", format: "date-time", example: "2026-04-20T15:45:00.000000Z")
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 400,
                description: "Bad Request — Pertemuan sudah selesai",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan sudah selesai, tidak bisa generate QR absensi")
                    ]
                )
            ),
            new OA\Response(
                response: 403,
                description: "Forbidden — Bukan kelas dosen yang bersangkutan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "Bukan kelas anda, anda tidak berhak mengakses kelas ini")
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "The pertemuan id field is required."),
                        new OA\Property(
                            property: "errors",
                            type: "object",
                            properties: [
                                new OA\Property(property: "pertemuan_id", type: "array", items: new OA\Items(type: "string", example: "The selected pertemuan id is invalid."))
                            ]
                        )
                    ]
                )
            )
        ]
    )]
    public function generateQR(Request $request)
    {
        $validated = $request->validate([
            'pertemuan_id' => 'required|exists:pertemuans,id',
            'latitude_dosen' => 'required|numeric',
            'longitude_dosen' => 'required|numeric',
        ]);

        return DB::transaction(function () use ($request, $validated) {
            // 1. Ambil data pertemuan dan relasi kelasnya
            $pertemuan = Pertemuan::with('kelas')->findOrFail($validated['pertemuan_id']);

            // 2. CEK DULU: Apakah dosen yang login adalah pemilik kelas ini?
            if ($pertemuan->kelas->dosen_id !== $request->user()->dosen->id) {
                return response()->json([
                    'message' => 'Bukan kelas anda, anda tidak berhak mengakses kelas ini'
                ], 403);
            }

            // 2.5 CEK STATUS: Apakah pertemuan sudah selesai?
            if ($pertemuan->status === 'Selesai') {
                return response()->json([
                    'success' => false,
                    'message' => 'Pertemuan sudah selesai, tidak bisa generate QR absensi'
                ], 400);
            }

            // 3. Gunakan updateOrCreate agar data absensi mahasiswa yang sudah scan tidak hilang
            $token = Str::random(40);

            $sesi = SesiAbsensi::updateOrCreate(
                ['pertemuan_id' => $validated['pertemuan_id']],
                [
                    'qr_token' => $token,
                    'latitude_dosen' => $validated['latitude_dosen'],
                    'longitude_dosen' => $validated['longitude_dosen'],
                    'radius_validasi' => 50,
                    'expired_at' => Carbon::now()->addMinutes(10),
                    'is_closed' => false,
                ]
            );

            // data yang akan di-encode ke QR
            $qrData = json_encode([
                'token' => $token
            ]);

            return response()->json([
                'success' => true,
                'message' => 'QR berhasil dibuat',
                'data' => [
                    'qr_data' => $qrData,
                    'expired_at' => $sesi->expired_at
                ]
            ], 201);
        });
    }

    #[OA\Post(
        path: "/api/sesi/{sesi_id}/close",
        summary: "Close an existing session and generate alfa attendance for absent students",
        security: [["bearerAuth" => []]],
        tags: ["Sesi Absensi"],
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
                description: "Sesi ditutup",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Sesi ditutup, alfa berhasil digenerate")
                    ]
                )
            ),
            new OA\Response(
                response: 400,
                description: "Bad Request — Sesi sudah ditutup",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Sesi ini sudah ditutup sebelumnya")
                    ]
                )
            ),
            new OA\Response(
                response: 403,
                description: "Forbidden — Bukan pemilik kelas",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "Anda tidak berhak menutup sesi ini")
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Sesi Absensi tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\SesiAbsensi] 999")
                    ]
                )
            )
        ]
    )]
    public function closeSesi($sesi_id, AbsensiService $absensiService)
    {
        $sesi = SesiAbsensi::with('pertemuan.kelas')->findOrFail($sesi_id);

        // 1. Cek Kepemilikan
        if ($sesi->pertemuan->kelas->dosen_id !== auth()->user()->dosen->id) {
            return response()->json([
                'message' => 'Anda tidak berhak menutup sesi ini'
            ], 403);
        }

        // 2. Cek apakah sudah ditutup
        if ($sesi->is_closed) {
            return response()->json([
                'success' => false,
                'message' => 'Sesi ini sudah ditutup sebelumnya'
            ], 400);
        }

        // 3. Eksekusi via Service
        $absensiService->closeSession($sesi->id);

        return response()->json([
            'success' => true,
            'message' => 'Sesi ditutup, alfa berhasil digenerate'
        ], 200);
    }

    #[OA\Get(
        path: "/api/sesi/{sesi_id}",
        summary: "Get specific session details",
        security: [["bearerAuth" => []]],
        tags: ["Sesi Absensi"],
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
                description: "Data sesi berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data sesi berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "pertemuan_id", type: "integer", example: 1),
                                new OA\Property(property: "qr_token", type: "string", example: "abcde..."),
                                new OA\Property(property: "is_closed", type: "boolean", example: false),
                                new OA\Property(property: "expired_at", type: "string", format: "date-time")
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Sesi tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\SesiAbsensi] 999")
                    ]
                )
            )
        ]
    )]
    public function show($sesi_id)
    {
        $sesi = SesiAbsensi::with('pertemuan.kelas.mataKuliah')->findOrFail($sesi_id);

        return response()->json([
            'success' => true,
            'message' => 'Data sesi berhasil diambil',
            'data' => $sesi,
        ], 200);
    }

    #[OA\Get(
        path: "/api/pertemuan/{pertemuan_id}/sesi",
        summary: "Get all sessisons for a specific meeting",
        security: [["bearerAuth" => []]],
        tags: ["Sesi Absensi"],
        parameters: [
            new OA\Parameter(
                name: "pertemuan_id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Pertemuan"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data sesi berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data sesi berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "array",
                            items: new OA\Items(
                                type: "object",
                                properties: [
                                    new OA\Property(property: "id", type: "integer", example: 1),
                                    new OA\Property(property: "pertemuan_id", type: "integer", example: 1),
                                    new OA\Property(property: "qr_token", type: "string", example: "abcde..."),
                                    new OA\Property(property: "absensis_count", type: "integer", example: 25)
                                ]
                            )
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Data sesi tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Data sesi tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function byPertemuan($pertemuan_id)
    {
        $sesi = SesiAbsensi::withCount('absensis')->where('pertemuan_id', $pertemuan_id)
            ->orderBy('created_at', 'desc')
            ->get();

        if ($sesi->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Data sesi tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data sesi berhasil diambil',
            'data' => $sesi,
        ], 200);
    }

    #[OA\Get(
        path: "/api/pertemuan/{pertemuan_id}/sesi-aktif",
        summary: "Get currently active session for a specific meeting",
        security: [["bearerAuth" => []]],
        tags: ["Sesi Absensi"],
        parameters: [
            new OA\Parameter(
                name: "pertemuan_id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Pertemuan"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Sesi aktif ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Sesi aktif ditemukan"),
                        new OA\Property(property: "data", type: "object")
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Tidak ada sesi aktif",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Tidak ada sesi aktif")
                    ]
                )
            )
        ]
    )]
    public function aktif($pertemuan_id)
    {
        $sesi = SesiAbsensi::where('pertemuan_id', $pertemuan_id)
            ->withCount('absensis')
            ->where('expired_at', '>', now())
            ->where('is_closed', false)
            ->first();

        if (!$sesi) {
            return response()->json([
                'success' => false,
                'message' => 'Tidak ada sesi aktif',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'message' => 'Sesi aktif ditemukan',
            'data' => $sesi,
        ], 200);
    }
}
