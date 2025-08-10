// Command-line argument parser inspired by Node.js util.parseArgs
// Supports formats:
// - Long options with equals: --foo=bar
// - Long options with space: --foo bar
// - Short options with space: -f bar
// - Short options with equals: -f=bar
// - Boolean flags: --verbose, -v
// - Multiple short options: -abc (equivalent to -a -b -c)
// - Short value concatenation: -Ipath
// - Sentinel: -- (everything after is positional)

///|
pub struct ParsedArgs {
  options : Map[String, String]
  flags : Map[String, Bool]
  positionals : Array[String]
}

///|
pub struct ParserConfig {
  // Map short options to long names (e.g., "v" -> "verbose")
  aliases : Map[String, String]
  // Options that expect values
  string_options : Array[String]
  // Boolean flags (no value expected)
  boolean_flags : Array[String]
  // Allow unknown options
  allow_unknown : Bool
}

///|
pub fn ParserConfig::default() -> ParserConfig {
  {
    aliases: Map::new(),
    string_options: [],
    boolean_flags: [],
    allow_unknown: true,
  }
}

///|
pub fn parse_args(args : Array[String], config : ParserConfig) -> ParsedArgs {
  let options : Map[String, String] = Map::new()
  let flags : Map[String, Bool] = Map::new()
  let positionals : Array[String] = []
  let mut i = 0
  let mut parsing_options = true
  while i < args.length() {
    let arg = args[i]

    // Sentinel: after "--" treat everything as positional
    if parsing_options && arg == "--" {
      parsing_options = false
      i = i + 1
      continue
    }

    // Positional if options-parsing is disabled or does not start with "-"
    if not(parsing_options) || not(has_prefix(arg, "-")) {
      positionals.push(arg)
      i = i + 1
      continue
    }

    // Long options: start with "--"
    if has_prefix(arg, "--") {
      let option_part = arg.substring(start=2)
      // --name=value
      let eq_idx = option_part.index_of("=")
      if eq_idx >= 0 {
        let name = option_part.substring(end=eq_idx)
        let value = option_part.substring(start=eq_idx + 1)
        let canonical_name = resolve_option_name(name, config)
        if is_boolean_flag(canonical_name, config) {
          // Unexpected value for flag: keep backward-compat by setting flag true
          flags[canonical_name] = true
        } else {
          options[canonical_name] = value
        }
        i = i + 1
        continue
      }

      // --name value  OR  --name (flag)
      let canonical_name = resolve_option_name(option_part, config)
      if is_boolean_flag(canonical_name, config) {
        flags[canonical_name] = true
        i = i + 1
        continue
      } else if is_string_option(canonical_name, config) {
        // value in next argument (compat: if next starts with "-" then treat as flag)
        if i + 1 < args.length() && not(has_prefix(args[i + 1], "-")) {
          options[canonical_name] = args[i + 1]
          i = i + 2
          continue
        } else {
          // fallback to flag for backward-compat
          flags[canonical_name] = true
          i = i + 1
          continue
        }
        // Unknown option
      } else if config.allow_unknown {
        // treat as flag or consume next arg as value if looks like a value
        if i + 1 < args.length() && not(has_prefix(args[i + 1], "-")) {
          options[canonical_name] = args[i + 1]
          i = i + 2
          continue
        } else {
          flags[canonical_name] = true
          i = i + 1
          continue
        }
      } else {
        // strict-ish but maintain compat: mark as flag
        flags[canonical_name] = true
        i = i + 1
        continue
      }
    }

    // Short options: start with "-" (but not "--")
    if has_prefix(arg, "-") {
      let short_part = arg.substring(start=1)

      // -o=val
      let eq_idx2 = short_part.index_of("=")
      if eq_idx2 >= 0 {
        let name = short_part.substring(end=eq_idx2)
        let value = short_part.substring(start=eq_idx2 + 1)
        let canonical_name = resolve_option_name(name, config)
        if is_boolean_flag(canonical_name, config) {
          // Unexpected value for flag: keep backward-compat by setting flag true
          flags[canonical_name] = true
        } else {
          options[canonical_name] = value
        }
        i = i + 1
        continue
      }

      // Cluster handling: -abc or -Ipath
      let mut j = 0
      let mut consumed_current_arg = false
      while j < short_part.length() {
        let ch = char_at(short_part, j)
        let canonical_name = resolve_option_name(ch, config)
        if is_boolean_flag(canonical_name, config) {
          flags[canonical_name] = true
          j = j + 1
          continue
        }
        if is_string_option(canonical_name, config) {
          // Value concatenated in same token: -Ipath
          let rest = if j + 1 < short_part.length() {
            short_part.substring(start=j + 1)
          } else {
            ""
          }
          if rest.length() > 0 {
            options[canonical_name] = rest
            i = i + 1
            // Value in next argv (compat: if next starts with "-" then fallback to flag)
          } else if i + 1 < args.length() && not(has_prefix(args[i + 1], "-")) {
            options[canonical_name] = args[i + 1]
            i = i + 2
          } else {
            // Missing value: cannot return error in current API, fallback to flag
            flags[canonical_name] = true
            i = i + 1
          }
          consumed_current_arg = true
          break
        }

        // Unknown short option
        if config.allow_unknown {
          flags[canonical_name] = true
        } else {
          // strict-ish but compat
          flags[canonical_name] = true
        }
        j = j + 1
      }
      if not(consumed_current_arg) {
        i = i + 1
      }
      continue
    }

    // Fallback (should not reach)
    positionals.push(arg)
    i = i + 1
  }
  { options, flags, positionals }
}

