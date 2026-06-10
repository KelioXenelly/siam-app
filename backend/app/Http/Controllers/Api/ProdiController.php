<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Prodi;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

class ProdiController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    #[OA\Get(
        path: "/api/program-studi",
        summary: "Get all program studi",
        tags: ["Program Studi"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "List of Program Studi",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Data Program Studi berhasil diambil"),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        type: "object",
                        properties: [
                            new OA\Property(property: "id", type: "integer"),
                            new OA\Property(property: "kode_prodi", type: "string"),
                            new OA\Property(property: "nama_prodi", type: "string"),
                            new OA\Property(property: "jenjang", type: "string"),
                            new OA\Property(property: "is_active", type: "boolean"),
                            new OA\Property(property: "created_at", type: "string"),
                            new OA\Property(property: "updated_at", type: "string"),
                        ]
                    ),
                    example: [
                        [
                            "id" => 1,
                            "kode_prodi" => "STI",
                            "nama_prodi" => "Sistem dan Teknologi Informasi",
                            "jenjang" => "S1",
                            "is_active" => true,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                        ],
                        [
                            "id" => 2,
                            "kode_prodi" => "BD",
                            "nama_prodi" => "Bisnis Digital",
                            "jenjang" => "S1",
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
        description: "Data Program Studi tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "message", type: "string", example: "Data Program Studi tidak ditemukan")
            ]
        )
    )]
    public function index(Request $request)
    {
        $search = $request->query('search');
        $perPage = $request->query('per_page', 15);
        $sortKey = $request->query('sort_key', 'kode_prodi');
        $sortDir = $request->query('sort_dir', 'asc');

        $query = Prodi::query();

        if ($search) {
            $query->where(function($q) use ($search) {
                $q->where('kode_prodi', 'like', "%{$search}%")
                  ->orWhere('nama_prodi', 'like', "%{$search}%");
            });
        }

        if ($sortKey) {
            $query->orderBy($sortKey, $sortDir);
        } else {
            $query->orderBy('kode_prodi', 'asc');
        }

        $data = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Data Program Studi berhasil diambil',
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
        path: "/api/program-studi",
        summary: "Create program studi",
        tags: ["Program Studi"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["kode_prodi", "nama_prodi", "jenjang"],
            properties: [
                new OA\Property(property: "kode_prodi", type: "string", example: "TSI"),
                new OA\Property(property: "nama_prodi", type: "string", example: "Teknik Sipil"),
                new OA\Property(property: "jenjang", type: "string", example: "S1")
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Program Studi created",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Program Studi berhasil ditambahkan"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "kode_prodi", type: "string", example: "STI"),
                        new OA\Property(property: "nama_prodi", type: "string", example: "Sistem dan Teknologi Informasi"),
                        new OA\Property(property: "jenjang", type: "string", example: "S1"),
                        new OA\Property(property: "is_active", type: "boolean", example: true)
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal (Kode Prodi sudah terdaftar)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "kode_prodi",
                            type: "array",
                            items: new OA\Items(type: "string", example: "Kode prodi sudah terdaftar.")
                        )
                    ]
                )
            ]
        )
    )]
    public function store(Request $request)
    {
        $validated = $request->validate([
            'kode_prodi' => 'required|string|unique:prodis,kode_prodi',
            'nama_prodi' => 'required|string|max:255',
            'jenjang' => 'required|string|in:D3,D4,S1,S2,S3',
        ]);

        $prodi = Prodi::create([
            'kode_prodi' => $validated['kode_prodi'],
            'nama_prodi' => $validated['nama_prodi'],
            'jenjang' => $validated['jenjang'],
            'is_active' => true,
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Program Studi berhasil ditambahkan',
            'data' => $prodi
        ], 201);
    }

    /**
     * Display the specified resource.
     */
    #[OA\Get(
        path: "/api/program-studi/{id}",
        summary: "Get specific program studi",
        tags: ["Program Studi"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\Response(
        response: 200,
        description: "Program Studi details",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Program Studi berhasil ditemukan"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "kode_prodi", type: "string", example: "STI"),
                        new OA\Property(property: "nama_prodi", type: "string", example: "Sistem dan Teknologi Informasi"),
                        new OA\Property(property: "jenjang", type: "string", example: "S1"),
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
        description: "Data Program Studi tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Record not found.")
            ]
        )
    )]
    public function show($id)
    {
        $prodi = Prodi::findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Program Studi berhasil ditemukan',
            'data' => $prodi,
        ], 200);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(Prodi $prodi)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    #[OA\Put(
        path: "/api/program-studi/{id}",
        summary: "Update program studi",
        tags: ["Program Studi"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["kode_prodi", "nama_prodi", "jenjang", "is_active"],
            properties: [
                new OA\Property(property: "kode_prodi", type: "string", example: "TI"),
                new OA\Property(property: "nama_prodi", type: "string", example: "Teknik Informatika"),
                new OA\Property(property: "jenjang", type: "string", example: "S1"),
                new OA\Property(property: "is_active", type: "boolean", example: true)
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Program Studi updated",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Program Studi berhasil diubah"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "kode_prodi", type: "string", example: "TI"),
                        new OA\Property(property: "nama_prodi", type: "string", example: "Teknik Informatika"),
                        new OA\Property(property: "jenjang", type: "string", example: "S1"),
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
        description: "Data Program Studi tidak ditemukan",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Record not found.")
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal (Kode Prodi sudah terdaftar)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "kode_prodi",
                            type: "array",
                            items: new OA\Items(type: "string", example: "Kode prodi sudah terdaftar.")
                        )
                    ]
                )
            ]
        )
    )]
    public function update(Request $request, $id)
    {
        $prodi = Prodi::findOrFail($id);

        $validated = $request->validate([
            'kode_prodi' => 'required|string|unique:prodis,kode_prodi,' . $prodi->id,
            'nama_prodi' => 'required|string|max:255',
            'jenjang' => 'required|string|in:D3,D4,S1,S2,S3',
            'is_active' => 'required|boolean',
        ]);

        $prodi->update([
            'kode_prodi' => $validated['kode_prodi'],
            'nama_prodi' => $validated['nama_prodi'],
            'jenjang' => $validated['jenjang'],
            'is_active' => $validated['is_active'],
        ]);

        return response()->json([
            'success' => true,
            'message' => 'Program Studi berhasil diubah',
            'data' => $prodi,
        ], 200);
    }

    /**
     * Remove the specified resource from storage.
     */
    #[OA\Delete(
        path: "/api/program-studi/{id}",
        summary: "Delete program studi",
        tags: ["Program Studi"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\Response(
        response: 200,
        description: "Program Studi deleted",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: true),
                new OA\Property(property: "message", type: "string", example: "Program Studi berhasil dihapus")
            ]
        )
    )]
    #[OA\Response(
        response: 400,
        description: "Delete failed",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "success", type: "boolean", example: false),
                new OA\Property(property: "errors", type: "string", example: "Program Studi masih memiliki mahasiswa, tidak bisa dihapus")
            ]
        )
    )]
    public function destroy($id)
    {
        $prodi = Prodi::findOrFail($id);

        if ($prodi->mahasiswas()->exists()) {
            return response()->json([
                'success' => false,
                'errors' => 'Program Studi masih memiliki mahasiswa, tidak bisa dihapus',
            ], 400);
        }

        $prodi->delete();

        return response()->json([
            'success' => true,
            'message' => 'Program Studi berhasil dihapus',
        ], 200);
    }
}
