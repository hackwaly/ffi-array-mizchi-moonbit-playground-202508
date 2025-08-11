// Test program to generate MoonBit FFI from sample-api.d.ts

fn main {
  // Read the sample .d.ts file
  let input = @fs.read_file_to_string?("./sample-api.d.ts")
  
  // Create lexer and parser
  let lexer = @typescript_parser.Lexer::new(input)
  let parser = @typescript_parser.Parser::new(lexer)
  
  // Parse the TypeScript declarations
  let declarations = parser.parse_typescript_file()
  
  println("Parsed \{declarations.length()} declarations")
  
  // Generate FFI code
  let ffi_code = @typescript_parser.generate_ffi_code(declarations)
  
  // Write to output file
  @fs.write_string_to_file("./sample-api-ffi.mbt", ffi_code)?
  
  println("FFI code generated successfully!")
  println("Output written to: sample-api-ffi.mbt")
}