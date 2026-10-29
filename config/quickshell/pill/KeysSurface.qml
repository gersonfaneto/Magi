pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * 鍵 KEYS surface: the pill's own keyboard reference, opened with Ctrl+/ from
 * any surface. It is deliberately static -- the authoritative bindings live in
 * the Keybinds surface (Hyprland) and in the PillSurface nav contract -- so the
 * help can never drift into a stale generated list. Escape or the header back
 * chevron closes the pill like any other standalone surface.
 */
PillSurface {
    id: root

    mTop: 15
    mLeft: 19
    mRight: 19
    mBottom: 14

    implicitHeight: content.implicitHeight

    readonly property var moveRows: [
        { key: "Up / Down", desc: "Move one row; j / k also work" },
        { key: "Left / Right", desc: "Move sideways, adjust, or seek" },
        { key: "PageUp / PageDown", desc: "Move one viewport" },
        { key: "Ctrl+Home / Ctrl+End", desc: "First or last row" },
        { key: "Tab / Shift+Tab", desc: "Cycle rows or open a source picker" },
        { key: "Enter / Space", desc: "Activate the focused row" },
        { key: "Escape", desc: "Pop one layer, then close" },
        { key: "Ctrl+P / Ctrl+N", desc: "Previous / next while searching" }
    ]

    readonly property var surfaceRows: [
        { key: "Alt+1 .. Alt+9", desc: "Launch the Nth search result" },
        { key: "Delete", desc: "Remove a stashed or routed app" },
        { key: "r", desc: "Rescan Wifi and Bluetooth" },
        { key: "a", desc: "Add an app or workspace" },
        { key: "t", desc: "Calendar cursor to today" },
        { key: "Ctrl+/", desc: "Toggle this reference" }
    ]

    component KeyRow: Item {
        id: row
        required property string key
        required property string desc
        width: parent.width
        height: 24 * root.s

        Rectangle {
            id: keyChip
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Math.max(120 * root.s, keyText.implicitWidth + 14 * root.s)
            height: 18 * root.s
            radius: 5 * root.s
            color: Theme.frameBg
            border.width: 1
            border.color: Theme.hairSoft

            Text {
                id: keyText
                anchors.centerIn: parent
                text: row.key
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 10 * root.s
                font.weight: Font.DemiBold
                font.letterSpacing: 0.2 * root.s
            }
        }

        Text {
            anchors.left: keyChip.right
            anchors.leftMargin: 10 * root.s
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            text: row.desc
            color: Theme.subtle
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            elide: Text.ElideRight
        }
    }

    component SectionLabel: Text {
        property string label: ""
        width: parent.width
        height: 18 * root.s
        verticalAlignment: Text.AlignBottom
        text: label
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 8.5 * root.s
        font.weight: Font.DemiBold
        font.letterSpacing: 1.2 * root.s
        font.capitalization: Font.AllUppercase
    }

    Column {
        id: content
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        spacing: 0

        SettingsHeader {
            s: root.s
            glyph: "鍵"
            title: "KEYS"
            showBack: true
        }

        Item { width: 1; height: 10 * root.s }

        Text {
            width: parent.width
            text: "The pill routes these itself whenever a surface is open."
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 10 * root.s
            wrapMode: Text.WordWrap
        }

        Item { width: 1; height: 12 * root.s }

        SectionLabel { label: "MOVE" }

        Repeater {
            model: root.moveRows

            KeyRow {
                required property var modelData
                key: modelData.key
                desc: modelData.desc
            }
        }

        Item { width: 1; height: 12 * root.s }

        SectionLabel { label: "SURFACES" }

        Repeater {
            model: root.surfaceRows

            KeyRow {
                required property var modelData
                key: modelData.key
                desc: modelData.desc
            }
        }

        Item { width: 1; height: 2 * root.s }
    }
}
