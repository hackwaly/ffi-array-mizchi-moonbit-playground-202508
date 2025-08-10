// Example: ES Module Runtime Usage

///|
fn main {
  let runtime = @runtime.ESRuntime::new()

  // Basic console operations
  runtime.console_log("🌙 MoonBit ES Module Runtime")
  runtime.console_log("================================")

  // Time operations
  let start_time = runtime.date_now()
  runtime.console_log("Current timestamp: \{start_time}")

  // Timer example
  let _ = runtime.set_timeout(
    fn() { runtime.console_log("⏰ Timer fired after 1 second!") },
    1000,
  )

  // Fetch example (if available)
  runtime.console_log("\nFetch example:")
  runtime.console_log(
    "Note: This will work only in environments with fetch API",
  )

  // Using high-level fetch API
  let example_url = "https://api.github.com/repos/moonbitlang/core"
  runtime.console_log("Fetching: \{example_url}")

  // Note: In a real application, you would handle this asynchronously
  // This is a simplified example showing the API usage

  runtime.console_log("\n✅ Runtime initialized successfully!")
}
