/**
 * Bang table for the launcher. A bang is a single descriptive word typed after
 * `!` (`!mix`, `!file --dir /tmp`), the way DuckDuckGo bangs route a search. Here
 * it routes a command to a pill surface or a `magi @menu` script, so the
 * Hyprland config keeps only the launcher (plus clipboard and power, the two
 * exceptions frequent enough to deserve a chord).
 *
 * Entry shape:
 *   id      canonical word after `!`; also the stable name for `ipc call bang`
 *   aliases extra words that resolve to the same entry
 *   title   row heading
 *   desc    one-line explanation under it
 *   kind    "surface" (a Pill.qml surface name), "menu" (a `magi @menu`
 *           argv prefix), "exec" (any argv) or "action" (a shell toggle with
 *           no surface)
 *   target  surface name, argv (menu or exec), or action name
 *
 * Search is forgiving: exact id/alias first, then prefixes, substrings and a
 * subsequence fallback. Once the first whitespace is crossed the rest is
 * arguments, passed through to menu commands (`!file --dir /tmp`). Quoted
 * arguments keep their spaces; `~` is not expanded because the argv is handed
 * to execve, not a shell.
 */

var bangs = [
    // * Surfaces

    { id: "mixer", aliases: ["mix", "audio", "vol", "volume"], title: "Mixer",
      desc: "Brightness, vibrance, volume and mic", kind: "surface", target: "mixer" },
    { id: "sound", aliases: ["eq"], title: "Sound",
      desc: "EQ, per-app volume and microphone", kind: "surface", target: "sound" },
    { id: "calendar", aliases: ["cal", "date"], title: "Calendar",
      desc: "Month grid, events and weather", kind: "surface", target: "calendar" },
    { id: "clipboard", aliases: ["clip", "paste"], title: "Clipboard",
      desc: "Clipboard history", kind: "surface", target: "clipboard" },
    { id: "wallpaper", aliases: ["wall", "bg"], title: "Wallpaper",
      desc: "Wallpaper filmstrip", kind: "surface", target: "wallpaper" },
    { id: "power", aliases: ["pow", "session"], title: "Power",
      desc: "Lock, logout, sleep, restart, shutdown", kind: "surface", target: "power" },
    { id: "media", aliases: ["music", "player"], title: "Media",
      desc: "Now playing", kind: "surface", target: "media" },
    { id: "link", aliases: ["notif", "notifications", "inbox"], title: "Notifications",
      desc: "Notification inbox", kind: "surface", target: "link" },
    { id: "wifi", aliases: ["net", "network"], title: "Wifi",
      desc: "Wifi networks", kind: "surface", target: "wifi" },
    { id: "bt", aliases: ["bluetooth"], title: "Bluetooth",
      desc: "Bluetooth devices", kind: "surface", target: "bt" },
    { id: "battery", aliases: ["bat"], title: "Battery",
      desc: "Battery read-out", kind: "surface", target: "battery" },
    { id: "settings", aliases: ["set", "prefs"], title: "Settings",
      desc: "Settings index", kind: "surface", target: "settings" },
    { id: "keybinds", aliases: ["keys", "binds", "shortcuts"], title: "Keybinds",
      desc: "Edit Hyprland keybinds", kind: "surface", target: "keybinds" },
    { id: "workspaces", aliases: ["ws", "spaces"], title: "Workspaces",
      desc: "Special workspaces and their apps", kind: "surface", target: "workspaces" },
    { id: "stash", aliases: ["stashed"], title: "Stash",
      desc: "Apps routed to the stash space", kind: "surface", target: "stash" },
    { id: "spaceapps", aliases: ["space-apps"], title: "Space apps",
      desc: "Apps in a special workspace", kind: "surface", target: "spaceapps" },
    { id: "recorder", aliases: ["rec", "record"], title: "Recorder",
      desc: "Screen recorder", kind: "surface", target: "recorder" },
    { id: "sysmon", aliases: ["sys", "monitor"], title: "System",
      desc: "System monitor", kind: "surface", target: "sysmon" },
    { id: "theme", aliases: ["colors", "palette"], title: "Theme",
      desc: "Palette and wallpaper theme", kind: "surface", target: "theme" },
    { id: "appearance", aliases: ["style"], title: "Appearance",
      desc: "Clock, glyphs, scale and motion", kind: "surface", target: "appearance" },
    { id: "updates", aliases: ["update", "upgrade"], title: "Updates",
      desc: "Quickshell updates", kind: "surface", target: "updates" },
    { id: "display", aliases: ["disp", "monitors"], title: "Display",
      desc: "Monitor layout, resolution and scale", kind: "surface", target: "display" },
    { id: "input", aliases: ["kbd", "keyboard", "pointer"], title: "Input",
      desc: "Pointer, keyboard and cursor", kind: "surface", target: "input" },
    { id: "look", aliases: ["deco", "decoration"], title: "Look",
      desc: "Gaps, rounding, opacity and blur", kind: "surface", target: "look" },
    { id: "idlelock", aliases: ["idle", "timeouts"], title: "Idle and lock",
      desc: "Idle timeouts and auto-lock", kind: "surface", target: "idlelock" },
    { id: "animation", aliases: ["anim"], title: "Animations",
      desc: "Hyprland animations", kind: "surface", target: "animation" },
    { id: "fontpicker", aliases: ["font", "fonts"], title: "Font",
      desc: "UI font", kind: "surface", target: "fontpicker" },
    { id: "emoji", aliases: ["em"], title: "Emoji",
      desc: "Emoji picker", kind: "surface", target: "emoji" },
    { id: "timer", aliases: ["countdown"], title: "Timer",
      desc: "Countdown timer", kind: "surface", target: "timer" },
    { id: "scratch", aliases: ["notes", "note"], title: "Notes",
      desc: "Scratchpad notes", kind: "surface", target: "scratch" },
    { id: "profile", aliases: ["me", "whoami"], title: "Profile",
      desc: "Who is at this machine", kind: "surface", target: "profile" },
    { id: "docksettings", aliases: ["dock"], title: "Dock",
      desc: "Dock behavior and size", kind: "surface", target: "docksettings" },
    { id: "rightclick", aliases: ["rc"], title: "Right click",
      desc: "Right-click walk stops", kind: "surface", target: "rightclick" },
    { id: "reference", aliases: ["help", "cheatsheet", "keys-help"], title: "Key reference",
      desc: "Pill keyboard reference", kind: "surface", target: "keys" },

    // * magi @menu scripts

    { id: "file", aliases: ["files", "open-file"], title: "Open file",
      desc: "Browse files and open one", kind: "menu", target: ["magi", "@menu", "file"] },
    { id: "dirs", aliases: ["folders", "open-dir"], title: "Open directory",
      desc: "Pick a directory and open a terminal", kind: "menu", target: ["magi", "@menu", "file", "--dirs"] },
    { id: "bookmark", aliases: ["bookmarks", "marks"], title: "Bookmarks",
      desc: "Open a browser bookmark", kind: "menu", target: ["magi", "@menu", "bookmark"] },
    { id: "icon", aliases: ["icons"], title: "Copy icon",
      desc: "Search and copy a Tabler icon", kind: "menu", target: ["magi", "@menu", "icon"] },
    { id: "mount", aliases: ["drives", "disks"], title: "Mount",
      desc: "Mount or unmount a device", kind: "menu", target: ["magi", "@menu", "mount"] },
    { id: "rbw", aliases: ["pass", "password", "passwords"], title: "Password",
      desc: "Pick a Bitwarden entry", kind: "menu", target: ["magi", "@menu", "rbw"] },
    { id: "rbw-new", aliases: ["newpass", "rbwnew"], title: "New password",
      desc: "Add a Bitwarden entry", kind: "menu", target: ["magi", "@menu", "rbw", "--new"] },

    // * Shell tools and actions

    { id: "color", aliases: ["colour", "hex"], title: "Color picker (hex)",
      desc: "Grab a screen color as hex", kind: "exec", target: ["hyprpicker", "-a", "-f", "hex"] },
    { id: "rgb", aliases: ["color-rgb"], title: "Color picker (RGB)",
      desc: "Grab a screen color as RGB", kind: "exec", target: ["hyprpicker", "-a", "-f", "rgb"] },
    { id: "hsl", aliases: ["color-hsl"], title: "Color picker (HSL)",
      desc: "Grab a screen color as HSL", kind: "exec", target: ["hyprpicker", "-a", "-f", "hsl"] },
    { id: "game", aliases: ["gamemode"], title: "Game mode",
      desc: "Toggle game mode", kind: "action", target: "gameMode" }
];

