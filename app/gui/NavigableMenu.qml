import QtQuick 2.0
import QtQuick.Controls 2.2

import NativeChrome 1.0

Menu {
    property var initiator

    Component.onCompleted: {
        // macOS: a real system context menu (Qt 6.8+). The native macOS style has
        // no QML Menu and would otherwise fall back to Fusion's.
        if (NativeChrome.enabled) {
            popupType = Popup.Native
        }
    }

    onOpened: {
        // If the initiating object currently has keyboard focus,
        // give focus to the first visible and enabled menu item
        if (initiator.focus) {
            for (var i = 0; i < count; i++) {
                var item = itemAt(i)
                if (item.visible && item.enabled) {
                    item.forceActiveFocus(Qt.TabFocusReason)
                    break
                }
            }
        }
    }
}
