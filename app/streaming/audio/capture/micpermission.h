#pragma once

#include <QObject>

#include <functional>

// Operating system permission to record from the microphone. Only macOS
// gates this; elsewhere access is always reported as granted.
namespace MicPermission
{
    enum class Status {
        Granted,
        Denied,
        Undetermined,
    };

    Status status();

    // Shows the system prompt if the user hasn't decided yet. The callback
    // runs on the thread that owns context (usually the GUI thread) unless
    // context is destroyed first.
    void request(QObject* context, std::function<void(bool granted)> callback);
}
