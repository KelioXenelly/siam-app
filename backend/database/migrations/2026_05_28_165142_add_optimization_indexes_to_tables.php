<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->index('name');
        });

        Schema::table('mahasiswas', function (Blueprint $table) {
            $table->index('angkatan');
        });

        Schema::table('kelas', function (Blueprint $table) {
            $table->index('kode_kelas');
            $table->index('tahun_ajaran');
        });

        Schema::table('activity_logs', function (Blueprint $table) {
            $table->index('action');
            // Adding a partial index or full index on detail might be too long if it's text,
            // but we'll index action since it's frequently searched.
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropIndex(['name']);
        });

        Schema::table('mahasiswas', function (Blueprint $table) {
            $table->dropIndex(['angkatan']);
        });

        Schema::table('kelas', function (Blueprint $table) {
            $table->dropIndex(['kode_kelas']);
            $table->dropIndex(['tahun_ajaran']);
        });

        Schema::table('activity_logs', function (Blueprint $table) {
            $table->dropIndex(['action']);
        });
    }
};
