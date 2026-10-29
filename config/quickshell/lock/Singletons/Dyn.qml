pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * The active palette bundle, the same current.json the pill reads. theme.py
 * copies whichever source is selected there, so the lock no longer keeps a
 * separate wallpaper-only palette that goes stale in scheme mode.
 */
Singleton {
    readonly property string primary: adapter.primary
    readonly property string verm: adapter.verm
    readonly property string cream: adapter.cream
    readonly property string bright: adapter.bright
    readonly property string dim: adapter.dim
    readonly property string error: adapter.error
    readonly property string surfaceLow: adapter.surface_container_low
    readonly property string outlineVariant: adapter.outline_variant

    FileView {
        id: file
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/quickshell/palettes/current.json"
        blockLoading: false
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string primary: "#e0563b"
            property string verm: "#c0442b"
            property string cream: "#e6d6cb"
            property string bright: "#fff6f0"
            property string dim: "#8a7d74"
            property string error: "#c0442b"
            property string surface_container_low: "#221813"
            property string outline_variant: "#3a2a22"
        }
    }
}
