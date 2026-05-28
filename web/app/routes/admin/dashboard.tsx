import { useState, useEffect } from "react";
import api from "~/lib/api";

export function meta() {
  return [
    { title: "Dashboard | SIAM Admin" },
    { name: "description", content: "Ringkasan statistik akademik SIAM." },
  ];
}
import AuthGuard from "~/components/auth_guard";
import { 
  Users, 
  GraduationCap, 
  Building2, 
  Calendar,
  MoreVertical,
  ArrowUpRight,
  TrendingUp,
  Clock,
  Loader2
} from 'lucide-react';
import { motion } from 'motion/react';
import { Link } from 'react-router';
import type { Activity } from "~/types/activity";

import { 
  AreaChart, 
  Area, 
  XAxis, 
  YAxis, 
  CartesianGrid, 
  Tooltip, 
  ResponsiveContainer
} from 'recharts';

export default function DashboardPage() {
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [range, setRange] = useState('7days');

  useEffect(() => {
    const fetchStats = async () => {
      try {
        const response = await api.get(`/dashboard-stats?range=${range}`);
        if (response.data.success) {
          setStats(response.data.data);
        }
      } catch (error) {
        console.error("Failed to fetch dashboard stats:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchStats();
  }, [range]);

  if (loading && !stats) {
    return (
      <AuthGuard>
        <div className="flex items-center justify-center min-h-[60vh] w-full">
          <div className="flex flex-col items-center gap-3">
            <Loader2 className="w-10 h-10 text-blue-500 animate-spin" />
            <p className="text-slate-500 font-medium">Memuat data dashboard...</p>
          </div>
        </div>
      </AuthGuard>
    );
  }

  const summaryCards = [
    {
      title: "Total Mahasiswa",
      value: stats?.summary?.total_mahasiswa?.toLocaleString() || "0",
      icon: Users,
      color: "bg-blue-500 text-white",
      trend: stats?.summary?.trends?.mahasiswa || "Stabil",
      trendIcon: TrendingUp,
      trendColor: "text-emerald-500",
    },
    {
      title: "Total Dosen",
      value: stats?.summary?.total_dosen?.toLocaleString() || "0",
      icon: GraduationCap,
      color: "bg-indigo-500 text-white",
      trend: stats?.summary?.trends?.dosen || "Steady",
      trendIcon: ArrowUpRight,
      trendColor: "text-blue-500",
    },
    {
      title: "Total Kelas Aktif",
      value: stats?.summary?.total_kelas_aktif?.toLocaleString() || "0",
      icon: Building2,
      color: "bg-emerald-500 text-white",
      trend: stats?.summary?.trends?.kelas || "Steady",
      trendIcon: TrendingUp,
      trendColor: "text-slate-400",
    },
    {
      title: "Total Pertemuan",
      value: stats?.summary?.total_pertemuan?.toLocaleString() || "0",
      icon: Calendar,
      color: "bg-violet-500 text-white",
      trend: stats?.summary?.trends?.pertemuan || "Steady",
      trendIcon: ArrowUpRight,
      trendColor: "text-emerald-500",
    },
  ];

  const recentActivity: Activity[] = stats?.recent_activities || [];

  // Format data for Recharts
  const chartData = stats?.statistics?.labels?.map((label: string, index: number) => ({
    name: label,
    value: stats.statistics.data[index]
  })) || [];

  return (
    <AuthGuard>
      <div className="flex flex-col gap-6 w-full">
        {/* SUMMARY CARDS */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
          {summaryCards.map((card, idx) => {
            const Icon = card.icon;
            const TrendIcon = card.trendIcon;

            return (
              <motion.div
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.1, duration: 0.4 }}
                key={idx}
                className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col hover:shadow-md transition-shadow relative overflow-hidden group"
              >
                <div className="flex justify-between items-start mb-4 relative z-10">
                  <div className={`p-3 rounded-xl ${card.color} shadow-sm`}>
                    <Icon className="w-6 h-6" />
                  </div>
                </div>

                <div className="relative z-10">
                  <h3 className="text-slate-500 text-sm font-medium">
                    {card.title}
                  </h3>
                  <p className="text-3xl font-bold text-slate-800 mt-1">
                    {card.value}
                  </p>
                </div>

                <div className="mt-4 flex items-center gap-1.5 text-xs font-medium relative z-10">
                  <TrendIcon className={`w-4 h-4 ${card.trendColor}`} />
                  <span className={card.trendColor}>{card.trend}</span>
                </div>

                {/* Decorative Background */}
                <div className="absolute -right-6 -bottom-6 w-32 h-32 rounded-full bg-slate-50 opacity-0 group-hover:opacity-100 transition-opacity blur-2xl z-0" />
              </motion.div>
            );
          })}
        </div>

        {/* RECENT ACTIVITY & CHARTS */}
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.4, duration: 0.4 }}
            className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col min-h-100"
          >
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-lg font-semibold text-slate-800">
                Statistik Absensi
              </h2>
              <select 
                value={range}
                onChange={(e) => setRange(e.target.value)}
                className="bg-slate-50 border border-slate-200 text-slate-600 text-sm rounded-lg focus:ring-blue-500 focus:border-blue-500 block p-2 outline-none"
              >
                <option value="7days">7 Hari Terakhir</option>
                <option value="month">30 Hari Terakhir</option>
                <option value="semester">6 Bulan Terakhir</option>
              </select>
            </div>

            <div className="flex-1 w-full h-75">
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={chartData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
                  <defs>
                    <linearGradient id="colorValue" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#3b82f6" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#3b82f6" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
                  <XAxis 
                    dataKey="name" 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{ fill: '#94a3b8', fontSize: 12 }}
                    dy={10}
                  />
                  <YAxis 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{ fill: '#94a3b8', fontSize: 12 }}
                  />
                  <Tooltip 
                    contentStyle={{ 
                      borderRadius: '12px', 
                      border: 'none', 
                      boxShadow: '0 4px 6px -1px rgb(0 0 0 / 0.1)',
                      fontSize: '12px'
                    }} 
                  />
                  <Area 
                    type="monotone" 
                    dataKey="value" 
                    stroke="#3b82f6" 
                    strokeWidth={3}
                    fillOpacity={1} 
                    fill="url(#colorValue)" 
                    animationDuration={1500}
                  />
                </AreaChart>
              </ResponsiveContainer>
            </div>
          </motion.div>

          <motion.div
            initial={{ opacity: 0, y: 20 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5, duration: 0.4 }}
            className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col"
          >
            <div className="flex justify-between items-center mb-6">
              <h2 className="text-lg font-semibold text-slate-800">
                Aktivitas Terbaru
              </h2>
              <Link to="/admin/activity-logs" className="text-blue-600 text-sm font-medium hover:text-blue-700">
                Lihat Semua
              </Link>
            </div>

            <div className="flex flex-col gap-5 relative">
              <div className="absolute left-3.5 top-2 bottom-2 w-px bg-slate-100" />

              {recentActivity.map((activity: Activity, idx: number) => (
                <div
                  key={activity.id}
                  className="flex gap-4 relative z-10 group"
                >
                  <div className="relative mt-1">
                    <div
                      className={`w-7 h-7 rounded-full flex items-center justify-center border-2 border-white ring-4 ring-slate-50 group-hover:ring-blue-50 transition-all ${
                        activity.status === "success"
                          ? "bg-emerald-100 text-emerald-600"
                          : activity.status === "warning"
                            ? "bg-amber-100 text-amber-600"
                            : "bg-blue-100 text-blue-600"
                      }`}
                    >
                      {activity.status === "success" && (
                        <div className="w-2 h-2 rounded-full bg-emerald-500" />
                      )}
                      {activity.status === "warning" && (
                        <div className="w-2 h-2 rounded-full bg-amber-500" />
                      )}
                      {activity.status === "info" && (
                        <div className="w-2 h-2 rounded-full bg-blue-500" />
                      )}
                    </div>
                  </div>
                  <div>
                    <p className="text-sm font-semibold text-slate-800">
                      {activity.action}
                    </p>
                    <p className="text-xs text-slate-500 mt-0.5">
                      {activity.detail}
                    </p>
                    <div className="flex items-center gap-1.5 mt-1 text-[10px] font-medium text-slate-400">
                      <Clock className="w-3 h-3" />
                      {activity.time}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          </motion.div>
        </div>
      </div>
    </AuthGuard>
  );
}
