import QtQuick 2.0
import QtQuick.Controls 2.2
import QtQuick.Layouts 1.3

import NativeChrome 1.0

ToolButton {
    property string iconSource

    activeFocusOnTab: true

    icon.source: iconSource
    // The native macOS style sizes the button from its icon, so tying the icon to
    // the background there would never settle
    icon.width: NativeChrome.enabled ? 22 : background.width
    icon.height: NativeChrome.enabled ? 22 : background.height

    // This determines the size of the Material highlight. We increase it
    // from the default because we use larger than normal icons for TV readability.
    Layout.preferredHeight: parent.height

    Keys.onReturnPressed: {
        clicked()
    }

    Keys.onEnterPressed: {
        clicked()
    }

    Keys.onRightPressed: {
        nextItemInFocusChain(true).forceActiveFocus(Qt.TabFocus)
    }

    Keys.onLeftPressed: {
        nextItemInFocusChain(false).forceActiveFocus(Qt.TabFocus)
    }
}
