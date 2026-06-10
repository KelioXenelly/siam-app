import { type RouteConfig, index, route } from "@react-router/dev/routes";

export default [
  index("./routes/home.tsx"),
  route("login", "routes/auth/login.tsx"),
  
  route("admin", "layouts/admin_layout.tsx", [
    route("dashboard", "routes/admin/dashboard.tsx"),
    route("program-studi", "routes/admin/program_studi.tsx"),
    route("ruangan", "routes/admin/ruangan.tsx"),
    route("users", "routes/admin/users.tsx"),
    route("mata-kuliah", "routes/admin/mata_kuliah.tsx"),
    route("kelas", "routes/admin/kelas.tsx"),
    route("pertemuan", "routes/admin/pertemuan.tsx"),
    route("activity-logs", "routes/admin/activity_logs.tsx"),
  ])
] satisfies RouteConfig;
