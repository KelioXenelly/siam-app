<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;

use App\Models\Dosen;
use OpenApi\Attributes as OA;

class DosenController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    #[OA\Get(
        path: "/api/dosen",
        summary: "Get all dosen",
        security: [["bearerAuth" => []]],
        tags: ["Dosen"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data dosen berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data dosen berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "array",
                            items: new OA\Items(
                                type: "object",
                                properties: [
                                    new OA\Property(property: "id", type: "integer", example: 1),
                                    new OA\Property(property: "user_id", type: "integer", example: 5),
                                    new OA\Property(property: "nidn", type: "string", example: "22110001"),
                                    new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                    new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                    new OA\Property(
                                        property: "user",
                                        type: "object",
                                        properties: [
                                            new OA\Property(property: "id", type: "integer", example: 5),
                                            new OA\Property(property: "name", type: "string", example: "Budi Santoso"),
                                            new OA\Property(property: "email", type: "string", example: "budi@itbss.ac.id"),
                                            new OA\Property(property: "role", type: "string", example: "dosen"),
                                            new OA\Property(property: "email_verified_at", type: "string", example: null),
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
                description: "Data dosen tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Data dosen tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function index()
    {
        $dosens = Dosen::with('user')->get();

        if ($dosens->isEmpty()) {
            return response()->json([
                'success' => false,
                'message' => 'Data dosen tidak ditemukan',
            ]);
        }

        return response()->json([
            'success' => true,
            'message' => 'Data dosen berhasil diambil',
            'data' => $dosens,
        ], 200);
    }

    /**
     * Display the specified resource.
     */
    #[OA\Get(
        path: "/api/dosen/{id}",
        summary: "Get specific dosen details",
        security: [["bearerAuth" => []]],
        tags: ["Dosen"],
        parameters: [
            new OA\Parameter(
                name: "id",
                in: "path",
                required: true,
                schema: new OA\Schema(type: "integer"),
                description: "ID of the Dosen"
            )
        ],
        responses: [
            new OA\Response(
                response: 200,
                description: "Data dosen berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(property: "message", type: "string", example: "Data dosen berhasil diambil"),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(property: "id", type: "integer", example: 1),
                                new OA\Property(property: "user_id", type: "integer", example: 5),
                                new OA\Property(property: "nidn", type: "string", example: "22110001"),
                                new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                new OA\Property(property: "updated_at", type: "string", format: "date-time"),
                                new OA\Property(
                                    property: "user",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "id", type: "integer", example: 5),
                                        new OA\Property(property: "name", type: "string", example: "Budi Santoso"),
                                        new OA\Property(property: "email", type: "string", example: "budi@itbss.ac.id"),
                                        new OA\Property(property: "role", type: "string", example: "dosen"),
                                        new OA\Property(property: "email_verified_at", type: "string", example: null),
                                        new OA\Property(property: "is_active", type: "boolean", example: true),
                                        new OA\Property(property: "created_at", type: "string", format: "date-time"),
                                        new OA\Property(property: "updated_at", type: "string", format: "date-time")
                                    ]
                                )
                            ]
                        )
                    ]
                )
            ),
            new OA\Response(
                response: 404,
                description: "Data dosen tidak ditemukan",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: false),
                        new OA\Property(property: "errors", type: "string", example: "Data dosen tidak ditemukan")
                    ]
                )
            )
        ]
    )]
    public function show($id)
    {
        $dosen = Dosen::with('user')->findOrFail($id);

        return response()->json([
            'success' => true,
            'message' => 'Data dosen berhasil diambil',
            'data' => $dosen,
        ], 200);
    }
}