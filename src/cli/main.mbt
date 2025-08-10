// Main entry point for JavaScript build

fn main {
  // This is required for "is-main": true packages
  // The actual exports are handled by public functions
  println("MoonBit TypeScript Parser")
}

// Export functions for JavaScript build
pub fn parseTypeScript(code : String) -> String {
  parse_typescript(code)
}

pub fn generateFFI(code : String) -> String {
  generate_ffi(code)
}