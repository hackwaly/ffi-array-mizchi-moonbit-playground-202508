import { parse_code } from "./target/js/release/build/typescript_parser/typescript_parser.js";

const out = parse_code("let x = 5;");

console.log(out);
