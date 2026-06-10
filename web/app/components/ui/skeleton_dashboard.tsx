import { motion } from "motion/react";

export function SkeletonDashboard() {
  return (
    <div className="flex flex-col gap-6 w-full animate-pulse">
      {/* SUMMARY CARDS SKELETON */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
        {[...Array(4)].map((_, idx) => (
          <div
            key={idx}
            className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col relative overflow-hidden"
          >
            <div className="flex justify-between items-start mb-4">
              <div className="w-12 h-12 rounded-xl bg-slate-200" />
            </div>
            <div>
              <div className="h-4 bg-slate-200 rounded w-1/2 mb-3" />
              <div className="h-8 bg-slate-200 rounded w-3/4" />
            </div>
            <div className="mt-4 flex items-center gap-1.5">
              <div className="w-4 h-4 bg-slate-200 rounded-full" />
              <div className="h-3 bg-slate-200 rounded w-1/3" />
            </div>
          </div>
        ))}
      </div>

      {/* RECENT ACTIVITY & CHARTS SKELETON */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Chart Skeleton */}
        <div className="lg:col-span-2 bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col min-h-100">
          <div className="flex justify-between items-center mb-6">
            <div className="h-6 bg-slate-200 rounded w-1/3" />
            <div className="h-10 bg-slate-200 rounded-lg w-32" />
          </div>
          <div className="flex-1 w-full h-75 bg-slate-50 border border-slate-100 rounded-xl relative overflow-hidden">
             {/* Fake chart waves */}
             <div className="absolute bottom-0 left-0 right-0 h-1/2 bg-blue-100/30 rounded-t-full blur-2xl" />
          </div>
        </div>

        {/* Activity Feed Skeleton */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-slate-100 flex flex-col">
          <div className="flex justify-between items-center mb-6">
            <div className="h-6 bg-slate-200 rounded w-1/2" />
            <div className="h-4 bg-slate-200 rounded w-16" />
          </div>

          <div className="flex flex-col gap-5 relative">
            <div className="absolute left-3.5 top-2 bottom-2 w-px bg-slate-100" />
            {[...Array(5)].map((_, idx) => (
              <div key={idx} className="flex gap-4 relative z-10">
                <div className="w-7 h-7 rounded-full bg-slate-200 border-2 border-white ring-4 ring-slate-50 shrink-0 mt-1" />
                <div className="flex-1">
                  <div className="h-4 bg-slate-200 rounded w-3/4 mb-2" />
                  <div className="h-3 bg-slate-200 rounded w-full mb-1" />
                  <div className="h-3 bg-slate-200 rounded w-5/6 mb-2" />
                  <div className="flex items-center gap-1.5 mt-1">
                    <div className="w-3 h-3 bg-slate-200 rounded-full" />
                    <div className="h-2 bg-slate-200 rounded w-1/4" />
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
