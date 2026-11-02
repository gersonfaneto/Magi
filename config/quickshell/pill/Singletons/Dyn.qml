pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * The active palette bundle. theme.py copies the selected scheme/tone to
 * current.json, so every surface reads the same role names without knowing the
 * source. The defaults are the default scheme (nano dark), used for the first
 * frame before the file loads.
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
            property string key: "nano-dark"
            property string scheme: "nano"
            property string surface: "#2e3440"
            property string surface_container_low: "#323844"
            property string surface_container_high: "#3b404c"
            property string surface_container_highest: "#414652"
            property string primary: "#81a1c0"
            property string primary_container: "#53657a"
            property string on_primary_container: "#c6d5e3"
            property string outline_variant: "#515660"
            property string cream: "#cbced2"
            property string bright: "#dddfe2"
            property string subtle: "#a8acb2"
            property string dim: "#898d95"
            property string faint: "#70757d"
            property string icon_dim: "#b8bcc0"
            property string tick_rest: "#9ca0a6"
            property string on_glow: "#a0b8d0"
            property string verm: "#6a849d"
            property string verm_lit: "#81a1c0"
            property string verm_deep: "#53657a"
            property string card_top: "#3b404c"
            property string card_bot: "#323844"
            property string border: "#515660"
            property string tile_bg: "#2e3440"
            property string verm_dim: "#556a7f"
            property string verm_dim_deep: "#3a4856"
            property string verm_burn: "#4b5b6e"
            property string flame_core: "#cfdbe7"
            property string flame_glow: "#a0b8d0"
            property string flame_ink: "#81a1c0"
            property string flame_ember: "#53657a"
            property string flame_burn: "#53657a"
            property string flame_tip: "#c6d5e3"
            property string today_warm: "#bacbdc"
            property string ghost: "#414652"
        }
    }
}
