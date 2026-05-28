import React, { use, useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";

export function meta() {
  return [
    { title: "Manajemen Kelas | SIAM Admin" },
    { name: "description", content: "Kelola data kelas perkuliahan SIAM." },
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
  Building2,
  Users,
  UserPlus,
  Calendar,
  Clock,
  MapPin,
} from "lucide-react";
import { toast } from "sonner";
import { useServerTable } from "../../hooks/useServerTable";
import { Pagination, SortableHeader } from "../../components/table_features";
import type { Kelas } from "~/types/kelas";
import type { Mahasiswa } from "~/types/mahasiswa";
import type { Dosen } from "~/types/dosen";
import type { MataKuliah } from "~/types/matakuliah";
import type { Ruangan } from "~/types/ruangan";
import api from "~/lib/api";

export default function KelasPage() {
  const [mahasiswaList, setMahasiswaList] = useState<Mahasiswa[]>([]);
  const [dosenList, setDosenList] = useState<Dosen[]>([]);
  const [mataKuliahList, setMataKuliahList] = useState<MataKuliah[]>([]);
  const [ruanganList, setRuanganList] = useState<Ruangan[]>([]);

  // Modal states
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [modalMode, setModalMode] = useState<
    "create" | "edit" | "view" | "delete"
  >("create");
  const [selectedKelas, setSelectedKelas] = useState<Kelas | null>(null);

  // Assign Mahasiswa Modal
  const [isAssignModalOpen, setIsAssignModalOpen] = useState(false);
  const [assignSearchTerm, setAssignSearchTerm] = useState("");
  const [assignedStudents, setAssignedStudents] = useState<number[]>([]); // Temp state for modal

  const [formData, setFormData] = useState<Partial<Kelas>>({});

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
  } = useServerTable<Kelas>("/kelas", 10);

  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1);
  };

  const handleOpenModal = (
    mode: "create" | "edit" | "view" | "delete",
    k?: Kelas,
  ) => {
    setModalMode(mode);
    if (k) {
      setSelectedKelas(k);
      setFormData(k);
    } else {
      setSelectedKelas(null);
      setFormData({
        kapasitas: 40,
        semester: 1,
        tahun_ajaran: "2023/2024",
        hari: "Senin",
      });
    }
    setIsModalOpen(true);
  };

  const handleCloseModal = () => {
    setIsModalOpen(false);
    setSelectedKelas(null);
    setFormData({});
  };

  const formatTime = (time: string) => {
    if (!time) return "";

    // ambil HH:mm aja
    return time.slice(0, 5);
  };

  const handleSave = async () => {
    if (
      !formData.kode_kelas ||
      !formData.mata_kuliah_id ||
      !formData.dosen_id ||
      !formData.ruangan_id ||
      !formData.semester ||
      !formData.tahun_ajaran ||
      !formData.hari ||
      !formData.jam_mulai ||
      !formData.jam_selesai ||
      !formData.kapasitas
    ) {
      toast.error("Mohon lengkapi semua data wajib!");
      return;
    }

    if (modalMode === "create") {
      const newKelas = {
        kode_kelas: formData.kode_kelas,
        mata_kuliah_id: formData.mata_kuliah_id,
        dosen_id: formData.dosen_id,
        ruangan_id: formData.ruangan_id,
        semester: formData.semester,
        tahun_ajaran: formData.tahun_ajaran,
        hari: formData.hari,
        jam_mulai: formatTime(formData.jam_mulai),
        jam_selesai: formatTime(formData.jam_selesai),
        kapasitas: formData.kapasitas,
      };

      try {
        await api.post("/kelas", newKelas);
        await refreshData();
        toast.success("Kelas berhasil ditambahkan!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors) {
          toast.error(errors[0]);
        } else {
          toast.error("Gagal menambahkan kelas.");
        }
      }
    } else if (modalMode === "edit" && selectedKelas) {
      const updatedKelas = {
        ...selectedKelas,
        kode_kelas: formData.kode_kelas,
        mata_kuliah_id: formData.mata_kuliah_id,
        dosen_id: formData.dosen_id,
        ruangan_id: formData.ruangan_id,
        semester: formData.semester,
        tahun_ajaran: formData.tahun_ajaran,
        hari: formData.hari,
        jam_mulai: formatTime(formData.jam_mulai),
        jam_selesai: formatTime(formData.jam_selesai),
        kapasitas: formData.kapasitas,
      };

      try {
        await api.put(`/kelas/${selectedKelas.id}`, updatedKelas);
        await refreshData();
        toast.success("Kelas berhasil diperbarui!");
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors) {
          toast.error(errors[0]);
        } else {
          toast.error("Gagal memperbarui kelas.");
        }
      }
    }
    handleCloseModal();
  };

  const handleDelete = async (id: number) => {
    if (!selectedKelas) return;

    try {
      await api.delete(`/kelas/${selectedKelas.id}`);
      await refreshData();
      toast.success("Kelas berhasil dihapus!");
      handleCloseModal();
    } catch (error: any) {
      const errors = error.response?.data?.errors;
      console.log(errors);
      toast.error(errors || "Gagal menghapus kelas.");
    }
  };

  // --- Assign Mahasiswa Logic ---
  const handleOpenAssignModal = (k: Kelas) => {
    setSelectedKelas(k);
    setAssignedStudents([...k.mahasiswas.map((m) => m.id)]);
    setIsAssignModalOpen(true);
    setAssignSearchTerm("");
  };

  const handleAssignMahasiswa = async () => {
    if (!selectedKelas) return;

    try {
      await api.post(`/kelas/${selectedKelas.id}/assign-mahasiswa`, {
        mahasiswa_ids: assignedStudents,
      });
      toast.success("Mahasiswa berhasil ditugaskan ke kelas!");
      await refreshData();
      setIsAssignModalOpen(false);
    } catch (error: any) {
      const errors = error.response?.data?.errors;
      if (errors) {
        toast.error(errors[0]);
      } else {
        toast.error("Gagal menambahkan mahasiswa ke kelas.");
      }
    }
  };

  const toggleStudent = (mId: number) => {
    setAssignedStudents((prev) =>
      prev.includes(mId) ? prev.filter((id) => id !== mId) : [...prev, mId],
    );
  };

  const filteredStudents = mahasiswaList.filter(
    (m) =>
      m.user?.name?.toLowerCase().includes(assignSearchTerm.toLowerCase()) ||
      m.prodi?.nama_prodi
        ?.toLowerCase()
        .includes(assignSearchTerm.toLowerCase()) ||
      m.nim.includes(assignSearchTerm),
  );

  useEffect(() => {
    const fetchMahasiswa = async () => {
      try {
        const res = await api.get("/mahasiswa");
        setMahasiswaList(res.data.data);
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors) {
          toast.error(errors[0]);
        } else {
          toast.error("Gagal mengambil data mahasiswa.");
        }
      }
    };
    const fetchDosen = async () => {
      try {
        const res = await api.get("/dosen");
        setDosenList(res.data.data);
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors) {
          toast.error(errors[0]);
        } else {
          toast.error("Gagal mengambil data dosen.");
        }
      }
    };
    const fetchMataKuliah = async () => {
      try {
        const res = await api.get("/mata-kuliah");
        setMataKuliahList(res.data.data);
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors) {
          toast.error(errors[0]);
        } else {
          toast.error("Gagal mengambil data mata kuliah.");
        }
      }
    };
    const fetchRuangan = async () => {
      try {
        const res = await api.get("ruangan");
        setRuanganList(res.data.data);
      } catch (error: any) {
        const errors = error.response?.data?.errors;

        if (errors) {
          toast.error(errors[0]);
        } else {
          toast.error("Gagal mengambil data ruangan.");
        }
      }
    };

    fetchMahasiswa();
    fetchDosen();
    fetchMataKuliah();
    fetchRuangan();
  }, []);

  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            Manajemen Kelas
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Kelola pembagian kelas, mata kuliah, jadwal, dan mahasiswa.
          </p>
        </div>

        <button
          onClick={() => handleOpenModal("create")}
          className="inline-flex items-center justify-center gap-2 px-4 py-2.5 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 focus:ring-4 focus:ring-blue-600/20 transition-all shadow-sm"
        >
          <Plus className="w-4 h-4" />
          <span>Tambah Kelas</span>
        </button>
      </div>

      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
        <div className="relative w-full">
          <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari berdasarkan kode kelas, mata kuliah, atau dosen..."
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
                  label="Kode Kelas"
                  sortKey="kode_kelas"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Mata Kuliah & Dosen"
                  sortKey="mata_kuliah_nama"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Jadwal & Ruangan"
                  sortKey="hari"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Mahasiswa"
                  sortKey="kapasitas"
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
                    colSpan={6}
                    className="px-6 py-12 text-center text-slate-500"
                  >
                    Tidak ada kelas yang ditemukan.
                  </td>
                </tr>
              ) : (
                currentData.map((k, index) => (
                  <tr
                    key={k.id}
                    className="hover:bg-slate-50/50 transition-colors group"
                  >
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {(currentPage - 1) * itemsPerPage + index + 1}
                    </td>
                    <td className="px-6 py-4">
                      <span className="font-bold text-slate-800 text-lg">
                        {k.kode_kelas}
                      </span>
                      <div className="text-xs text-slate-500 mt-0.5">
                        Smt {k.semester} • {k.tahun_ajaran}
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col">
                        <span className="font-medium text-slate-900">
                          {k.mata_kuliah?.nama_mk}
                        </span>
                        <span className="text-sm text-slate-500 flex items-center gap-1.5 mt-0.5">
                          <span className="w-1.5 h-1.5 rounded-full bg-blue-500"></span>
                          {k.dosen?.user?.name}
                        </span>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col gap-1 text-sm text-slate-700">
                        <div className="flex items-center gap-1.5">
                          <Calendar className="w-3.5 h-3.5 text-slate-400" />
                          <span>Hari {k.hari}</span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <Clock className="w-3.5 h-3.5 text-slate-400" />
                          <span>
                            {k.jam_mulai.slice(0, 5)} - {k.jam_selesai.slice(0, 5)}
                          </span>
                        </div>
                        <div className="flex items-center gap-1.5">
                          <MapPin className="w-3.5 h-3.5 text-slate-400" />
                          <span>Ruang {k.ruangan?.nama}</span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex flex-col gap-1">
                        <div className="flex items-center gap-2">
                          <Users className="w-4 h-4 text-slate-400" />
                          <span className="text-sm font-medium text-slate-700">
                            {k.mahasiswas.length} / {k.kapasitas}
                          </span>
                        </div>
                        <button
                          onClick={() => handleOpenAssignModal(k)}
                          className="text-xs text-blue-600 hover:text-blue-700 font-medium flex items-center gap-1 w-max"
                        >
                          <UserPlus className="w-3 h-3" /> Kelola Mhs
                        </button>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center justify-start gap-2 opacity-0 group-hover:opacity-100 transition-opacity">
                        <button
                          onClick={() => handleOpenModal("view", k)}
                          className="p-1.5 text-slate-400 hover:text-blue-600 hover:bg-blue-50 rounded-lg"
                        >
                          <Eye className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("edit", k)}
                          className="p-1.5 text-slate-400 hover:text-amber-600 hover:bg-amber-50 rounded-lg"
                        >
                          <Edit className="w-4 h-4" />
                        </button>
                        <button
                          onClick={() => handleOpenModal("delete", k)}
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

      {/* Main Form Modal */}
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
              className="relative bg-white rounded-2xl shadow-xl w-full max-w-2xl overflow-hidden border border-slate-100"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50/50">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-blue-100 text-blue-600 flex items-center justify-center">
                    <Building2 className="w-4 h-4" />
                  </div>
                  <h3 className="text-lg font-semibold text-slate-800">
                    {modalMode === "create"
                      ? "Tambah Kelas"
                      : modalMode === "edit"
                        ? "Edit Kelas"
                        : "Detail Kelas"}
                  </h3>
                </div>
                <button
                  onClick={handleCloseModal}
                  className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="p-6 space-y-4 max-h-[70vh] overflow-y-auto">
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Kode Kelas <span className="text-red-500">*</span>
                    </label>
                    <input
                      type="text"
                      value={formData.kode_kelas || ""}
                      onChange={(e) =>
                        setFormData({ ...formData, kode_kelas: e.target.value })
                      }
                      disabled={modalMode === "view"}
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                      placeholder="Cth: A-ST001"
                      required
                    />
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Mata Kuliah <span className="text-red-500">*</span>
                    </label>
                    {mataKuliahList.length > 0 && (
                      <select
                        value={formData.mata_kuliah_id || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            mata_kuliah_id: e.target.value,
                          })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100 capitalize"
                        required
                      >
                        <option value="">-- Pilih Mata Kuliah --</option>
                        {mataKuliahList.map((mk) => (
                          <option key={mk.id} value={mk.id}>
                            {mk.nama_mk}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Dosen Pengajar <span className="text-red-500">*</span>
                    </label>
                    {dosenList.length > 0 && (
                      <select
                        value={formData.dosen_id || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            dosen_id: e.target.value,
                          })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100 capitalize"
                        required
                      >
                        <option value="">-- Pilih Dosen --</option>
                        {dosenList.map((dosen) => (
                          <option key={dosen.id} value={dosen.id}>
                            {dosen.user?.name}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Ruangan <span className="text-red-500">*</span>
                    </label>
                    {ruanganList.length > 0 && (
                      <select
                        value={formData.ruangan_id || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            ruangan_id: e.target.value,
                          })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 disabled:opacity-70 disabled:bg-slate-100 capitalize"
                        required
                      >
                        <option value="">-- Pilih Ruangan --</option>
                        {ruanganList.map((r) => (
                          <option key={r.id} value={r.id}>
                            {r.nama}
                          </option>
                        ))}
                      </select>
                    )}
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Semester & Tahun Ajaran{" "}
                      <span className="text-red-500">*</span>
                    </label>
                    <div className="grid grid-cols-2 gap-2">
                      <input
                        type="number"
                        value={formData.semester}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            semester: parseInt(e.target.value),
                          })
                        }
                        disabled={modalMode === "view"}
                        placeholder="Semester"
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm"
                        required
                      />
                      <input
                        type="text"
                        value={formData.tahun_ajaran || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            tahun_ajaran: e.target.value,
                          })
                        }
                        disabled={modalMode === "view"}
                        placeholder="Tahun Ajaran"
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Jadwal (Hari & Jam){" "}
                      <span className="text-red-500">*</span>
                    </label>
                    <div className="grid grid-cols-3 gap-2">
                      <select
                        value={formData.hari || ""}
                        onChange={(e) =>
                          setFormData({ ...formData, hari: e.target.value })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm"
                        required
                      >
                        <option value="Senin">Senin</option>
                        <option value="Selasa">Selasa</option>
                        <option value="Rabu">Rabu</option>
                        <option value="Kamis">Kamis</option>
                        <option value="Jumat">Jumat</option>
                        <option value="Sabtu">Sabtu</option>
                        <option value="Minggu">Minggu</option>
                      </select>
                      <input
                        type="time"
                        value={formData.jam_mulai || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            jam_mulai: e.target.value,
                          })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm"
                        required
                      />
                      <input
                        type="time"
                        value={formData.jam_selesai || ""}
                        onChange={(e) =>
                          setFormData({
                            ...formData,
                            jam_selesai: e.target.value,
                          })
                        }
                        disabled={modalMode === "view"}
                        className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm"
                        required
                      />
                    </div>
                  </div>

                  <div className="space-y-1.5">
                    <label className="text-sm font-medium text-slate-700">
                      Kapasitas <span className="text-red-500">*</span>
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
                      className="w-full px-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20"
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
                    className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 shadow-sm"
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

      {/* Assign Mahasiswa Modal */}
      <AnimatePresence>
        {isAssignModalOpen && selectedKelas && (
          <div className="fixed inset-0 z-50 flex items-center justify-center p-4 sm:p-0">
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setIsAssignModalOpen(false)}
              className="absolute inset-0 bg-slate-900/40 backdrop-blur-sm"
            />
            <motion.div
              initial={{ opacity: 0, scale: 0.95, y: 10 }}
              animate={{ opacity: 1, scale: 1, y: 0 }}
              exit={{ opacity: 0, scale: 0.95, y: 10 }}
              className="relative bg-white rounded-2xl shadow-xl w-full max-w-lg overflow-hidden border border-slate-100 flex flex-col max-h-[80vh]"
            >
              <div className="flex items-center justify-between px-6 py-4 border-b border-slate-100 bg-slate-50/50 shrink-0">
                <div className="flex flex-col">
                  <h3 className="text-lg font-semibold text-slate-800">
                    Assign Mahasiswa
                  </h3>
                  <p className="text-sm text-slate-500">
                    Kelas: {selectedKelas.kode_kelas} ({assignedStudents.length}{" "}
                    / {selectedKelas.kapasitas} terpilih)
                  </p>
                </div>
                <button
                  onClick={() => setIsAssignModalOpen(false)}
                  className="p-2 text-slate-400 hover:text-slate-600 hover:bg-slate-100 rounded-lg"
                >
                  <X className="w-5 h-5" />
                </button>
              </div>

              <div className="p-4 border-b border-slate-100 shrink-0">
                <div className="relative w-full">
                  <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="Cari nama atau NIM mahasiswa..."
                    value={assignSearchTerm}
                    onChange={(e) => setAssignSearchTerm(e.target.value)}
                    className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20"
                  />
                </div>
              </div>

              <div className="flex-1 overflow-y-auto p-2">
                {filteredStudents.length === 0 ? (
                  <p className="text-center text-slate-500 py-8">
                    Mahasiswa tidak ditemukan.
                  </p>
                ) : (
                  <div className="space-y-1">
                    {filteredStudents.map((mhs) => (
                      <label
                        key={mhs.id}
                        className="flex items-center justify-between p-3 hover:bg-slate-50 rounded-xl cursor-pointer transition-colors border border-transparent hover:border-slate-100"
                      >
                        <div className="flex items-center gap-3">
                          <input
                            type="checkbox"
                            checked={assignedStudents.includes(mhs.id)}
                            onChange={() => toggleStudent(mhs.id)}
                            className="w-5 h-5 text-blue-600 rounded border-slate-300 focus:ring-blue-500"
                          />
                          <div className="flex flex-col">
                            <span className="font-medium text-slate-800">
                              {mhs.name}
                            </span>
                            <span className="text-xs text-slate-500">
                              NIM: {mhs.nim} • Nama: {mhs.user?.name} • Prodi:{" "}
                              {mhs.prodi?.kode_prodi}
                            </span>
                          </div>
                        </div>
                      </label>
                    ))}
                  </div>
                )}
              </div>

              <div className="px-6 py-4 border-t border-slate-100 bg-slate-50/50 flex items-center justify-end gap-3 shrink-0">
                <button
                  onClick={() => setIsAssignModalOpen(false)}
                  className="px-4 py-2 text-sm font-medium text-slate-600 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition-colors"
                >
                  Batal
                </button>
                <button
                  onClick={handleAssignMahasiswa}
                  className="inline-flex items-center justify-center gap-2 px-4 py-2 bg-blue-600 text-white rounded-xl font-medium text-sm hover:bg-blue-700 shadow-sm"
                >
                  <Check className="w-4 h-4" />
                  <span>Simpan Mahasiswa</span>
                </button>
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
                  Hapus Kelas
                </h3>

                <p className="text-sm text-slate-500 mt-1">
                  Apakah kamu yakin ingin menghapus Kelas ini?
                </p>
              </div>

              {/* CONTENT */}
              <div className="px-6 pb-4 text-sm text-slate-600 space-y-1">
                <p>
                  <span className="font-medium text-slate-800">
                    Kode Kelas:
                  </span>{" "}
                  {formData.kode_kelas}
                </p>
                <p>
                  <span className="font-medium text-slate-800">
                    Mata Kuliah:
                  </span>{" "}
                  {formData.mata_kuliah?.nama_mk}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Dosen:</span>{" "}
                  {formData.dosen?.user.name}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Ruangan:</span>{" "}
                  {formData.ruangan?.nama}
                </p>
                <p>
                  <span className="font-medium text-slate-800">Kapasitas:</span>{" "}
                  {formData.ruangan?.kapasitas} Kursi
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
                  onClick={() => handleDelete(selectedKelas!.id)}
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
