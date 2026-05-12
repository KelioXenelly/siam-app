class User {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isActive;
  final String? identifier; // NIM or NIDN
  final String? prodiName; // For Mahasiswa

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.isActive,
    this.identifier,
    this.prodiName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    String? idf;
    String? prodi;
    
    if (json['role'] == 'mahasiswa' && json['mahasiswa'] != null) {
      idf = json['mahasiswa']['nim']?.toString();
      prodi = json['mahasiswa']['prodi']?['nama_prodi']?.toString();
    } else if (json['role'] == 'dosen' && json['dosen'] != null) {
      idf = json['dosen']['nidn']?.toString();
    }

    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      role: json['role'],
      isActive: json['is_active'] == 1 || json['is_active'] == true,
      identifier: idf,
      prodiName: prodi,
    );
  }
}