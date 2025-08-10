// This file is
import type * as mbt from "./target/js/release/build/main/moonbit.d.ts";

export type Point = {
  x: mbt.Int;
  y: mbt.Int;
};

export function add(a: mbt.Int, b: mbt.Int): mbt.Int {
  return a + b;
}

export function distance(a: Point, b: Point): mbt.Float {
  const dx = a.x - b.x;
  const dy = a.y - b.y;
  return Math.sqrt(dx * dx + dy * dy);
}

export async function readFile(path: mbt.String): Promise<mbt.String> {
  const content = await Deno.readTextFile(path);
  return content;
}

export async function writeFile(
  path: mbt.String,
  content: mbt.String
): Promise<void> {
  await Deno.writeTextFile(path, content);
}
