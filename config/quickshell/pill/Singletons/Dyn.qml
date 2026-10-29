pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * The active palette bundle. theme.py copies whichever source is selected
 * (washi, a scheme/tone, or the wallpaper) to current.json, so every surface
 * reads the same role names without knowing the source. The defaults are the
 * washi identity, used for the first frame before the file loads.
 */
Singleton {
    id: root

    readonly property string home: Quickshell.env("HOME")
    readonly property string stateDir: Quickshell.env("XDG_STATE_HOME") || (home + "/.local/state")

    readonly property string scheme: adapter.scheme
    readonly property string key: adapter.key
    readonly property string path: stateDir + "/quickshell/palettes/current.json"

    readonly property string surface: adapter.surface
    readonly property string surfaceContainerLow: adapter.surface_container_low
    readonly property string surfaceContainerHigh: adapter.surface_container_high
    readonly property string surfaceContainerHighest: adapter.surface_container_highest
    readonly property string primary: adapter.primary
    readonly property string primaryContainer: adapter.primary_container
    readonly property string onPrimaryContainer: adapter.on_primary_container
    readonly property string outlineVariant: adapter.outline_variant
    readonly property string cream: adapter.cream
    readonly property string bright: adapter.bright
    readonly property string subtle: adapter.subtle
    readonly property string dim: adapter.dim
    readonly property string faint: adapter.faint
    readonly property string iconDim: adapter.icon_dim
    readonly property string tickRest: adapter.tick_rest

    readonly property color onGlow: adapter.on_glow
    readonly property color verm: adapter.verm
    readonly property color vermLit: adapter.verm_lit
    readonly property color vermDeep: adapter.verm_deep
    readonly property color cardTop: adapter.card_top
    readonly property color cardBot: adapter.card_bot
    readonly property color border: adapter.border
    readonly property color tileBg: adapter.tile_bg
    readonly property color vermDim: adapter.verm_dim
    readonly property color vermDimDeep: adapter.verm_dim_deep
    readonly property color vermBurn: adapter.verm_burn
    readonly property color flameCore: adapter.flame_core
    readonly property color flameGlow: adapter.flame_glow
    readonly property string flameInk: adapter.flame_ink
    readonly property string flameEmber: adapter.flame_ember
    readonly property string flameBurn: adapter.flame_burn
    readonly property string flameTip: adapter.flame_tip
    readonly property color todayWarm: adapter.today_warm
    readonly property color ghost: adapter.ghost

    FileView {
        id: file
        path: root.path
        blockLoading: false
        watchChanges: true
        printErrors: false

        onFileChanged: reload()

        JsonAdapter {
            id: adapter
            property string key: "washi"
            property string scheme: "washi"
            property string surface: "#211711"
            property string surface_container_low: "#221813"
            property string surface_container_high: "#2e231b"
            property string surface_container_highest: "#3b342b"
            property string primary: "#e0563b"
            property string primary_container: "#a3371f"
            property string on_primary_container: "#ffb38a"
            property string outline_variant: "#3a2a22"
            property string cream: "#e6d6cb"
            property string bright: "#fff6f0"
            property string subtle: "#b9a99e"
            property string dim: "#8a7d74"
            property string faint: "#6f635b"
            property string icon_dim: "#cdbfb4"
            property string tick_rest: "#cbb6a3"
            property string on_glow: "#ff9a64"
            property string verm: "#c0442b"
            property string verm_lit: "#e0563b"
            property string verm_deep: "#a3371f"
            property string card_top: "#2e231b"
            property string card_bot: "#221813"
            property string border: "#3a2a22"
            property string tile_bg: "#211711"
            property string verm_dim: "#8a5440"
            property string verm_dim_deep: "#5a3526"
            property string verm_burn: "#8a2c14"
            property string flame_core: "#ffd9c2"
            property string flame_glow: "#ff9a64"
            property string flame_ink: "#f0795a"
            property string flame_ember: "#7e2812"
            property string flame_burn: "#8a2c14"
            property string flame_tip: "#ffb38a"
            property string today_warm: "#ffb38a"
            property string ghost: "#594636"
        }
    }
}
