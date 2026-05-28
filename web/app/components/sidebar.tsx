import React from 'react';
import { 
  LayoutDashboard, 
  Users, 
  GraduationCap, 
  BookOpen, 
  Building2, 
  Calendar, 
  LogOut,
  History
} from 'lucide-react';
import { motion } from 'motion/react';
import { NavLink, useLocation, useNavigate } from 'react-router';
import { logout } from '~/lib/auth';
import { useAuth } from '~/context/auth_context';

export default function Sidebar({ isOpen, onClose }: { isOpen?: boolean; onClose?: () => void }) {
  const { user, isLoading } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  if (isLoading || !user) {
    return (
      <aside className={`fixed lg:relative inset-y-0 left-0 w-64 bg-slate-900 text-slate-300 flex flex-col shrink-0 z-50 shadow-xl transition-transform duration-300 ease-in-out lg:translate-x-0 ${isOpen ? "translate-x-0" : "-translate-x-full"}`}>
        <div className="h-16 flex items-center px-6 border-b border-slate-800">
          <div className="flex items-center gap-2 text-white font-bold text-xl tracking-tight">
            <div className="w-8 h-8 rounded-lg bg-blue-600/50 animate-pulse"></div>
            <div className="w-16 h-4 bg-slate-800 rounded animate-pulse"></div>
          </div>
        </div>
        <div className="flex-1 py-6 px-4 space-y-2">
          {[...Array(7)].map((_, i) => (
            <div key={i} className="h-10 bg-slate-800/50 rounded-xl w-full animate-pulse"></div>
          ))}
        </div>
      </aside>
    );
  }

  const menuItems = [
    { name: 'Dashboard', path: `/${user.role}/dashboard`, icon: LayoutDashboard },
    { name: 'Program Studi', path: `/${user.role}/program-studi`, icon: GraduationCap },
    { name: 'Ruangan', path: `/${user.role}/ruangan`, icon: Building2 },
    { name: 'Users', path: `/${user.role}/users`, icon: Users },
    { name: 'Mata Kuliah', path: `/${user.role}/mata-kuliah`, icon: BookOpen },
    { name: 'Kelas', path: `/${user.role}/kelas`, icon: Building2 },
    { name: 'Pertemuan', path: `/${user.role}/pertemuan`, icon: Calendar },
    { name: 'Log Aktivitas', path: `/${user.role}/activity-logs`, icon: History },
  ];

  const handleLogout = () => {
    logout();
    navigate('/login');
  }

  return (
    <>
      {isOpen && (
        <div 
          className="fixed inset-0 bg-slate-900/50 backdrop-blur-sm z-40 lg:hidden"
          onClick={onClose}
        />
      )}
      <aside className={`fixed lg:relative inset-y-0 left-0 w-64 bg-slate-900 text-slate-300 flex flex-col shrink-0 z-50 shadow-xl transition-transform duration-300 ease-in-out lg:translate-x-0 ${isOpen ? "translate-x-0" : "-translate-x-full"}`}>
      <div className="h-16 flex items-center px-6 border-b border-slate-800">
        <div className="flex items-center gap-2 text-white font-bold text-xl tracking-tight">
          <div className="w-8 h-8 rounded-lg bg-blue-600 flex items-center justify-center">
            <span className="text-white text-sm">S</span>
          </div>
          SIAM
        </div>
      </div>

      <div className="flex-1 py-6 px-4 overflow-y-auto flex flex-col gap-1">
        <div className="text-xs font-semibold text-slate-500 uppercase tracking-wider mb-2 px-2">
          Menu Utama
        </div>
        {menuItems.map((item) => {
          const isActive = location.pathname === item.path;
          const Icon = item.icon;

          return (
            <NavLink
              key={item.path}
              to={item.path}
              onClick={onClose}
              className={({ isActive }) => `
                  flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium transition-all duration-200 group relative
                  ${
                    isActive
                      ? "text-white bg-blue-600/10"
                      : "hover:text-white hover:bg-slate-800"
                  }
                `}
            >
              {isActive && (
                <motion.div
                  layoutId="sidebar-active"
                  className="absolute inset-0 bg-blue-600 rounded-lg -z-10"
                  transition={{ type: "spring", stiffness: 300, damping: 30 }}
                />
              )}
              <Icon
                className={`w-5 h-5 ${isActive ? "text-white" : "text-slate-400 group-hover:text-slate-300"}`}
              />
              {item.name}
            </NavLink>
          );
        })}
      </div>

      <div className="p-4 border-t border-slate-800">
        <button
          onClick={handleLogout}
          className="flex items-center gap-3 px-3 py-2.5 rounded-lg text-sm font-medium text-slate-400 hover:text-white hover:bg-slate-800 w-full transition-colors"
        >
          <LogOut className="w-5 h-5" />
          Logout
        </button>
      </div>
    </aside>
    </>
  );
}
