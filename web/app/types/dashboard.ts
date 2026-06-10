import type { Activity } from "./activity";

export interface DashboardTrends {
  mahasiswa: string;
  dosen: string;
  kelas: string;
  pertemuan: string;
}

export interface DashboardSummary {
  total_mahasiswa: number;
  total_dosen: number;
  total_kelas_aktif: number;
  total_pertemuan: number;
  trends: DashboardTrends;
}

export interface DashboardStatistics {
  labels: string[];
  data: number[];
}

export interface DashboardStats {
  summary: DashboardSummary;
  recent_activities: Activity[];
  statistics: DashboardStatistics;
}

export interface DashboardResponse {
  success: boolean;
  data: DashboardStats;
  message?: string;
}
