export type User = {
  id: number;
  name: string;
  email: string;
  role: 'admin' | 'mahasiswa' | 'dosen';
  is_active: boolean;
  avatar?: string | null;
  nim_nidn: string;
  prodi_id: number;
  angkatan: string;
  password: string;

  mahasiswa?: {
    nim: string;
    prodi_id: number;
    angkatan: string;
  } | null;

  dosen?: {
    nidn: string;
  } | null;
}