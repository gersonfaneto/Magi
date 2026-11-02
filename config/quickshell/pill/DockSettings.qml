pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * 舟 DOCK sub-surface: the bottom dock's own settings, reached from the gear on
 * the bar itself. The bar is the place apps are pinned, reordered and unpinned;
 * this page only carries how it behaves and how large it draws. Every control
 * writes straight through Flags, which persists to flags.json, so the dock
 * window and its reserved band react live.
 */
SettingsSurface {
    id: root

    implicitHeight: content.implicitHeight

    component GroupLabel: SettingsLabel { s: root.s; leftPadding: 12 * root.s }

    rows: {
        var r = [];
        r.push({ item: enabledRow, kind: "toggle", get: function () { return Flags.dockEnabled; }, set: function (v) { Flags.dockEnabled = v; } });
        if (Flags.dockEnabled) {
            r.push({ item: hideRow, kind: "toggle", get: function () { return Flags.dockAutoHide; }, set: function (v) { Flags.dockAutoHide = v; } });
            r.push({ item: minimalRow, kind: "toggle", get: function () { return Flags.dockMinimal; }, set: function (v) { Flags.dockMinimal = v; } });
            r.push({ item: styleRow, kind: "seg", vals: ["transparent", "solid"], get: function () { return Flags.dockStyle; }, set: function (v) { Flags.dockStyle = v; } });
            r.push({ item: scaleRow, kind: "scrub", bump: function (d) { scaleScrub.bump(d); } });
            if (!Flags.dockAutoHide)
                r.push({ item: gapRow, kind: "scrub", bump: function (d) { gapScrub.bump(d); } });
        }
        return r;
    }

    Column {
        id: content
        width: parent ? parent.width : 0
        spacing: 0

        SettingsHeader {
            s: root.s
            glyph: "舟"
            title: "DOCK"
            showBack: true
        }

        Item { width: 1; height: 8 * root.s }

        GroupLabel { text: "Behaviour" }

        SettingsRow {
            id: enabledRow
            surface: root
            name: "Show the dock"
            sub: "Pinned and running apps along the bottom edge"
            captionOnFocus: true
            icon: "dock"
            last: !Flags.dockEnabled
            LinkToggle {
                s: root.s
                on: Flags.dockEnabled
                onToggled: Flags.dockEnabled = !Flags.dockEnabled
            }
        }

        SettingsRow {
            id: hideRow
            surface: root
            name: "Auto-hide"
            sub: "Retract to a bottom reveal strip until the pointer finds it"
            captionOnFocus: true
            icon: "chevron-down"
            visible: Flags.dockEnabled
            LinkToggle {
                s: root.s
                on: Flags.dockAutoHide
                onToggled: Flags.dockAutoHide = !Flags.dockAutoHide
            }
        }

        SettingsRow {
            id: minimalRow
            surface: root
            name: "Minimal"
            sub: "Icons only -- no running-app titles under the chips"
            captionOnFocus: true
            icon: "scaling"
            visible: Flags.dockEnabled
            LinkToggle {
                s: root.s
                on: Flags.dockMinimal
                onToggled: Flags.dockMinimal = !Flags.dockMinimal
            }
        }

        GroupLabel { text: "Appearance" }

        SettingsRow {
            id: styleRow
            surface: root
            name: "Surface"
            sub: "Glass follows the pill's palette; solid paints the card"
            captionOnFocus: true
            icon: "layers"
            visible: Flags.dockEnabled
            SettingsSeg {
                s: root.s
                value: Flags.dockStyle
                options: [
                    { label: "Glass", value: "transparent" },
                    { label: "Solid", value: "solid" }
                ]
                onPicked: (v) => Flags.dockStyle = v
            }
        }

        SettingsRow {
            id: scaleRow
            surface: root
            name: "Scale"
            sub: "Dock size on top of the interface scale"
            captionOnFocus: true
            icon: "scaling"
            visible: Flags.dockEnabled
            ScrubValue {
                id: scaleScrub
                s: root.s
                value: Flags.dockUiScale
                from: 0.6; to: 1.6; step: 0.05; decimals: 2
                onEdited: v => Flags.dockUiScale = v
            }
        }

        SettingsRow {
            id: gapRow
            surface: root
            name: "Window gap"
            sub: "Air between the reserved band and tiled windows"
            captionOnFocus: true
            icon: "app-window"
            visible: Flags.dockEnabled && !Flags.dockAutoHide
            last: true
            ScrubValue {
                id: gapScrub
                s: root.s
                value: Flags.dockGap
                from: 0; to: 3; step: 0.25; decimals: 2
                onEdited: v => Flags.dockGap = v
            }
        }

        Item { width: 1; height: 10 * root.s }

        Text {
            width: content.width - 24 * root.s
            x: 12 * root.s
            text: "Right-click a chip to pin or unpin it; drag pinned chips to reorder. The gear opens this page."
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10 * root.s
            wrapMode: Text.WordWrap
            lineHeight: 1.25
        }

        Item { width: 1; height: 12 * root.s }
    }
}
