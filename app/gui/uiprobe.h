#pragma once

#include <QFile>
#include <QObject>
#include <QString>

class QQmlApplicationEngine;
class QQuickWindow;

// Self-test hook for UI checks without a person at the screen. Only built into test
// builds (qmake CONFIG+=ui_probe), and it does nothing unless MOONLIGHT_UI_PROBE names a
// QML file: that script is created inside main.qml's context
// (so it can call goBack(), navigateTo() and so on), gets `uiProbe` to save window
// screenshots and log lines into MOONLIGHT_UI_PROBE_OUT, and quits with finish().
// Scripts use the app's own types (SettingsView, PcView…) with `import "qrc:/gui"`. The
// run ends with exit code 3 after MOONLIGHT_UI_PROBE_TIMEOUT seconds (default 120).
class UiProbe : public QObject
{
    Q_OBJECT

public:
    // Loads the probe script if the environment asks for one
    static void startIfRequested(QQmlApplicationEngine* engine);

    // Saves the window's contents as <out>/<name>.png
    Q_INVOKABLE bool shot(const QString& name);
    // Appends a line to <out>/probe.log (and the app log)
    Q_INVOKABLE void log(const QString& line);
    // Ends the run: the app quits with this exit code
    Q_INVOKABLE void finish(int exitCode);

private:
    UiProbe(QQuickWindow* window, const QString& outDir);

    QQuickWindow* m_Window;
    QString m_OutDir;
    QFile m_Log;
};
