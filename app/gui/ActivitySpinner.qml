import QtQuick 2.0
import QtQuick.Controls 2.2

import NativeChrome 1.0

// A BusyIndicator that looks like the system's on macOS: twelve fading spokes.
// The native macOS style's own indicator is an animated WebP, and the Qt used to
// build the app has no WebP plugin, so it would draw nothing. Pure QML needs none.
// Other platforms keep their style's indicator.
BusyIndicator {
    id: spinner

    Component.onCompleted: {
        if (NativeChrome.enabled) {
            implicitWidth = 20
            implicitHeight = 20
            padding = 0
            contentItem = macSpinnerComponent.createObject(spinner)
        }
    }

    Component {
        id: macSpinnerComponent

        Item {
            id: spokes
            property int step: 0
            opacity: spinner.running ? 1 : 0

            Timer {
                interval: 80
                repeat: true
                running: spinner.running && spinner.visible
                onTriggered: spokes.step = (spokes.step + 1) % 12
            }

            Repeater {
                model: 12

                Rectangle {
                    x: (spokes.width - width) / 2
                    y: 0
                    width: Math.max(2, spokes.width * 0.09)
                    height: spokes.height * 0.28
                    radius: width / 2
                    color: spinner.palette.text
                    // The lead spoke is darkest; the trail fades behind it
                    opacity: 0.2 + 0.8 * ((index - spokes.step + 12) % 12) / 11
                    transform: Rotation {
                        origin.x: width / 2
                        origin.y: spokes.height / 2
                        angle: index * 30
                    }
                }
            }
        }
    }
}
