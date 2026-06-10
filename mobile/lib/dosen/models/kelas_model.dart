class Kelas {
  final String id;
  final String nama;
  final String kode;
  final String dosen;
  final String jurusan;
  final String fakultas;

  Kelas({
    required this.id,
    required this.nama,
    required this.kode,
    required this.dosen,
    required this.jurusan,
    required this.fakultas,
  });

  factory Kelas.fromJson(Map<String, dynamic> json) {
    return Kelas(
      id: json['id'] as String,
      nama: json['nama'] as String,
      kode: json['kode'] as String,
      dosen: json['dosen'] as String,
      jurusan: json['jurusan'] as String,
      fakultas: json['fakultas'] as String,
    );
  }
}