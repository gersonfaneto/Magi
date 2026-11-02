import { Plugin } from "@opencode/plugin";
import { readFile } from "node:fs/promises";
import { spawn } from "node:child_process";

const configPath = `${process.env.HOME}/.markdownlint-cli2.cjs`;

function runMarkdownlint(filePath: string) {
  return new Promise<{ stdout: string; stderr: string; code: number }>(
    (resolve) => {
      const proc = spawn("markdownlint-cli2", [
        "--config",
        configPath,
        "--fix",
        filePath,
      ]);
      let stdout = "";
      let stderr = "";
      proc.stdout.on("data", (chunk: Buffer) => {
        stdout += chunk.toString();
      });
      proc.stderr.on("data", (chunk: Buffer) => {
        stderr += chunk.toString();
      });
      proc.on("close", (code) => {
        resolve({ stdout, stderr, code: code ?? 0 });
      });
    },
  );
}

export default Plugin.define({
  id: "md-lint",
  async setup(ctx) {
    await ctx.tool.hook("execute.after", async (event) => {
      if (event.tool !== "write" && event.tool !== "edit") return;
      if (event.status !== "completed") return;

      const input = event.input as { args?: { filePath?: string } } | undefined;
      const filePath = input?.args?.filePath;
      if (!filePath || !filePath.endsWith(".md")) return;

      let before: string;
      try {
        before = await readFile(filePath, "utf8");
      } catch {
        return;
      }

      const { stdout, stderr, code } = await runMarkdownlint(filePath);

      let after: string;
      try {
        after = await readFile(filePath, "utf8");
      } catch {
        return;
      }

      const details = [stdout, stderr].filter(Boolean).join("\n").trim();

      let feedback = "";
      if (before !== after) {
        feedback =
          "markdownlint-cli2 automatically fixed Markdown formatting. Review the updated file before finishing.";
      } else if (code !== 0) {
        feedback = `markdownlint-cli2 found unresolved issues:\n${details}`;
      }

      if (!feedback) return;

      const result = event.result as { content?: string | unknown };
      if (typeof result.content === "string") {
        result.content = `${result.content}\n\n${feedback}`;
      }

      console.log(`[md-lint] ${feedback}`);
    });
  },
});
