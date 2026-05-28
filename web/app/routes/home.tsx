import { useEffect } from "react";
import { Link, useNavigate } from "react-router";
import { isAuthenticated } from "~/lib/auth";

export function meta() {
  return [
    { title: "SIAM | Digital Campus Experience" },
    { name: "description", content: "Sistem Informasi Akademik Mahasiswa dalam genggaman Anda." },
  ];
}

export default function Home() {
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuthenticated()) {
      navigate("/admin/dashboard");
    }
  }, [navigate]);

  return (
    <div className="min-h-screen bg-linear-to-br from-blue-600 via-indigo-700 to-violet-800 flex flex-col items-center justify-center p-6 text-white overflow-hidden relative">
      {/* Decorative Elements */}
      <div className="absolute top-[-10%] right-[-10%] w-64 h-64 bg-white/10 rounded-full blur-3xl animate-pulse"></div>
      <div className="absolute bottom-[-5%] left-[-10%] w-80 h-80 bg-blue-400/20 rounded-full blur-3xl animate-pulse delay-700"></div>

      <main className="max-w-md w-full flex flex-col items-center text-center space-y-8 relative z-10">
        {/* Logo / Icon Placeholder */}
        <div className="w-24 h-24 bg-white rounded-3xl flex items-center justify-center shadow-2xl rotate-12 transition-transform hover:rotate-0 duration-500">
          <span className="text-blue-600 text-5xl font-black italic">S</span>
        </div>

        <div className="space-y-4">
          <h1 className="text-4xl md:text-5xl font-black tracking-tight drop-shadow-lg">
            SIAM <span className="text-blue-200">Mobile</span>
          </h1>
          <p className="text-lg text-blue-100/90 font-medium leading-relaxed max-w-70 mx-auto">
            Sistem Informasi Akademik Mahasiswa dalam genggaman Anda.
          </p>
        </div>

        <div className="flex flex-col w-full gap-4 pt-10">
          <Link
            to="/login"
            className="w-full bg-white text-blue-700 font-bold py-4 rounded-2xl shadow-xl hover:bg-blue-50 active:scale-95 transition-all flex items-center justify-center text-lg group"
          >
            Mulai Sekarang
            <svg
              className="w-5 h-5 ml-2 group-hover:translate-x-1 transition-transform"
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth={2}
                d="M13 7l5 5m0 0l-5 5m5-5H6"
              />
            </svg>
          </Link>
          
          <p className="text-sm text-blue-200/60 font-medium">
            Versi 1.0.0 • Digital Campus Experience
          </p>
        </div>
      </main>

      {/* Footer Branding */}
      <footer className="absolute bottom-8 text-white/40 text-xs font-semibold tracking-widest uppercase">
        Powered by SIAM IT Support
      </footer>
    </div>
  );
}
