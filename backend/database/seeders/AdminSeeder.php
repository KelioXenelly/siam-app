<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        User::firstOrCreate(
            // 1. Kriteria Pencarian (Hanya email yang unik)
            ['email' => 'admin@itbss.ac.id'],

            // 2. Data Tambahan (Hanya diisi jika data belum ada)
            [
                'name' => 'Admin SIAM',
                'password' => Hash::make('admin123'),
                'role' => 'admin',
                'is_active' => true,
            ]
        );
    }
}
