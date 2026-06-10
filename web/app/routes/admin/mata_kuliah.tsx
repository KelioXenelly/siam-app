import {
  BookOpen,
  Check,
  Edit,
  Eye,
  Plus,
  Search,
  Trash2,
  X,
  Loader2 } from "lucide-react";
import { AnimatePresence, motion } from "motion/react";
import { useEffect, useState } from "react";

export function meta() {
  return [
    { title: "Mata Kuliah | SIAM Admin" },
    { name: "description", content: "Kelola data mata kuliah SIAM." },
  ];
}
import { toast } from "sonner";
import { SkeletonTable } from "~/components/ui/skeleton_table";
import { EmptyState } from "~/components/ui/empty_state";
import { Pagination, SortableHeader } from "~/components/table_features";
import { useServerTable } from "~/hooks/useServerTable";
import api from "~/lib/api";
import type { MataKuliah } from "~/types/matakuliah";

export default function MataKuliahPage() {

  // Modal states
  const [isSaving, setIsSaving] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<
    "create" | "edit" | "view" | "delete"
  >("create");
  const [selectedMK, setSelectedMK] = useState<MataKuliah | null>(null);

  // Form states
  const [formData, setFormData] = useState<Partial<MataKuliah>>({});


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
  } = useServerTable<MataKuliah>("/mata-kuliah", 10);


  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1); // ❗ reset biar gak out of range
  };

  const handleOpenModal = (
    mode: "create" | "edit" | "view" | "delete",
    mk?: MataKuliah,
  ) => {
    setModalMode(mode);
    if (mk) {
      setSelectedMK(mk);
      setFormData(mk);
    } else {
      setSelectedMK(null);
      setFormData({ sks: 3 });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedMK(null);
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
    if (!formData.kode_mk || !formData.nama_mk || !formData.sks) {
      toast.error("Mohon lengkapi semua data wajib!");
      return;
    }

    if (modalMode === "create") {
      const newMK = {
        kode_mk: formData.kode_mk,
        nama_mk: formData.nama_mk,
        sks: formData.sks,
      };

      try {
        const res = await api.post("/mata-kuliah", newMK);
        const createdMK = res.data.data;
        await refreshData();
        toast.success(res.data.message || "Mata Kuliah berhasil ditambahkan!"); // kenapa masih terlempar di sini? Bukannya error yaaa?
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.kode_mk) {
          toast.error("Kode mata kuliah sudah digunakan");
        } else {
          toast.error("Gagal menambahkan mata kuliah.");
        }
      }
    } else if (modalMode === "edit" && selectedMK) {
      const updatedMK = {
        ...selectedMK,
        kode_mk: formData.kode_mk || selectedMK.kode_mk,
        nama_mk: formData.nama_mk || selectedMK.nama_mk,
        sks: formData.sks || selectedMK.sks,
      };

      try {
        const res = await api.put(`/mata-kuliah/${selectedMK.id}`, updatedMK);
        const updatedMKFromRes = res.data.data;
        await refreshData();
        toast.success(res.data.message || "Mata Kuliah berhasil diperbarui!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.kode_mk) {
          toast.error("Kode mata kuliah sudah digunakan");
        } else {
          toast.error("Gagal memperbarui mata kuliah.");
        }
      }
    }
    handleCloseModal();
  setIsSaving(false);
  };


  const handleDelete = async (id: number) => {
    setIsSaving(true);
    if (!selectedMK) return;

    try {
      const res = await api.delete(`/mata-kuliah/${id}`);
      await refreshData();
      toast.success(res.data.message || "Mata Kuliah berhasil dihapus!");
      handleCloseModal();
    } catch (error: any) {
      const errors = error.response?.data?.errors;

      toast.error(errors || "Gagal menghapus mata kuliah.");
    }
    setIsSaving(false);
  };


  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            Manajemen Mata Kuliah
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Kelola data kurikulum dan mata kuliah yang tersedia.
          </p>
        </div>

        <button
          onClick={() => handleOpenModal("create")}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Tambah Mata Kuliah</span>
        </button>
      </div>

      {/* Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
        <div className="relative w-full">
          <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama atau kode mata kuliah..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
          />
        </div>
      </div>

      {/* Table */}
      <div className="bg-white border border-slate-200 rounded-2xl shadow-sm flex-1 overflow-hidden flex flex-col">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/50">
                <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-12">
                  No
                </th>
                <SortableHeader
                  label="Mata Kuliah"
                  sortKey="nama_mk"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="SKS"
                  sortKey="sks"
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
                currentData.map((mk, index) => (
                  <tr
                    key={mk.id}
                    className="hover:bg-slate-50/50 transition-colors group"
                  >
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {index + 1}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col">
                        <span className="font-medium text-slate-900">
                          {mk.nama_mk}
                        </span>
                        <span className="text-sm font-medium text-blue-600">
                          {mk.kode_mk}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm font-medium text-slate-700">
                      {mk.sks} SKS
                    </td>
                    <td className="px-6 py-4 text-right">
                      <div className="flex items-center justify-start gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => handleOpenModal("view", mk)}
                          className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Detail"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("edit", mk)}
                          className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("delete", mk)}
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

      {/* Modal */}
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
                    <BookOpen className="w-4 h-4" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">
                    {modalMode === "create"
                      ? "Tambah Mata Kuliah"
                      : modalMode === "edit"
                        ? "Edit Mata Kuliah"
                        : "Detail Mata Kuliah"}
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
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Kode Mata Kuliah <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.kode_mk || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, kode_mk: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100 font-medium"
                      placeholder="Contoh: ST001"
                      required
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Jumlah SKS <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="6"
                      value={formData.sks || ""}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          sks: parseInt(e.target.value),
                        })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                      required
                    />
                  </div>

                  <div className="space-y-1.5 sm:col-span-2">
                    <label className="text-sm font-medium text-slate-700">
                      Nama Mata Kuliah <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.nama_mk || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, nama_mk: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                      placeholder="Contoh: Algoritma dan Pemrograman"
                      required
                    />
                  </div>
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
                  Hapus Mata Kuliah
                </h3>

                <p className="text-sm text-slate-500 mt-1">
                  Apakah kamu yakin ingin menghapus mata kuliah ini?
                </p>
              </div>

              {/* CONTENT */}
              <div className="px-6 pb-4 text-sm text-slate-600 space-y-1">
                <p>
                  <span className="font-medium text-slate-800">Nama:</span>{" "}
                  {formData.nama_mk}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Kode:</span>{" "}
                  {formData.kode_mk}
                </p>
                <p>
                  <span className="font-medium text-slate-800">SKS:</span>{" "}
                  {formData.sks}
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
                  onClick={() => handleDelete(selectedMK!.id)}
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
