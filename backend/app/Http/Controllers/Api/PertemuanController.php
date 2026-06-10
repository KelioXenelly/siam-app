<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Pertemuan;
use App\Models\SesiAbsensi;
use App\Services\AbsensiService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use OpenApi\Attributes as OA;

class PertemuanController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    #[OA\Get(
        path: "/api/pertemuan",
        summary: "Get all pertemuan ordered by mata kuliah and pertemuan ke",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data pertemuan berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(
                            property: "data",
                            type: "array",
                            items: new OA\Items(
                                type: "object",
                                properties: [
                                    new OA\Property(property: "id", type: "integer", example: 1),
                                    new OA\Property(property: "kelas_id", type: "integer", example: 2),
                                    new OA\Property(property: "pertemuan_ke", type: "integer", example: 1),
                                    new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-02-05"),
                                    new OA\Property(property: "topik", type: "string", example: "Pertemuan 1"),
                                    new OA\Property(property: "status", type: "string", enum: ["Terjadwal", "Berlangsung", "Selesai"], example: "Terjadwal"),
                                    new OA\Property(property: "started_at", type: "string", example: null),
                                    new OA\Property(property: "ended_at", type: "string", example: null),
                                    new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                    new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                    new OA\Property(
                                        property: "kelas",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 2),
                                            new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                            new OA\Property(property: "semester", type: "integer", example: 3),
                                            new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                            new OA\Property(property: "hari", type: "string", example: "Senin"),
                                            new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                            new OA\Property(property: "jam_selesai", type: "string", example: "10:00"),
                                            new OA\Property(
                                                property: "mata_kuliah",
                                                type: "object",
                                                properties: [
                                                    new OA\Property(property: "id", type: "integer", example: 1),
                                                    new OA\Property(property: "kode_mk", type: "string", example: "ST001"),
                                                    new OA\Property(property: "nama_mk", type: "string", example: "Algoritma dan Pemrograman"),
                                                    new OA\Property(property: "sks", type: "integer", example: 3)
                                                ]
                                            ),
                                            new OA\Property(
                                                property: "ruangan",
                                                type: "object",
                                                properties: [
                                                    new OA\Property(property: "id", type: "integer", example: 3),
                                                    new OA\Property(property: "nama", type: "string", example: "LAB-1"),
                                                    new OA\Property(property: "kapasitas", type: "integer", example: 40)
                                                ]
                                            )
                                        ]
                                    )
                                ]
                            )
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Data pertemuan tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Data pertemuan tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function index(Request $request)
    {
        $search = $request->query('search');
        $perPage = $request->query('per_page', 15);
        $sortKey = $request->query('sort_key');
        $sortDir = $request->query('sort_dir', 'asc');

        $query = Pertemuan::query()
            ->join('kelas', 'pertemuans.kelas_id', '=', 'kelas.id')
            ->join('mata_kuliahs', 'kelas.mata_kuliah_id', '=', 'mata_kuliahs.id')
            ->with(['kelas.mataKuliah', 'kelas.ruangan'])
            ->select('pertemuans.*');

        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('mata_kuliahs.nama_mk', 'like', "%{$search}%")
                  ->orWhere('mata_kuliahs.kode_mk', 'like', "%{$search}%")
                  ->orWhere('pertemuans.materi', 'like', "%{$search}%");
            });
        }

        if ($sortKey && in_array($sortKey, ['tanggal', 'pertemuan_ke', 'status'])) {
            $query->orderBy("pertemuans.{$sortKey}", $sortDir);
        } else {
            $query->orderBy('mata_kuliahs.kode_mk', 'asc')
                  ->orderBy('pertemuans.pertemuan_ke', 'asc');
        }

        $data = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'data' => $data
        ], 200);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    #[OA\Post(
        path: "/api/pertemuan",
        summary: "Create a new pertemuan",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["kelas_id", "pertemuan_ke", "tanggal", "topik"],
                properties: [
                    new OA\Property(property: "kelas_id", type: "integer", example: 2),
                    new OA\Property(property: "pertemuan_ke", type: "integer", example: 17),
                    new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-06-10"),
                    new OA\Property(property: "topik", type: "string", example: "Kuis Akhir")
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: "Pertemuan berhasil dibuat",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan berhasil dibuat"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "kelas_id", type: "integer", example: 2),
                                new OA\Property(property: "pertemuan_ke", type: "integer", example: 17),
                                new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-06-10"),
                                new OA\Property(property: "topik", type: "string", example: "Kuis Akhir"),
                                new OA\Property(property: "status", type: "string", example: "Terjadwal"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time", example: "2026-04-20T15:35:42.000000Z"),
                                new OA\Property(property: "created_at", type: "string", format: "date-time", example: "2026-04-20T15:35:42.000000Z"),
                                new OA\Property(property: "id", type: "integer", example: 209),
                                new OA\Property(
                                    property: "kelas",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 2),
                                        new OA\Property(property: "kode_kelas", type: "string", example: "A-ST002"),
                                        new OA\Property(property: "mata_kuliah_id", type: "integer", example: 2),
                                        new OA\Property(property: "dosen_id", type: "integer", example: 2),
                                        new OA\Property(property: "ruangan_id", type: "integer", example: 2),
                                        new OA\Property(property: "semester", type: "integer", example: 3),
                                        new OA\Property(property: "tahun_ajaran", type: "string", example: "2025/2026"),
                                        new OA\Property(property: "hari", type: "string", example: "Selasa"),
                                        new OA\Property(property: "jam_mulai", type: "string", example: "08:00:00"),
                                        new OA\Property(property: "jam_selesai", type: "string", example: "10:00:00"),
                                        new OA\Property(property: "kapasitas", type: "integer", example: 30),
                                        new OA\Property(property: "created_at", type: "string", format: "date-time", example: "2026-04-20T11:31:13.000000Z"),
                                        new OA\Property(property: "updated_at", type: "string", format: "date-time", example: "2026-04-20T11:31:13.000000Z")
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 409,
                description: "Conflict — pertemuan ke sudah ada di kelas ini",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Pertemuan ke 17 sudah ada di kelas ini, tidak bisa ditambahkan")
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "The kelas id field is required. (and 1 more error)"),
                        new OA\Property(
                            property: "errors",
                            type: "object",
                            properties: [
                                new OA\Property(
                                    property: "kelas_id",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The selected kelas id is invalid.")
                                ),
                                new OA\Property(
                                    property: "tanggal",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The tanggal field must be a valid date.")
                                )
                            ]
                        )
                    ]
                )
            )
        ]
    )]
    public function store(Request $request)
    {
        $validated = $request->validate([
            'kelas_id' => 'required|exists:kelas,id',
            'pertemuan_ke' => 'required|integer',
            'tanggal' => 'required|date',
            'topik' => 'required|string|max:255',
        ]);

        // optional: prevent duplicate pertemuan_ke dalam 1 kelas
        $exists = Pertemuan::where('kelas_id', $validated['kelas_id'])
            ->where('pertemuan_ke', $validated['pertemuan_ke'])
            ->exists();

        if ($exists) {
            return response()->json([
                'success' => false,
                'errors' => 'Pertemuan ke ' . $validated['pertemuan_ke'] . ' sudah ada di kelas ini, tidak bisa ditambahkan'
            ], 409);
        }

        $pertemuan = Pertemuan::create([
            'kelas_id' => $validated['kelas_id'],
            'pertemuan_ke' => $validated['pertemuan_ke'],
            'tanggal' => $validated['tanggal'],
            'topik' => $validated['topik'],
            'status' => 'Terjadwal',
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pertemuan berhasil dibuat',
            'data' => $pertemuan->load('kelas'),
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    #[OA\Get(
        path: "/api/pertemuan/{id}",
        summary: "Get specific pertemuan details",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Pertemuan"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Pertemuan berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "kelas_id", type: "integer", example: 2),
                                new OA\Property(property: "pertemuan_ke", type: "integer", example: 1),
                                new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-02-05"),
                                new OA\Property(property: "topik", type: "string", example: "Pertemuan 1"),
                                new OA\Property(property: "status", type: "string", example: "Terjadwal"),
                                new OA\Property(property: "started_at", type: "string", example: null),
                                new OA\Property(property: "ended_at", type: "string", example: null),
                                new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                new OA\Property(
                                    property: "kelas",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 2),
                                        new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                        new OA\Property(property: "semester", type: "integer", example: 3),
                                        new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                        new OA\Property(property: "hari", type: "string", example: "Senin"),
                                        new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                        new OA\Property(property: "jam_selesai", type: "string", example: "10:00")
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Pertemuan not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Pertemuan] 999")
                    ]
                )
            )
        ]
    )]
    public function show($id)
    {
        $pertemuan = Pertemuan::with('kelas')->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Pertemuan berhasil diambil',
            'data' => $pertemuan,
        ], 200);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Pertemuan $pertemuan)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    #[OA\Put(
        path: "/api/pertemuan/{id}",
        summary: "Update an existing pertemuan",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Pertemuan"
            )
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["kelas_id", "pertemuan_ke", "tanggal", "topik", "status"],
                properties: [
                    new OA\Property(property: "kelas_id", type: "integer", example: 2),
                    new OA\Property(property: "pertemuan_ke", type: "integer", example: 1),
                    new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-02-05"),
                    new OA\Property(property: "topik", type: "string", example: "Pertemuan 1 - Update"),
                    new OA\Property(property: "status", type: "string", enum: ["Terjadwal", "Berlangsung", "Selesai"], example: "Berlangsung"),
                    new OA\Property(property: "started_at", type: "string", example: "08:00", description: "Required if status is Berlangsung or Selesai"),
                    new OA\Property(property: "ended_at", type: "string", example: null, description: "Required if status is Selesai")
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: "Pertemuan berhasil diubah",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan berhasil diubah"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "kelas_id", type: "integer", example: 2),
                                new OA\Property(property: "pertemuan_ke", type: "integer", example: 1),
                                new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-02-05"),
                                new OA\Property(property: "topik", type: "string", example: "Pertemuan 1 - Update"),
                                new OA\Property(property: "status", type: "string", example: "Berlangsung"),
                                new OA\Property(property: "started_at", type: "string", example: "08:00"),
                                new OA\Property(property: "ended_at", type: "string", example: null),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                new OA\Property(
                                    property: "kelas",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 2),
                                        new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                        new OA\Property(property: "hari", type: "string", example: "Senin"),
                                        new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                        new OA\Property(property: "jam_selesai", type: "string", example: "10:00")
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Pertemuan not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Pertemuan] 999")
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error or Business Logic Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(
                            property: "errors",
                            type: "array",
                            items: new OA\Items(type: "string", example: "Waktu selesai hanya boleh diisi saat status Selesai")
                        )
                    ]
                )
            )
        ]
    )]
    public function update(Request $request, $id)
    {
        $pertemuan = Pertemuan::with('kelas')->findOrFail($id);

        $validated = $request->validate([
            'kelas_id' => 'required|exists:kelas,id',
            'pertemuan_ke' => 'required|integer',
            'tanggal' => 'required|date',
            'topik' => 'required|string|max:255',
            'status' => 'required|string|in:Terjadwal,Berlangsung,Selesai',
            'started_at' => 'nullable|date_format:H:i|required_if:status,Berlangsung,Selesai',
            'ended_at' => 'nullable|date_format:H:i|after:started_at|required_if:status,Selesai',
        ]);

        if ($validated['status'] !== 'Selesai' && !empty($validated['ended_at'])) {
            return response()->json([
                'success' => false,
                'errors' => ['Waktu selesai hanya boleh diisi saat status Selesai']
            ], 422);
        }

        if (
            !empty($validated['ended_at']) &&
            !empty($validated['started_at']) &&
            $validated['ended_at'] < $validated['started_at']
        ) {
            return response()->json([
                'success' => false,
                'errors' => ['Waktu selesai tidak boleh lebih awal dari waktu mulai'],
            ], 422);
        }

        $pertemuan->update([
            'kelas_id' => $validated['kelas_id'],
            'pertemuan_ke' => $validated['pertemuan_ke'],
            'tanggal' => $validated['tanggal'],
            'topik' => $validated['topik'],
            'status' => $validated['status'],
            'started_at' => $validated['started_at'],
            'ended_at' => $validated['ended_at'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Pertemuan berhasil diubah',
            'data' => $pertemuan->load('kelas'),
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    #[OA\Delete(
        path: "/api/pertemuan/{id}",
        summary: "Delete a pertemuan",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Pertemuan"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Pertemuan berhasil dihapus",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan berhasil dihapus")
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Pertemuan not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Pertemuan] 999")
                    ]
                )
            ),
            new OA\Response(
                response: 409,
                description: "Conflict — pertemuan tidak dapat dihapus",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Pertemuan masih berlangsung, tidak bisa dihapus")
                    ]
                )
            )
        ]
    )]
    public function destroy($id)
    {
        $pertemuan = Pertemuan::with('kelas')->findOrFail($id);

        if ($pertemuan->status === 'Berlangsung') {
            return response()->json([
                'success' => false,
                'errors' => 'Pertemuan masih berlangsung, tidak bisa dihapus',
            ], 409);
        }

        if ($pertemuan->status === 'Selesai') {
            return response()->json([
                'success' => false,
                'errors' => 'Pertemuan sudah selesai, tidak bisa dihapus',
            ], 409);
        }

        if ($pertemuan->sesiAbsensi()->exists()) {
            return response()->json([
                'success' => false,
                'errors' => 'Pertemuan masih memiliki sesi absensi, tidak bisa dihapus',
            ], 409);
        }

        $pertemuan->delete();

        return response()->json([
            'success' => true,
            'message' => 'Pertemuan berhasil dihapus',
        ], 200);
    }

    // Ambil pertemuan berdasarkan kelas
    #[OA\Get(
        path: "/api/kelas/{kelas_id}/pertemuan",
        summary: "Get all pertemuan for a specific kelas",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
        parameters: [
            new OA\Parameter(
                name: "kelas_id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Kelas"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data pertemuan berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(
                            property: "data",
                            type: "array",
                            items: new OA\Items(
                                type: "object",
                                properties: [
                                    new OA\Property(property: "id", type: "integer", example: 1),
                                    new OA\Property(property: "kelas_id", type: "integer", example: 1),
                                    new OA\Property(property: "pertemuan_ke", type: "integer", example: 1),
                                    new OA\Property(property: "tanggal", type: "string", format: "date", example: "2026-04-20"),
                                    new OA\Property(property: "topik", type: "string", example: "Pertemuan 1"),
                                    new OA\Property(property: "status", type: "string", example: "Selesai"),
                                    new OA\Property(property: "started_at", type: "string", example: "08:00:00"),
                                    new OA\Property(property: "ended_at", type: "string", example: "10:00:00"),
                                    new OA\Property(property: "created_at", type: "string", format: "date-time", example: "2026-04-20T15:39:48.000000Z"),
                                    new OA\Property(property: "updated_at", type: "string", format: "date-time", example: "2026-04-20T15:39:48.000000Z"),
                                    new OA\Property(
                                        property: "kelas",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 1),
                                            new OA\Property(property: "kode_kelas", type: "string", example: "A-ST001"),
                                            new OA\Property(property: "mata_kuliah_id", type: "integer", example: 1),
                                            new OA\Property(property: "dosen_id", type: "integer", example: 1),
                                            new OA\Property(property: "ruangan_id", type: "integer", example: 1),
                                            new OA\Property(property: "semester", type: "integer", example: 3),
                                            new OA\Property(property: "tahun_ajaran", type: "string", example: "2025/2026"),
                                            new OA\Property(property: "hari", type: "string", example: "Senin"),
                                            new OA\Property(property: "jam_mulai", type: "string", example: "08:00:00"),
                                            new OA\Property(property: "jam_selesai", type: "string", example: "10:00:00"),
                                            new OA\Property(property: "kapasitas", type: "integer", example: 30),
                                            new OA\Property(property: "created_at", type: "string", format: "date-time", example: "2026-04-20T15:39:48.000000Z"),
                                            new OA\Property(property: "updated_at", type: "string", format: "date-time", example: "2026-04-20T15:39:48.000000Z"),
                                            new OA\Property(
                                                property: "mata_kuliah",
                                                type: "object",
                                                properties: [
                                                    new OA\Property(property: "id", type: "integer", example: 1),
                                                    new OA\Property(property: "kode_mk", type: "string", example: "ST001"),
                                                    new OA\Property(property: "nama_mk", type: "string", example: "Pengantar TI"),
                                                    new OA\Property(property: "sks", type: "integer", example: 3),
                                                    new OA\Property(property: "created_at", type: "string", format: "date-time", example: "2026-04-20T15:39:48.000000Z"),
                                                    new OA\Property(property: "updated_at", type: "string", format: "date-time", example: "2026-04-20T15:39:48.000000Z")
                                                ]
                                            )
                                        ]
                                    )
                                ]
                            )
                        )
                    ]
                )
            )
        ]
    )]
    public function byKelas($kelas_id)
    {
        $data = Pertemuan::where('kelas_id', $kelas_id)
            ->with(['kelas', 'kelas.mataKuliah'])
            ->orderBy('pertemuan_ke', 'asc')
            ->get();

        return response()->json([
            'success' => true,
            'data' => $data
        ]);
    }

    #[OA\Post(
        path: "/api/pertemuan/{pertemuan_id}/start",
        summary: "Start a pertemuan (set status to Berlangsung)",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
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
                description: "Pertemuan dimulai",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan dimulai"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "kelas_id", type: "integer", example: 2),
                                new OA\Property(property: "pertemuan_ke", type: "integer", example: 1),
                                new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-02-05"),
                                new OA\Property(property: "topik", type: "string", example: "Pertemuan 1"),
                                new OA\Property(property: "status", type: "string", example: "Berlangsung"),
                                new OA\Property(property: "started_at", type: "string", example: "08:00:00"),
                                new OA\Property(property: "ended_at", type: "string", example: null),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time")
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Pertemuan not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Pertemuan] 999")
                    ]
                )
            ),
            new OA\Response(
                response: 409,
                description: "Conflict — pertemuan tidak dapat dimulai",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan sudah dimulai")
                    ]
                )
            )
        ]
    )]
    public function start($pertemuan_id)
    {
        return DB::transaction(function () use ($pertemuan_id) {
            $pertemuan = Pertemuan::lockForUpdate()->findOrFail($pertemuan_id);

            // ❗ prevent double start
            if ($pertemuan->started_at !== null) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pertemuan sudah dimulai'
                ], 409);
            }

            // ❗ pastikan tidak ada session aktif lain
            $active = Pertemuan::where('kelas_id', $pertemuan->kelas_id)
                ->where('status', 'Berlangsung')
                ->lockForUpdate()
                ->exists();

            if ($active) {
                return response()->json([
                    'success' => false,
                    'message' => 'Masih ada pertemuan yang berlangsung'
                ], 409);
            }

            $pertemuan->update([
                'status' => 'Berlangsung',
                'started_at' => now()->format('H:i:s'),
            ]);

            return response()->json([
                'success' => true,
                'message' => 'Pertemuan dimulai',
                'data' => $pertemuan
            ]);
        });
    }

    #[OA\Post(
        path: "/api/pertemuan/{pertemuan_id}/end",
        summary: "End a pertemuan (set status to Selesai)",
        security: [["bearerAuth" => []]],
        tags: ["Pertemuan"],
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
                description: "Pertemuan diakhiri",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan diakhiri"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "kelas_id", type: "integer", example: 2),
                                new OA\Property(property: "pertemuan_ke", type: "integer", example: 1),
                                new OA\Property(property: "tanggal", type: "string", format: "date", example: "2024-02-05"),
                                new OA\Property(property: "topik", type: "string", example: "Pertemuan 1"),
                                new OA\Property(property: "status", type: "string", example: "Selesai"),
                                new OA\Property(property: "started_at", type: "string", example: "08:00:00"),
                                new OA\Property(property: "ended_at", type: "string", example: "10:00:00"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time")
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Pertemuan not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Pertemuan] 999")
                    ]
                )
            ),
            new OA\Response(
                response: 409,
                description: "Conflict — pertemuan tidak dapat diakhiri",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Pertemuan belum dimulai")
                    ]
                )
            )
        ]
    )]
    public function end($pertemuan_id, AbsensiService $absensiService)
    {
        return DB::transaction(function () use ($pertemuan_id, $absensiService) {
            $pertemuan = Pertemuan::with('kelas', 'sesiAbsensi')->lockForUpdate()->findOrFail($pertemuan_id);

            // 0. Cek Kepemilikan
            if ($pertemuan->kelas->dosen_id !== auth()->user()->dosen->id) {
                return response()->json([
                    'message' => 'Bukan kelas anda, anda tidak berhak mengakses kelas ini'
                ], 403);
            }

            if ($pertemuan->started_at === null) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pertemuan belum dimulai'
                ], 409);
            }

            if ($pertemuan->ended_at !== null) {
                return response()->json([
                    'success' => false,
                    'message' => 'Pertemuan sudah selesai'
                ], 409);
            }

            $pertemuan->update([
                'status' => 'Selesai',
                'ended_at' => now()->format('H:i:s'),
            ]);

            // 3. Auto-close sesi absensi jika ada yang masih terbuka
            if ($pertemuan->sesiAbsensi && !$pertemuan->sesiAbsensi->is_closed) {
                $absensiService->closeSession($pertemuan->sesiAbsensi->id);
            }

            return response()->json([
                'success' => true,
                'message' => 'Pertemuan diakhiri dan sesi absensi otomatis ditutup',
                'data' => $pertemuan->load('sesiAbsensi') // Using load here is fine because it loads a newly updated relationship
            ]);
        });
    }
}
