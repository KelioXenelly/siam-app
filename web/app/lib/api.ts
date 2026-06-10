import axios from "axios";

// Fallback to localhost if environment variable is not provided
const baseURL = import.meta.env?.VITE_API_URL || "http://localhost:8000/api";
export const API_HOST = baseURL.replace(/\/api\/?$/, "");

const api = axios.create({
  baseURL,
});

api.interceptors.request.use((config) => {
  // Guard against SSR environment where localStorage is not defined
  if (typeof window !== "undefined") {
    const token = localStorage.getItem("token");

    if (token) {
      config.headers["Authorization"] = `Bearer ${token}`;
    }
  }

  return config;
});

api.interceptors.response.use(
  (response) => response,
  (error) => {
    if (error.response && error.response.status === 401) {
      // Guard against SSR environment
      if (typeof window !== "undefined") {
        // Handle unauthorized access
        localStorage.removeItem("token");
        
        // Prevent full page refresh if the user is already on the login page
        if (window.location.pathname !== "/login") {
          window.location.href = "/login";
        }
      }
    }
    
    return Promise.reject(error);
  }
);

export default api;