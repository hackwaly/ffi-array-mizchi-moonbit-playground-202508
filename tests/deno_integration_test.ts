import { assertEquals } from "jsr:@std/assert";

const td = new TextDecoder();

Deno.test("Moonbit JS build and type-check integration", async (t) => {
  const run = async (cmd: string, args: string[]) => {
    const { code, stdout, stderr } = await new Deno.Command(cmd, {
      args,
    }).output();
    return { code, stdout, stderr };
  };

  await t.step("build: moon build -t js --release", async () => {
    const { code, stdout, stderr } = await run("moon", [
      "build",
      "--target",
      "js",
      "--release",
    ]);
    if (code !== 0) {
      console.error("[moon build -t js --release] failed");
      console.error(td.decode(stderr));
    }
    assertEquals(code, 0);
    if (stdout && stdout.length > 0) console.log(td.decode(stdout));
  });

  await t.step("type-check: deno check sample-bindings.ts", async () => {
    const { code, stdout, stderr } = await run("deno", [
      "check",
      "sample-bindings.ts",
    ]);
    if (code !== 0) {
      console.error("[deno check sample-bindings.ts] failed");
      console.error(td.decode(stderr));
    }
    assertEquals(code, 0);
    if (stdout && stdout.length > 0) console.log(td.decode(stdout));
  });
});
