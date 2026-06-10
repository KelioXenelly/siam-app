<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Mahasiswa;
use Illuminate\Http\Request;
use OpenApi\Attributes as OA;

class MahasiswaController extends Controller
{
    /**
     * Display a listing of the resource.
     */

    #[OA\Get(
        path: "/api/mahasiswa",
        summary: "Get all mahasiswa",
        security: [["bearerAuth" => []]],
        tags: ["Mahasiswa"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data mahasiswa berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data mahasiswa berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "array",
                            items: new OA\Items(
                                type: "object",
                                properties: [
                                    new OA\Property(property: "id", type: "integer", example: 1),
                                    new OA\Property(property: "user_id", type: "integer", example: 5),
                                    new OA\Property(property: "nim", type: "string", example: "22110001"),
                                    new OA\Property(property: "angkatan", type: "string", example: "2022"),
                                    new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                    new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                    new OA\Property(
                                        property: "user",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 5),
                                            new OA\Property(property: "name", type: "string", example: "Budi Santoso"),
                                            new OA\Property(property: "email", type: "string", example: "budi@itbss.ac.id"),
                                            new OA\Property(property: "role", type: "string", example: "mahasiswa"),
                                            new OA\Property(property: "email_verified_at", type: "string", example: null),
                                            new OA\Property(property: "is_active", type: "boolean", example: true),
                                            new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                            new OA\Property(property: "updated_at", type: "string", format: "date-time")
                                        ]
                                    ),
                                    new OA\Property(
                                        property: "prodi",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 1),
                                            new OA\Property(property: "kode_prodi", type: "string", example: "TS"),
                                            new OA\Property(property: "nama_prodi", type: "string", example: "Teknik Sipil"),
                                            new OA\Property(property: "jenjang", type: "string", example: "S1"),
                                            new OA\Property(property: "is_active", type: "boolean", example: true),
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
                response: 404,
                description: "Data mahasiswa tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Data mahasiswa tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function index(Request $request)
    {
        $search = $request->query('search');
        $perPage = $request->query('per_page', 15);
        $sortKey = $request->query('sort_key', 'created_at');
        $sortDir = $request->query('sort_dir', 'desc');

        $query = Mahasiswa::with('user', 'prodi');

        if ($search) {
            $query->whereHas('user', function($q) use ($search) {
                $q->where('name', 'like', "%{$search}%")
                  ->orWhere('email', 'like', "%{$search}%");
            })->orWhere('nim', 'like', "%{$search}%");
        }

        // Basic sorting (skip complex relationships for now)
        if (in_array($sortKey, ['nim', 'angkatan', 'created_at'])) {
            $query->orderBy($sortKey, $sortDir);
        } else {
            $query->orderBy('created_at', 'desc');
        }

        $mahasiswas = $query->paginate($perPage);

        return response()->json([
            'success' => true,
            'message' => 'Data mahasiswa berhasil diambil',
            'data' => $mahasiswas,
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
     * Display the specified resource.
     */
    #[OA\Get(
        path: "/api/mahasiswa/{id}",
        summary: "Get specific mahasiswa details",
        security: [["bearerAuth" => []]],
        tags: ["Mahasiswa"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Mahasiswa"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data mahasiswa berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data mahasiswa berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "user_id", type: "integer", example: 5),
                                new OA\Property(property: "nim", type: "string", example: "22110001"),
                                new OA\Property(property: "angkatan", type: "string", example: "2022"),
                                new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                new OA\Property(
                                    property: "user",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 5),
                                        new OA\Property(property: "name", type: "string", example: "Budi Santoso"),
                                        new OA\Property(property: "email", type: "string", example: "budi@itbss.ac.id"),
                                        new OA\Property(property: "role", type: "string", example: "mahasiswa"),
                                        new OA\Property(property: "is_active", type: "boolean", example: true)
                                    ]
                                ),
                                new OA\Property(
                                    property: "prodi",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 1),
                                        new OA\Property(property: "kode_prodi", type: "string", example: "TS"),
                                        new OA\Property(property: "nama_prodi", type: "string", example: "Teknik Sipil"),
                                        new OA\Property(property: "jenjang", type: "string", example: "S1"),
                                        new OA\Property(property: "is_active", type: "boolean", example: true),
                                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                        new OA\Property(property: "updated_at", type: "string", format: "date-time")
                                    ]
                                ),
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Mahasiswa not found",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "message", type: "string", example: "No query results for model [App\\Models\\Mahasiswa] 999")
                    ]
                )
            )
        ]
    )]
    public function show($id)
    {
        $mahasiswa = Mahasiswa::with(['user', 'prodi'])->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Data mahasiswa berhasil diambil',
            'data' => $mahasiswa,
        ], 200);
    }
}