import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { visibleApps } = require("./apps.js");

let failed = 0;
function eq(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a === e) console.log("PASS " + msg);
    else { failed++; console.log("FAIL " + msg + "\n  expected " + e + "\n  got      " + a); }
}

const files = { id: "files.desktop", name: "Files" };
const vim = { id: "vim.desktop", name: "Vim", runInTerminal: true };
const daemon = { id: "daemon.desktop", name: "Daemon", noDisplay: true };
const nvim = { id: "nvim.desktop", name: "Neovim", runInTerminal: true };

eq(
    visibleApps([vim, files, daemon, nvim]),
    [files],
    "drops noDisplay and Terminal=true entries"
);

eq(
    visibleApps([files]),
    [files],
    "keeps ordinary entries"
);

eq(
    visibleApps([null, undefined, vim]),
    [],
    "ignores missing entries"
);

if (failed > 0) { console.log("\n" + failed + " test(s) FAILED"); process.exit(1); }
console.log("\nAll tests PASSED");
