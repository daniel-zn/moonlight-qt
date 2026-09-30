import QtQuick
import QtQuick.Controls

// The macOS menu bar (Qt 6.8+ draws a QML MenuBar natively there). Every action
// in the window is also here, with its keyboard shortcut, so nothing is hidden
// behind a right-click. Items that don't apply to the current selection are
// disabled rather than removed, as the Human Interface Guidelines ask.
// Only created on macOS, by main.qml.
MenuBar {
    id: menuBar

    // Streaming, or a dialog is open: the menu bar isn't blocked by QML's modal
    // dialogs, so it must not act behind them
    readonly property bool busy: window.chromeHidden || window.openDialogs > 0
    readonly property Item page: stackView.currentItem
    readonly property bool onComputers: page instanceof PcView
    readonly property bool onGames: page instanceof AppView

    // The selected row on the current page, if any
    readonly property Item pc: onComputers && page.currentIndex >= 0 ? page.currentItem : null
    readonly property Item game: onGames && page.currentIndex >= 0 ? page.currentItem : null

    readonly property bool pcReady: pc !== null && pc.pcOnline && pc.pcPaired

    Menu {
        title: qsTr("Computer")
        enabled: !menuBar.busy

        Action {
            text: qsTr("Add Computer…")
            shortcut: StandardKey.New
            enabled: !menuBar.busy
            onTriggered: addPcDialog.open()
        }
        MenuSeparator {}
        Action {
            text: qsTr("Open")
            shortcut: "Ctrl+O"
            enabled: menuBar.pcReady && !menuBar.busy
            onTriggered: menuBar.pc.activate()
        }
        Action {
            text: qsTr("Show All Games, Including Hidden")
            enabled: menuBar.pcReady && !menuBar.busy
            onTriggered: menuBar.pc.showApps(true)
        }
        Action {
            text: qsTr("Pair…")
            enabled: menuBar.pc !== null && menuBar.pc.pcOnline && !menuBar.pc.pcPaired && !menuBar.busy
            onTriggered: menuBar.pc.pair()
        }
        Action {
            text: qsTr("Wake")
            enabled: menuBar.pc !== null && !menuBar.pc.pcOnline && !menuBar.busy
            onTriggered: menuBar.pc.wake()
        }
        MenuSeparator {}
        Action {
            text: qsTr("Rename…")
            enabled: menuBar.pc !== null && !menuBar.busy
            onTriggered: menuBar.pc.rename()
        }
        Action {
            text: qsTr("Test Network…")
            enabled: menuBar.pc !== null && !menuBar.busy
            onTriggered: menuBar.pc.testNetwork()
        }
        Action {
            text: qsTr("Get Info")
            shortcut: "Ctrl+I"
            enabled: menuBar.pc !== null && !menuBar.busy
            onTriggered: menuBar.pc.showDetails()
        }
        MenuSeparator {}
        Action {
            text: qsTr("Remove…")
            shortcut: "Ctrl+Backspace"
            enabled: menuBar.pc !== null && !menuBar.busy
            onTriggered: menuBar.pc.remove()
        }
    }

    Menu {
        title: qsTr("Game")
        enabled: !menuBar.busy

        Action {
            text: menuBar.game !== null && menuBar.game.appRunning ? qsTr("Resume") : qsTr("Launch")
            shortcut: "Ctrl+R"
            enabled: menuBar.game !== null && !menuBar.busy
            onTriggered: menuBar.game.launchOrResumeSelectedApp(true)
        }
        Action {
            // Not "Quit…": Qt turns any menu bar item starting with Quit (or Exit, About,
            // Preferences, Settings…) into that app-menu command, which disabled Quit
            // Moonlight and pointed Cmd+Q at the game
            text: qsTr("End Game on PC…")
            enabled: menuBar.game !== null && menuBar.game.appRunning && !menuBar.busy
            onTriggered: menuBar.game.doQuitGame()
        }
        MenuSeparator {}
        Action {
            text: qsTr("Launch Automatically When Opening PC")
            checkable: true
            checked: menuBar.game !== null && menuBar.game.appDirectLaunch
            enabled: menuBar.game !== null && !menuBar.game.appHidden && !menuBar.busy
            onTriggered: menuBar.game.toggleDirectLaunch()
        }
        Action {
            text: qsTr("Hide Game")
            checkable: true
            checked: menuBar.game !== null && menuBar.game.appHidden
            enabled: menuBar.game !== null && !menuBar.busy && (menuBar.game.appHidden || (!menuBar.game.appRunning && !menuBar.game.appDirectLaunch))
            onTriggered: menuBar.game.toggleHidden()
        }
    }

    Menu {
        title: qsTr("Go")
        enabled: !menuBar.busy

        Action {
            text: qsTr("Back")
            shortcut: "Ctrl+["
            enabled: stackView.depth > 1 && !menuBar.busy
            onTriggered: goBack()
        }
        Action {
            text: qsTr("Computers")
            shortcut: "Ctrl+Shift+C"
            enabled: stackView.depth > 1 && !menuBar.busy
            onTriggered: {
                stackView.pop(null)
                clearOnBack = false
            }
        }
        MenuSeparator {}
        Action {
            // Qt moves this into the app menu (where it shows as its standard Settings item)
            text: qsTr("Settings…")
            shortcut: StandardKey.Preferences
            enabled: !menuBar.busy
            onTriggered: navigateTo("qrc:/gui/SettingsView.qml", SettingsView)
        }
    }

    Menu {
        title: qsTr("Help")

        Action {
            text: qsTr("Moonlight Setup Guide")
            shortcut: StandardKey.HelpContents
            onTriggered: Qt.openUrlExternally("https://github.com/moonlight-stream/moonlight-docs/wiki/Setup-Guide")
        }
        Action {
            text: qsTr("Troubleshooting")
            onTriggered: Qt.openUrlExternally("https://github.com/moonlight-stream/moonlight-docs/wiki/Troubleshooting")
        }
    }
}
