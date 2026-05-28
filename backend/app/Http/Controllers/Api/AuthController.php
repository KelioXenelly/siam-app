<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use App\Models\User;
use App\Models\Mahasiswa;
use App\Models\Dosen;
use App\Models\Kelas;
use App\Models\Pertemuan;
use App\Models\Absensi;
use App\Models\ActivityLog;
use Carbon\Carbon;
use OpenApi\Attributes as OA;

class AuthController extends Controller
{
    #[OA\Post(
        path: "/api/login",
        summary: "Login user (Mahasiswa / Dosen)",
        tags: ["Auth"]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["identifier", "password"],
            properties: [
                new OA\Property(property: "identifier", description: "Email, NIM, atau NIDN", type: "string", example: "23110001 / eric@itbss.ac.id / 10000001 / admin@itbss.ac.id"),
                new OA\Property(property: "password", type: "string", example: "password / admin123")
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Login berhasil",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Login berhasil! Selamat datang Kelio \u{1F44B}"),
                new OA\Property(property: "token", type: "string", example: "1|abc123xyz"),
                new OA\Property(
                    property: "user",
                    properties: [
                        new OA\Property(property: "id", type: "integer", example: 1),
                        new OA\Property(property: "name", type: "string", example: "Kelio Xenelly"),
                        new OA\Property(property: "email", type: "string", example: "kelio.xenelly@itbss.ac.id"),
                        new OA\Property(property: "role", type: "string", example: "mahasiswa"),
                        new OA\Property(property: "is_active", type: "boolean", example: true)
                    ],
                    type: "object"
                )
            ]
        )
    )]
    #[OA\Response(
        response: 401,
        description: "Login gagal",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "errors", type: "string", example: "Email atau password salah")
            ]
        )
    )]
    public function login(Request $request)
    {
        $request->validate([
            'identifier' => 'required',
            'password' => 'required'
        ]);

        $user = User::where('email', $request->identifier)
            ->orWhereHas('mahasiswa', function ($q) use ($request) {
                $q->where('nim', $request->identifier);
            })
            ->orWhereHas('dosen', function ($q) use ($request) {
                $q->where('nidn', $request->identifier);
            })
            ->first();

        if (!$user || !Hash::check($request->password, $user->password)) {
            return response()->json([
                'errors' => 'Email atau password salah'
            ], 401);
        }

        if (!$user->is_active) {
            return response()->json([
                'errors' => 'Akun tidak aktif'
            ], 401);
        }

        $token = $user->createToken('siam_token')->plainTextToken;

        return response()->json([
            'message' => "Login berhasil! Selamat datang " . $user->name . " 👋",
            'token' => $token,
            'user' => $user
        ]);
    }

    #[OA\Post(
        path: "/api/logout",
        summary: "Logout user",
        tags: ["Auth"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Logout berhasil",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Logout berhasil")
            ]
        )
    )]
    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json([
            'message' => 'Logout berhasil'
        ]);
    }


    #[OA\Get(
        path: "/api/me",
        summary: "Get current authenticated user",
        tags: ["Auth"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "User data",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "id", type: "integer", example: 1),
                new OA\Property(property: "name", type: "string", example: "Kelio Xenelly"),
                new OA\Property(property: "email", type: "string", example: "kelio@gmail.com"),
                new OA\Property(property: "role", type: "string", example: "mahasiswa"),
                new OA\Property(property: "is_active", type: "boolean", example: true)
            ]
        )
    )]
    public function me(Request $request)
    {
        return response()->json($request->user()->load('mahasiswa.prodi', 'dosen'));
    }

    #[OA\Post(
        path: "/api/change-password",
        summary: "Change password",
        tags: ["Auth"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["oldPassword", "newPassword"],
            properties: [
                new OA\Property(property: "oldPassword", type: "string", example: "old123"),
                new OA\Property(property: "newPassword", type: "string", example: "new123456")
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Password berhasil diubah",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Password berhasil diubah")
            ]
        )
    )]
    #[OA\Response(
        response: 400,
        description: "Password lama salah",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Password lama salah")
            ]
        )
    )]
    public function changePassword(Request $request)
    {
        $request->validate([
            'oldPassword' => 'required',
            'newPassword' => 'required'
        ]);
        $user = $request->user();

        if (!Hash::check($request->oldPassword, $user->password)) {
            return response()->json([
                'message' => 'Password lama salah'
            ], 400);
        }

        $user->password = Hash::make($request->newPassword);
        $user->save();

        return response()->json([
            'message' => 'Password berhasil diubah'
        ]);
    }

    #[OA\Post(
        path: "/api/register",
        summary: "Register user (Admin only) (nim required for mahasiswa, nidn required for dosen)",
        tags: ["Auth"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\RequestBody(
        required: true,
        content: new OA\JsonContent(
            required: ["name", "email", "role"],
            properties: [
                new OA\Property(property: "name", type: "string"),
                new OA\Property(property: "email", type: "string"),
                new OA\Property(property: "role", type: "string"),
                new OA\Property(property: "nim", type: "string", nullable: true),
                new OA\Property(property: "nidn", type: "string", nullable: true),
                new OA\Property(property: "prodi_id", type: "integer", nullable: true),
                new OA\Property(property: "angkatan", type: "string", nullable: true)
            ],
            examples: [
                new OA\Examples(
                    example: "Mahasiswa",
                    summary: "Input Mahasiswa",
                    value: [
                        "name" => "Anggario",
                        "email" => "anggario@itbss.ac.id",
                        "role" => "mahasiswa",
                        "nim" => "22110001",
                        "prodi_id" => 1,
                        "angkatan" => "2022"
                    ]
                ),
                new OA\Examples(
                    example: "Dosen",
                    summary: "Input Dosen",
                    value: [
                        "name" => "Kevin",
                        "email" => "kevin@itbss.ac.id",
                        "role" => "dosen",
                        "nidn" => "0087654321",
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 201,
        description: "Pendaftaran berhasil",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer"),
                        new OA\Property(property: "name", type: "string"),
                        new OA\Property(property: "email", type: "string"),
                        new OA\Property(property: "role", type: "string"),
                        new OA\Property(property: "is_active", type: "boolean"),
                        new OA\Property(property: "created_at", type: "string"),
                        new OA\Property(property: "updated_at", type: "string"),
                        new OA\Property(
                            property: "mahasiswa",
                            type: "object",
                            nullable: true,
                            properties: [
                                new OA\Property(property: "id", type: "integer"),
                                new OA\Property(property: "user_id", type: "integer"),
                                new OA\Property(property: "nim", type: "string"),
                                new OA\Property(property: "prodi_id", type: "integer"),
                                new OA\Property(property: "angkatan", type: "string"),
                                new OA\Property(property: "created_at", type: "string"),
                                new OA\Property(property: "updated_at", type: "string"),
                            ]
                        ),
                        new OA\Property(
                            property: "dosen",
                            type: "object",
                            nullable: true,
                            properties: [
                                new OA\Property(property: "id", type: "integer"),
                                new OA\Property(property: "user_id", type: "integer"),
                                new OA\Property(property: "nidn", type: "string"),
                                new OA\Property(property: "created_at", type: "string"),
                                new OA\Property(property: "updated_at", type: "string"),
                            ]
                        )
                    ]
                )
            ],
            examples: [
                new OA\Examples(
                    example: "Mahasiswa",
                    summary: "Respon Mahasiswa",
                    value: [
                        "message" => "Pengguna berhasil didaftarkan",
                        "data" => [
                            "id" => 10,
                            "name" => "Anggario",
                            "email" => "anggrio@itbss.ac.id",
                            "role" => "mahasiswa",
                            "is_active" => true,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                            "mahasiswa" => [
                                "id" => 1,
                                "user_id" => 1,
                                "nim" => "22110001",
                                "prodi_id" => 1,
                                "angkatan" => "2022",
                                "created_at" => "2026-04-07T09:03:06.000000Z",
                                "updated_at" => "2026-04-07T09:03:06.000000Z"
                            ],
                            "dosen" => null
                        ]
                    ]
                ),
                new OA\Examples(
                    example: "Dosen",
                    summary: "Respon Dosen",
                    value: [
                        "message" => "Pengguna berhasil didaftarkan",
                        "data" => [
                            "id" => 11,
                            "name" => "Kevin",
                            "email" => "kevin@itbss.ac.id",
                            "role" => "dosen",
                            "is_active" => true,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                            "mahasiswa" => null,
                            "dosen" => [
                                "id" => 2,
                                "user_id" => 2,
                                "nidn" => "0087654321",
                                "created_at" => "2026-04-07T09:03:06.000000Z",
                                "updated_at" => "2026-04-07T09:03:06.000000Z"
                            ]
                        ]
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal (Email, NIM, atau NIDN sudah terdaftar)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The email has already been taken."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "email",
                            type: "array",
                            items: new OA\Items(type: "string", example: "The email has already been taken.")
                        ),
                        new OA\Property(
                            property: "nim",
                            type: "array",
                            items: new OA\Items(type: "string", example: "The nim has already been taken.")
                        ),
                        new OA\Property(
                            property: "nidn",
                            type: "array",
                            items: new OA\Items(type: "string", example: "The nidn has already been taken.")
                        )
                    ]
                )
            ]
        )
    )]
    public function register(Request $request)
    {
        $request->validate([
            'name' => 'required|string|max:255',
            'email' => 'required|email|unique:users,email',
            'role' => 'required|in:admin,dosen,mahasiswa',
            'nim' => 'required_if:role,mahasiswa|unique:mahasiswas,nim',
            'nidn' => 'required_if:role,dosen|unique:dosens,nidn',
            'prodi_id' => 'required_if:role,mahasiswa|exists:prodis,id',
            'angkatan' => 'required_if:role,mahasiswa',
        ]);

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make("password"), // default password
            'role' => $request->role,
            'is_active' => true,
        ]);

        if ($request->role === 'mahasiswa') {
            $user->mahasiswa()->create([
                'user_id' => $user->id,
                'nim' => $request->nim,
                'prodi_id' => $request->prodi_id,
                'angkatan' => $request->angkatan,
            ]);
        } elseif ($request->role === 'dosen') {
            $user->dosen()->create([
                'user_id' => $user->id,
                'nidn' => $request->nidn,
            ]);
        }

        return response()->json([
            'message' => 'Pengguna berhasil didaftarkan',
            'data' => $user->load('mahasiswa', 'dosen'),
        ], 201);
    }

    #[OA\Get(
        path: "/api/users",
        summary: "Get all users",
        tags: ["User"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Response(
        response: 200,
        description: "Daftar pengguna",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Daftar pengguna berhasil diambil"),
                new OA\Property(
                    property: "data",
                    type: "array",
                    items: new OA\Items(
                        type: "object",
                        properties: [
                            new OA\Property(property: "id", type: "integer"),
                            new OA\Property(property: "name", type: "string"),
                            new OA\Property(property: "email", type: "string"),
                            new OA\Property(property: "email_verified_at", type: "string", nullable: true),
                            new OA\Property(property: "role", type: "string"),
                            new OA\Property(property: "is_active", type: "integer"),
                            new OA\Property(property: "created_at", type: "string"),
                            new OA\Property(property: "updated_at", type: "string"),
                            new OA\Property(
                                property: "mahasiswa",
                                type: "object",
                                nullable: true,
                                properties: [
                                    new OA\Property(property: "id", type: "integer"),
                                    new OA\Property(property: "user_id", type: "integer"),
                                    new OA\Property(property: "nim", type: "string"),
                                    new OA\Property(property: "prodi_id", type: "integer"),
                                    new OA\Property(property: "angkatan", type: "string"),
                                    new OA\Property(property: "created_at", type: "string"),
                                    new OA\Property(property: "updated_at", type: "string")
                                ]
                            ),
                            new OA\Property(
                                property: "dosen",
                                type: "object",
                                nullable: true,
                                properties: [
                                    new OA\Property(property: "id", type: "integer"),
                                    new OA\Property(property: "user_id", type: "integer"),
                                    new OA\Property(property: "nidn", type: "string"),
                                    new OA\Property(property: "created_at", type: "string"),
                                    new OA\Property(property: "updated_at", type: "string")
                                ]
                            )
                        ]
                    ),
                    example: [
                        [
                            "id" => 10,
                            "name" => "Kelio Xenelly",
                            "email" => "kelio.xenelly@itbss.ac.id",
                            "email_verified_at" => null,
                            "role" => "mahasiswa",
                            "is_active" => 1,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                            "mahasiswa" => [
                                "id" => 1,
                                "user_id" => 10,
                                "nim" => "23110001",
                                "prodi_id" => 1,
                                "angkatan" => "2023",
                                "created_at" => "2026-04-07T09:03:06.000000Z",
                                "updated_at" => "2026-04-07T09:03:06.000000Z"
                            ],
                            "dosen" => null
                        ],
                        [
                            "id" => 11,
                            "name" => "Eric",
                            "email" => "eric@itbss.ac.id",
                            "email_verified_at" => null,
                            "role" => "dosen",
                            "is_active" => 1,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                            "mahasiswa" => null,
                            "dosen" => [
                                "id" => 2,
                                "user_id" => 11,
                                "nidn" => "0012345678",
                                "created_at" => "2026-04-07T09:03:06.000000Z",
                                "updated_at" => "2026-04-07T09:03:06.000000Z"
                            ]
                        ]
                    ]
                )
            ]
        )
    )]
    public function users()
    {
        $users = User::with(['mahasiswa', 'dosen'])->get();
        return response()->json([
            'message' => 'Daftar pengguna berhasil diambil',
            'data' => $users->load('mahasiswa', 'dosen'),
        ], 200);
    }

    #[OA\Put(
        path: "/api/users/{user_id}",
        summary: "Update user",
        tags: ["User"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "user_id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\RequestBody(
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "name", type: "string"),
                new OA\Property(property: "email", type: "string"),
                new OA\Property(property: "is_active", type: "boolean"),
                new OA\Property(property: "role", type: "string"),
                new OA\Property(property: "nim", type: "string", nullable: true),
                new OA\Property(property: "nidn", type: "string", nullable: true),
                new OA\Property(property: "prodi_id", type: "integer", nullable: true),
                new OA\Property(property: "angkatan", type: "string", nullable: true),
                new OA\Property(property: "password", type: "string", nullable: true)
            ],
            examples: [
                new OA\Examples(
                    example: "Mahasiswa",
                    summary: "Update form Mahasiswa",
                    value: [
                        "name" => "Anggario",
                        "email" => "anggario@itbss.ac.id",
                        "role" => "mahasiswa",
                        "nim" => "22110001",
                        "prodi_id" => 1,
                        "angkatan" => "2022",
                        "password" => null
                    ]
                ),
                new OA\Examples(
                    example: "Dosen",
                    summary: "Update form Dosen",
                    value: [
                        "name" => "Kevin",
                        "email" => "kevin@itbss.ac.id",
                        "role" => "dosen",
                        "nidn" => "0087654321",
                        "password" => null
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 200,
        description: "Pengguna berhasil diperbarui",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string"),
                new OA\Property(
                    property: "data",
                    type: "object",
                    properties: [
                        new OA\Property(property: "id", type: "integer"),
                        new OA\Property(property: "name", type: "string"),
                        new OA\Property(property: "email", type: "string"),
                        new OA\Property(property: "role", type: "string"),
                        new OA\Property(property: "is_active", type: "boolean"),
                        new OA\Property(property: "created_at", type: "string"),
                        new OA\Property(property: "updated_at", type: "string"),
                        new OA\Property(
                            property: "mahasiswa",
                            type: "object",
                            nullable: true,
                            properties: [
                                new OA\Property(property: "id", type: "integer"),
                                new OA\Property(property: "user_id", type: "integer"),
                                new OA\Property(property: "nim", type: "string"),
                                new OA\Property(property: "prodi_id", type: "integer"),
                                new OA\Property(property: "angkatan", type: "string"),
                                new OA\Property(property: "created_at", type: "string"),
                                new OA\Property(property: "updated_at", type: "string"),
                            ]
                        ),
                        new OA\Property(
                            property: "dosen",
                            type: "object",
                            nullable: true,
                            properties: [
                                new OA\Property(property: "id", type: "integer"),
                                new OA\Property(property: "user_id", type: "integer"),
                                new OA\Property(property: "nidn", type: "string"),
                                new OA\Property(property: "created_at", type: "string"),
                                new OA\Property(property: "updated_at", type: "string"),
                            ]
                        )
                    ]
                )
            ],
            examples: [
                new OA\Examples(
                    example: "Mahasiswa",
                    summary: "Respon Mahasiswa",
                    value: [
                        "message" => "Pengguna berhasil diperbarui",
                        "data" => [
                            "id" => 10,
                            "name" => "Kelio Xenelly",
                            "email" => "kelio.xenelly@itbss.ac.id",
                            "role" => "mahasiswa",
                            "is_active" => true,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                            "mahasiswa" => [
                                "id" => 1,
                                "user_id" => 10,
                                "nim" => "23110001",
                                "prodi_id" => 1,
                                "angkatan" => "2023",
                                "created_at" => "2026-04-07T09:03:06.000000Z",
                                "updated_at" => "2026-04-07T09:03:06.000000Z"
                            ],
                            "dosen" => null
                        ]
                    ]
                ),
                new OA\Examples(
                    example: "Dosen",
                    summary: "Respon Dosen",
                    value: [
                        "message" => "Pengguna berhasil diperbarui",
                        "data" => [
                            "id" => 11,
                            "name" => "Eric",
                            "email" => "eric@itbss.ac.id",
                            "role" => "dosen",
                            "is_active" => true,
                            "created_at" => "2026-04-07T09:03:06.000000Z",
                            "updated_at" => "2026-04-07T09:03:06.000000Z",
                            "mahasiswa" => null,
                            "dosen" => [
                                "id" => 2,
                                "user_id" => 11,
                                "nidn" => "0012345678",
                                "created_at" => "2026-04-07T09:03:06.000000Z",
                                "updated_at" => "2026-04-07T09:03:06.000000Z"
                            ]
                        ]
                    ]
                )
            ]
        )
    )]
    #[OA\Response(
        response: 400,
        description: "Pengguna gagal diubah karena relasi kelas",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "errors", type: "string", example: "Mahasiswa/Dosen masih memiliki kelas, pengguna ini tidak bisa diubah")
            ]
        )
    )]
    #[OA\Response(
        response: 422,
        description: "Validasi gagal (Email, NIM, NIDN yang duplikat atau format tidak sesuai)",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "The given data was invalid."),
                new OA\Property(
                    property: "errors",
                    type: "object",
                    properties: [
                        new OA\Property(
                            property: "email",
                            type: "array",
                            items: new OA\Items(type: "string", example: "The email has already been taken.")
                        ),
                        new OA\Property(
                            property: "nim",
                            type: "array",
                            items: new OA\Items(type: "string", example: "The nim has already been taken atau required.")
                        ),
                        new OA\Property(
                            property: "nidn",
                            type: "array",
                            items: new OA\Items(type: "string", example: "The nidn has already been taken.")
                        )
                    ]
                )
            ]
        )
    )]
    public function updateUser(Request $request, $user_id)
    {
        $user = User::findOrFail($user_id);

        $request->validate([
            'name' => 'sometimes|required|string|max:255',
            'email' => 'sometimes|required|email|unique:users,email,' . $user->id,
            'is_active' => 'sometimes|required|boolean',
            'prodi_id' => 'required_if:role,mahasiswa|exists:prodis,id',
            'angkatan' => 'required_if:role,mahasiswa',
            'nidn' => 'required_if:role,dosen|unique:dosens,nidn,' . ($user->dosen ? $user->dosen->id : 'null'),
            'nim' => 'required_if:role,mahasiswa|unique:mahasiswas,nim,' . ($user->mahasiswa ? $user->mahasiswa->id : 'null'),
            'role' => 'sometimes|required|in:admin,dosen,mahasiswa',
            'password' => 'sometimes|nullable|min:8',
        ]);

        $userData = $request->only('name', 'email', 'is_active', 'prodi_id', 'angkatan', 'nidn', 'nim', 'role', 'password');

        if ($request->filled('password')) {
            $userData['password'] = Hash::make($request->password);
        } else {
            unset($userData['password']); // Jangan update password jika tidak diisi
        }

        if ($user->dosen && $user->dosen->kelas()->exists()) {
            return response()->json([
                'errors' => 'Dosen masih memiliki kelas, pengguna ini tidak bisa diubah'
            ], 400);
        }

        if ($user->mahasiswa && $user->mahasiswa->kelas()->exists()) {
            return response()->json([
                'errors' => 'Mahasiswa masih memiliki kelas, pengguna ini tidak bisa diubah'
            ], 400);
        }

        // Update tabel users
        $user->update($userData);

        if ($user->role === 'mahasiswa') {
            $user->dosen()->delete(); // Hapus data dosen jika sebelumnya adalah dosen

            $user->mahasiswa()->updateOrCreate(
                ['user_id' => $user->id],
                [
                    'nim' => $request->nim,
                    'prodi_id' => $request->prodi_id,
                    'angkatan' => $request->angkatan,
                ]
            );
        } else if ($user->role === 'dosen') {
            $user->mahasiswa()->delete(); // Hapus data mahasiswa jika sebelumnya adalah mahasiswa

            $user->dosen()->updateOrCreate(
                ['user_id' => $user->id],
                ['nidn' => $request->nidn]
            );
        } else {
            // Kalau rolenya admin, hapus dua-duanya (karena admin gak butuh nim/nidn)
            $user->mahasiswa()->delete();
            $user->dosen()->delete();
        }

        return response()->json([
            'message' => 'Pengguna berhasil diperbarui',
            'data' => $user->load('mahasiswa', 'dosen'),
        ], 200);
    }

    #[OA\Delete(
        path: "/api/users/{user_id}",
        summary: "Delete user",
        tags: ["User"],
        security: [["bearerAuth" => []]]
    )]
    #[OA\Parameter(
        name: "user_id",
        in: "path",
        required: true,
        schema: new OA\Schema(type: "integer")
    )]
    #[OA\Response(
        response: 200,
        description: "User deleted",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "message", type: "string", example: "Pengguna berhasil dihapus")
            ]
        )
    )]
    #[OA\Response(
        response: 400,
        description: "Pengguna gagal dihapus",
        content: new OA\JsonContent(
            properties: [
                new OA\Property(property: "errors", type: "string", example: "Mahasiswa/Dosen masih memiliki kelas, pengguna ini tidak bisa dihapus")
            ]
        )
    )]
    public function deleteUser($user_id)
    {
        $user = User::findOrFail($user_id);

        if ($user->dosen && $user->dosen->kelas()->exists()) {
            return response()->json([
                'errors' => 'Dosen masih memiliki kelas, pengguna ini tidak bisa dihapus'
            ], 400);
        }

        if ($user->mahasiswa && $user->mahasiswa->kelas()->exists()) {
            return response()->json([
                'errors' => 'Mahasiswa masih memiliki kelas, pengguna ini tidak bisa dihapus'
            ], 400);
        }

        if ($user->mahasiswa) {
            $user->mahasiswa()->delete();
        } elseif ($user->dosen) {
            $user->dosen()->delete();
        }

        $user->delete();

        return response()->json([
            'message' => 'Pengguna berhasil dihapus',
        ], 200);
    }

    #[OA\Get(
        path: "/api/dashboard-stats",
        summary: "Get statistics for admin dashboard",
        security: [["bearerAuth" => []]],
        tags: ["Dashboard"],
        responses: [
            new OA\Response(
                response: 200,
                description: "Statistik dashboard berhasil diambil",
                content: new OA\JsonContent(
                    properties: [
                        new OA\Property(property: "success", type: "boolean", example: true),
                        new OA\Property(
                            property: "data",
                            type: "object",
                            properties: [
                                new OA\Property(
                                    property: "summary",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "total_mahasiswa", type: "integer", example: 4209),
                                        new OA\Property(property: "total_dosen", type: "integer", example: 312),
                                        new OA\Property(property: "total_kelas_aktif", type: "integer", example: 184),
                                        new OA\Property(property: "total_pertemuan", type: "integer", example: 1024),
                                        new OA\Property(
                                            property: "trends",
                                            type: "object",
                                            properties: [
                                                new OA\Property(property: "mahasiswa", type: "string", example: "+12% from last month"),
                                                new OA\Property(property: "dosen", type: "string", example: "+4 new this semester"),
                                                new OA\Property(property: "kelas", type: "string", example: "Steady"),
                                                new OA\Property(property: "pertemuan", type: "string", example: "+8% this week")
                                            ]
                                        )
                                    ]
                                ),
                                new OA\Property(
                                    property: "recent_activities",
                                    type: "array",
                                    items: new OA\Items(type: "object")
                                ),
                                new OA\Property(
                                    property: "statistics",
                                    type: "object",
                                    properties: [
                                        new OA\Property(property: "labels", type: "array", items: new OA\Items(type: "string")),
                                        new OA\Property(property: "data", type: "array", items: new OA\Items(type: "integer"))
                                    ]
                                )
                            ]
                        )
                    ]
                )
            )
        ]
    )]
    public function dashboardStats(Request $request)
    {
        $range = $request->query('range', '7days');

        // 1. Summary
        $totalMahasiswa = Mahasiswa::count();
        $totalDosen = Dosen::count();
        $totalKelas = Kelas::count();
        $totalPertemuan = Pertemuan::count();

        // Trend Mahasiswa
        $thisMonth = Mahasiswa::whereMonth('created_at', Carbon::now()->month)->count();
        $lastMonth = Mahasiswa::whereMonth('created_at', Carbon::now()->subMonth()->month)->count();
        
        $mahasiswaTrend = "Stabil";
        if ($lastMonth > 0) {
            $percent = (($thisMonth - $lastMonth) / $lastMonth) * 100;
            $mahasiswaTrend = ($percent >= 0 ? '+' : '') . round($percent, 1) . "% from last month";
        } elseif ($thisMonth > 0) {
            $mahasiswaTrend = "+" . $thisMonth . " new this month";
        }

        // 2. Recent Activities
        $recentActivities = ActivityLog::with('user')
            ->latest()
            ->limit(5)
            ->get()
            ->map(function ($log) {
                return [
                    'id' => $log->id,
                    'action' => $log->action,
                    'detail' => $log->detail,
                    'time' => $log->created_at->diffForHumans(),
                    'status' => $log->status,
                ];
            });

        // 3. Attendance Statistics based on range
        $labels = [];
        $data = [];

        if ($range === 'month') {
            // Last 30 days
            for ($i = 29; $i >= 0; $i--) {
                $date = Carbon::now()->subDays($i);
                if ($i % 5 === 0) {
                    $labels[] = $date->format('d M');
                } else {
                    $labels[] = ''; // Empty labels for cleaner look on mobile
                }
                $data[] = Absensi::whereDate('created_at', $date->toDateString())->count();
            }
        } elseif ($range === 'semester') {
            // Last 6 months
            for ($i = 5; $i >= 0; $i--) {
                $date = Carbon::now()->subMonths($i);
                $labels[] = $date->format('M');
                $data[] = Absensi::whereMonth('created_at', $date->month)
                    ->whereYear('created_at', $date->year)
                    ->count();
            }
        } else {
            // Default 7 days
            for ($i = 6; $i >= 0; $i--) {
                $date = Carbon::now()->subDays($i);
                $labels[] = $date->isoFormat('ddd');
                $data[] = Absensi::whereDate('created_at', $date->toDateString())->count();
            }
        }

        return response()->json([
            'success' => true,
            'data' => [
                'summary' => [
                    'total_mahasiswa' => $totalMahasiswa,
                    'total_dosen' => $totalDosen,
                    'total_kelas_aktif' => $totalKelas,
                    'total_pertemuan' => $totalPertemuan,
                    'trends' => [
                        'mahasiswa' => $mahasiswaTrend,
                        'dosen' => "+0 new this semester", 
                        'kelas' => "Steady",
                        'pertemuan' => "+0% this week"
                    ]
                ],
                'recent_activities' => $recentActivities,
                'statistics' => [
                    'labels' => $labels,
                    'data' => $data
                ]
            ]
        ]);
    }

    public function updateAvatar(Request $request)
    {
        $request->validate([
            'avatar' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048'
        ]);

        $user = $request->user();

        if ($request->hasFile('avatar')) {
            // Hapus avatar lama jika ada
            if ($user->avatar) {
                $oldPath = str_replace('/storage/', '', $user->avatar);
                \Illuminate\Support\Facades\Storage::disk('public')->delete($oldPath);
            }

            $file = $request->file('avatar');
            $filename = time() . '_' . $file->getClientOriginalName();
            $path = $file->storeAs('avatars', $filename, 'public');

            $user->avatar = '/storage/' . $path;
            $user->save();

            // Memuat relasi agar kembalian user lengkap
            if ($user->role === 'mahasiswa') {
                $user->load('mahasiswa.prodi');
            } elseif ($user->role === 'dosen') {
                $user->load('dosen');
            }

            return response()->json([
                'success' => true,
                'message' => 'Avatar berhasil diperbarui',
                'user' => $user
            ]);
        }

        return response()->json(['success' => false, 'message' => 'Gagal mengunggah file'], 400);
    }

    public function updateUserAvatar(Request $request, $user_id)
    {
        $user = User::findOrFail($user_id);

        $request->validate([
            'avatar' => 'required|image|mimes:jpeg,png,jpg,webp|max:2048'
        ]);

        if ($request->hasFile('avatar')) {
            // Hapus avatar lama jika ada
            if ($user->avatar) {
                $oldPath = str_replace('/storage/', '', $user->avatar);
                \Illuminate\Support\Facades\Storage::disk('public')->delete($oldPath);
            }

            $file = $request->file('avatar');
            $filename = time() . '_' . $file->getClientOriginalName();
            $path = $file->storeAs('avatars', $filename, 'public');

            $user->avatar = '/storage/' . $path;
            $user->save();

            // Memuat relasi
            if ($user->role === 'mahasiswa') {
                $user->load('mahasiswa.prodi');
            } elseif ($user->role === 'dosen') {
                $user->load('dosen');
            }

            return response()->json([
                'success' => true,
                'message' => 'Avatar pengguna berhasil diperbarui',
                'data' => $user
            ]);
        }

        return response()->json(['success' => false, 'message' => 'Gagal mengunggah file'], 400);
    }
}