function all() {
    return bangs.slice();
}

function splitArgs(text) {
    var out = [];
    var cur = "";
    var quote = "";
    for (var i = 0; i < text.length; i++) {
        var c = text.charAt(i);
        if (quote) {
            if (c === "\\" && i + 1 < text.length) {
                cur += text.charAt(++i);
                continue;
            }
            if (c === quote) {
                quote = "";
                continue;
            }
            cur += c;
            continue;
        }
        if (c === '"' || c === "'") {
            quote = c;
            continue;
        }
        if (/\s/.test(c)) {
            if (cur.length > 0) {
                out.push(cur);
                cur = "";
            }
            continue;
        }
        cur += c;
    }
    if (cur.length > 0)
        out.push(cur);
    return out;
}

/** Split `!word rest` into its word and the untouched argument text. */
function parse(input) {
    var text = String(input == null ? "" : input).replace(/^\s+/, "");
    if (text.charAt(0) === "!")
        text = text.slice(1);
    text = text.replace(/^\s+/, "");
    var i = 0;
    while (i < text.length && !/\s/.test(text.charAt(i)))
        i++;
    var rest = text.slice(i).replace(/^\s+/, "");
    return {
        word: text.slice(0, i).toLowerCase(),
        args: splitArgs(rest),
        argText: rest
    };
}

