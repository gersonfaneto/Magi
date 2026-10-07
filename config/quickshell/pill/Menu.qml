pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "Singletons"

/**
 * 品 MENU surface: the pill's generic, caller-driven list picker. It owns no
 * data of its own -- a caller hands it a JSON payload (over the `menu` IPC) of
 * rows to render, and it hands the pick back either by writing a result file or
 * by running a callback command. That keeps every menu's logic where it already
 * lives (a Janet script, a Lua keybind) and leaves the shell with one renderer.
 *
 * Payload:
 *   {
 *     "title":  "WINDOWS",             header title
 *     "glyph":  "窓",                   header kanji, optional
 *     "prompt": "Search windows",       search field placeholder; omit for no field
 *     "items":  [ {label, desc, icon, glyph, data, accent}, ... ],
 *     "input":  false,                  text-entry mode: no list, Enter returns the text
 *     "password": false,                mask the input
 *     "resultPath": "/run/user/.../x",  write the pick here (JSON), optional
 *     "callback": ["hyprctl","dispatch","focuswindow","address:{}"],  run on pick
 *     "cancel":   ["..."]               run on Escape, optional
 *   }
 *
 * A list pick yields the row's `data` (falling back to its label); an input pick
 * yields the typed text. `resultPath` is how a blocking caller (Janet) collects
 * the value; `callback` is how a fire-and-forget caller (a Lua keybind) acts.
 */

