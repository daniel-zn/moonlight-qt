import QtQuick
import QtQuick.Effects

// Box art thumbnail for the macOS game list: rounded corners and a soft shadow.
// Only loaded on macOS (Qt 6), so QtQuick.Effects is fine here.
Item {
    id: root

    property url source
    property real radius: 14

    // Shadow cast by a rounded card behind the art
    Rectangle {
        id: shadowShape
        anchors.fill: parent
        radius: root.radius
        color: "black"
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: shadowShape
        shadowEnabled: true
        shadowColor: "black"
        shadowBlur: 0.8
        shadowOpacity: 0.3
        shadowVerticalOffset: 5
    }

    Image {
        id: art
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        mipmap: true
        visible: false
    }
    Rectangle {
        id: mask
        anchors.fill: parent
        radius: root.radius
        visible: false
        layer.enabled: true
    }
    MultiEffect {
        anchors.fill: parent
        source: art
        maskEnabled: true
        maskSource: mask
    }

    // Hairline edge, like the system's own artwork thumbnails
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
    }
}
