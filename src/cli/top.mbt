// Export wrapper for JavaScript
// This file provides the entry points for the JavaScript module

// Re-export the main functions for JavaScript
pub fn js_parse_typescript(code : String) -> String {
  parse_typescript(code)
}

pub fn js_generate_ffi(code : String) -> String {
  generate_ffi(code)
}