pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import "Singletons"
import "lib/emoji.js" as EmojiData

/**
 * Emoji surface: a search field over the bundled emoji table, drawn as one of
 * the pill's surfaces. Typing filters on the emoji's name and keywords, the
 * arrows walk the grid, Return or a click copies the glyph to the clipboard and
 * closes, so it pastes into whatever app has focus next. Esc dismisses. A tone
 * strip recolours the glyphs that have a skin-tone base; the pick lives in
 * Flags, so it survives reopening the surface and a shell restart.
 */
PillSurface {
    id: root

    mTop: 15
    mLeft: 17
    mRight: 17
    mBottom: 14

    property string query: ""

    readonly property var results: EmojiData.search(query)
    readonly property int totalCount: EmojiData.all().length
    readonly property int tone: Flags.emojiTone

    /** Seven glyphs across the 360px card. */
    readonly property int columns: 7

    function focusField() { search.input.forceActiveFocus(); }

    function copy(glyph) {
        Quickshell.execDetached(["sh", "-c", "printf '%s' \"$1\" | wl-copy", "_", glyph]);
    }

    function activate() {
        if (grid.currentIndex < 0 || grid.currentIndex >= results.length)
            return;
        copy(EmojiData.tone(results[grid.currentIndex].glyph, root.tone));
        root.requestClose();
    }

    function move(delta) {
        if (results.length === 0)
            return;
        grid.currentIndex = Math.max(0, Math.min(results.length - 1, grid.currentIndex + delta));
        grid.positionViewAtIndex(grid.currentIndex, GridView.Contain);
    }

    onActiveChanged: {
        if (active) {
            query = "";
            search.text = "";
            grid.currentIndex = 0;
            Qt.callLater(root.focusField);
        }
    }

    onQueryChanged: grid.currentIndex = 0
    onResultsChanged: if (grid.currentIndex >= results.length) grid.currentIndex = Math.max(0, results.length - 1)

    SearchField {
        id: search
        z: 5
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        s: root.s
        kanji: "絵"
        placeholder: "Search emoji"
        counterText: root.results.length + " / " + root.totalCount
        onTextChanged: root.query = text
        onAccepted: root.activate()
        onDismissed: root.requestClose()
        onKeyPressed: (e) => {
            if (e.key === Qt.Key_Left) {
                root.move(-1);
                e.accepted = true;
            } else if (e.key === Qt.Key_Right) {
                root.move(1);
                e.accepted = true;
            } else if (e.key === Qt.Key_Up) {
                root.move(-root.columns);
                e.accepted = true;
            } else if (e.key === Qt.Key_Down) {
                root.move(root.columns);
                e.accepted = true;
            }
        }
    }

    Rectangle {
        id: divider
        anchors.top: search.bottom
        anchors.topMargin: 8 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        height: 1
        color: Theme.hair
    }

    Row {
        id: toneRow
        anchors.top: divider.bottom
        anchors.topMargin: 6 * root.s
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 4 * root.s

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "TONE"
            color: Theme.faint
            font.family: Theme.font
            font.pixelSize: 8.5 * root.s
            font.weight: Font.DemiBold
            font.letterSpacing: 1.2 * root.s
        }

        Repeater {
            model: EmojiData.TONE_CHOICES

            Rectangle {
                id: swatch
                required property var modelData
                readonly property bool selected: Flags.emojiTone === modelData.value
                width: 30 * root.s
                height: 24 * root.s
                radius: 6 * root.s
                color: selected ? Theme.frameBg : "transparent"
                border.width: 1
                border.color: selected ? Theme.frameBorder : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: EmojiData.tone("✋", swatch.modelData.value)
                    color: Theme.cream
                    font.family: Theme.font
                    font.pixelSize: 15 * root.s
                    textFormat: Text.PlainText
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Flags.emojiTone = swatch.modelData.value
                }
            }
        }
    }

    Text {
        anchors.centerIn: grid
        visible: root.results.length === 0
        text: "No matches"
        color: Theme.faint
        font.family: Theme.font
        font.pixelSize: 10.5 * root.s
    }

    GridView {
        id: grid
        anchors.top: toneRow.bottom
        anchors.topMargin: 6 * root.s
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        model: root.results.length

        /**
         * Square cells at `columns` across, then stretched by at most one row's
         * share so the viewport always ends on a whole row: a partially cut row
         * reads as a broken picker, not as a scroll hint. Both bindings are live
         * on `s`, so every interface size keeps the glyphs centred in their cells.
         */
        readonly property real colW: Math.max(1, width / root.columns)
        readonly property int rows: Math.max(1, Math.floor(height / colW))

        cellWidth: colW
        cellHeight: height > 0 ? height / rows : colW

        delegate: Item {
            id: cell
            required property int index

            width: grid.cellWidth
            height: grid.cellHeight

            readonly property var entry: root.results[index]
            readonly property bool current: index === grid.currentIndex

            HoverHandler {
                id: cellHover
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2 * root.s
                radius: 9 * root.s
                color: cell.current ? Qt.alpha(Theme.cream, 0.10)
                    : (cellHover.hovered ? Qt.alpha(Theme.cream, 0.05) : "transparent")
                border.width: 1
                border.color: cell.current ? Qt.alpha(Theme.vermLit, 0.30) : "transparent"
            }

            Text {
                anchors.centerIn: parent
                text: cell.entry ? EmojiData.tone(cell.entry.glyph, root.tone) : ""
                color: Theme.cream
                font.family: Theme.font
                font.pixelSize: 24 * root.s
                textFormat: Text.PlainText
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    grid.currentIndex = cell.index;
                    root.activate();
                }
            }
        }
    }

    WheelScroller {
        anchors.fill: grid
        s: root.s
        flick: grid
    }
}
