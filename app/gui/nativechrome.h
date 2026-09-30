#pragma once

#include <QObject>
#include <QString>

class QQuickWindow;
class QQmlEngine;

// Native window chrome for platforms that have it (macOS): a system toolbar
// with SF Symbol buttons and a translucent Liquid Glass window background.
// Elsewhere `enabled` is false and QML keeps drawing its own toolbar.
class NativeChrome : public QObject
{
    Q_OBJECT

    Q_PROPERTY(bool enabled READ isEnabled CONSTANT)
    Q_PROPERTY(bool canGoBack READ canGoBack WRITE setCanGoBack NOTIFY canGoBackChanged)
    Q_PROPERTY(bool showAddPc READ showAddPc WRITE setShowAddPc NOTIFY showAddPcChanged)
    Q_PROPERTY(bool showHelp READ showHelp WRITE setShowHelp NOTIFY showHelpChanged)
    Q_PROPERTY(bool showSettings READ showSettings WRITE setShowSettings NOTIFY showSettingsChanged)
    Q_PROPERTY(QString updateText READ updateText WRITE setUpdateText NOTIFY updateTextChanged)

public:
    explicit NativeChrome(QObject* parent = nullptr);
    ~NativeChrome() override;

    // Also registers the "sfsymbol" image provider where supported
    static void registerTypes(QQmlEngine* engine);

    bool isEnabled() const;

    bool canGoBack() const { return m_CanGoBack; }
    void setCanGoBack(bool canGoBack);
    bool showAddPc() const { return m_ShowAddPc; }
    void setShowAddPc(bool show);
    bool showHelp() const { return m_ShowHelp; }
    void setShowHelp(bool show);
    bool showSettings() const { return m_ShowSettings; }
    void setShowSettings(bool show);
    QString updateText() const { return m_UpdateText; }
    void setUpdateText(const QString& text);

    // Installs the toolbar and glass background on the window
    Q_INVOKABLE void attach(QQuickWindow* window);

    // Moves and resizes the window (its content area, in Qt's coordinates). On macOS it can
    // animate like a native window; the call returns when the animation has finished.
    Q_INVOKABLE void setWindowGeometry(QQuickWindow* window, qreal x, qreal y, qreal width, qreal height, bool animate);

    // Image URL for an SF Symbol drawn in the given color, for Image.source
    Q_INVOKABLE QString symbol(const QString& name, const QColor& color) const;

signals:
    void canGoBackChanged();
    void showAddPcChanged();
    void showHelpChanged();
    void showSettingsChanged();
    void updateTextChanged();

    void backClicked();
    void addPcClicked();
    void helpClicked();
    void settingsClicked();
    void updateClicked();

private:
    void updateToolbar();

    bool m_CanGoBack = false;
    bool m_ShowAddPc = false;
    bool m_ShowHelp = false;
    bool m_ShowSettings = true;
    QString m_UpdateText;
    void* m_Native = nullptr;  // Platform state (the toolbar delegate on macOS)
};
