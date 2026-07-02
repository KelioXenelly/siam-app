import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";

export function meta() {
  return [
    { title: "Program Studi | SIAM Admin" },
    { name: "description", content: "Kelola data program studi SIAM." },
  ];
}
import {
  Plus,
  Search,
  Edit,
  Trash2,
  Eye,
  X,
  Check,
  BookOpen,
  Loader2 } from "lucide-react";
import { toast } from "sonner";
import { useServerTable } from "~/hooks/useServerTable";
import type { Prodi as ProgramStudi } from '~/types/prodi';
import { SkeletonTable } from "~/components/ui/skeleton_table";
import { EmptyState } from "~/components/ui/empty_state";
import { Pagination, SortableHeader } from "../../components/table_features";
import type { Prodi } from "~/types/prodi";
import api from "~/lib/api";

export default function ProgramStudiPage() {
  const [isSaving, setIsSaving] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<"create" | "edit" | "view" | "delete">("create");
  const [selectedProdi, setSelectedProdi] = useState<Prodi | null>(null);
  const [formData, setFormData] = useState<Partial<Prodi>>({});

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
  } = useServerTable<ProgramStudi>("/program-studi", 10);


  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1); // ❗ reset biar gak out of range
  };

  const handleOpenModal = (
    mode: "create" | "edit" | "view" | "delete",
    prodi?: Prodi,
  ) => {
    setModalMode(mode);
    if (prodi) {
      setSelectedProdi(prodi);
      setFormData(prodi);
    } else {
      setSelectedProdi(null);
      setFormData({ jenjang: "S1", is_active: true });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedProdi(null);
    setFormData({});
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
    if (!formData.kode_prodi || !formData.nama_prodi || !formData.jenjang) {
      toast.error("Mohon lengkapi semua data wajib!");
      return;
    }

    if (modalMode === "create") {
      const newProdi = {
        kode_prodi: formData.kode_prodi,
        nama_prodi: formData.nama_prodi,
        jenjang: formData.jenjang,
      };

      try {
        const res = await api.post("/program-studi", newProdi);
        const createdProdi = res.data.data;
        refreshData();
        toast.success(
          res.data.message || "Program Studi berhasil ditambahkan!",
        );
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.kode_prodi) {
          toast.error("Kode Prodi sudah digunakan");
        } else {
          toast.error(errors || "Gagal menambahkan program studi.");
        }
      }
    } else if (modalMode === "edit" && selectedProdi) {
      const updatedProdi = {
        ...selectedProdi,
        kode_prodi: formData.kode_prodi,
        nama_prodi: formData.nama_prodi,
        jenjang: formData.jenjang,
        is_active: formData.is_active,
      };

      try {
        const res = await api.put(
          `/program-studi/${selectedProdi.id}`,
          updatedProdi,
        );
        const updatedProdiFromServer = res.data.data;
        await refreshData();
        toast.success(res.data.message || "Program Studi berhasil diperbarui!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.kode_prodi) {
          toast.error("Kode Prodi sudah digunakan");
        } else {
          toast.error(errors || "Gagal memperbarui program studi.");
        }
      }
    }
    handleCloseModal();
  setIsSaving(false);
  };


  const handleDelete = async (id: number) => {
    setIsSaving(true);
    if (!selectedProdi) return;

    try {
      const res = await api.delete(`/program-studi/${id}`);
      refreshData();
      toast.success(res.data.message || "Program Studi berhasil dihapus!");
      handleCloseModal();
    } catch (error: any) {
      const errors = error.response?.data?.errors;

      toast.error(errors || "Gagal menghapus program studi.");
    }
    setIsSaving(false);
  };

  useEffect(() => {
    const fetchProdi = async () => {
      try {
        const res = await api.get("/program-studi");
        refreshData();
      } catch (error) {
        toast.error("Gagal mengambil data program studi.");
      }
    };

    fetchProdi();
  }, []);

  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            Manajemen Program Studi
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Kelola data program studi yang tersedia.
          </p>
        </div>

        <button
          onClick={() => handleOpenModal("create")}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Tambah Prodi</span>
        </button>
      </div>

      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
        <div className="relative w-full">
          <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama atau kode prodi..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
          />
        </div>
      </div>

      <div className="bg-white border border-slate-200 rounded-2xl shadow-sm flex-1 flex flex-col overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/50">
                <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-12">
                  No
                </th>
                <SortableHeader
                  label="Kode"
                  sortKey="kode_prodi"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Program Studi"
                  sortKey="nama_prodi"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Jenjang"
                  sortKey="jenjang"
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
                currentData.map((p, index) => (
                  <tr
                    key={p.id}
                    className="hover:bg-slate-50/50 transition-colors group"
                  >
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {(currentPage - 1) * itemsPerPage + index + 1}
                    </td>
                    <td className="px-6 py-4 text-sm font-bold text-slate-800">
                      {p.kode_prodi}
                    </td>
                    <td className="px-6 py-4 font-medium text-slate-900">
                      {p.nama_prodi}
                    </td>
                    <td className="px-6 py-4 text-sm text-slate-700">
                      {p.jenjang}
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${
                          p.is_active == true
                            ? "bg-green-50 text-green-700 border-green-200"
                            : "bg-slate-100 text-slate-600 border-slate-200"
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${p.is_active == true ? "bg-green-500" : "bg-slate-400"}`}
                        ></span>
                        {p.is_active == true ? "Aktif" : "Nonaktif"}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-start gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => handleOpenModal("view", p)}
                          className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("edit", p)}
                          className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("delete", p)}
                          className="p-1.5 text-slate-400 hover:text-red-600 hover:bg-red-50 rounded-lg"
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

      <AnimatePresence>
        {isModalOpen && modalMode !== "delete" && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4">
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
              className="relative bg-white rounded-2xl shadow-xl w-full max-w-lg border border-slate-100"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50/50">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center">
                    <BookOpen className="w-4 h-4" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">
                    {modalMode === "create"
                      ? "Tambah Program Studi"
                      : modalMode === "edit"
                        ? "Edit Program Studi"
                        : "Detail Program Studi"}
                  </h3>
                </div>
                <button
                  onClick={handleCloseModal}
                  className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="p-6 space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Kode Prodi <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.kode_prodi || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, kode_prodi: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 font-medium uppercase"
                      placeholder="Contoh: STI"
                      required
                    />
                  </div>
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Jenjang <span className="text-red-500">*</span>
                    </label>
                    <select
                      value={formData.jenjang || "S1"}
                      onChange={(e) =>
                        setFormData({ ...formData, jenjang: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70"
                      required
                    >
                      <option value="D3">D3</option>
                      <option value="D4">D4</option>
                      <option value="S1">S1</option>
                      <option value="S2">S2</option>
                      <option value="S3">S3</option>
                    </select>
                  </div>
                  <div className="space-y-1.5 sm:col-span-2">
                    <label className="text-sm font-medium text-slate-700">
                      Nama Prodi <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.nama_prodi || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, nama_prodi: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70"
                      placeholder="Contoh: Teknik Informatika"
                      required
                    />
                  </div>

                  {modalMode !== "create" && (
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
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70"
                        required
                      >
                        <option value="true">Aktif</option>
                        <option value="false">Nonaktif</option>
                      </select>
                    </div>
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
                    className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 shadow-sm disabled:opacity-70"
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
                  Hapus Program Studi
                </h3>

                <p className="text-sm text-slate-500 mt-1">
                  Apakah kamu yakin ingin menghapus Program Studi ini?
                </p>
              </div>

              {/* CONTENT */}
              <div className="px-6 pb-4 text-sm text-slate-600 space-y-1">
                <p>
                  <span className="font-medium text-slate-800">Kode Prodi:</span>{" "}
                  {formData.kode_prodi}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Nama Prodi:</span>{" "}
                  {formData.nama_prodi}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Jenjang:</span>{" "}
                  {formData.jenjang}
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
                  onClick={() => handleDelete(selectedProdi!.id)}
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
