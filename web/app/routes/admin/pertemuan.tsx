import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";

export function meta() {
  return [
    { title: "Pertemuan Kelas | SIAM Admin" },
    { name: "description", content: "Kelola data pertemuan kelas SIAM." },
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
  Calendar,
  Clock,
  MapPin,
} from "lucide-react";
import { toast } from "sonner";
import { useTable } from "../../hooks/useTable";
import { Pagination, SortableHeader } from "../../components/table_features";
import type { Pertemuan } from "~/types/pertemuan";
import api from "~/lib/api";
import dayjs from "dayjs";
import type { Kelas } from "~/types/kelas";

export default function PertemuanPage() {
  const [pertemuanList, setPertemuanList] = useState<Pertemuan[]>([]);
  const [kelasList, setKelasList] = useState<Kelas[]>([]);
  const [searchTerm, setSearchTerm] = useState("");
  const [filterStatus, setFilterStatus] = useState<
    "All" | "Terjadwal" | "Berlangsung" | "Selesai"
  >("All");
  const [itemsPerPage, setItemsPerPage] = useState(10);

  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<
    "create" | "edit" | "view" | "delete"
  >("create");
  const [selectedPertemuan, setSelectedPertemuan] = useState<Pertemuan | null>(
    null,
  );

  // Form states
  const [formData, setFormData] = useState<Partial<Pertemuan>>({});

  const filteredData = pertemuanList.filter((p) => {
    const matchesSearch =
      p.kelas?.kode_kelas.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.kelas?.mata_kuliah?.nama_mk
        .toLowerCase()
        .includes(searchTerm.toLowerCase()) ||
      p.kelas?.ruangan?.nama.toLowerCase().includes(searchTerm.toLowerCase()) ||
      p.kelas?.hari.toLowerCase().includes(searchTerm.toLowerCase()) ||
      `${p.kelas?.hari}, ${dayjs(p.tanggal).format("DD MMMM YYYY")}`
        .toLowerCase()
        .includes(searchTerm.toLowerCase()) ||
      p.topik.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesStatus = filterStatus === "All" || p.status === filterStatus;
    return matchesSearch && matchesStatus;
  });

  const {
    currentData,
    currentPage,
    setCurrentPage,
    totalPages,
    requestSort,
    sortConfig,
    totalItems,
  } = useTable(filteredData, itemsPerPage);

  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1); // ❗ reset biar gak out of range
  };

  const handleOpenModal = (
    mode: "create" | "edit" | "view" | "delete",
    p?: Pertemuan,
  ) => {
    setModalMode(mode);
    if (p) {
      setSelectedPertemuan(p);
      setFormData(p);
    } else {
      setSelectedPertemuan(null);
      setFormData({ status: "Terjadwal", pertemuan_ke: 1 });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedPertemuan(null);
    setFormData({});
  };

  const formatTime = (time?: string) => {
    if (!time) return "";

    // ambil HH:mm aja
    return time.slice(0, 5);
  };

  const handleSave = async () => {
    if (
      !formData.kelas_id ||
      !formData.pertemuan_ke ||
      !formData.topik ||
      !formData.tanggal ||
      !formData.status
    ) {
      toast.error("Mohon lengkapi semua data wajib!");
      return;
    }

    if (modalMode === "create") {
      const newPertemuan = {
        kelas_id: formData.kelas_id,
        pertemuan_ke: formData.pertemuan_ke,
        topik: formData.topik,
        tanggal: formData.tanggal,
      };

      try {
        const res = await api.post("/pertemuan", newPertemuan);
        await fetchPertemuan();
        toast.success(res.data.message || "Pertemuan berhasil ditambahkan!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        toast.error(errors || "Gagal menambahkan pertemuan.");
      }
    } else if (modalMode === "edit" && selectedPertemuan) {
      const updatedPertemuan = {
        ...selectedPertemuan,
        kelas_id: formData.kelas_id,
        pertemuan_ke: formData.pertemuan_ke,
        topik: formData.topik,
        tanggal: formData.tanggal,
        started_at: formatTime(formData.started_at),
        ended_at: formatTime(formData.ended_at),
        status: formData.status || "Terjadwal",
      };

      try {
        const res = await api.put(
          `/pertemuan/${selectedPertemuan.id}`,
          updatedPertemuan,
        );
        await fetchPertemuan()
        toast.success(res.data.message || "Pertemuan berhasil diperbarui!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        toast.error(errors || "Gagal memperbarui pertemuan.");
      }
    }
    handleCloseModal();
  };

  const handleDelete = async (id: number) => {
    if (!selectedPertemuan) return;

    try {
      const res = await api.delete(`pertemuan/${id}`);
      await fetchPertemuan();
      toast.success(res.data.message || "Pertemuan berhasil dihapus!");
      handleCloseModal();
    } catch (error: any) {
      const errors = error.response?.data?.errors;

      toast.error(errors || "Gagal menghapus pertemuan.");
    }
  };

  const getStatusBadge = (status: Pertemuan["status"]) => {
    switch (status) {
      case "Terjadwal":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-blue-100 text-blue-700 border border-blue-200">
            <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
            Terjadwal
          </span>
        );
      case "Berlangsung":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-amber-100 text-amber-700 border border-amber-200">
            <span className="w-1.5 h-1.5 rounded-full bg-amber-500 animate-pulse"></span>
            Berlangsung
          </span>
        );
      case "Selesai":
        return (
          <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium bg-emerald-100 text-emerald-700 border border-emerald-200">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
            Selesai
          </span>
        );
    }
  };

  const fetchPertemuan = async () => {
    try {
      const res = await api.get("/pertemuan");
      setPertemuanList(res.data.data);
    } catch (error: any) {
      const errors = error.response?.data?.errors;

      if (errors) {
        toast.error(errors[0]);
      } else {
        toast.error("Gagal mengambil data pertemuan.");
      }
    }
  };

  useEffect(() => {
    const fetchKelas = async () => {
      try {
        const res = await api.get("/kelas");
        setKelasList(res.data.data);
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors) {
          toast.error(errors[0]);
        } else {
          toast.error("Gagal mengambil data kelas.");
        }
      }
    };

    fetchPertemuan();
    fetchKelas();
  }, []);

  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            Manajemen Pertemuan
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Kelola jadwal pertemuan dan absensi untuk setiap kelas.
          </p>
        </div>

        <button
          onClick={() => handleOpenModal("create")}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Tambah Jadwal Pertemuan</span>
        </button>
      </div>

      {/* Filters & Search */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col sm:flex-row gap-4">
        <div className="relative flex-1">
          <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari berdasarkan nama kelas atau topik..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
          />
        </div>
        <div className="flex gap-2 shrink-0">
          {(["All", "Terjadwal", "Berlangsung", "Selesai"] as const).map(
            (status) => (
              <button
                key={status}
                onClick={() => setFilterStatus(status)}
                className={`px-4 py-2.5 rounded-xl text-sm font-medium capitalize transition-all ${
                  filterStatus === status
                    ? "bg-slate-800 text-white shadow-sm"
                    : "bg-slate-50 text-slate-600 border border-slate-200 hover:bg-slate-100"
                }`}
              >
                {status === "All" ? "Semua Status" : status}
              </button>
            ),
          )}
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
                  label="Kelas & Topik"
                  sortKey="topik"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Jadwal & Ruangan"
                  sortKey="tanggal"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Status"
                  sortKey="status"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider">
                  Aksi
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {currentData.length === 0 ? (
                <tr>
                  <td
                    colSpan={5}
                    className="px-6 py-12 text-center text-slate-500"
                  >
                    Tidak ada jadwal pertemuan yang ditemukan.
                  </td>
                </tr>
              ) : (
                currentData.map((p, index) => (
                  <tr
                    key={p.id}
                    className="hover:bg-slate-50/50 transition-colors group"
                  >
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {(currentPage - 1) * itemsPerPage + index + 1}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col">
                        <span className="font-bold text-slate-800 mb-0.5">
                          Pertemuan {p.pertemuan_ke}: {p.topik}
                        </span>
                        <span className="text-sm font-medium text-blue-600">
                          {p.kelas?.kode_kelas} -{" "}
                          {p.kelas?.mata_kuliah?.nama_mk}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col gap-1 text-sm text-slate-700">
                        <div className="flex items-center gap-1.5">
                          <Calendar className="w-3.5 h-3.5 text-slate-400" />
                          <span>
                            {p.kelas?.hari},{" "}
                            {dayjs(p.tanggal).format("DD MMMM YYYY")}
                          </span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5 text-slate-400" />
                          <span>
                            {p.started_at?.slice(0, 5)} -{" "}
                            {p.ended_at?.slice(0, 5)}
                          </span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <MapPin className="w-3.5 h-3.5 text-slate-400" />
                          <span>Ruang {p.kelas?.ruangan?.nama}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">{getStatusBadge(p.status)}</td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-start gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => handleOpenModal("view", p)}
                          className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors"
                          title="Detail"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("edit", p)}
                          className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg transition-colors"
                          title="Edit"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("delete", p)}
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
                    <Calendar className="w-4 h-4" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">
                    {modalMode === "create"
                      ? "Tambah Jadwal Pertemuan"
                      : modalMode === "edit"
                        ? "Edit Jadwal Pertemuan"
                        : "Detail Pertemuan"}
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
                  <div className="space-y-1.5 sm:col-span-2">
                    <label className="text-sm font-medium text-slate-700">
                      Pilih Kelas <span className="text-red-500">*</span>
                    </label>
                    {kelasList.length > 0 && (
                      <select
                        value={formData.kelas_id || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            kelas_id: Number(e.target.value),
                          })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100 capitalize"
                        required
                      >
                        <option value="">-- Pilih Kelas --</option>
                        {kelasList.map((k) => (
                          <option key={k.id} value={k.id}>
                            {k.kode_kelas} - {k.mata_kuliah?.nama_mk}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Pertemuan Ke- <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="number"
                      min="1"
                      max="16"
                      value={formData.pertemuan_ke || ""}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          pertemuan_ke: Number(e.target.value),
                        })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                    />
                  </div>

                  {modalMode !== "create" && (
                    <div className="space-y-1.5">
                      <label className="text-sm font-medium text-slate-700">
                        Status <span className="text-red-500">*</span>
                      </label>
                      <select
                        value={formData.status || "Terjadwal"}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            status: e.target.value as Pertemuan["status"],
                          })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                      >
                        <option value="Terjadwal">Terjadwal</option>
                        <option value="Berlangsung">Berlangsung</option>
                        <option value="Selesai">Selesai</option>
                      </select>
                    </div>
                  )}

                  <div className="space-y-1.5 sm:col-span-2">
                    <label className="text-sm font-medium text-slate-700">
                      Topik Pembahasan <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.topik || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, topik: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                      placeholder="Contoh: Pengantar Algoritma Dasar"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Tanggal <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="date"
                      value={formData.tanggal || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, tanggal: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                    />
                  </div>

                  {modalMode !== "create" && (
                    <>
                      <div className="space-y-1.5">
                        <label className="text-sm font-medium text-slate-700">
                          Waktu Mulai <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="time"
                          value={formData.started_at || ""}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              started_at: e.target.value,
                            })
                          }
                          disabled={modalMode === "view"}
                          className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
                        />
                      </div>

                      <div className="space-y-1.5">
                        <label className="text-sm font-medium text-slate-700">
                          Waktu Selesai <span className="text-red-500">*</span>
                        </label>
                        <input
                          type="time"
                          value={formData.ended_at || ""}
                          onChange={(e) =>
                            setFormData({
                              ...formData,
                              ended_at: e.target.value,
                            })
                          }
                          disabled={
                            modalMode === "view" &&
                            formData.status !== "Selesai"
                          }
                          className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100"
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
                    className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm"
                  >
                    <Check className="w-4 h-4" />
                    <span>Simpan Data</span>
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
                  Hapus Pertemuan
                </h3>

                <p className="text-sm text-slate-500 mt-1">
                  Apakah kamu yakin ingin menghapus Pertemuan ini?
                </p>
              </div>

              {/* CONTENT */}
              <div className="px-6 pb-4 text-sm text-slate-600 space-y-1">
                <p>
                  <span className="font-medium text-slate-800">
                    Pertemuan:
                  </span>{" "}
                  Pertemuan {formData.pertemuan_ke}: {formData.topik}
                </p>
                <p>
                  <span className="font-medium text-slate-800">
                    Kelas:
                  </span>{" "}
                  {formData.kelas?.kode_kelas} - {formData.kelas?.mata_kuliah?.nama_mk}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Jadwal:</span>{" "}
                  {formData.kelas?.hari}, {dayjs(formData.tanggal).format("DD MMMM YYYY")}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Waktu:</span>{" "}
                  {formData.started_at?.slice(0, 5)} - {formData.ended_at?.slice(0, 5)}</p>
                <p>
                  <span className="font-medium text-slate-800">Ruangan:</span>{" "}
                  {formData.kelas?.ruangan?.nama}
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
                  onClick={() => handleDelete(selectedPertemuan!.id)}
                  className="px-4 py-2 text-sm font-medium text-white bg-red-600 hover:bg-red-700 rounded-xl transition shadow-sm"
                >
                  Hapus
                </button>
              </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>
    </div>
  );
}
