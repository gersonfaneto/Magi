pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Wallpaper bridge: keeps a warm in-memory snapshot of the wallpaper folder so
 * the wallpaper strip opens instantly without shelling out on demand. A
 * refresh first runs the thumbnail script (generating missing 512px previews
 * and pruning ones whose source is gone), then re-lists the directory
 * newest-first and finally re-reads the state file wallpaper.sh maintains, so
 * `current` always names the wallpaper on screen. Thumbnails land before the
 * list so strip delegates never bind to a not-yet-existing file; a refresh
 * arriving while the pipeline runs sets `pending` and replays once the state
 * lands. Applying routes through wallpaper.sh so the picker shares the exact
 * transition, palette and state path with the random keybind.
 *
 * The folder resolves through one chain, first hit wins: an explicit
 * `wallpaperDir` in flags.json, then the dir wallpaper.sh resolved and wrote
 * to the quickshell-wallpaper-dir state file on its last run, then
 * ~/Pictures/Wallpapers for a first boot before wallpaper.sh init has run.
 *
 * Theme wallpapers come from $XDG_DATA_HOME/magi/wallpapers/<theme>/, linked
 * from the checkout's assets/wallpapers. They are listed in the same snapshot
 * with `theme` set and `builtin` true, so the strip can filter to the active
 * scheme without a second process. Their previews are cached under a per-theme
 * subdirectory, so a 5K WebP never decodes just to fill a 512px tile.
 *
 * Entries are plain objects: { path, name, mtime, thumb, theme, builtin } where
 * path is the absolute source file, mtime its modification time in epoch
 * seconds, thumb the absolute path of the cached preview, theme the scheme
 * directory it belongs to (empty for the local folder) and builtin true for
 * theme-owned files.
 */
Singleton {
    id: root

    property var entries: []
    readonly property int count: entries.length
    property string current: ""
    property bool pending: false

    property string resolvedDir: ""
    readonly property string wpDir: Flags.wallpaperDir.length > 0 ? Flags.wallpaperDir
        : (resolvedDir.length > 0 ? resolvedDir : Quickshell.env("HOME") + "/Pictures/Wallpapers")
    readonly property string thumbDir: (Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")) + "/quickshell-wp-thumbs/"
    readonly property string themeDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/magi/wallpapers"
    readonly property string thumbScript: Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-thumbs.sh"
    readonly property string setScript: Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper.sh"
    readonly property string stateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell-wallpaper"
    readonly property string dirStateFile: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell-wallpaper-dir"

    onWpDirChanged: refresh()

    FileView {
        id: dirFile
        path: root.dirStateFile
        blockLoading: true
        watchChanges: true
        printErrors: false
        onLoaded: root.resolvedDir = dirFile.text().trim()
        onFileChanged: reload()
        onLoadFailed: root.resolvedDir = ""
    }

    function refresh() {
        if (resolveProc.running || thumbProc.running || listProc.running || stateProc.running) {
            pending = true;
            return;
        }
        /**
         * Re-resolve the folder first when autodetect is in play: it only runs
         * inside wallpaper.sh, so a shell restart used to leave the strip on
         * the stale state file. An explicit folder skips that hop entirely and
         * swaps straight away.
         */
        if (Flags.wallpaperDir.length > 0) {
            thumbProc.running = true;
            return;
        }
        resolveProc.command = ["bash", root.setScript, "resolve"];
        resolveProc.running = true;
    }

    Process {
        id: resolveProc
        onExited: thumbProc.running = true
    }

    /**
     * wallpaper.sh blocks through the whole transition (awww wave, reload),
     * easily 1-2s; a pick landing in that window used to be silently
     * swallowed. Now the newest request is queued and replayed once the
     * running transition exits, so rapid iteration converges on the last pick.
     */
    property string queuedApply: ""
    property string queuedOutput: ""

    function apply(path, output) {
        var out = output === undefined ? "" : output;
        if (applyProc.running) {
            queuedApply = path;
            queuedOutput = out;
            return;
        }
        applyProc.command = out.length > 0
            ? ["bash", root.setScript, "set", path, out]
            : ["bash", root.setScript, "set", path];
        applyProc.running = true;
    }

    function trash(path) {
        if (path.indexOf(root.themeDir + "/") === 0)
            return;
        trashProc.command = ["gio", "trash", path];
        trashProc.running = true;
        var kept = [];
        for (var i = 0; i < entries.length; i++)
            if (entries[i].path !== path)
                kept.push(entries[i]);
        entries = kept;
    }

    Process {
        id: trashProc
        onExited: function(exitCode) {
            if (exitCode !== 0)
                root.refresh();
        }
    }

    Process {
        id: thumbProc
        command: ["sh", root.thumbScript]
        onExited: listProc.running = true
    }

    Process {
        id: listProc
        command: ["sh", "-c", "find \"$1\" -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\) -printf 'local\\t%T@\\t%p\\n' 2>/dev/null; find -L \"$2\" -mindepth 2 -maxdepth 2 -type f \\( -iname '*.jpg' -o -iname '*.png' -o -iname '*.gif' -o -iname '*.webp' -o -iname '*.mp4' -o -iname '*.webm' -o -iname '*.mkv' -o -iname '*.mov' \\) -printf 'theme\\t%T@\\t%p\\n' 2>/dev/null", "_", root.wpDir, root.themeDir]
        stdout: StdioCollector {
            onStreamFinished: {
                var lines = this.text.split("\n");
                var out = [];
                for (var i = 0; i < lines.length; i++) {
                    var first = lines[i].indexOf("\t");
                    var second = lines[i].indexOf("\t", first + 1);
                    if (first < 1 || second < 0)
                        continue;
                    var kind = lines[i].substring(0, first);
                    var path = lines[i].substring(second + 1);
                    var name = path.substring(path.lastIndexOf("/") + 1);
                    var theme = "";
                    var builtin = kind === "theme";
                    if (builtin) {
                        var rel = path.substring(root.themeDir.length + 1);
                        var slash = rel.indexOf("/");
                        theme = slash >= 0 ? rel.substring(0, slash) : "";
                    }
                    out.push({
                        path: path,
                        name: name,
                        mtime: parseFloat(lines[i].substring(first + 1, second)),
                        thumb: builtin ? root.thumbDir + "theme/" + theme + "/" + name + ".png" : root.thumbDir + name + ".png",
                        theme: theme,
                        builtin: builtin
                    });
                }
                out.sort(function (a, b) { return b.mtime - a.mtime; });
                root.entries = out;
                stateProc.running = true;
            }
        }
    }

    Process {
        id: stateProc
        command: ["sh", "-c", "cat \"$1\" 2>/dev/null || true", "_", root.stateFile]
        stdout: StdioCollector {
            onStreamFinished: {
                root.current = this.text.trim();
                if (root.pending) {
                    root.pending = false;
                    Qt.callLater(root.refresh);
                }
            }
        }
    }

    Process {
        id: applyProc
        onExited: {
            if (root.queuedApply.length) {
                var next = root.queuedApply;
                var nextOut = root.queuedOutput;
                root.queuedApply = "";
                root.queuedOutput = "";
                applyProc.command = nextOut.length > 0
                    ? ["bash", root.setScript, "set", next, nextOut]
                    : ["bash", root.setScript, "set", next];
                applyProc.running = true;
                return;
            }
            stateProc.running = true;
        }
    }

    Component.onCompleted: refresh()
}
