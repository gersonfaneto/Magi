pragma ComponentBehavior: Bound

import QtQuick
import "Singletons"

/**
 * 右 RIGHT-CLICK sub-surface: the two stops the bar's right-click walk leaves to
 * the user. The walk always opens on media, then the timer; these two rows name
 * the stops after that, and Off drops one. The step reads from the surface that
 * is actually open, so a stop reached another way continues from where the eye
 * already is.
 */
SettingsSurface {
    id: root

    implicitHeight: content.implicitHeight

    readonly property var choices: [
        { label: "Off", value: "" },
        { label: "Cal", value: "calendar" },
        { label: "Emo", value: "emoji" },
        { label: "Note", value: "scratch" },
        { label: "Timer", value: "timer" },
        { label: "Wall", value: "wallpaper" },
        { label: "Power", value: "power" }
    ]

    readonly property var vals: {
        const out = [];
        for (let i = 0; i < root.choices.length; i++)
            out.push(root.choices[i].value);
        return out;
    }

    rows: [
        { item: slot4Row, kind: "seg", vals: root.vals, get: function () { return Flags.cycleSlot4; }, set: function (v) { Flags.cycleSlot4 = v; } },
        { item: slot5Row, kind: "seg", vals: root.vals, get: function () { return Flags.cycleSlot5; }, set: function (v) { Flags.cycleSlot5 = v; } }
    ]

    Column {
        id: content
        width: parent ? parent.width : 0
        spacing: 0

        SettingsHeader {
            s: root.s
            glyph: "右"
            title: "RIGHT-CLICK"
            showBack: true
        }

        Item { width: 1; height: 10 * root.s }

        SettingsRow {
            id: slot4Row
            surface: root
            icon: "cursor"
            name: "4th stop"
            sub: "After media and the timer"
            captionOnFocus: true
            SettingsSeg {
                s: root.s
                value: Flags.cycleSlot4
                options: root.choices
                onPicked: (v) => Flags.cycleSlot4 = v
            }
        }

        SettingsRow {
            id: slot5Row
            surface: root
            icon: "cursor"
            name: "5th stop"
            sub: "The last stop before the walk wraps home"
            captionOnFocus: true
            last: true
            SettingsSeg {
                s: root.s
                value: Flags.cycleSlot5
                options: root.choices
                onPicked: (v) => Flags.cycleSlot5 = v
            }
        }

        Item { width: 1; height: 12 * root.s }
    }
}
