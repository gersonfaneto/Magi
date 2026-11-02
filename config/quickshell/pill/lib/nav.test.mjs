import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const { clamp, step, page, edge } = require("./nav.js");

let failed = 0;
function eq(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a === e) console.log("PASS " + msg);
    else { failed++; console.log("FAIL " + msg + "\n  expected " + e + "\n  got      " + a); }
}

eq(step(-1, 5, 1, false), 0, "first step down lands on row 0");
eq(step(-1, 5, -1, false), 4, "first step up lands on the last row");
eq(step(0, 5, -1, false), 0, "clamp at the top");
eq(step(4, 5, 1, false), 4, "clamp at the bottom");
eq(step(4, 5, 1, true), 0, "wrap bottom to top");
eq(step(0, 5, -1, true), 4, "wrap top to bottom");
eq(step(2, 5, 9, true), 1, "wrap repeatedly");
eq(step(0, 0, 1, true), -1, "empty list");
eq(step(2, 5, 0, true), 2, "zero delta stays put");

eq(page(0, 30, 1, 8, false), 8, "page down by a viewport");
eq(page(29, 30, 1, 8, false), 29, "page down clamps");
eq(page(0, 30, -1, 8, true), 22, "page up wraps");
eq(page(0, 0, 1, 8, true), -1, "page on empty list");

eq(edge(5, -1), 0, "edge to first");
eq(edge(5, 1), 4, "edge to last");
eq(edge(0, 1), -1, "edge on empty list");

eq(clamp(9, 0, 4), 4, "clamp high");
eq(clamp(-3, 0, 4), 0, "clamp low");

if (failed > 0) { console.log("\n" + failed + " test(s) FAILED"); process.exit(1); }
console.log("\nAll tests PASSED");