function isSubsequence(needle, hay) {
    var j = 0;
    for (var i = 0; i < hay.length && j < needle.length; i++)
        if (hay.charAt(i) === needle.charAt(j)) j++;
    return j === needle.length;
}

function score(entry, word) {
    if (word.length === 0)
        return 1;

    var id = entry.id.toLowerCase();
    if (id === word)
        return 1000;

    var best = 0;
    if (id.indexOf(word) === 0)
        best = 850;
    else if (id.indexOf(word) !== -1)
        best = 750;
    else if (isSubsequence(word, id))
        best = 450;

    var words = [entry.title || ""].concat(entry.aliases || []);
    for (var i = 0; i < words.length; i++) {
        var w = String(words[i]).toLowerCase();
        if (w === word)
            return 900;
        if (w.indexOf(word) === 0)
            best = Math.max(best, 800);
        else if (w.indexOf(word) !== -1)
            best = Math.max(best, 700);
        else if (isSubsequence(word, w))
            best = Math.max(best, 400);
    }

    var desc = String(entry.desc || "").toLowerCase();
    if (desc.indexOf(word) !== -1)
        best = Math.max(best, 500);
    return best;
}

/** Rank every bang matching INPUT, best first. Bare `!` returns the whole table. */
function search(input) {
    var word = parse(input).word;
    var scored = [];
    for (var i = 0; i < bangs.length; i++) {
        var s = score(bangs[i], word);
        if (s > 0)
            scored.push({ entry: bangs[i], score: s, order: i });
    }
    scored.sort(function (a, b) {
        if (a.score !== b.score)
            return b.score - a.score;
        return a.order - b.order;
    });
    return scored.map(function (x) { return x.entry; });
}

/** Best matching entry plus its parsed arguments, or null. */
function resolve(input) {
    var p = parse(input);
    if (p.word.length === 0)
        return null;
    var ranked = search(input);
    if (ranked.length === 0)
        return null;
    return { entry: ranked[0], args: p.args, argText: p.argText };
}

/** Canonical command for ENTRY, keeping the argument text from INPUT. */
function command(entry, input) {
    var suffix = parse(input).argText;
    return "!" + entry.id + (suffix.length > 0 ? " " + suffix : "");
}

if (typeof module !== "undefined" && module.exports) {
    module.exports = { bangs, all, parse, search, resolve, command, splitArgs };
}
