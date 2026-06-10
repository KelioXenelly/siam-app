<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call([
            AdminSeeder::class,
            ProdiSeeder::class,
            DosenSeeder::class,
            MahasiswaSeeder::class,
            MataKuliahSeeder::class,
            RuanganSeeder::class,
            KelasSeeder::class,
            KelasMahasiswaSeeder::class,
            PertemuanSeeder::class,
            ActivityLogSeeder::class,
            // AbsensiSeeder::class,
        ]);
    }
}
