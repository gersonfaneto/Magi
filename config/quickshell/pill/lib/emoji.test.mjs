import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const Emoji = require("./emoji.js");

let failed = 0;
function eq(actual, expected, msg) {
    const a = JSON.stringify(actual);
    const e = JSON.stringify(expected);
    if (a === e) console.log("PASS " + msg);
    else { failed++; console.log("FAIL " + msg + "\n  expected " + e + "\n  got      " + a); }
}

eq(Emoji.TONE_CHOICES.length, 6, "default plus five skin tones");
eq(Emoji.TONES.length, Emoji.TONE_CHOICES.length, "tone glyphs match the UI choices");

eq(Emoji.tone("👍", 0), "👍", "tone 0 keeps the base glyph");
eq(Emoji.tone("👍", 3), "👍🏽", "tone 3 recolours a modifier base");
eq(Emoji.tone("☝️", 1), "☝🏻", "a variation selector is dropped before the modifier");
eq(Emoji.tone("👨‍🍳", 4), "👨🏾‍🍳", "a ZWJ sequence tones its first base");
eq(Emoji.tone("🫱", 5), "🫱🏿", "newer Unicode bases are included");
eq(Emoji.tone("🫶", 2), "🫶🏼", "heart hands tones too");
eq(Emoji.tone("😀", 3), "😀", "glyphs without a modifier base stay unchanged");
eq(Emoji.tone("❤️", 3), "❤️", "the heart is not a modifier base");
eq(Emoji.tone("👍", 99), "👍", "out-of-range tones fall back to the base");

const all = Emoji.all();
const base = all.find((e) => e.glyph === "👋");
eq(Emoji.tone(base.glyph, 2), "👋🏼", "the bundled table feeds the tone helper");

if (failed > 0) { console.log("\n" + failed + " test(s) FAILED"); process.exit(1); }
console.log("\nAll tests PASSED");
