pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * The active palette bundle, the same current.json the pill and the lock read.
 * theme.py copies the selected scheme/tone there, so the passphrase card
 * follows the session without knowing where the colours came from. The
 * defaults are the default scheme (nano dark), used for the first frame before
 * the file loads.
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
            property string cream: "#cbced2"
            property string bright: "#dddfe2"
            property string subtle: "#a8acb2"
            property string dim: "#898d95"
            property string faint: "#70757d"
            property string verm: "#6a849d"
            property string verm_lit: "#81a1c0"
            property string verm_deep: "#53657a"
            property string card_top: "#3b404c"
            property string card_bot: "#323844"
            property string border: "#515660"
        }
    }
}
