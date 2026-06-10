import React from 'react';

interface SkeletonTableProps {
  columns: number;
  rows?: number;
}

export function SkeletonTable({ columns, rows = 5 }: SkeletonTableProps) {
  return (
    <>
      {[...Array(rows)].map((_, rowIndex) => (
        <tr key={rowIndex} className="border-b border-slate-100 last:border-0">
          {[...Array(columns)].map((_, colIndex) => (
            <td key={colIndex} className="px-6 py-4 whitespace-nowrap">
              <div 
                className="h-4 bg-slate-200 rounded animate-pulse" 
                style={{ 
                  width: colIndex === 0 ? '24px' : `${Math.random() * 40 + 40}%`,
                  animationDelay: `${colIndex * 100}ms` 
                }}
              ></div>
            </td>
          ))}
        </tr>
      ))}
    </>
  );
}
