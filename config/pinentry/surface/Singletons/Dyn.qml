pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * The active palette bundle, the same current.json the pill and the lock read.
 * theme.py copies whichever source is selected (washi, a scheme/tone, or the
 * wallpaper) there, so the passphrase card follows the session without
 * knowing where the colours came from. The defaults are the washi identity,
 * used for the first frame before the file loads.
 */
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")
    readonly property string path: stateDir + "/quickshell/palettes/current.json"

    readonly property color cream: adapter.cream
    readonly property color bright: adapter.bright
    readonly property color subtle: adapter.subtle
    readonly property color dim: adapter.dim
    readonly property color faint: adapter.faint
    readonly property color verm: adapter.verm
    readonly property color vermLit: adapter.verm_lit
    readonly property color vermDeep: adapter.verm_deep
    readonly property color cardTop: adapter.card_top
    readonly property color cardBot: adapter.card_bot
    readonly property color border: adapter.border

    FileView {
        id: file
        path: root.path
        blockLoading: false
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string cream: "#e6d6cb"
            property string bright: "#fff6f0"
            property string subtle: "#b9a99e"
            property string dim: "#8a7d74"
            property string faint: "#6f635b"
            property string verm: "#c0442b"
            property string verm_lit: "#e0563b"
            property string verm_deep: "#a3371f"
            property string card_top: "#2e231b"
            property string card_bot: "#221813"
            property string border: "#3a2a22"
        }
    }
}
