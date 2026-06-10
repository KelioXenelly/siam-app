import { useEffect } from "react";
import { useNavigate } from "react-router";
import { isAuthenticated } from "~/lib/auth";

export function meta() {
  return [
    { title: "SIAM | Digital Campus Experience" },
    { name: "description", content: "Sistem Informasi Absensi Mahasiswa dalam genggaman Anda." },
  ];
}

export default function Home() {
  const navigate = useNavigate();

  useEffect(() => {
    if (isAuthenticated()) {
      navigate("/admin/dashboard", { replace: true });
    } else {
      navigate("/login", { replace: true });
    }
  }, [navigate]);

  return (
    <div className="min-h-screen bg-linear-to-br from-blue-600 via-indigo-700 to-violet-800 flex items-center justify-center">
      <div className="w-12 h-12 border-4 border-white/20 border-t-white rounded-full animate-spin"></div>
    </div>
  );
}
