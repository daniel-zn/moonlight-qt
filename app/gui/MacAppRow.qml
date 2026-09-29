import QtQuick
import QtQuick.Controls

// One game in the macOS game list: a small rounded box art thumbnail, the name,
// and a "Running" badge. The row's buttons and behavior live in AppView.
// Only loaded on macOS (Qt 6).
Item {
    id: row

    property url boxArt
    property string name
    property bool running: false
    property bool selected: false
    property bool hovered: false
    // Leave room on the right for AppView's Resume/Quit buttons
    property real trailingSpace: 0

    readonly property color textColor: selected ? "white" : palette.text

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: row.selected ? palette.highlight
             : row.hovered ? Qt.rgba(palette.text.r, palette.text.g, palette.text.b, 0.08)
             : "transparent"
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    MacBoxArt {
        id: thumbnail
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height - 12
        width: height * 0.75
        radius: 6
        source: row.boxArt
    }

    Column {
        anchors.left: thumbnail.right
        anchors.leftMargin: 12
        anchors.right: parent.right
        anchors.rightMargin: 12 + row.trailingSpace
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Label {
            width: parent.width
            text: row.name
            color: row.textColor
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Row {
            spacing: 5
            visible: row.running

            Rectangle {
                width: 7; height: 7; radius: 3.5
                anchors.verticalCenter: parent.verticalCenter
                color: row.selected ? "white" : "#30D158"
            }
            Label {
                text: qsTr("Running")
                color: row.textColor
                opacity: 0.75
                font.pixelSize: 11
            }
        }
    }
}
