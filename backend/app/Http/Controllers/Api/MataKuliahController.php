<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\MataKuliah;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

class MataKuliahController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    #[OA\Get(
        path: "/api/mata-kuliah",
        summary: "Mendapatkan semua data mata kuliah",
        tags: ["Mata Kuliah"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Daftar Mata Kuliah",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Data mata kuliah berhasil diambil"),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        type: "object",
                        properties: [
                            new OA\Property(property: "id", type: "integer"),
                            new OA\Property(property: "kode_mk", type: "string"),
                            new OA\Property(property: "nama_mk", type: "string"),
                            new OA\Property(property: "sks", type: "integer"),
                            new OA\Property(property: "created_at", type: "string", format: "date-time"),
                            new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                        ]
                    ),
                    example: [
                        [
                            "id" => 1,
                            "kode_mk" => "ST001",
                            "nama_mk" => "Pengantar TI",
                            "sks" => 3,
                            "created_at" => "2026-04-20T10:10:33.000000Z",
                            "updated_at" => "2026-04-20T10:10:33.000000Z",
                        ]
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Data mata kuliah tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "errors", type: "string", example: "Data mata kuliah tidak ditemukan")
            ]
        )
    )]
    public function index(Request $request)
    {
        $search = $request->query('search');
        $perPage = $request->query('per_page', 15);
        $sortKey = $request->query('sort_key', 'kode_mk');
        $sortDir = $request->query('sort_dir', 'asc');

        $query = MataKuliah::query();

        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('kode_mk', 'like', "%{$search}%")
                  ->orWhere('nama_mk', 'like', "%{$search}%");
            });
        }

        if ($sortKey) {
            $query->orderBy($sortKey, $sortDir);
        } else {
            $query->orderBy('kode_mk', 'asc');
        }

        $data = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Data mata kuliah berhasil diambil',
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
        path: "/api/mata-kuliah",
        summary: "Menambahkan mata kuliah baru",
        tags: ["Mata Kuliah"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["kode_mk", "nama_mk", "sks"],
            properties: [
                new OA\Property(property: "kode_mk", type: "string", example: "ST005"),
                new OA\Property(property: "nama_mk", type: "string", example: "Kecerdasan Buatan"),
                new OA\Property(property: "sks", type: "integer", example: 3)
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Mata kuliah berhasil ditambahkan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Mata kuliah berhasil ditambahkan"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "kode_mk", type: "string", example: "ST005"),
                        new OA\Property(property: "nama_mk", type: "string", example: "Kecerdasan Buatan"),
                        new OA\Property(property: "sks", type: "integer", example: 3),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time")
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal (Kode MK sudah terdaftar)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "kode_mk",
                            type: "array",
                            items: new OA\Items(type: "string", example: "Kode mk sudah terdaftar.")
                        )
                    ]
                )
            ]
        )
    )]
    public function store(Request $request)
    {
        $validated = $request->validate([
            'kode_mk' => 'required|string|unique:mata_kuliahs,kode_mk',
            'nama_mk' => 'required|string|max:255',
            'sks' => 'required|integer|min:1|max:6',
        ]);

        $mataKuliah = MataKuliah::create([
            'kode_mk' => $validated['kode_mk'],
            'nama_mk' => $validated['nama_mk'],
            'sks' => $validated['sks'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mata kuliah berhasil ditambahkan',
            'data' => $mataKuliah
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    #[OA\Get(
        path: "/api/mata-kuliah/{id}",
        summary: "Mendapatkan detail mata kuliah",
        tags: ["Mata Kuliah"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", example: 1)
    )]
    #[OA\Response(
        response: 200,
        description: "Mata kuliah ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Mata kuliah ditemukan"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "kode_mk", type: "string", example: "CS101"),
                        new OA\Property(property: "nama_mk", type: "string", example: "Struktur Data"),
                        new OA\Property(property: "sks", type: "integer", example: 3),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Mata kuliah tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Record not found.")
            ]
        )
    )]
    public function show($id)
    {
        $mataKuliah = MataKuliah::findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Mata kuliah ditemukan',
            'data' => $mataKuliah,
        ], 200);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(MataKuliah $mataKuliah)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    #[OA\Put(
        path: "/api/mata-kuliah/{id}",
        summary: "Memperbarui data mata kuliah",
        tags: ["Mata Kuliah"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", example: 1)
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["kode_mk", "nama_mk", "sks"],
            properties: [
                new OA\Property(property: "kode_mk", type: "string", example: "ST006"),
                new OA\Property(property: "nama_mk", type: "string", example: "Jaringan Komputer"),
                new OA\Property(property: "sks", type: "integer", example: 3)
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Mata kuliah berhasil diubah",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Mata kuliah berhasil diubah"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "kode_mk", type: "string", example: "ST006"),
                        new OA\Property(property: "nama_mk", type: "string", example: "Jaringan Komputer"),
                        new OA\Property(property: "sks", type: "integer", example: 3),
                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                        new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Mata kuliah tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Record not found.")
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal (Kode MK sudah terdaftar)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "kode_mk",
                            type: "array",
                            items: new OA\Items(type: "string", example: "Kode mk sudah terdaftar.")
                        )
                    ]
                )
            ]
        )
    )]
    public function update(Request $request, $id)
    {
        $mataKuliah = MataKuliah::findOrFail($id);

        $validated = $request->validate([
            'kode_mk' => 'required|string|unique:mata_kuliahs,kode_mk,' . $mataKuliah->id,
            'nama_mk' => 'required|string|max:255',
            'sks' => 'required|integer|min:1|max:6',
        ]);

        $mataKuliah->update([
            'kode_mk' => $validated['kode_mk'],
            'nama_mk' => $validated['nama_mk'],
            'sks' => $validated['sks'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Mata kuliah berhasil diubah',
            'data' => $mataKuliah,
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    #[OA\Delete(
        path: "/api/mata-kuliah/{id}",
        summary: "Menghapus data mata kuliah",
        tags: ["Mata Kuliah"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer", example: 1)
    )]
    #[OA\Response(
        response: 200,
        description: "Mata kuliah berhasil dihapus",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Mata kuliah berhasil dihapus")
            ]
        )
    )]
    #[OA\Response(
        response: 404,
        description: "Mata kuliah tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Record not found.")
            ]
        )
    )]
    #[OA\Response(
        response: 400,
        description: "Mata kuliah masih memiliki kelas, sehingga tidak bisa dihapus",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "errors", type: "string", example: "Mata kuliah masih memiliki kelas, sehingga tidak bisa dihapus")
            ]
        )
    )]
    public function destroy($id)
    {
        $mataKuliah = MataKuliah::findOrFail($id);

        if ($mataKuliah->kelas()->exists()) {
            return response()->json([
                'success' => false,
                'errors' => 'Mata kuliah masih memiliki kelas, sehingga tidak bisa dihapus',
            ], 400);
        }

        $mataKuliah->delete();

        return response()->json([
            'success' => true,
            'message' => 'Mata kuliah berhasil dihapus',
        ], 200);
    }
}
