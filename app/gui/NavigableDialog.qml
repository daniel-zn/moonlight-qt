import QtQuick 2.0
import QtQuick.Controls 2.5

import NativeChrome 1.0

Dialog {
    id: dialog
    modal: true
    anchors.centerIn: Overlay.overlay

    // macOS: a rounded sheet-like panel over a dimmed window, as in system alerts
    Component.onCompleted: {
        if (NativeChrome.enabled) {
            padding = 20
            topPadding = 18
            background = macBackgroundComponent.createObject(dialog)
        }
    }

    Component {
        id: macBackgroundComponent
        Rectangle {
            radius: 16
            color: dialog.palette.window
            border.width: 1
            border.color: Qt.rgba(dialog.palette.text.r, dialog.palette.text.g, dialog.palette.text.b, 0.12)
        }
    }

    Overlay.modal: Rectangle {
        color: NativeChrome.enabled ? Qt.rgba(0, 0, 0, 0.35) : Qt.rgba(0, 0, 0, 0.5)
    }

    onClosed: {
        // We must force focus back to the last item. If we don't,
        // gamepad and keyboard navigation will break after a
        // dialog appears.
        stackView.forceActiveFocus()
    }
}
