#include "nativechrome.h"

#include <QColor>
#include <QQmlEngine>

// Platforms without native chrome: QML keeps its own toolbar and icons

NativeChrome::NativeChrome(QObject* parent)
    : QObject(parent)
{
}

NativeChrome::~NativeChrome() = default;

void NativeChrome::registerTypes(QQmlEngine*)
{
    qmlRegisterSingletonType<NativeChrome>("NativeChrome", 1, 0, "NativeChrome",
                                           [](QQmlEngine*, QJSEngine*) -> QObject* {
                                               return new NativeChrome();
                                           });
}

bool NativeChrome::isEnabled() const
{
    return false;
}

void NativeChrome::attach(QQuickWindow*)
{
}

QString NativeChrome::symbol(const QString&, const QColor&) const
{
    return QString();
}

void NativeChrome::updateToolbar()
{
}
