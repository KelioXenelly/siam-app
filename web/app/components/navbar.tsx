import { Search, Bell, ChevronDown, LogOut, Menu } from "lucide-react";
import { motion, AnimatePresence } from "motion/react";
import { useState } from "react";
import { useLocation, useNavigate } from "react-router";
import { toast } from "sonner";
import { API_HOST } from '~/lib/api';
import { useAuth } from "~/context/auth_context";
import { logout } from "~/lib/auth";

export default function Navbar({ onMenuClick }: { onMenuClick?: () => void }) {
  const { user, isLoading } = useAuth();
  const navigate = useNavigate();
  const location = useLocation();
  const [isProfileOpen, setIsProfileOpen] = useState(false);

  const getPageTitle = () => {
    const path = location.pathname;
    if (path === "/admin/dashboard") return "Dashboard";
    if (path === "/admin/program-studi") return "Manajemen Program Studi";
    if (path === "/admin/ruangan") return "Manajemen Ruangan";
    if (path === "/admin/users") return "Manajemen Pengguna";
    if (path === "/admin/mata-kuliah") return "Manajemen Mata Kuliah";
    if (path === "/admin/kelas") return "Manajemen Kelas";
    if (path === "/admin/pertemuan") return "Manajemen Pertemuan";
    if (path === "/admin/activity-logs") return "Log Aktivitas";
    return "Admin Panel";
  };

  const handleLogout = () => {
    logout();
    navigate("/login");
    toast.success("Logout berhasil, sampai jumpa lagi! 👋")
  };

  return (
    <header className="h-16 bg-white border-b border-slate-200 flex items-center justify-between px-4 sm:px-8 shrink-0 z-10">
      <div className="flex items-center gap-3">
        <button
          className="p-2 -ml-2 text-slate-500 hover:text-slate-700 lg:hidden"
          onClick={onMenuClick}
        >
          <Menu className="w-6 h-6" />
        </button>
        <h1 className="text-xl font-semibold text-slate-800 hidden sm:block">{getPageTitle()}</h1>
        <h1 className="text-lg font-semibold text-slate-800 sm:hidden">SIAM</h1>
      </div>

      <div className="flex items-center gap-4 sm:gap-6 relative">
        <button
          className="flex items-center gap-3 hover:opacity-80 transition-opacity"
          onClick={() => !isLoading && setIsProfileOpen(!isProfileOpen)}
        >
          {isLoading ? (
            <>
              <div className="w-8 h-8 rounded-full bg-slate-200 animate-pulse shrink-0" />
              <div className="text-left hidden md:block">
                <div className="h-4 w-24 bg-slate-200 rounded animate-pulse mb-1" />
                <div className="h-3 w-16 bg-slate-200 rounded animate-pulse" />
              </div>
              <ChevronDown className="w-4 h-4 text-slate-300" />
            </>
          ) : (
            <>
              <div className="w-8 h-8 rounded-full bg-indigo-100 flex items-center justify-center border border-indigo-200 overflow-hidden shrink-0">
                {user?.avatar ? (
                  <img src={`${API_HOST}${user.avatar}`} alt={user.name} className="w-full h-full object-cover" />
                ) : (
                  <span className="text-indigo-600 font-bold text-sm">
                    {user ? user.name.charAt(0).toUpperCase() : "A"}
                  </span>
                )}
              </div>
              <div className="text-left hidden md:block">
                <p className="text-sm font-medium text-slate-700 leading-tight">
                  {user?.name}
                </p>
                <p className="text-xs text-slate-500">
                  {user?.role ? user.role.charAt(0).toUpperCase() + user.role.slice(1) : ""}
                </p>
              </div>
              <ChevronDown
                className={`w-4 h-4 text-slate-400 transition-transform ${isProfileOpen ? "rotate-180" : ""}`}
              />
            </>
          )}
        </button>

        <AnimatePresence>
          {isProfileOpen && (
            <>
              <div
                className="fixed inset-0 z-40"
                onClick={() => setIsProfileOpen(false)}
              />
              <motion.div
                initial={{ opacity: 0, y: 10, scale: 0.95 }}
                animate={{ opacity: 1, y: 0, scale: 1 }}
                exit={{ opacity: 0, y: 10, scale: 0.95 }}
                transition={{ duration: 0.15 }}
                className="absolute right-0 top-full mt-2 w-48 bg-white rounded-xl shadow-lg border border-slate-100 z-50 overflow-hidden"
              >
                <div className="p-2">
                  <button
                    onClick={handleLogout}
                    className="w-full flex items-center gap-2 px-3 py-2 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors font-medium"
                  >
                    <LogOut className="w-4 h-4" />
                    Logout
                  </button>
                </div>
              </motion.div>
            </>
          )}
        </AnimatePresence>
      </div>
    </header>
  );
}
