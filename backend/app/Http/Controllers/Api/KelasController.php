<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Kelas;
use Carbon\Carbon;
use Carbon\Constants\UnitValue;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

class KelasController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    #[OA\Get(
        path: "/api/kelas",
        summary: "Get all kelas",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data kelas berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data kelas berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "array",
                            items: new OA\Items(
                                type: "object",
                                properties: [
                                    new OA\Property(property: "id", type: "integer", example: 1),
                                    new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                    new OA\Property(property: "mata_kuliah_id", type: "integer", example: 2),
                                    new OA\Property(property: "dosen_id", type: "integer", example: 1),
                                    new OA\Property(property: "ruangan_id", type: "integer", example: 3),
                                    new OA\Property(property: "semester", type: "integer", example: 3),
                                    new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                    new OA\Property(property: "hari", type: "string", example: "Senin"),
                                    new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                    new OA\Property(property: "jam_selesai", type: "string", example: "10:00"),
                                    new OA\Property(property: "kapasitas", type: "integer", example: 30),
                                    new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                    new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                    new OA\Property(
                                        property: "mata_kuliah",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 2),
                                            new OA\Property(property: "kode_mk", type: "string", example: "ST001"),
                                            new OA\Property(property: "nama_mk", type: "string", example: "Algoritma dan Pemrograman"),
                                            new OA\Property(property: "sks", type: "integer", example: 3)
                                        ]
                                    ),
                                    new OA\Property(
                                        property: "dosen",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 1),
                                            new OA\Property(property: "nidn", type: "string", example: "0087654321"),
                                            new OA\Property(
                                                property: "user",
                                                type: "object",
                                                properties: [
                                                    new OA\Property(property: "id", type: "integer", example: 5),
                                                    new OA\Property(property: "name", type: "string", example: "Kevin"),
                                                    new OA\Property(property: "email", type: "string", example: "kevin@itbss.ac.id")
                                                ]
                                            )
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
                                    ),
                                    new OA\Property(
                                        property: "mahasiswas",
                                        type: "array",
                                        items: new OA\Items(
                                            type: "object",
                                            properties: [
                                                new OA\Property(property: "id", type: "integer", example: 1),
                                                new OA\Property(property: "nim", type: "string", example: "22110001"),
                                                new OA\Property(
                                                    property: "user",
                                                    type: "object",
                                                    properties: [
                                                        new OA\Property(property: "id", type: "integer", example: 10),
                                                        new OA\Property(property: "name", type: "string", example: "Budi Santoso"),
                                                        new OA\Property(property: "email", type: "string", example: "budi@itbss.ac.id")
                                                    ]
                                                )
                                            ]
                                        )
                                    )
                                ]
                            )
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Data kelas tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "message", type: "string", example: "Data kelas tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function index()
    {
        $kelas = Kelas::with([
            'mataKuliah',
            'dosen.user',
            'mahasiswas.user',
            'ruangan'
        ])->orderBy('kode_kelas', 'asc')->get();

        if ($kelas->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Data kelas tidak ditemukan',
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data kelas berhasil diambil',
            'data' => $kelas,
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
        path: "/api/kelas",
        summary: "Create a new kelas",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["kode_kelas", "mata_kuliah_id", "dosen_id", "ruangan_id", "semester", "tahun_ajaran", "hari", "jam_mulai", "jam_selesai", "kapasitas"],
                properties: [
                    new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                    new OA\Property(property: "mata_kuliah_id", type: "integer", example: 2),
                    new OA\Property(property: "dosen_id", type: "integer", example: 1),
                    new OA\Property(property: "ruangan_id", type: "integer", example: 3),
                    new OA\Property(property: "semester", type: "integer", example: 3),
                    new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                    new OA\Property(property: "hari", type: "string", enum: ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"], example: "Senin"),
                    new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                    new OA\Property(property: "jam_selesai", type: "string", example: "10:00"),
                    new OA\Property(property: "kapasitas", type: "integer", example: 30)
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 201,
                description: "Kelas berhasil ditambahkan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Kelas berhasil ditambahkan"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                new OA\Property(property: "mata_kuliah_id", type: "integer", example: 2),
                                new OA\Property(property: "dosen_id", type: "integer", example: 1),
                                new OA\Property(property: "ruangan_id", type: "integer", example: 3),
                                new OA\Property(property: "semester", type: "integer", example: 3),
                                new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                new OA\Property(property: "hari", type: "string", example: "Senin"),
                                new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                new OA\Property(property: "jam_selesai", type: "string", example: "10:00"),
                                new OA\Property(property: "kapasitas", type: "integer", example: 30),
                                new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                new OA\Property(
                                    property: "mata_kuliah",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 2),
                                        new OA\Property(property: "kode_mk", type: "string", example: "ST001"),
                                        new OA\Property(property: "nama_mk", type: "string", example: "Algoritma dan Pemrograman"),
                                        new OA\Property(property: "sks", type: "integer", example: 3)
                                    ]
                                ),
                                new OA\Property(
                                    property: "dosen",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 1),
                                        new OA\Property(property: "nidn", type: "string", example: "0087654321")
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
                                ),
                                new OA\Property(
                                    property: "mahasiswas",
                                    type: "array",
                                    items: new OA\Items(type: "object")
                                )
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "The kode kelas has already been taken. (and 1 more error)"),
                        new OA\Property(
                            property: "errors",
                            type: "object",
                            properties: [
                                new OA\Property(
                                    property: "kode_kelas",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The kode kelas has already been taken.")
                                ),
                                new OA\Property(
                                    property: "mata_kuliah_id",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The selected mata kuliah id is invalid.")
                                ),
                                new OA\Property(
                                    property: "jam_selesai",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The jam selesai field must be a date after jam mulai.")
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
            'kode_kelas' => 'required|string|unique:kelas,kode_kelas',
            'mata_kuliah_id' => 'required|integer|exists:mata_kuliahs,id',
            'dosen_id' => 'required|integer|exists:dosens,id',
            'ruangan_id' => 'required|integer|exists:ruangans,id',
            'semester' => 'required|integer|min:1|max:8',
            'tahun_ajaran' => 'required|string|max:255',
            'hari' => 'required|string|in:Senin,Selasa,Rabu,Kamis,Jumat,Sabtu,Minggu',
            'jam_mulai' => 'required|date_format:H:i',
            'jam_selesai' => 'required|date_format:H:i|after:jam_mulai',
            'kapasitas' => 'required|integer|min:1',
        ]);

        $kelas = Kelas::create([
            'kode_kelas' => $validated['kode_kelas'],
            'mata_kuliah_id' => $validated['mata_kuliah_id'],
            'dosen_id' => $validated['dosen_id'],
            'ruangan_id' => $validated['ruangan_id'],
            'semester' => $validated['semester'],
            'tahun_ajaran' => $validated['tahun_ajaran'],
            'hari' => $validated['hari'],
            'jam_mulai' => $validated['jam_mulai'],
            'jam_selesai' => $validated['jam_selesai'],
            'kapasitas' => $validated['kapasitas'],
        ]);

        // 🔥 MAP HARI → CARBON
        $hariMap = [
            'Senin' => UnitValue::MONDAY,
            'Selasa' => UnitValue::TUESDAY,
            'Rabu' => UnitValue::WEDNESDAY,
            'Kamis' => UnitValue::THURSDAY,
            'Jumat' => UnitValue::FRIDAY,
            'Sabtu' => UnitValue::SATURDAY,
            'Minggu' => UnitValue::SUNDAY,
        ];

        $targetDay = $hariMap[$kelas->hari] ?? UnitValue::MONDAY;

        $startDate = Carbon::now()->startOfWeek();

        while ($startDate->dayOfWeek !== $targetDay) {
            $startDate->addDay();
        }

        // 🔥 PREPARE ARRAY
        $pertemuanData = [];

        for ($i = 1; $i <= 16; $i++) {

            $tanggal = $startDate->copy()->addWeeks($i - 1);

            $topik = match ($i) {
                8 => 'UTS',
                16 => 'UAS',
                default => 'Pertemuan ' . $i,
            };

            $pertemuanData[] = [
                'pertemuan_ke' => $i,
                'tanggal' => $tanggal->format('Y-m-d'),
                'topik' => $topik,
                'status' => 'Terjadwal',
                'started_at' => null,
                'ended_at' => null,
            ];
        }

        // 🔥 INSERT SEKALI
        $kelas->pertemuans()->createMany($pertemuanData);

        return response()->json([
            'success' => true,
            'message' => 'Kelas berhasil ditambahkan',
            'data' => $kelas->load(['mataKuliah', 'dosen', 'mahasiswas', 'ruangan'])
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    #[OA\Get(
        path: "/api/kelas/{id}",
        summary: "Get specific kelas details",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Kelas"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Kelas berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Kelas berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                new OA\Property(property: "semester", type: "integer", example: 3),
                                new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                new OA\Property(property: "hari", type: "string", example: "Senin"),
                                new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                new OA\Property(property: "jam_selesai", type: "string", example: "10:00"),
                                new OA\Property(property: "kapasitas", type: "integer", example: 30),
                                new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                new OA\Property(
                                    property: "mata_kuliah",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 2),
                                        new OA\Property(property: "kode_mk", type: "string", example: "ST001"),
                                        new OA\Property(property: "nama_mk", type: "string", example: "Algoritma dan Pemrograman"),
                                        new OA\Property(property: "sks", type: "integer", example: 3)
                                    ]
                                ),
                                new OA\Property(
                                    property: "dosen",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 1),
                                        new OA\Property(property: "nidn", type: "string", example: "0087654321")
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
                                ),
                                new OA\Property(
                                    property: "mahasiswas",
                                    type: "array",
                                    items: new OA\Items(
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 1),
                                            new OA\Property(property: "nim", type: "string", example: "22110001"),
                                            new OA\Property(
                                                property: "user",
                                                type: "object",
                                                properties: [
                                                    new OA\Property(property: "name", type: "string", example: "Budi Santoso"),
                                                    new OA\Property(property: "email", type: "string", example: "budi@itbss.ac.id")
                                                ]
                                            )
                                        ]
                                    )
                                )
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Kelas not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Kelas] 999")
                    ]
                )
            )
        ]
    )]
    public function show($id)
    {
        $kelas = Kelas::with(['mataKuliah', 'dosen', 'mahasiswas', 'ruangan'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Kelas berhasil diambil',
            'data' => $kelas->load(['mataKuliah', 'dosen', 'mahasiswas', 'ruangan'])
        ], 200);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Kelas $kelas)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    #[OA\Put(
        path: "/api/kelas/{id}",
        summary: "Update an existing kelas",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Kelas"
            )
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["kode_kelas", "mata_kuliah_id", "dosen_id", "ruangan_id", "semester", "tahun_ajaran", "hari", "jam_mulai", "jam_selesai", "kapasitas"],
                properties: [
                    new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023-UPDATE"),
                    new OA\Property(property: "mata_kuliah_id", type: "integer", example: 2),
                    new OA\Property(property: "dosen_id", type: "integer", example: 1),
                    new OA\Property(property: "ruangan_id", type: "integer", example: 3),
                    new OA\Property(property: "semester", type: "integer", example: 3),
                    new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                    new OA\Property(property: "hari", type: "string", enum: ["Senin", "Selasa", "Rabu", "Kamis", "Jumat", "Sabtu", "Minggu"], example: "Selasa"),
                    new OA\Property(property: "jam_mulai", type: "string", example: "10:00"),
                    new OA\Property(property: "jam_selesai", type: "string", example: "12:00"),
                    new OA\Property(property: "kapasitas", type: "integer", example: 35)
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: "Kelas berhasil diupdate",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Kelas berhasil diupdate"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023-UPDATE"),
                                new OA\Property(property: "semester", type: "integer", example: 3),
                                new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                new OA\Property(property: "hari", type: "string", example: "Selasa"),
                                new OA\Property(property: "jam_mulai", type: "string", example: "10:00"),
                                new OA\Property(property: "jam_selesai", type: "string", example: "12:00"),
                                new OA\Property(property: "kapasitas", type: "integer", example: 35),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time")
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Kelas not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Kelas] 999")
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "The kode kelas has already been taken."),
                        new OA\Property(
                            property: "errors",
                            type: "object",
                            properties: [
                                new OA\Property(
                                    property: "kode_kelas",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The kode kelas has already been taken.")
                                ),
                                new OA\Property(
                                    property: "jam_selesai",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The jam selesai field must be a date after jam mulai.")
                                )
                            ]
                        )
                    ]
                )
            )
        ]
    )]
    public function update(Request $request, $id)
    {
        $kelas = Kelas::findOrFail($id);

        $validated = $request->validate([
            'kode_kelas' => 'required|string|unique:kelas,kode_kelas,' . $kelas->id,
            'mata_kuliah_id' => 'required|integer|exists:mata_kuliahs,id',
            'dosen_id' => 'required|integer|exists:dosens,id',
            'ruangan_id' => 'required|integer|exists:ruangans,id',
            'semester' => 'required|integer|min:1|max:8',
            'tahun_ajaran' => 'required|string|max:255',
            'hari' => 'required|string|in:Senin,Selasa,Rabu,Kamis,Jumat,Sabtu,Minggu',
            'jam_mulai' => 'required|date_format:H:i',
            'jam_selesai' => 'required|date_format:H:i|after:jam_mulai',
            'kapasitas' => 'required|integer|min:1',
        ]);

        $kelas->update([
            'kode_kelas' => $validated['kode_kelas'],
            'mata_kuliah_id' => $validated['mata_kuliah_id'],
            'dosen_id' => $validated['dosen_id'],
            'ruangan_id' => $validated['ruangan_id'],
            'semester' => $validated['semester'],
            'tahun_ajaran' => $validated['tahun_ajaran'],
            'hari' => $validated['hari'],
            'jam_mulai' => $validated['jam_mulai'],
            'jam_selesai' => $validated['jam_selesai'],
            'kapasitas' => $validated['kapasitas'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Kelas berhasil diupdate',
            'data' => $kelas->load(['mataKuliah', 'dosen', 'mahasiswas', 'ruangan'])
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    #[OA\Delete(
        path: "/api/kelas/{id}",
        summary: "Delete a kelas",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Kelas"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Kelas berhasil dihapus",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Kelas berhasil dihapus")
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Kelas not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Kelas] 999")
                    ]
                )
            ),
            new OA\Response(
                response: 409,
                description: "Conflict — kelas masih memiliki data terkait",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Kelas masih memiliki pertemuan, tidak bisa dihapus")
                    ]
                )
            )
        ]
    )]
    public function destroy($id)
    {
        $kelas = Kelas::findOrFail($id);

        if ($kelas->pertemuans()->exists()) {
            return response()->json([
                'success' => false,
                'errors' => 'Kelas masih memiliki pertemuan, tidak bisa dihapus',
            ], 409);
        }

        if ($kelas->mahasiswas()->exists()) {
            return response()->json([
                'success' => false,
                'errors' => 'Kelas masih memiliki mahasiswa, tidak bisa dihapus',
            ], 409);
        }

        $kelas->delete();

        return response()->json([
            'success' => true,
            'message' => 'Kelas berhasil dihapus'
        ]);
    }

    #[OA\Post(
        path: "/api/kelas/{kelas_id}/assign-mahasiswa",
        summary: "Assign mahasiswa to kelas",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        parameters: [
            new OA\Parameter(
                name: "kelas_id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Kelas"
            )
        ],
        requestBody: new OA\RequestBody(
            required: true,
            content: new OA\JsonContent(
                required: ["mahasiswa_ids"],
                properties: [
                    new OA\Property(
                        property: "mahasiswa_ids",
                        type: "array",
                        items: new OA\Items(type: "integer", example: 1),
                        description: "Array of mahasiswa IDs to assign"
                    )
                ]
            )
        ),
        responses: [
            new OA\Response(
                response: 200,
                description: "Mahasiswa berhasil ditambahkan ke kelas",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Mahasiswa berhasil ditambahkan ke kelas")
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Kelas not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Kelas] 999")
                    ]
                )
            ),
            new OA\Response(
                response: 422,
                description: "Validation Error",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "The mahasiswa ids field is required."),
                        new OA\Property(
                            property: "errors",
                            type: "object",
                            properties: [
                                new OA\Property(
                                    property: "mahasiswa_ids",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The mahasiswa ids field is required.")
                                ),
                                new OA\Property(
                                    property: "mahasiswa_ids.0",
                                    type: "array",
                                    items: new OA\Items(type: "string", example: "The selected mahasiswa ids.0 is invalid.")
                                )
                            ]
                        )
                    ]
                )
            )
        ]
    )]
    public function assignMahasiswa(Request $request, $kelas_id)
    {
        $kelas = Kelas::findOrFail($kelas_id);

        $validated = $request->validate([
            'mahasiswa_ids' => 'required|array',
            'mahasiswa_ids.*' => 'exists:mahasiswas,id'
        ]);

        $kelas->mahasiswas()->sync($validated['mahasiswa_ids']);

        return response()->json([
            'success' => true,
            'message' => 'Mahasiswa berhasil ditambahkan ke kelas'
        ], 200);
    }

    #[OA\Get(
        path: "/api/dosen/kelas-saya",
        summary: "Get kelas for the authenticated dosen",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Kelas dosen berhasil diambil",
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
                                    new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                    new OA\Property(property: "semester", type: "integer", example: 3),
                                    new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                    new OA\Property(property: "hari", type: "string", example: "Senin"),
                                    new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                    new OA\Property(property: "jam_selesai", type: "string", example: "10:00"),
                                    new OA\Property(property: "kapasitas", type: "integer", example: 30),
                                    new OA\Property(
                                        property: "mata_kuliah",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 2),
                                            new OA\Property(property: "kode_mk", type: "string", example: "ST001"),
                                            new OA\Property(property: "nama_mk", type: "string", example: "Algoritma dan Pemrograman"),
                                            new OA\Property(property: "sks", type: "integer", example: 3)
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
                description: "Data kelas tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Data kelas tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function kelasDosen(Request $request)
    {
        $dosen = $request->user()->dosen;

        $kelas = Kelas::where('dosen_id', $dosen->id)
            ->with(['mataKuliah', 'mahasiswas', 'pertemuans'])
            ->get();

        if ($kelas->isEmpty()) {
            return response()->json([
                'success' => false,
                'errors' => 'Data kelas tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $kelas
        ], 200);
    }

    #[OA\Get(
        path: "/api/kelas/{kelas_id}/mahasiswa",
        summary: "Get list of mahasiswas in a specific kelas",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
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
                description: "Daftar mahasiswa berhasil diambil",
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
                                    new OA\Property(property: "user_id", type: "integer", example: 10),
                                    new OA\Property(property: "nim", type: "string", example: "23110001"),
                                    new OA\Property(property: "prodi_id", type: "integer", example: 1),
                                    new OA\Property(property: "angkatan", type: "string", example: "2023"),
                                    new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                    new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                    new OA\Property(
                                        property: "pivot",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "kelas_id", type: "integer", example: 1),
                                            new OA\Property(property: "mahasiswa_id", type: "integer", example: 1)
                                        ]
                                    ),
                                    new OA\Property(
                                        property: "user",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 10),
                                            new OA\Property(property: "name", type: "string", example: "Kelio Xenelly"),
                                            new OA\Property(property: "email", type: "string", example: "kelio.xenelly@itbss.ac.id"),
                                            new OA\Property(property: "email_verified_at", type: "string", format: "date-time", nullable: true),
                                            new OA\Property(property: "role", type: "string", example: "mahasiswa"),
                                            new OA\Property(property: "is_active", type: "integer", example: 1),
                                            new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                            new OA\Property(property: "updated_at", type: "string", format: "date-time")
                                        ]
                                    )
                                ]
                            )
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 403,
                description: "Anda tidak memiliki akses ke kelas ini",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Anda tidak memiliki akses ke kelas ini")
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Kelas tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Data kelas tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function listMahasiswa(Request $request, $kelas_id)
    {
        $dosen = $request->user()->dosen;

        $kelas = Kelas::find($kelas_id);

        if (!$kelas) {
            return response()->json([
                'success' => false,
                'errors' => 'Data kelas tidak ditemukan'
            ], 404);
        }

        if ($kelas->dosen_id !== $dosen->id) {
            return response()->json([
                'success' => false,
                'errors' => 'Anda tidak memiliki akses ke kelas ini'
            ], 403);
        }

        $kelas->load('mahasiswas.user');

        return response()->json([
            'success' => true,
            'data' => $kelas->mahasiswas
        ], 200);
    }

    #[OA\Get(
        path: "/api/mahasiswa/kelas-saya",
        summary: "Get kelas for the authenticated mahasiswa",
        security: [["bearerAuth" => []]],
        tags: ["Kelas"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Kelas mahasiswa berhasil diambil",
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
                                    new OA\Property(property: "kode_kelas", type: "string", example: "TI-A-2023"),
                                    new OA\Property(property: "semester", type: "integer", example: 3),
                                    new OA\Property(property: "tahun_ajaran", type: "string", example: "2023/2024"),
                                    new OA\Property(property: "hari", type: "string", example: "Senin"),
                                    new OA\Property(property: "jam_mulai", type: "string", example: "08:00"),
                                    new OA\Property(property: "jam_selesai", type: "string", example: "10:00"),
                                    new OA\Property(property: "kapasitas", type: "integer", example: 30),
                                    new OA\Property(
                                        property: "mata_kuliah",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 2),
                                            new OA\Property(property: "kode_mk", type: "string", example: "ST001"),
                                            new OA\Property(property: "nama_mk", type: "string", example: "Algoritma dan Pemrograman"),
                                            new OA\Property(property: "sks", type: "integer", example: 3)
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
                description: "Data kelas tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Data kelas tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function kelasMahasiswa(Request $request)
    {
        $mahasiswa = $request->user()->mahasiswa;

        $kelas = Kelas::whereHas('mahasiswas', function ($query) use ($mahasiswa) {
            $query->where('mahasiswa_id', $mahasiswa->id);
        })
            ->with(['mataKuliah', 'dosen.user'])
            ->get();

        if ($kelas->isEmpty()) {
            return response()->json([
                'success' => false,
                'errors' => 'Data kelas tidak ditemukan',
            ], 404);
        }

        return response()->json([
            'success' => true,
            'data' => $kelas
        ], 200);
    }
}
