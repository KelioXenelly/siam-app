import React from 'react';
import { SearchX, FolderOpen } from 'lucide-react';

interface EmptyStateProps {
  icon?: React.ElementType;
  title: string;
  description: string;
  action?: React.ReactNode;
  colSpan: number;
}

export function EmptyState({ 
  icon: Icon = SearchX, 
  title, 
  description, 
  action,
  colSpan 
}: EmptyStateProps) {
  return (
    <tr>
      <td colSpan={colSpan} className="px-6 py-16">
        <div className="flex flex-col items-center justify-center text-center">
          <div className="w-16 h-16 bg-slate-100 rounded-full flex items-center justify-center mb-4">
            <Icon className="w-8 h-8 text-slate-400" />
          </div>
          <h3 className="text-lg font-semibold text-slate-900 mb-1">{title}</h3>
          <p className="text-sm text-slate-500 max-w-sm mx-auto mb-6">
            {description}
          </p>
          {action && (
            <div>{action}</div>
          )}
        </div>
      </td>
    </tr>
  );
}
