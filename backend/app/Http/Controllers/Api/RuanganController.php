<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Ruangan;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

class RuanganController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    #[OA\Get(
        path: "/api/ruangan",
        summary: "Get all ruangan",
        tags: ["Ruangan"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "List of Ruangan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Ruangan berhasil diambil"),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        type: "object",
                        properties: [
                            new OA\Property(property: "id", type: "integer"),
                            new OA\Property(property: "nama", type: "string"),
                            new OA\Property(property: "kapasitas", type: "integer"),
                            new OA\Property(property: "is_active", type: "boolean"),
                            new OA\Property(property: "created_at", type: "string"),
                            new OA\Property(property: "updated_at", type: "string"),
                        ]
                    ),
                    example: [
                        [
                            "id" => 1,
                            "nama" => "1.01",
                            "kapasitas" => 40,
                            "is_active" => true,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                        ],
                        [
                            "id" => 2,
                            "nama" => "1.02",
                            "kapasitas" => 35,
                            "is_active" => true,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                        ]
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Ruangan tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ruangan tidak ditemukan")
            ]
        )
    )]
    public function index(Request $request)
    {
        $search = $request->query('search');
        $perPage = $request->query('per_page', 15);
        $sortKey = $request->query('sort_key', 'nama');
        $sortDir = $request->query('sort_dir', 'asc');

        $query = Ruangan::query();

        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('nama', 'like', "%{$search}%");
            });
        }

        if ($sortKey) {
            $query->orderBy($sortKey, $sortDir);
        } else {
            $query->orderBy('nama', 'asc');
        }

        $data = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Ruangan berhasil diambil',
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
        path: "/api/ruangan",
        summary: "Menambahkan ruangan baru",
        tags: ["Ruangan"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["nama", "kapasitas"],
            properties: [
                new OA\Property(property: "nama", type: "string", example: "LAB-3"),
                new OA\Property(property: "kapasitas", type: "integer", example: 40)
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Ruangan berhasil ditambahkan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Ruangan berhasil ditambahkan"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 40),
                        new OA\Property(property: "nama", type: "string", example: "LAB-3"),
                        new OA\Property(property: "kapasitas", type: "integer", example: 40),
                        new OA\Property(property: "is_active", type: "boolean", example: true),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal (Nama ruangan sudah terdaftar)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "nama",
                            type: "array",
                            items: new OA\Items(type: "string", example: "Nama ruangan sudah terdaftar.")
                        )
                    ]
                )
            ]
        )
    )]
    public function store(Request $request)
    {
        $validated = $request->validate([
            'nama' => 'required|string|max:255|unique:ruangans,nama',
            'kapasitas' => 'required|integer|min:1',
        ]);

        $ruangan = Ruangan::create([
            'nama' => $validated['nama'],
            'kapasitas' => $validated['kapasitas'],
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Ruangan berhasil ditambahkan',
            'data' => $ruangan,
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    #[OA\Get(
        path: "/api/ruangan/{ruangan_id}",
        summary: "Mendapatkan data ruangan berdasarkan ID",
        tags: ["Ruangan"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "ruangan_id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", example: 1)
    )]
    #[OA\Response(
        response: 200,
        description: "Ruangan berhasil ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Ruangan berhasil ditemukan"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "nama", type: "string", example: "LAB-3"),
                        new OA\Property(property: "kapasitas", type: "integer", example: 40),
                        new OA\Property(property: "is_active", type: "boolean", example: true),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Ruangan tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ruangan tidak ditemukan")
            ]
        )
    )]
    public function show($id)
    {
        $ruangan = Ruangan::findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Ruangan berhasil ditemukan',
            'data' => $ruangan,
        ], 200);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Ruangan $ruangan)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    #[OA\Put(
        path: "/api/ruangan/{ruangan_id}",
        summary: "Memperbarui data ruangan",
        tags: ["Ruangan"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "ruangan_id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", example: 1)
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["nama", "kapasitas", "is_active"],
            properties: [
                new OA\Property(property: "nama", type: "string", example: "LAB-10"),
                new OA\Property(property: "kapasitas", type: "integer", example: 40),
                new OA\Property(property: "is_active", type: "boolean", example: true)
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Ruangan berhasil diubah",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Ruangan berhasil diubah"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "nama", type: "string", example: "LAB-10"),
                        new OA\Property(property: "kapasitas", type: "integer", example: 40),
                        new OA\Property(property: "is_active", type: "boolean", example: true),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Ruangan tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ruangan tidak ditemukan")
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "nama",
                            type: "array",
                            items: new OA\Items(type: "string", example: "Nama ruangan sudah terdaftar.")
                        )
                    ]
                )
            ]
        )
    )]
    public function update(Request $request, $id)
    {
        $ruangan = Ruangan::findOrFail($id);

        $validated = $request->validate([
            'nama' => 'required|string|max:255|unique:ruangans,nama,' . $ruangan->id,
            'kapasitas' => 'required|integer|min:1',
            'is_active' => 'required|boolean',
        ]);

        $ruangan->update([
            'nama' => $validated['nama'],
            'kapasitas' => $validated['kapasitas'],
            'is_active' => $validated['is_active'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Ruangan berhasil diubah',
            'data' => $ruangan,
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    #[OA\Delete(
        path: "/api/ruangan/{ruangan_id}",
        summary: "Menghapus data ruangan",
        tags: ["Ruangan"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "ruangan_id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", example: 1)
    )]
    #[OA\Response(
        response: 200,
        description: "Ruangan berhasil dihapus",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Ruangan berhasil dihapus")
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Ruangan tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ruangan tidak ditemukan")
            ]
        )
    )]
    #[OA\Response(
        response: 400,
        description: "Ruangan masih memiliki kelas, sehingga tidak bisa dihapus",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Ruangan masih memiliki kelas, sehingga tidak bisa dihapus")
            ]
        )
    )]
    public function destroy($id)
    {
        $ruangan = Ruangan::with('kelas')->findOrFail($id);

        if ($ruangan->kelas()->exists()) {
            return response()->json([
                'success' => false,
                'errors' => 'Ruangan masih memiliki kelas, sehingga tidak bisa dihapus',
            ], 400);
        }

        $ruangan->delete();

        return response()->json([
            'success' => true,
            'message' => 'Ruangan berhasil dihapus',
        ], 200);
    }
}
