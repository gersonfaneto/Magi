pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import "Singletons"

/**
 * 相 APPEARANCE sub-surface: the clock format and seconds, the Japanese-glyph
 * toggle that gates every surface header, the palette source (a curated scheme
 * or a per-wallpaper palette), whether GTK apps follow that palette, the UI
 * scale and a reduce-motion switch. Reached from the settings index and morphs
 * back to it on an empty click or the back chevron.
 *
 * Every branch delegates to theme.py, the same entry point setcolor/setbg and
 * the login service use, so the pill, lock, Hyprland, Qt, foot, highlight and
 * nvim cannot drift apart.
 */
SettingsSurface {
    id: root

    implicitHeight: content.implicitHeight

    property var pendingTheme: null

    function runTheme(args) {
        if (themeProc.running) {
            pendingTheme = args;
            return;
        }
        themeProc.command = ["sh", "-c", "python3 \"$HOME/.config/hypr/scripts/theme.py\" \"$@\"", "sh"].concat(args);
        themeProc.running = true;
    }

    function applyMode(v) {
        Flags.paletteMode = v;
        runTheme(["source", v]);
    }

    function setAppTheme(v) {
        if (Flags.appTheme === v)
            return;
        Flags.appTheme = v;
        runTheme(["apps", v ? "on" : "off"]);
    }

    Process {
        id: themeProc
        onExited: {
            if (root.pendingTheme) {
                var args = root.pendingTheme;
                root.pendingTheme = null;
                root.runTheme(args);
            }
        }
    }

    rows: [
        { item: timeRow, kind: "seg", vals: [false, true], get: function () { return Flags.time12h; }, set: function (v) { Flags.time12h = v; } },
        { item: secRow, kind: "toggle", get: function () { return Flags.clockSeconds; }, set: function (v) { Flags.clockSeconds = v; } },
        { item: glyphRow, kind: "toggle", get: function () { return Flags.showGlyphs; }, set: function (v) { Flags.showGlyphs = v; } },
        { item: vizRow, kind: "toggle", get: function () { return Flags.musicViz; }, set: function (v) { Flags.musicViz = v; } },
        { item: paletteRow, kind: "seg", vals: ["scheme", "dynamic"], get: function () { return Flags.paletteMode === "dynamic" ? "dynamic" : "scheme"; }, set: function (v) { root.applyMode(v); } },
        { item: appRow, kind: "toggle", get: function () { return Flags.appTheme; }, set: function (v) { root.setAppTheme(v); } },
        { item: randomRow, kind: "seg", vals: ["all", "cursor"], get: function () { return Flags.randomScope; }, set: function (v) { Flags.randomScope = v; } },
        { item: scaleRow, kind: "seg", vals: [0.9, 1.0, 1.1, 1.25], get: function () { return Flags.uiScale; }, set: function (v) { Flags.uiScale = v; } },
        { item: motionRow, kind: "toggle", get: function () { return Flags.reduceMotion; }, set: function (v) { Flags.reduceMotion = v; } },
        { item: fontRow, kind: "nav", surface: "fontpicker" }
    ]

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            glyph: "相"
            title: "APPEARANCE"
            showBack: true
        }

        Item { width: 1; height: 12 * root.s }

        SettingsRow {
            id: timeRow
            surface: root
            name: "Time format"
            icon: "clock"

            SettingsSeg {
                s: root.s
                options: [{ label: "24H", value: false }, { label: "12H", value: true }]
                value: Flags.time12h
                onPicked: (v) => Flags.time12h = v
            }
        }

        SettingsRow {
            id: secRow
            surface: root
            name: "Clock seconds"
            icon: "stopwatch"

            LinkToggle {
                s: root.s
                on: Flags.clockSeconds
                onToggled: Flags.clockSeconds = !Flags.clockSeconds
            }
        }

        SettingsRow {
            id: glyphRow
            surface: root
            name: "Japanese glyphs"
            icon: "language"

            LinkToggle {
                s: root.s
                on: Flags.showGlyphs
                onToggled: Flags.showGlyphs = !Flags.showGlyphs
            }
        }

        SettingsRow {
            id: vizRow
            surface: root
            name: "Music visualizer"
            icon: "music"

            LinkToggle {
                s: root.s
                on: Flags.musicViz
                onToggled: Flags.musicViz = !Flags.musicViz
            }
        }

        SettingsRow {
            id: paletteRow
            surface: root
            name: "Palette"
            icon: "palette"
            sub: Flags.paletteMode === "dynamic" ? "" : Dyn.scheme

            SettingsSeg {
                s: root.s
                options: [{ label: "Scheme", value: "scheme" }, { label: "Dynamic", value: "dynamic" }]
                value: Flags.paletteMode
                onPicked: (v) => root.applyMode(v)
            }
        }

        SettingsRow {
            id: appRow
            surface: root
            name: "App theme"
            icon: "app-window"

            LinkToggle {
                s: root.s
                on: Flags.appTheme
                onToggled: root.setAppTheme(!Flags.appTheme)
            }
        }

        SettingsRow {
            id: randomRow
            surface: root
            name: "Random wallpaper"
            icon: "monitor"

            SettingsSeg {
                s: root.s
                options: [{ label: "All screens", value: "all" }, { label: "Cursor screen", value: "cursor" }]
                value: Flags.randomScope
                onPicked: (v) => Flags.randomScope = v
            }
        }

        SettingsRow {
            id: scaleRow
            surface: root
            name: "UI scale"
            icon: "scaling"

            SettingsSeg {
                s: root.s
                options: [{ label: "90%", value: 0.9 }, { label: "100%", value: 1.0 }, { label: "110%", value: 1.1 }, { label: "125%", value: 1.25 }]
                value: Flags.uiScale
                onPicked: (v) => Flags.uiScale = v
            }
        }

        SettingsRow {
            id: motionRow
            surface: root
            name: "Reduce motion"
            icon: "waves"

            LinkToggle {
                s: root.s
                on: Flags.reduceMotion
                onToggled: Flags.reduceMotion = !Flags.reduceMotion
            }
        }

        SettingsRow {
            id: fontRow
            surface: root
            name: "Font"
            icon: "type"
            sub: Flags.uiFont.length > 0 ? Flags.uiFont : "Inter"
            last: true

            GlyphIcon {
                width: 16 * root.s
                height: 16 * root.s
                name: "chevron-right"
                color: root.focusRowItem === fontRow ? Theme.cream : Theme.iconDim
                stroke: 1.9
            }
        }
    }
}