PillSurface {
    id: root

    mTop: 13
    mLeft: 15
    mRight: 15
    mBottom: 13

    property string payload: ""
    readonly property var request: {
        if (!payload || payload.length === 0)
            return null;
        try {
            return JSON.parse(payload);
        } catch (e) {
            return null;
        }
    }

    readonly property var items: (request && request.items) ? request.items : []
    readonly property bool inputMode: request ? request.input === true : false
    readonly property bool password: request ? request.password === true : false
    readonly property string prompt: (request && request.prompt !== undefined) ? String(request.prompt) : ""
    readonly property bool hasSearch: inputMode || prompt.length > 0
    readonly property string title: (request && request.title) ? String(request.title) : "MENU"
    readonly property string glyph: (request && request.glyph) ? String(request.glyph) : ""
    readonly property string message: (request && request.message) ? String(request.message) : ""

    property string query: ""
    property int selectedIndex: 0
    property point lastPointer: Qt.point(-1, -1)
    property bool done: false

    readonly property int maxRows: 9
    readonly property real rowH: 36 * s
    readonly property int shownRows: Math.min(items.length, maxRows)
    readonly property real listHeight: shownRows === 0 ? 26 * s : shownRows * rowH + (shownRows - 1) * 2 * s

    implicitWidth: 380 * s
    implicitHeight: root.inputMode ? (search.y + search.height + 4 * s) : (list.y + list.height)

    readonly property var results: {
        var all = root.items;
        var q = root.query.trim().toLowerCase();
        if (!q.length)
            return all;
        var out = [];
        for (var i = 0; i < all.length; i++) {
            var it = all[i];
            var hay = (String(it.label || "") + " " + String(it.desc || "")).toLowerCase();
            if (hay.indexOf(q) !== -1)
                out.push(it);
        }
        return out;
    }

    function move(delta) {
        if (results.length === 0)
            return;
        selectedIndex = Math.max(0, Math.min(results.length - 1, selectedIndex + delta));
        list.positionViewAtIndex(selectedIndex, ListView.Contain);
    }

    /** Commit the focused row (or the typed text) and close. */
    function activate() {
        if (root.done)
            return;
        if (root.inputMode) {
            root.finish(true, search.text, search.text);
            return;
        }
        if (results.length === 0 || selectedIndex < 0 || selectedIndex >= results.length)
            return;
        var it = results[selectedIndex];
        root.finish(true, it.data !== undefined ? it.data : it.label, it.label);
    }

    /** Escape/backdrop: run the cancel hook and close. */
    function cancel() {
        if (root.done)
            return;
        root.finish(false, "", "");
    }

    function finish(ok, data, label) {
        root.done = true;
        var req = root.request || {};
        if (req.resultPath)
            root.writeResult(ok, data, label);
        if (ok && req.callback && req.callback.length)
            root.runCallback(req.callback, data);
        if (!ok && req.cancel && req.cancel.length)
            Quickshell.execDetached(req.cancel);
        root.requestClose();
    }

    /**
     * Run CALLBACK with every `{}` placeholder replaced by DATA; if it has none,
     * DATA is appended. execDetached takes the argv directly, so no shell quoting.
     */
    function runCallback(tmpl, data) {
        var out = [];
        var used = false;
        for (var i = 0; i < tmpl.length; i++) {
            var a = String(tmpl[i]);
            if (a.indexOf("{}") !== -1) {
                out.push(a.replace("{}", data));
                used = true;
            } else {
                out.push(tmpl[i]);
            }
        }
        if (!used)
            out.push(data);
        Quickshell.execDetached(out);
    }

    /**
     * Hand the pick to a waiting caller as a JSON file. `printf` writes it in one
     * syscall so a poller never sees a half-written result; the caller's temp
     * path is unique per request.
     */
    function writeResult(ok, data, label) {
        var body = JSON.stringify({ ok: ok, data: data, label: label });
        Quickshell.execDetached(["sh", "-c", 'printf %s "$1" > "$2"', "_", body, String(root.request.resultPath)]);
    }

    onActiveChanged: {
        if (active) {
            done = false;
            query = "";
            search.text = "";
            selectedIndex = 0;
            if (root.hasSearch)
                Qt.callLater(function() { search.input.forceActiveFocus(); });
        }
    }
    onResultsChanged: if (selectedIndex >= results.length) selectedIndex = Math.max(0, results.length - 1)

    SettingsHeader {
        id: header
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        s: root.s
        glyph: root.glyph
        title: root.title
        showIcon: false
    }

    Text {
        id: message
        anchors.top: header.bottom
        anchors.topMargin: root.message.length > 0 ? 8 * root.s : 0
        anchors.left: parent.left
        anchors.right: parent.right
        visible: root.message.length > 0
        text: root.message
        color: Theme.subtle
        font.family: Theme.font
        font.pixelSize: 11.5 * root.s
        wrapMode: Text.WordWrap
    }

    Rectangle {
        id: divider
        anchors.top: message.visible ? message.bottom : header.bottom
        anchors.topMargin: 9 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hair
    }

    SearchField {
        id: search
        anchors.top: divider.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        s: root.s
        visible: root.hasSearch
        kanji: root.inputMode ? "問" : "探"
        placeholder: root.prompt
        counterText: root.inputMode ? "" : (root.results.length + " / " + root.items.length)
        echoMode: root.password ? TextInput.Password : TextInput.Normal
        onTextChanged: {
            root.query = text;
            root.selectedIndex = 0;
        }
        onMoved: (d) => root.move(d)
        onAccepted: root.activate()
        onDismissed: root.cancel()
    }

    Text {
        anchors.centerIn: list
        visible: !root.inputMode && root.results.length === 0
        text: root.query.length ? "No matches" : "Nothing here"
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
    }

    ListView {
        id: list
        anchors.top: root.hasSearch ? search.bottom : divider.bottom
        anchors.topMargin: 6 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.listHeight
        visible: !root.inputMode
        spacing: 2 * root.s
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results.length

        delegate: Item {
            id: row
            required property int index
            width: list.width
            height: root.rowH

            readonly property var item: root.results[index]
            readonly property bool selected: index === root.selectedIndex
            readonly property bool accent: item ? item.accent === true : false

            HoverHandler {
                id: rowHover
                onPointChanged: {
                    if (!hovered)
                        return;
                    var sp = point.scenePosition;
                    if (sp.x !== root.lastPointer.x || sp.y !== root.lastPointer.y) {
                        root.lastPointer = Qt.point(sp.x, sp.y);
                        root.selectedIndex = row.index;
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                radius: 9 * root.s
                visible: row.selected || rowHover.hovered
                color: row.selected ? Theme.frameBg : Qt.rgba(0.94, 0.88, 0.84, 0.03)
                border.width: row.selected ? 1 : 0
                border.color: Theme.frameBorder
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.selectedIndex = row.index;
                    root.activate();
                }
            }

            Item {
                anchors.fill: parent
                anchors.leftMargin: 11 * root.s
                anchors.rightMargin: 11 * root.s

                Rectangle {
                    id: iconTile
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24 * root.s
                    height: 24 * root.s
                    radius: 6 * root.s
                    color: Theme.tileBg
                    border.width: 1
                    border.color: Theme.border
                    visible: row.item !== undefined && !!row.item.icon

                    Image {
                        anchors.fill: parent
                        anchors.margins: 3 * root.s
                        asynchronous: true
                        smooth: true
                        sourceSize.width: Math.round(48 * root.s)
                        sourceSize.height: Math.round(48 * root.s)
                        fillMode: Image.PreserveAspectFit
                        source: {
                            if (row.item === undefined || !row.item.icon)
                                return "";
                            var ic = String(row.item.icon);
                            return ic.indexOf("/") === 0 ? "file://" + ic : Quickshell.iconPath(ic, true);
                        }
                    }
                }

                GlyphIcon {
                    id: iconGlyph
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 20 * root.s
                    height: 20 * root.s
                    visible: !(row.item !== undefined && !!row.item.icon) && row.item !== undefined && !!row.item.glyph
                    name: row.item !== undefined && row.item.glyph ? String(row.item.glyph) : ""
                    color: row.accent ? Theme.vermLit : Theme.iconDim
                    stroke: 1.7
                }

                Column {
                    anchors.left: iconTile.visible ? iconTile.right : (iconGlyph.visible ? iconGlyph.right : parent.left)
                    anchors.leftMargin: (iconTile.visible || iconGlyph.visible) ? 10 * root.s : 0
                    anchors.right: ret.left
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1 * root.s

                    Text {
                        width: parent.width
                        text: row.item !== undefined ? String(row.item.label || "") : ""
                        color: row.accent ? Theme.vermLit : Theme.cream
                        font.family: Theme.font
                        font.pixelSize: 13 * root.s
                        font.weight: row.selected ? Font.DemiBold : Font.Normal
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text.length > 0
                        text: row.item !== undefined ? String(row.item.desc || "") : ""
                        color: row.selected ? Theme.dim : Theme.faint
                        font.family: Theme.font
                        font.pixelSize: 10.5 * root.s
                        elide: Text.ElideRight
                    }
                }

                Text {
                    id: ret
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "↵"
                    color: Theme.vermLit
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                    visible: row.selected
                }
            }
        }
    }

    WheelScroller {
        anchors.fill: list
        s: root.s
        flick: list
    }
}
