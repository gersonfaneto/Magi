import { createRequire } from "node:module";
import { readFileSync } from "node:fs";
const require = createRequire(import.meta.url);
const Bangs = require("./bangs.js");

// The surface names are canonical in Pill.qml's `surfaces` map; keep the bang
// table from drifting away from it without duplicating the list here.
const pill = readFileSync(new URL("../Pill.qml", import.meta.url), "utf8");
const surfacesStart = pill.indexOf("readonly property var surfaces: ({");
const surfacesBlock = pill.slice(surfacesStart, pill.indexOf("\n    })", surfacesStart));
const surfaceNames = new Set(
    [...surfacesBlock.matchAll(/^\s{8}([A-Za-z][A-Za-z0-9]*):\s*\{/gm)].map((m) => m[1])
);

let failed = 0;
function eq(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a === e) console.log("PASS " + msg);
    else { failed++; console.log("FAIL " + msg + "\n  expected " + e + "\n  got      " + a); }
}
function ok(cond, msg) { eq(!!cond, true, msg); }

const ids = Bangs.bangs.map((b) => b.id);
eq(new Set(ids).size, ids.length, "every bang id is unique");

const words = [];
for (const b of Bangs.bangs) {
    ok(b.id.length > 0 && b.title.length > 0 && b.desc.length > 0, b.id + " has id, title and desc");
    ok(["surface", "menu", "exec", "action"].includes(b.kind), b.id + " has a known kind");
    ok(Array.isArray(b.target) ? b.target.length > 0 : String(b.target).length > 0, b.id + " has a target");
    if (b.kind === "surface")
        ok(surfaceNames.has(b.target), b.id + " points at a real Pill.qml surface");
    if (b.kind === "menu")
        ok(b.target[0] === "magi" && b.target[1] === "@menu", b.id + " runs a magi @menu script");
    if (b.kind === "exec")
        ok(Array.isArray(b.target) && b.target.length > 0, b.id + " has an argv");
    words.push(b.id.toLowerCase(), ...b.aliases.map((a) => a.toLowerCase()));
}
eq(new Set(words).size, words.length, "every id and alias is unique");

eq(Bangs.parse("!mix").word, "mix", "parse reads the bang word");
eq(Bangs.parse("!file --dir /tmp").args, ["--dir", "/tmp"], "parse splits arguments");
eq(Bangs.parse('!file --dir "/tmp/a b"').args, ["--dir", "/tmp/a b"], "quoted arguments keep spaces");
eq(Bangs.parse("!").word, "", "bare bang has no word");
eq(Bangs.parse("  !  ").word, "", "bare bang tolerates spaces");

eq(Bangs.resolve("!mix").entry.id, "mixer", "alias resolves to its entry");
eq(Bangs.resolve("!volume").entry.id, "mixer", "second alias resolves too");
eq(Bangs.resolve("!bt").entry.id, "bt", "short id does not lose to a longer prefix");
eq(Bangs.resolve("!bat").entry.id, "battery", "bat is battery, not bluetooth");
eq(Bangs.resolve("!newpass").entry.id, "rbw-new", "specific alias beats a prefix");
eq(Bangs.resolve("!hex").entry.id, "color", "color picker keeps the hex alias");
eq(Bangs.resolve("!rgb").entry.id, "rgb", "color picker exposes rgb");
eq(Bangs.resolve("!hsl").entry.id, "hsl", "color picker exposes hsl");
eq(Bangs.resolve("!file --dir /tmp").args, ["--dir", "/tmp"], "resolve returns the arguments");
eq(Bangs.resolve("!nosuch"), null, "unknown bang resolves to null");
eq(Bangs.resolve("!"), null, "bare bang resolves to null");

const empty = Bangs.search("!");
eq(empty.length, Bangs.bangs.length, "bare bang lists every entry");
eq(Bangs.search("!mi")[0].id, "mixer", "prefix search ranks the exact prefix first");
eq(Bangs.search("!se")[0].id, "settings", "prefix search finds settings");

const mixer = Bangs.resolve("!mix").entry;
eq(Bangs.command(mixer, "!mix"), "!mixer", "command canonicalizes the word");
const file = Bangs.resolve("!file").entry;
eq(Bangs.command(file, '!fil --dir "/tmp/a b"'), '!file --dir "/tmp/a b"', "command keeps the argument text");

if (failed > 0) { console.log("\n" + failed + " test(s) FAILED"); process.exit(1); }
console.log("\nAll tests PASSED");
