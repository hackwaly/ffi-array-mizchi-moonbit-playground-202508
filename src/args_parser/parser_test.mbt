// Minimal tests for args parser: short cluster, concatenated value, equals syntax, sentinel

///|
test "cluster flags -abc sets a,b,c true" {
  let cfg = ParserConfig::default()
  cfg.boolean_flags.push("a")
  cfg.boolean_flags.push("b")
  cfg.boolean_flags.push("c")
  let res = parse_args(["-abc"], cfg)
  match res.flags["a"] {
    Some(v) => assert_true(v)
    None => assert_true(false)
  }
  match res.flags["b"] {
    Some(v) => assert_true(v)
    None => assert_true(false)
  }
  match res.flags["c"] {
    Some(v) => assert_true(v)
    None => assert_true(false)
  }
}

///|
test "cluster + value -abIxx => a=true,b=true,I=xx" {
  let cfg = ParserConfig::default()
  cfg.boolean_flags.push("a")
  cfg.boolean_flags.push("b")
  cfg.string_options.push("I")
  let res = parse_args(["-abIxx"], cfg)
  match res.flags["a"] {
    Some(v) => assert_true(v)
    None => assert_true(false)
  }
  match res.flags["b"] {
    Some(v) => assert_true(v)
    None => assert_true(false)
  }
  match res.options["I"] {
    Some(v) => assert_eq(v, "xx")
    None => assert_true(false)
  }
}

///|
test "short concatenated value split across argv: -I path" {
  let cfg = ParserConfig::default()
  cfg.string_options.push("I")
  let res = parse_args(["-I", "path"], cfg)
  match res.options["I"] {
    Some(v) => assert_eq(v, "path")
    None => assert_true(false)
  }
}

///|
test "equals long --output=out" {
  let cfg = ParserConfig::default()
  cfg.string_options.push("output")
  let res = parse_args(["--output=out"], cfg)
  match res.options["output"] {
    Some(v) => assert_eq(v, "out")
    None => assert_true(false)
  }
}

///|
test "equals short -v=123" {
  let cfg = ParserConfig::default()
  // short name 'v' treated as standalone option
  cfg.string_options.push("v")
  let res = parse_args(["-v=123"], cfg)
  match res.options["v"] {
    Some(v) => assert_eq(v, "123")
    None => assert_true(false)
  }
}

///|
test "flag with equals value keeps flag true (compat): -f=true" {
  let cfg = ParserConfig::default()
  cfg.boolean_flags.push("f")
  let res = parse_args(["-f=true"], cfg)
  match res.flags["f"] {
    Some(v) => assert_true(v)
    None => assert_true(false)
  }
  // Ensure it wasn't recorded as an option
  match res.options["f"] {
    Some(_v) => assert_true(false)
    None => assert_true(true)
  }
}

///|
test "sentinel -- stops option parsing and preserves following as positionals" {
  let cfg = ParserConfig::default()
  cfg.boolean_flags.push("a")
  cfg.boolean_flags.push("b")
  cfg.boolean_flags.push("c")
  let res = parse_args(["-a", "--", "-bc", "--name=val"], cfg)
  match res.flags["a"] {
    Some(v) => assert_true(v)
    None => assert_true(false)
  }
  assert_eq(res.positionals.length(), 2)
  assert_eq(res.positionals[0], "-bc")
  assert_eq(res.positionals[1], "--name=val")
}
