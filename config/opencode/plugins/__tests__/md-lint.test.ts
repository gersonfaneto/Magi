import { after, afterEach, before, describe, test } from "node:test";
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import assert from "node:assert/strict";

const directories: string[] = [];

afterEach(() => {
  for (const directory of directories.splice(0)) {
    rmSync(directory, { recursive: true, force: true });
  }
});

function makeContext() {
  const hooks = new Map<string, (event: unknown) => unknown>();
  const ctx = {
    tool: {
      hook: async (
        name: string,
        callback: (event: unknown) => unknown,
      ) => {
        hooks.set(name, callback);
        return { dispose: async () => {} };
      },
    },
  } as never;
  return { ctx, hooks };
}

function temporaryFile(name: string, content: string) {
  const directory = mkdtempSync(join(tmpdir(), "opencode-md-lint-"));
  directories.push(directory);
  const filePath = join(directory, name);
  writeFileSync(filePath, content);
  return filePath;
}

// configPath in md-lint.ts is computed from process.env.HOME at module load,
// so set HOME to a temp dir with a working config before dynamically importing.
let mdLintPlugin: unknown;
let homeDir: string;
before(async () => {
  homeDir = mkdtempSync(join(tmpdir(), "opencode-md-lint-home-"));
  writeFileSync(
    join(homeDir, ".markdownlint-cli2.cjs"),
    `module.exports = { config: { default: true, MD009: { br_spaces: 0 }, MD022: true } };`,
  );
  process.env.HOME = homeDir;
  const mod = await import("../md-lint.ts");
  mdLintPlugin = mod.default;
});

after(() => {
  rmSync(homeDir, { recursive: true, force: true });
});

describe("MdLintPlugin", () => {
  test("fixes malformed Markdown and returns model-visible feedback", async () => {
    const filePath = temporaryFile("bad.md", "## 1. Bad\nBody.\n");
    const { ctx, hooks } = makeContext();
    await mdLintPlugin.setup(ctx);

    const hook = hooks.get("execute.after");
    assert.ok(hook, "execute.after hook was not registered");

    const result = { content: "Wrote file." };
    await hook({
      tool: "write",
      status: "completed",
      input: { args: { filePath } },
      result,
    } as never);

    const after = readFileSync(filePath, "utf8");
    assert.notStrictEqual(after, "## 1. Bad\nBody.\n", "lint should have fixed the file");
    assert.ok(
      (result.content as string).includes(
        "automatically fixed Markdown formatting",
      ),
      "expected lint-fix feedback in tool output",
    );
  });

  test("leaves clean Markdown silent", async () => {
    const filePath = temporaryFile("clean.md", "# Title\n\nBody.\n");
    const { ctx, hooks } = makeContext();
    await mdLintPlugin.setup(ctx);

    const hook = hooks.get("execute.after");
    assert.ok(hook);

    const result = { content: "Edit applied." };
    await hook({
      tool: "edit",
      status: "completed",
      input: { args: { filePath } },
      result,
    } as never);

    assert.strictEqual(result.content, "Edit applied.");
  });

  test("ignores non-Markdown files and unrelated tools", async () => {
    const filePath = temporaryFile("bad.txt", "## 1. Bad\nBody.\n");
    const { ctx, hooks } = makeContext();
    await mdLintPlugin.setup(ctx);

    const hook = hooks.get("execute.after");
    assert.ok(hook);

    const result = { content: "Wrote file." };
    await hook({
      tool: "write",
      status: "completed",
      input: { args: { filePath } },
      result,
    } as never);
    await hook({
      tool: "read",
      status: "completed",
      input: { args: { filePath } },
      result,
    } as never);

    assert.strictEqual(readFileSync(filePath, "utf8"), "## 1. Bad\nBody.\n");
    assert.strictEqual(result.content, "Wrote file.");
  });
});
