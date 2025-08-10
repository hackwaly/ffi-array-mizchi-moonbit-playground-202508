// JavaScript wrapper for MoonBit TypeScript parser
// This file wraps the compiled MoonBit code for use from JavaScript/Deno

import * as moonbit from "./target/js/release/build/cli/cli.js";

export function parseTypeScript(code) {
  return moonbit.parseTypeScript(code);
}

export function generateFFI(code) {
  return moonbit.generateFFI(code);
}

// Re-export for compatibility
export const parse_typescript = parseTypeScript;
export const generate_ffi = generateFFI;