import { useState, useEffect, useMemo } from 'react';
import useSWR from 'swr';
import api from '~/lib/api';

// Create a generic fetcher that uses our configured axios instance
const fetcher = async ([url, params]: [string, any]) => {
  const res = await api.get(url, { params });
  return res.data;
};

export function useServerTable<T>(endpoint: string, initialItemsPerPage = 10, additionalFilters: Record<string, any> = {}) {
  const [currentPage, setCurrentPage] = useState(1);
  const [itemsPerPage, setItemsPerPage] = useState(initialItemsPerPage);
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearch, setDebouncedSearch] = useState('');
  const [sortConfig, setSortConfig] = useState<{ key: string; direction: 'asc' | 'desc' } | null>(null);

  // Debounce search term
  useEffect(() => {
    const timer = setTimeout(() => {
      setDebouncedSearch(searchTerm);
      setCurrentPage(1); // Reset page on new search
    }, 500);
    return () => clearTimeout(timer);
  }, [searchTerm]);

  const requestSort = (key: string) => {
    let direction: 'asc' | 'desc' = 'asc';
    if (sortConfig && sortConfig.key === key && sortConfig.direction === 'asc') {
      direction = 'desc';
    }
    setSortConfig({ key, direction });
    setCurrentPage(1);
  };

  const params = useMemo(() => ({
    page: currentPage,
    per_page: itemsPerPage,
    search: debouncedSearch,
    sort_key: sortConfig?.key,
    sort_dir: sortConfig?.direction,
    ...additionalFilters
  }), [currentPage, itemsPerPage, debouncedSearch, sortConfig, JSON.stringify(additionalFilters)]);

  // SWR handles deduplication, caching, and background revalidation
  const { data: response, error, isLoading, mutate } = useSWR(
    [endpoint, params],
    fetcher,
    {
      keepPreviousData: true, // Prevents flashing empty state when paginating
      revalidateOnFocus: false // Don't spam if just switching tabs frequently (optional, but good for admin tables)
    }
  );

  // Parse response
  let data: T[] = [];
  let totalPages = 1;
  let totalItems = 0;

  if (response?.data) {
    const responseData = response.data;
    if (responseData && typeof responseData === 'object' && 'current_page' in responseData) {
      // Laravel Paginated Response
      data = responseData.data || [];
      totalPages = responseData.last_page || Math.ceil(responseData.total / itemsPerPage);
      totalItems = responseData.total || 0;
    } else {
      // Fallback for endpoints that haven't been migrated yet (Client-side simulation)
      const allData = Array.isArray(responseData) ? responseData : [];
      
      // Simulating search on fallback
      const filtered = debouncedSearch 
        ? allData.filter((item: any) => JSON.stringify(item).toLowerCase().includes(debouncedSearch.toLowerCase()))
        : allData;

      // Simulating pagination on fallback
      const start = (currentPage - 1) * itemsPerPage;
      data = filtered.slice(start, start + itemsPerPage);
      totalPages = Math.ceil(filtered.length / itemsPerPage) || 1;
      totalItems = filtered.length;
    }
  }

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
    isLoading: isLoading && !data.length, // Only show loading when no data is cached yet
    refreshData: () => mutate()
  };
}
