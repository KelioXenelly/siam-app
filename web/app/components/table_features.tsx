import {
  ChevronLeft,
  ChevronRight,
  ArrowUpDown,
  ArrowDownAZ,
  ArrowUpZA,
} from "lucide-react";

interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  totalItems: number;
  itemsPerPage: number;
  onItemsPerPageChange: (value: number) => void;
}

export function Pagination({
  currentPage,
  totalPages,
  onPageChange,
  totalItems,
  itemsPerPage,
  onItemsPerPageChange,
}: PaginationProps) {
  if (totalItems === 0) return null;

  const start = (currentPage - 1) * itemsPerPage + 1;
  const end = Math.min(currentPage * itemsPerPage, totalItems);

  return (
    <div className="flex flex-col sm:flex-row items-center justify-between px-6 py-4 border-t border-slate-200 bg-slate-50/50 gap-4">
      
      <div className="text-sm text-slate-500 text-center sm:text-left">
        Menampilkan <span className="font-medium text-slate-700">{start}</span>{" "}
        hingga <span className="font-medium text-slate-700">{end}</span> dari{" "}
        <span className="font-medium text-slate-700">{totalItems}</span> data
      </div>

      <div className="flex items-center gap-2">
        <div className="flex items-center gap-2 text-sm text-slate-500">
          <span>Tampilkan</span>
          <select
            value={itemsPerPage}
            onChange={(e) => onItemsPerPageChange(Number(e.target.value))}
            className="border border-slate-200 rounded-lg px-2 py-1 bg-white text-slate-700 focus:outline-none focus:ring-2 focus:ring-blue-500/20"
          >
            {[10, 25, 50, 100].map((size) => (
              <option key={size} value={size}>
                {size}
              </option>
            ))}
          </select>
          <span>data</span>
        </div>

        <div className="flex items-center gap-2 text-sm text-slate-500">
          <button
            onClick={() => onPageChange(currentPage - 1)}
            disabled={currentPage === 1}
            className="p-1.5 rounded-lg border border-slate-200 text-slate-500 hover:bg-white hover:text-blue-600 hover:border-blue-200 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm bg-white"
          >
            <ChevronLeft className="w-4 h-4" />
          </button>
          <span className="text-sm font-medium text-slate-700 px-3 py-1 bg-white rounded-lg border border-slate-200 shadow-sm">
            {currentPage} / {totalPages}
          </span>
          <button
            onClick={() => onPageChange(currentPage + 1)}
            disabled={currentPage === totalPages}
            className="p-1.5 rounded-lg border border-slate-200 text-slate-500 hover:bg-white hover:text-blue-600 hover:border-blue-200 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm bg-white"
          >
            <ChevronRight className="w-4 h-4" />
          </button>
        </div>
      </div>
    </div>
  );
}

interface SortableHeaderProps {
  label: string;
  sortKey: string;
  currentSort: { key: string; direction: "asc" | "desc" } | null;
  onRequestSort: (key: string) => void;
  className?: string;
}

export function SortableHeader({
  label,
  sortKey,
  currentSort,
  onRequestSort,
  className = "",
}: SortableHeaderProps) {
  const isActive = currentSort?.key === sortKey;
  const isAsc = isActive && currentSort?.direction === "asc";

  return (
    <th
      className={`px-6 py-4 text-xs font-semibold text-slate-500 uppercase tracking-wider cursor-pointer hover:bg-slate-100/50 transition-colors select-none group ${className}`}
      onClick={() => onRequestSort(sortKey)}
    >
      <div
        className={`flex items-center gap-2 ${className.includes("text-right") ? "justify-end" : ""}`}
      >
        {label}
        <span className="inline-flex flex-col opacity-0 group-hover:opacity-100 transition-opacity">
          {isActive ? (
            isAsc ? (
              <ArrowDownAZ className="w-3.5 h-3.5 text-blue-600 opacity-100" />
            ) : (
              <ArrowUpZA className="w-3.5 h-3.5 text-blue-600 opacity-100" />
            )
          ) : (
            <ArrowUpDown className="w-3.5 h-3.5 text-slate-400" />
          )}
        </span>
      </div>
    </th>
  );
}
