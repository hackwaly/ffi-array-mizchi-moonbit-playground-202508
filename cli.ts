#!/usr/bin/env deno
// deno run -A cli.ts parse test.d.ts

/**
 * TypeScript parser CLI
 *
 * Usage:
 *   ts-node cli.ts parse <file.ts>       - Parse TypeScript file and output AST as JSON
 *   ts-node cli.ts ffi <file.ts>         - Generate FFI bindings from TypeScript file
 */

import fs from "node:fs";
import path from "node:path";
import process from "node:process";

// Import the MoonBit compiled module
// Note: You need to build the MoonBit code first with: moon build --target js
async function loadMoonBitModule() {
  try {
    // Try to load the compiled module
    const modulePath = path.join(
      process.cwd(),
      "target/js/release/build/cli/cli.js"
    );
    if (!fs.existsSync(modulePath)) {
      console.error(
        "Error: MoonBit module not found. Please run: moon build --target js"
      );
      process.exit(1);
    }

    // Dynamic import of the module
    const module = await import(modulePath);
    return module;
  } catch (error) {
    console.error("Error loading MoonBit module:", error);
    process.exit(1);
  }
}

async function main() {
  const args = process.argv.slice(2);

  if (args.length < 2) {
    console.log("Usage:");
    console.log(
      "  ts-node cli.ts parse <file.ts>  - Parse TypeScript file and output AST as JSON"
    );
    console.log(
      "  ts-node cli.ts ffi <file.ts>    - Generate FFI bindings from TypeScript file"
    );
    process.exit(1);
  }

  const command = args[0];
  const filePath = args[1];

  // Check if file exists
  if (!fs.existsSync(filePath)) {
    console.error(`Error: File not found: ${filePath}`);
    process.exit(1);
  }

  // Read the TypeScript file
  const code = fs.readFileSync(filePath, "utf-8");

  // Load MoonBit module
  const moonbit = await loadMoonBitModule();

  try {
    switch (command) {
      case "parse": {
        // Parse and output AST as JSON
        const astJson = moonbit.parse_typescript(code);
        const ast = JSON.parse(astJson);
        console.log(JSON.stringify(ast, null, 2));
        break;
      }

      case "ffi": {
        // Generate FFI bindings
        const ffiCode = moonbit.generate_ffi(code);
        console.log(ffiCode);
        break;
      }

      default:
        console.error(`Unknown command: ${command}`);
        console.log("Available commands: parse, ffi");
        process.exit(1);
    }
  } catch (error) {
    console.error("Error processing file:", error);
    process.exit(1);
  }
}

// Run the CLI
main().catch((error) => {
  console.error("Fatal error:", error);
  process.exit(1);
});
