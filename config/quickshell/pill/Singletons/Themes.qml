pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * The selectable theme corpus, read once from theme.py's catalog command. Each
 * entry carries the scheme name, its editor target and one preview per
 * available tone; the theme surface flattens the tones into rows and applies a
 * pick through theme.py, so this singleton never writes flags itself.
 */
Singleton {
    id: root

    property var themes: []
    property bool loaded: false
    property string error: ""

    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/theme.py"

    function refresh() {
        if (proc.running) {
            queued = true;
            return;
        }
        proc.running = true;
    }

    property bool queued: false

    Process {
        id: proc
        command: ["python3", root.script, "catalog"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    var data = JSON.parse(this.text);
                    root.themes = Array.isArray(data.themes) ? data.themes : [];
                    root.loaded = true;
                    root.error = "";
                } catch (e) {
                    root.error = String(e);
                }
            }
        }
        onExited: {
            if (root.queued) {
                root.queued = false;
                root.refresh();
            }
        }
    }

    Component.onCompleted: refresh()
}