///|
fn resolve_option_name(name : String, config : ParserConfig) -> String {
  match config.aliases[name] {
    Some(long_name) => long_name
    None => name
  }
}

///|
fn is_boolean_flag(name : String, config : ParserConfig) -> Bool {
  for flag in config.boolean_flags {
    if flag == name {
      return true
    }
  }
  false
}

///|
fn is_string_option(name : String, config : ParserConfig) -> Bool {
  for opt in config.string_options {
    if opt == name {
      return true
    }
  }
  false
}

// Helper function to create config with common aliases (kept for compatibility)

///|
pub fn ParserConfig::with_common_aliases() -> ParserConfig {
  let config = ParserConfig::default()
  config.aliases["h"] = "help"
  config.aliases["v"] = "version"
  config.aliases["V"] = "verbose"
  config.aliases["f"] = "file"
  config.aliases["o"] = "output"
  config.aliases["i"] = "input"
  config.aliases["d"] = "debug"
  config.aliases["q"] = "quiet"
  config.boolean_flags.push("help")
  config.boolean_flags.push("version")
  config.boolean_flags.push("verbose")
  config.boolean_flags.push("debug")
  config.boolean_flags.push("quiet")
  config.string_options.push("file")
  config.string_options.push("output")
  config.string_options.push("input")
  config
}

// Utility to parse command line args, skipping the program name

///|
pub fn parse_cli_args(
  argv : Array[String],
  config : ParserConfig,
) -> ParsedArgs {
  let args = if argv.length() > 0 {
    let acc : Array[String] = []
    for idx = 1; idx < argv.length(); idx = idx + 1 {
      acc.push(argv[idx])
    }
    acc
  } else {
    []
  }
  parse_args(args, config)
}

// ===== Local helpers for string handling (compatible with Moonbit core) =====

// Return true if s starts with prefix

///|
fn has_prefix(s : String, prefix : String) -> Bool {
  if s.length() < prefix.length() {
    return false
  }
  s.substring(end=prefix.length()) == prefix
}

// Get single-character string at index i

///|
fn char_at(s : String, i : Int) -> String {
  s.substring(start=i, end=i + 1)
}
