import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";

export function meta() {
  return [
    { title: "Manajemen Ruangan | SIAM Admin" },
    { name: "description", content: "Kelola data ruangan kelas SIAM." },
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
  MapPin,
  Loader2 } from "lucide-react";
import { toast } from "sonner";
import { useServerTable } from "~/hooks/useServerTable";
import { SkeletonTable } from "~/components/ui/skeleton_table";
import { EmptyState } from "~/components/ui/empty_state";
import { Pagination, SortableHeader } from "../../components/table_features";
import type { Ruangan } from "~/types/ruangan";
import api from "~/lib/api";

export default function RuanganPage() {
  const [isSaving, setIsSaving] = useState(false);

  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<
    "create" | "edit" | "view" | "delete"
  >("create");
  const [selectedRuangan, setSelectedRuangan] = useState<Ruangan | null>(null);
  const [formData, setFormData] = useState<Partial<Ruangan>>({});
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
  } = useServerTable<Ruangan>("/ruangan", 10);


  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1); // ❗ reset biar gak out of range
  };

  const handleOpenModal = (
    mode: "create" | "edit" | "view" | "delete",
    r?: Ruangan,
  ) => {
    setModalMode(mode);
    if (r) {
      setSelectedRuangan(r);
      setFormData(r);
    } else {
      setSelectedRuangan(null);
      setFormData({ kapasitas: 40, is_active: true });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedRuangan(null);
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
    if (!formData.nama || !formData.kapasitas) {
      toast.error("Mohon lengkapi semua data wajib!");
      return;
    }

    if (modalMode === "create") {
      const newRuangan = {
        nama: formData.nama,
        kapasitas: formData.kapasitas,
        is_active: formData.is_active ?? true,
      };

      try {
        const res = await api.post("/ruangan", newRuangan);
        const createdRuangan = res.data.data;
        await refreshData();
        toast.success(res.data.message || "Ruangan baru berhasil dibuat!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.nama) {
          toast.error("Nama ruangan sudah digunakan");
        } else {
          toast.error(errors || "Gagal membuat ruangan baru.");
        }
      }
    } else if (modalMode === "edit" && selectedRuangan) {
      const updatedRuangan = {
        ...selectedRuangan,
        nama: formData.nama,
        kapasitas: formData.kapasitas,
        is_active: formData.is_active,
      };

      try {
        const res = await api.put(
          `/ruangan/${selectedRuangan.id}`,
          updatedRuangan,
        );
        const updatedRuanganFromServer = res.data.data;
        await refreshData();
        toast.success(res.data.message || "Ruangan berhasil diperbarui!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors?.nama) {
          toast.error("Nama ruangan sudah digunakan");
        } else {
          toast.error(errors || "Gagal memperbarui ruangan.");
        }
      }
    }
    handleCloseModal();
  setIsSaving(false);
  };


  const handleDelete = async (id: number) => {
    setIsSaving(true);
    if (!selectedRuangan) return;

    try {
      const res = await api.delete(`/ruangan/${id}`);
      await refreshData();
      toast.success(res.data.message || "Ruangan berhasil dihapus!");
      handleCloseModal();
    } catch (error: any) {
      const errors = error.response?.data?.errors;

      toast.error(errors || "Gagal menghapus ruangan.");
    }
    setIsSaving(false);
  };


  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            Manajemen Ruangan
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Kelola data ruangan kelas dan lab.
          </p>
        </div>

        <button
          onClick={() => handleOpenModal("create")}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Tambah Ruangan</span>
        </button>
      </div>

      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
        <div className="relative w-full">
          <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama ruangan..."
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
                  label="Nama Ruangan"
                  sortKey="nama"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Kapasitas"
                  sortKey="kapasitas"
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
                <SkeletonTable columns={5} rows={5} />
              ) : currentData.length === 0 ? (
                <EmptyState 
                  title="Data Kosong"
                  description="Belum ada data yang ditemukan. Silakan tambahkan data baru atau sesuaikan pencarian."
                  colSpan={5}
                />
              ) : (
                currentData.map((r, index) => (
                  <tr
                    key={r.id}
                    className="hover:bg-slate-50/50 transition-colors group"
                  >
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {(currentPage - 1) * itemsPerPage + index + 1}
                    </td>
                    <td className="px-6 py-4 font-bold text-slate-800">
                      {r.nama}
                    </td>
                    <td className="px-6 py-4 text-sm font-medium text-slate-700">
                      {r.kapasitas} Kursi
                    </td>
                    <td className="px-6 py-4">
                      <span
                        className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium border ${
                          r.is_active == true
                            ? "bg-green-50 text-green-700 border-green-200"
                            : "bg-slate-100 text-slate-600 border-slate-200"
                        }`}
                      >
                        <span
                          className={`w-1.5 h-1.5 rounded-full ${r.is_active == true ? "bg-green-500" : "bg-slate-400"}`}
                        ></span>
                        {r.is_active == true ? "Aktif" : "Nonaktif"}
                      </span>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-start gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => handleOpenModal("view", r)}
                          className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("edit", r)}
                          className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("delete", r)}
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
              className="relative bg-white rounded-2xl shadow-xl w-full max-w-sm border border-slate-100"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50/50">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center">
                    <MapPin className="w-4 h-4" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">
                    {modalMode === "create"
                      ? "Tambah Ruangan"
                      : modalMode === "edit"
                        ? "Edit Ruangan"
                        : "Detail Ruangan"}
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
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-slate-700">
                    Nama Ruangan <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="text"
                    value={formData.nama || ""}
                    onChange={(e) =>
                      setFormData({ ...formData, nama: e.target.value })
                    }
                    disabled={modalMode === "view"}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 font-medium"
                    placeholder="Contoh: GKB-101"
                    required
                  />
                </div>
                <div className="space-y-1.5">
                  <label className="text-sm font-medium text-slate-700">
                    Kapasitas Kursi <span className="text-red-500">*</span>
                  </label>
                  <input
                    type="number"
                    value={formData.kapasitas || ""}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        kapasitas: parseInt(e.target.value),
                      })
                    }
                    disabled={modalMode === "view"}
                    className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70"
                    placeholder="Contoh: 40"
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
                    >
                      <option value="true">Aktif</option>
                      <option value="false">Nonaktif</option>
                    </select>
                  </div>
                )}
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
                  Hapus Ruangan
                </h3>

                <p className="text-sm text-slate-500 mt-1">
                  Apakah kamu yakin ingin menghapus Ruangan ini?
                </p>
              </div>

              {/* CONTENT */}
              <div className="px-6 pb-4 text-sm text-slate-600 space-y-1">
                <p>
                  <span className="font-medium text-slate-800">
                    Nama Ruangan:
                  </span>{" "}
                  {formData.nama}
                </p>
                <p>
                  <span className="font-medium text-slate-800">
                    Kapasitas:
                  </span>{" "}
                  {formData.kapasitas} Kursi
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
                  onClick={() => handleDelete(selectedRuangan!.id)}
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
