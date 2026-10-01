#include "nativechrome.h"

// Platform-independent parts. The platform parts live in nativechrome_mac.mm
// and nativechrome_generic.cpp.

void NativeChrome::setCanGoBack(bool canGoBack)
{
    if (m_CanGoBack != canGoBack) {
        m_CanGoBack = canGoBack;
        updateToolbar();
        emit canGoBackChanged();
    }
}

void NativeChrome::setShowAddPc(bool show)
{
    if (m_ShowAddPc != show) {
        m_ShowAddPc = show;
        updateToolbar();
        emit showAddPcChanged();
    }
}

void NativeChrome::setShowHelp(bool show)
{
    if (m_ShowHelp != show) {
        m_ShowHelp = show;
        updateToolbar();
        emit showHelpChanged();
    }
}

void NativeChrome::setShowSettings(bool show)
{
    if (m_ShowSettings != show) {
        m_ShowSettings = show;
        updateToolbar();
        emit showSettingsChanged();
    }
}

void NativeChrome::setSettingsOpen(bool open)
{
    if (m_SettingsOpen != open) {
        m_SettingsOpen = open;
        updateToolbar();
        emit settingsOpenChanged();
    }
}

void NativeChrome::setUpdateText(const QString& text)
{
    if (m_UpdateText != text) {
        m_UpdateText = text;
        updateToolbar();
        emit updateTextChanged();
    }
}
