#pragma once

#include <qlist.h>

namespace vast {

    struct KeyboardDevice {
        int  fd;
        bool hasLED;
    };

    /// Scans /dev/input for devices that behave like a physical keyboard
    /// (has EV_KEY + KEY_CAPSLOCK + KEY_A, not a mouse/touchpad/trackpoint,
    /// no EV_REL/EV_ABS). Returned fds are open (O_RDONLY | O_NONBLOCK) and
    /// owned by the caller — the caller is responsible for closing them.
    [[nodiscard]] QList<KeyboardDevice> findKeyboards();
}
