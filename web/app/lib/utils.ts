/**
 * Extracts a safe error message string from an API response error object.
 * Handles Laravel validation error objects, string arrays, or plain strings.
 * 
 * @param error The error object caught in a try/catch block
 * @param fallbackMessage A fallback string to return if no clear error is found
 * @returns A safe error message string to be displayed to the user
 */
export function handleApiError(error: any, fallbackMessage: string = "Terjadi kesalahan pada sistem"): string {
  // If no error object is provided, return fallback
  if (!error) return fallbackMessage;

  // Extract from error.response.data (Axios format)
  const data = error.response?.data;
  
  // If there's an explicit "errors" field (Laravel validation)
  if (data?.errors) {
    const errors = data.errors;
    
    // If errors is just a string
    if (typeof errors === 'string') return errors;
    
    // If errors is an array (less common in Laravel, but possible)
    if (Array.isArray(errors)) {
      if (errors.length > 0 && typeof errors[0] === 'string') {
        return errors[0];
      }
    }
    
    // If errors is an object (standard Laravel validation)
    // e.g. { "email": ["Email already taken."], "nim": ["NIM too short."] }
    if (typeof errors === 'object' && errors !== null) {
      const keys = Object.keys(errors);
      if (keys.length > 0) {
        const firstErrorArray = (errors as Record<string, any>)[keys[0]];
        if (Array.isArray(firstErrorArray) && firstErrorArray.length > 0) {
          return firstErrorArray[0];
        }
        // In case the value itself is just a string, not an array
        if (typeof firstErrorArray === 'string') {
          return firstErrorArray;
        }
      }
    }
  }

  // If there's a simple message field
  if (data?.message && typeof data.message === 'string') {
    // Sometimes Laravel returns "The given data was invalid." which isn't helpful
    // If there's a message but no 'errors', we can show it
    if (data.message !== "The given data was invalid." && data.message !== "Server Error") {
      return data.message;
    }
  }

  // If error has its own message (like "Network Error")
  if (error.message && typeof error.message === 'string') {
    return error.message;
  }

  return fallbackMessage;
}
