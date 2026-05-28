import { useState, useEffect, useCallback } from 'react';
import api from '~/lib/api';

export function useServerTable<T>(endpoint: string, initialItemsPerPage = 10, additionalFilters: Record<string, any> = {}) {
  const [data, setData] = useState<T[]>([]);
  const [currentPage, setCurrentPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalItems, setTotalItems] = useState(0);
  const [isLoading, setIsLoading] = useState(true);
  const [itemsPerPage, setItemsPerPage] = useState(initialItemsPerPage);
  const [searchTerm, setSearchTerm] = useState('');
  const [sortConfig, setSortConfig] = useState<{ key: string; direction: 'asc' | 'desc' } | null>(null);

  const requestSort = (key: string) => {
    let direction: 'asc' | 'desc' = 'asc';
    if (sortConfig && sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
    setCurrentPage(1);
  };

  const fetchData = useCallback(async () => {
    setIsLoading(true);
    try {
      const params = {
        page: currentPage,
        per_page: itemsPerPage,
        search: searchTerm,
        sort_key: sortConfig?.key,
        sort_dir: sortConfig?.direction,
        ...additionalFilters
      };
      
      const res = await api.get(endpoint, { params });
      
      // Handle standard Laravel paginated response vs non-paginated (fallback)
      const responseData = res.data.data;
      if (responseData && typeof responseData === 'object' && 'current_page' in responseData) {
        setData(responseData.data || []);
        setCurrentPage(responseData.current_page);
        setTotalPages(responseData.last_page || Math.ceil(responseData.total / itemsPerPage));
        setTotalItems(responseData.total || 0);
      } else {
        // Fallback for endpoints that haven't been migrated yet (Client-side simulation)
        const allData = Array.isArray(responseData) ? responseData : [];
        
        // Simulating search on fallback
        const filtered = searchTerm 
          ? allData.filter(item => JSON.stringify(item).toLowerCase().includes(searchTerm.toLowerCase()))
          : allData;

        // Simulating pagination on fallback
        const start = (currentPage - 1) * itemsPerPage;
        const paginatedFallback = filtered.slice(start, start + itemsPerPage);
        
        setData(paginatedFallback);
        setTotalPages(Math.ceil(filtered.length / itemsPerPage) || 1);
        setTotalItems(filtered.length);
      }
    } catch (error) {
      console.error("Failed to fetch table data", error);
    } finally {
      setIsLoading(false);
    }
  }, [endpoint, currentPage, itemsPerPage, searchTerm, sortConfig, JSON.stringify(additionalFilters)]);

  useEffect(() => {
    // Debounce search with 500ms delay to prevent API spam
    const timer = setTimeout(() => {
      fetchData();
    }, 500);
    return () => clearTimeout(timer);
  }, [fetchData]);

  return {
    currentData: data,
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
    refreshData: fetchData
  };
}
