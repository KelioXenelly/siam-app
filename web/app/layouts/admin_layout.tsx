import { useState } from 'react';
import { Outlet } from 'react-router';
import Sidebar from '~/components/sidebar';
import Navbar from '~/components/navbar';

export default function AdminLayout() {
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

  return (
    <div className="flex h-screen w-full bg-[#F8FAFC] overflow-hidden font-sans text-slate-800 selection:bg-blue-100 relative">
      {/* LEFT SIDEBAR */}
      <Sidebar isOpen={isMobileMenuOpen} onClose={() => setIsMobileMenuOpen(false)} />

      {/* RIGHT CONTENT */}
      <div className="flex-1 flex flex-col min-w-0 h-screen overflow-hidden">
        {/* TOP NAVBAR */}
        <Navbar onMenuClick={() => setIsMobileMenuOpen(true)} />

        {/* MAIN CONTENT AREA */}
        <main className="flex-1 overflow-y-auto p-4 md:p-8 relative scroll-smooth">
          <div className="max-w-7xl mx-auto min-h-full flex flex-col">
            <div className="flex-1">
              <Outlet />
            </div>

            {/* FOOTER */}
            <footer className="mt-12 pt-6 pb-2 border-t border-slate-200/60 flex flex-col sm:flex-row items-center justify-between gap-4">
              <p className="text-sm font-medium text-slate-500">
                &copy; {new Date().getFullYear()} SIAM Admin. Hak Cipta Dilindungi.
              </p>
              <div className="flex items-center gap-4 text-sm font-medium text-slate-400">
                <span className="hover:text-slate-600 transition-colors cursor-pointer">Bantuan</span>
                <span className="hover:text-slate-600 transition-colors cursor-pointer">Privasi</span>
                <span className="w-1 h-1 rounded-full bg-slate-300"></span>
                <span>v1.0.0</span>
              </div>
            </footer>
          </div>
        </main>
      </div>
    </div>
  );
}
