import React, { useEffect, useState } from "react";
import { motion, AnimatePresence } from "motion/react";
import { Clock, Search, History } from "lucide-react";
import { toast } from "sonner";
import api from "~/lib/api";
import { handleApiError } from "~/lib/utils";
import { useServerTable } from "~/hooks/useServerTable";
import { Pagination, SortableHeader } from "~/components/table_features";
import type { Activity } from "~/types/activity";

export function meta() {
  return [
    { title: "Log Aktivitas | SIAM Admin" },
    { name: "description", content: "Riwayat aktivitas sistem SIAM." },
  ];
}

export default function ActivityLogsPage() {
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
    isLoading
  } = useServerTable<Activity>("/activity-logs", 10);

  const handleItemsPerPageChange = (value: number) => {
    setItemsPerPage(value);
    setCurrentPage(1);
  };

  return (
    <div className="flex flex-col gap-6 h-full">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h1 className="text-2xl font-bold text-slate-800 tracking-tight">
            Log Aktivitas
          </h1>
          <p className="text-sm text-slate-500 mt-1">
            Pantau seluruh riwayat aktivitas yang terjadi di dalam sistem.
          </p>
        </div>
      </div>

      <div className="bg-white p-4 rounded-2xl border border-slate-200 shadow-sm flex flex-col gap-4">
        <div className="relative w-full">
          <Search className="w-5 h-5 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Cari berdasarkan aksi, detail, atau nama pengguna..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="w-full pl-10 pr-4 py-2.5 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-none focus:ring-2 focus:ring-blue-500/20 focus:border-blue-500 transition-all"
          />
        </div>
      </div>

      <div className="bg-white border border-slate-200 rounded-2xl shadow-sm flex-1 overflow-hidden flex flex-col">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="border-b border-slate-200 bg-slate-50/50">
                <th className="px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider w-12">
                  No
                </th>
                <SortableHeader
                  label="Aktivitas"
                  sortKey="action"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Pengguna"
                  sortKey="user_name"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
                <SortableHeader
                  label="Waktu"
                  sortKey="created_at"
                  currentSort={sortConfig}
                  onRequestSort={requestSort as (key: string) => void}
                />
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-200">
              {isLoading ? (
                <tr>
                  <td colSpan={4} className="px-6 py-12 text-center text-slate-500">
                    <div className="flex justify-center items-center gap-2">
                      <span className="w-5 h-5 border-2 border-slate-300 border-t-blue-600 rounded-full animate-spin"></span>
                      Memuat data...
                    </div>
                  </td>
                </tr>
              ) : currentData.length === 0 ? (
                <tr>
                  <td
                    colSpan={4}
                    className="px-6 py-12 text-center text-slate-500"
                  >
                    Tidak ada log aktivitas yang ditemukan.
                  </td>
                </tr>
              ) : (
                currentData.map((log, index) => (
                  <tr
                    key={log.id}
                    className="hover:bg-slate-50/50 transition-colors group"
                  >
                    <td className="px-6 py-4 text-sm text-slate-500">
                      {(currentPage - 1) * itemsPerPage + index + 1}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex gap-4 items-center">
                        <div
                          className={`w-8 h-8 shrink-0 rounded-full flex items-center justify-center border-2 border-white ring-4 ring-slate-50 ${
                            log.status === "success"
                              ? "bg-emerald-100 text-emerald-600"
                              : log.status === "warning"
                                ? "bg-amber-100 text-amber-600"
                                : "bg-blue-100 text-blue-600"
                          }`}
                        >
                          <History className="w-4 h-4" />
                        </div>
                        <div className="flex flex-col">
                          <span className="font-semibold text-slate-800">
                            {log.action}
                          </span>
                          <span className="text-sm text-slate-500 mt-0.5">
                            {log.detail}
                          </span>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4 font-medium text-slate-700">
                      {log.user_name || "Sistem"}
                    </td>
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-1.5 text-sm font-medium text-slate-500">
                        <Clock className="w-4 h-4 text-slate-400" />
                        {log.time}
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
    </div>
  );
}
