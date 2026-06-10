import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";

export function meta() {
  return [
    { title: "Manajemen Pengguna | SIAM Admin" },
    { name: "description", content: "Kelola data pengguna SIAM." },
  ];
}
import {
  Plus,
  Search,
  MoreVertical,
  Edit,
  Trash2,
  Eye,
  UserPlus,
  Shield,
  GraduationCap,
  X,
  Check,
  Users,
  Loader2 } from "lucide-react";
import api from "~/lib/api";
import type { User } from "~/types/user";
import type { Role } from "~/types/role";
import type { Prodi } from "~/types/prodi";
import { toast } from "sonner";
import { useServerTable } from "~/hooks/useServerTable";
import { useAuth } from "~/context/auth_context";
import { SkeletonTable } from "~/components/ui/skeleton_table";
import { EmptyState } from "~/components/ui/empty_state";
import { Pagination, SortableHeader } from "~/components/table_features";

export default function UsersPage() {
  const { user: currentUser, refreshUser } = useAuth();
  const [prodis, setProdis] = useState<Prodi[]>([]);
  const [filterRole, setFilterRole] = useState<Role | "all">("all");

  // Modal states
  const [isSaving, setIsSaving] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<
    "create" | "edit" | "view" | "delete"
  >("create");
  const [selectedUser, setSelectedUser] = useState<User | null>(null);

  // Form states
  const [formData, setFormData] = useState<Partial<User>>({});
  const [avatarFile, setAvatarFile] = useState<File | null>(null);
  const [avatarPreview, setAvatarPreview] = useState<string | null>(null);


  const {
    currentData,
    currentPage,
    setCurrentPage,
    totalPages,
    totalItems,
    itemsPerPage,
    setItemsPerPage,
    searchTerm,
    setSearchTerm,
    sortConfig,
    requestSort,
    isLoading,
    refreshData
  } = useServerTable<User>("/users", 10);


  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1); // ❗ reset biar gak out of range
  };

  const handleOpenModal = (
    mode: "create" | "edit" | "view" | "delete",
    user?: User,
  ) => {
    setModalMode(mode);
    console.log("Opening modal in mode:", mode, "with user:", user);
    if (user) {
      setSelectedUser(user);
      setAvatarFile(null);
      setAvatarPreview(user.avatar ? `http://127.0.0.1:8000${user.avatar}` : null);
      setFormData({
        ...user,
        nim_nidn: user.mahasiswa?.nim || user.dosen?.nidn || "",
        prodi_id: user.mahasiswa?.prodi_id,
        angkatan: user.mahasiswa?.angkatan || "",
      });
    } else {
      setSelectedUser(null);
      setAvatarFile(null);
      setAvatarPreview(null);
      setFormData({ role: "mahasiswa", is_active: true });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedUser(null);
    setFormData({});
    setAvatarFile(null);
    setAvatarPreview(null);
  };

  
  // Close modal on Escape
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === "Escape" && isModalOpen) {
        handleCloseModal();
      }
    };
    window.addEventListener("keydown", handleKeyDown);
    return () => window.removeEventListener("keydown", handleKeyDown);
  }, [isModalOpen]);

  const handleSave = async () => {
    setIsSaving(true);
    // Ambil role dan nilai input nim_nidn dari form
    const role = (formData.role as Role) || "mahasiswa";
    const inputNimNidn = formData.nim_nidn || "";

    if (modalMode === "create") {
      const newUser = {
        name: formData.name || "",
        email: formData.email || "",
        role: role,
        nim: role === "mahasiswa" ? inputNimNidn : null,
        nidn: role === "dosen" ? inputNimNidn : null,
        prodi_id: role === "mahasiswa" ? formData.prodi_id || null : null,
        angkatan: role === "mahasiswa" ? formData.angkatan || null : null,
      };

      try {
        const res = await api.post("/register", newUser);
        let createdUser = res.data.data;

        if (avatarFile) {
          const formDataAvatar = new FormData();
          formDataAvatar.append("avatar", avatarFile);
          try {
            const resAvatar = await api.post(`/users/${createdUser.id}/avatar`, formDataAvatar, {
              headers: { "Content-Type": "multipart/form-data" },
            });
            createdUser = resAvatar.data.data;
          } catch (err) {
            toast.error("Pengguna dibuat, tapi gagal mengunggah avatar.");
          }
        }

        await refreshData();
        toast.success(res.data.message || "Pengguna baru berhasil dibuat!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.email) {
          toast.error("Email sudah digunakan");
        } else if (errors?.nim) {
          toast.error("NIM sudah digunakan");
        } else if (errors?.nidn) {
          toast.error("NIDN sudah digunakan");
        } else {
          toast.error("Gagal membuat pengguna baru.");
        }
      }
    } else if (modalMode === "edit" && selectedUser) {
      const updatedUser = {
        ...selectedUser,
        name: formData.name || selectedUser.name,
        email: formData.email || selectedUser.email,
        role: formData.role || selectedUser.role,
        nim: role === "mahasiswa" ? inputNimNidn : null,
        nidn: role === "dosen" ? inputNimNidn : null,
        prodi_id:
          role === "mahasiswa"
            ? formData.prodi_id : undefined,
        angkatan:
          role === "mahasiswa"
            ? formData.angkatan || selectedUser.mahasiswa?.angkatan || null
            : null,
        is_active: formData.is_active,
        password: formData.password || undefined, // Hanya kirim password jika diisi
      };

      try {
        const res = await api.put(`/users/${selectedUser.id}`, updatedUser);
        let updatedUserFromServer = res.data.data;

        if (avatarFile) {
          const formDataAvatar = new FormData();
          formDataAvatar.append("avatar", avatarFile);
          try {
            const resAvatar = await api.post(`/users/${selectedUser.id}/avatar`, formDataAvatar, {
              headers: { "Content-Type": "multipart/form-data" },
            });
            updatedUserFromServer = resAvatar.data.data;
          } catch (err) {
            toast.error("Pengguna diperbarui, tapi gagal mengunggah avatar.");
          }
        }

        await refreshData();
        toast.success(res.data.message || "Pengguna berhasil diperbarui!");

        if (currentUser?.id === selectedUser.id) {
          refreshUser();
        }
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.email) {
          toast.error("Email sudah digunakan");
        } else if (errors?.nim) {
          toast.error("NIM sudah digunakan");
        } else if (errors?.nidn) {
          toast.error("NIDN sudah digunakan");
        } else {
          toast.error(errors || "Gagal memperbarui pengguna.");
        }
      }
    }
    handleCloseModal();
    setIsSaving(false);
  };

  const handleDelete = async (id: number) => {
    if (!selectedUser) return;

    try {
      const res = await api.delete(`/users/${id}`);
      await refreshData();
      toast.success(res.data.message || "Pengguna berhasil dihapus!");
      handleCloseModal();
    } catch (error: any) {
      const errors = error.response?.data?.errors;

      toast.error(errors || "Gagal menghapus pengguna.");
    }
  };

  const getRoleBadge = (role: Role) => {
    switch (role) {
      case "admin":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-purple-100 text-purple-700 border border-purple-200">
            <Shield className="w-3.5 h-3.5" /> Admin
          </span>
        );
      case "dosen":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 border border-blue-200">
            <GraduationCap className="w-3.5 h-3.5" /> Dosen
          </span>
        );
      case "mahasiswa":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700 border border-emerald-200">
            <UserPlus className="w-3.5 h-3.5" /> Mahasiswa
          </span>
        );
    }
  };


  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            Manajemen Pengguna
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Kelola data seluruh pengguna sistem: Admin, Dosen, dan Mahasiswa.
          </p>
        </div>

        <button
          onClick={() => handleOpenModal("create")}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Tambah Pengguna</span>
        </button>
      </div>

      {/* Filters & Search */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama, NIM/NIP, atau email..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
          />
        </div>
        <div className="flex gap-2 shrink-0">
          {(["all", "mahasiswa", "dosen", "admin"] as const).map((role) => (
            <button
              key={role}
              onClick={() => setFilterRole(role)}
              className={`px-4 py-2.5 rounded-xl text-sm font-medium capitalize transition-all ${
                filterRole === role
                  ? "bg-slate-800 text-white shadow-sm"
                  : "bg-slate-50 text-slate-600 border border-slate-200 hover:bg-slate-100"
              }`}
            >
              {role === "all" ? "Semua Role" : role}
            </button>
          ))}
        </div>
      </div>

      {/* Users Table */}
      <div className="bg-white border border-slate-200 rounded-2xl shadow-sm flex-1 overflow-hidden flex flex-col">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/50">
                <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-12">
                  No
                </th>
                <SortableHeader
                  label="Informasi Pengguna"
                  sortKey="name"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Role"
                  sortKey="role"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="NIM / NIDN"
                  sortKey="nim_nidn"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Status"
                  sortKey="is_active"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Aksi
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {isLoading ? (
                <SkeletonTable columns={6} rows={5} />
              ) : currentData.length === 0 ? (
                <EmptyState 
                  title="Data Kosong"
                  description="Belum ada data yang ditemukan. Silakan tambahkan data baru atau sesuaikan pencarian."
                  colSpan={6}
                />
              ) : (
                currentData.map((user, index) => (
                  <tr
                    key={user.id}
                    className="hover:bg-slate-50/50 transition-colors group"
                  >
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {index + 1}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-9 h-9 rounded-full bg-slate-100 border border-slate-200 overflow-hidden flex items-center justify-center shrink-0">
                          {user.avatar ? (
                            <img src={`http://127.0.0.1:8000${user.avatar}`} alt={user.name} className="w-full h-full object-cover" />
                          ) : (
                            <span className="text-sm font-bold text-slate-500">
                              {user.name.charAt(0).toUpperCase()}
                            </span>
                          )}
                        </div>
                        <div className="flex flex-col">
                          <span className="font-medium text-slate-900">
                            {user.name}
                          </span>
                          <span className="text-sm text-slate-500">
                            {user.email}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">{getRoleBadge(user.role)}</td>
                    <td className="px-6 py-4 text-sm font-medium text-slate-700">
                      {user.mahasiswa?.nim || user.dosen?.nidn || "-"}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${
                          user.is_active == true
                            ? "bg-green-50 text-green-700 border-green-200"
                            : "bg-slate-100 text-slate-600 border-slate-200"
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${user.is_active == true ? "bg-green-500" : "bg-slate-400"}`}
                        ></span>
                        {user.is_active == true ? "Aktif" : "Nonaktif"}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-start gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => handleOpenModal("view", user)}
                          className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Detail"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("edit", user)}
                          className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("delete", user)}
                          className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg transition-colors"
                          title="Hapus"
                        >
                          <Trash2 className="w-4 h-4" />
                        </button>
                      </div>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
        <Pagination
          currentPage={currentPage}
          totalPages={totalPages}
          onPageChange={setCurrentPage}
          totalItems={totalItems}
          itemsPerPage={itemsPerPage}
          onItemsPerPageChange={handleItemsPerPageChange}
        />
      </div>

      {/* Modal CRUD */}
      <AnimatePresence>
        {isModalOpen && modalMode !== "delete" && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-0">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={handleCloseModal}
              className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="relative bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden border border-slate-100"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50/50">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center">
                    <Users className="w-4 h-4" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">
                    {modalMode === "create"
                      ? "Tambah Pengguna Baru"
                      : modalMode === "edit"
                        ? "Edit Pengguna"
                        : "Detail Pengguna"}
                  </h3>
                </div>
                <button
                  onClick={handleCloseModal}
                  className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg transition-colors"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5 sm:col-span-2 flex items-center gap-4">
                    <div className="w-16 h-16 rounded-full bg-slate-100 border border-slate-200 overflow-hidden flex items-center justify-center shrink-0">
                      {avatarPreview ? (
                        <img src={avatarPreview} alt="Preview" className="w-full h-full object-cover" />
                      ) : (
                        <span className="text-2xl font-bold text-slate-400">
                          {formData.name ? formData.name.charAt(0).toUpperCase() : "?"}
                        </span>
                      )}
                    </div>
                    <div className="flex-1">
                      <label className="text-sm font-medium text-slate-700">Foto Profil (Opsional)</label>
                      <input
                        type="file"
                        accept="image/png, image/jpeg, image/webp"
                        onChange={(e) => {
                          const file = e.target.files?.[0];
                          if (file) {
                            setAvatarFile(file);
                            setAvatarPreview(URL.createObjectURL(file));
                          }
                        }}
                        disabled={modalMode === "view"}
                        className="w-full mt-1 px-3 py-1.5 text-sm bg-slate-50 border border-slate-200 rounded-xl file:mr-4 file:py-1.5 file:px-3 file:rounded-lg file:border-0 file:text-sm file:font-semibold file:bg-blue-50 file:text-blue-700 hover:file:bg-blue-100 disabled:opacity-70"
                      />
                    </div>
                  </div>

                  <div className="space-y-1.5 sm:col-span-2">
                    <label className="text-sm font-medium text-slate-700">
                      Nama Lengkap <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.name || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, name: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                      placeholder="Masukkan nama lengkap"
                      required
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Role <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={formData.role || "mahasiswa"}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          role: e.target.value as Role,
                        })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100 capitalize"
                    >
                      <option value="mahasiswa">Mahasiswa</option>
                      <option value="dosen">Dosen</option>
                      <option value="admin">Admin</option>
                    </select>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      NIM / NIDN <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.nim_nidn || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, nim_nidn: e.target.value })
                      }
                      disabled={
                        modalMode === "view" || formData.role === "admin"
                      }
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                      placeholder={
                        formData.role === "mahasiswa"
                          ? "NIM..."
                          : formData.role === "dosen"
                            ? "NIDN..."
                            : "-"
                      }
                    />
                  </div>

                  <div className="space-y-1.5 sm:col-span-2">
                    <label className="text-sm font-medium text-slate-700">
                      Email <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="email"
                      value={formData.email || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, email: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                      placeholder="email@univ.ac.id"
                    />
                  </div>

                  {formData.role === "mahasiswa" && (
                    <>
                      <div className="space-y-1.5">
                        <label className="text-sm font-medium text-slate-700">
                          Prodi <span className="text-red-500">*</span>
                        </label>
                        {prodis.length > 0 && (
                          <select
                            value={formData.prodi_id || ""}
                            onChange={(e) =>
                              setFormData({
                                ...formData,
                                prodi_id: Number(e.target.value),
                              })
                            }
                            disabled={modalMode === "view"}
                            className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100 capitalize"
                          >
                            <option value="">-- Pilih Prodi --</option>
                            {prodis.map((prodi) => (
                              <option key={prodi.id} value={prodi.id}>
                                {prodi.nama_prodi}
                              </option>
                            ))}
                          </select>
                        )}
                      </div>

                      <div className="space-y-1.5">
                        <label className="text-sm font-medium text-slate-700">
                          Angkatan <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="text"
                          value={formData.angkatan || ""}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              angkatan: e.target.value,
                            })
                          }
                          disabled={modalMode === "view"}
                          className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                          placeholder="Angkatan..."
                        />
                      </div>
                    </>
                  )}

                  {modalMode !== "create" && (
                    <>
                      <div className="space-y-1.5">
                        <label className="text-sm font-medium text-slate-700">
                          Status <span className="text-red-500">*</span>
                        </label>
                        <select
                          value={formData.is_active ? "true" : "false"}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              // 2. Ubah kembali string dari dropdown menjadi boolean untuk disimpan ke state
                              // Jika e.target.value adalah "true", maka is_active akan bernilai boolean true
                              is_active: e.target.value === "true",
                            })
                          }
                          disabled={modalMode === "view"}
                          className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                        >
                          <option value="true">Aktif</option>
                          <option value="false">Nonaktif</option>
                        </select>
                      </div>
                      <div
                        className="space-y-1.5"
                        hidden={modalMode === "view"}
                      >
                        <label className="text-sm font-medium text-slate-700">
                          Password
                        </label>
                        <input
                          type="password"
                          value={formData.password || ""}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              password: e.target.value,
                            })
                          }
                          disabled={modalMode === "view"}
                          className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                          placeholder={
                            modalMode === "edit" ? "Password baru" : "-"
                          }
                        />
                      </div>
                    </>
                  )}
                </div>
              </div>

              <div className="px-6 py-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-end gap-3">
                <button
                  onClick={handleCloseModal}
                  className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition-colors"
                >
                  {modalMode === "view" ? "Tutup" : "Batal"}
                </button>
                {modalMode !== "view" && (
                  <button
                    onClick={handleSave}
                    disabled={isSaving}
                    className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm disabled:opacity-70"
                  >
                    {isSaving ? <Loader2 className="w-4 h-4 animate-spin" /> : <Check className="w-4 h-4" />}
                    <span>{isSaving ? "Menyimpan..." : "Simpan Data"}</span>
                  </button>
                )}
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* Delete Confirmation Modal */}
      <AnimatePresence>
        {isModalOpen && modalMode === "delete" && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
            {/* BACKDROP */}
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={handleCloseModal}
              className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
            />

            {/* MODAL */}
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="relative bg-white rounded-2xl shadow-xl w-full max-w-md overflow-hidden border border-slate-100"
            >
              {/* HEADER */}
              <div className="px-6 py-5 text-center">
                <div className="w-12 h-12 mx-auto mb-3 flex items-center justify-center rounded-full bg-red-100">
                  <Trash2 className="w-6 h-6 text-red-600" />
                </div>

                <h3 className="text-lg font-semibold text-slate-800">
                  Hapus Pengguna
                </h3>

                <p className="text-sm text-slate-500 mt-1">
                  Apakah kamu yakin ingin menghapus pengguna ini?
                </p>
              </div>

              {/* CONTENT */}
              <div className="px-6 pb-4 text-sm text-slate-600 space-y-1">
                <p>
                  <span className="font-medium text-slate-800">Nama:</span>{" "}
                  {formData.name}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Email:</span>{" "}
                  {formData.email}
                </p>
                <p>
                  {formData.role === "mahasiswa" ? (
                    <>
                      <span className="font-medium text-slate-800">NIM:</span>{" "}
                      {formData.nim_nidn}
                    </>
                  ) : formData.role === "dosen" ? (
                    <>
                      <span className="font-medium text-slate-800">NIDN:</span>{" "}
                      {formData.nim_nidn}
                    </>
                  ) : null}
                </p>
              </div>

              {/* ACTION */}
              <div className="px-6 py-4 border-t border-slate-100 flex justify-end gap-3">
                <button
                  onClick={handleCloseModal}
                  className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition"
                >
                  Batal
                </button>

                <button
                  onClick={() => handleDelete(selectedUser!.id)}
                  disabled={isSaving}
                  className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-xl transition shadow-sm disabled:opacity-70 inline-flex items-center gap-2"
                >
                  {isSaving && <Loader2 className="w-4 h-4 animate-spin" />}
                  {isSaving ? "Menghapus..." : "Hapus"}
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
