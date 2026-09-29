import QtQuick
import QtQuick.Effects

// Box art for the macOS game grid: rounded corners, a soft shadow, and a lift
// on hover. Only loaded on macOS (Qt 6), so QtQuick.Effects is fine here.
Item {
    id: root

    property url source
    property bool lifted: false
    property real radius: 14

    scale: lifted ? 1.04 : 1.0
    Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

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
        shadowOpacity: root.lifted ? 0.5 : 0.3
        shadowVerticalOffset: root.lifted ? 10 : 5
        Behavior on shadowOpacity { NumberAnimation { duration: 160 } }
        Behavior on shadowVerticalOffset { NumberAnimation { duration: 160 } }
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
