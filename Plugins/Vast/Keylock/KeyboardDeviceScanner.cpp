#include "KeyboardDeviceScanner.hpp"

#include <linux/input-event-codes.h>
#include <linux/input.h>
#include <array>
#include <qbytearray.h>
#include <qdir.h>
#include <qlist.h>
#include <fcntl.h>
#include <cstdint>
#include <string_view>
#include <sys/ioctl.h>
#include <unistd.h>

namespace vast {

    QList<KeyboardDevice> findKeyboards() {
        QList<KeyboardDevice> devices;
        QDir const            inputDir("/dev/input");
        const auto            entries = inputDir.entryList({"event*"}, QDir::System);

        for (const QString& entry : entries) {
            const QByteArray path = ("/dev/input/" + entry).toLocal8Bit();
            int const        fd   = ::open(path.constData(), O_RDONLY | O_NONBLOCK);

            if (fd < 0)
                continue;

            std::array<char, 256> name{};
            if (::ioctl(fd, EVIOCGNAME(name.size()), name.data()) < 0) {
                ::close(fd);
                continue;
            }

            const std::string_view devName(name.data());
            const bool             isMouse = devName.find("Mouse") != std::string_view::npos || devName.find("mouse") != std::string_view::npos ||
                devName.find("Touchpad") != std::string_view::npos || devName.find("touchpad") != std::string_view::npos || devName.find("TrackPoint") != std::string_view::npos;

            if (isMouse) {
                ::close(fd);
                continue;
            }

            uint64_t evBits = 0;
            if (::ioctl(fd, EVIOCGBIT(0, sizeof(evBits)), &evBits) < 0) {
                ::close(fd);
                continue;
            }

            const bool hasKey = evBits & (1UL << EV_KEY);
            const bool hasLED = evBits & (1UL << EV_LED);
            const bool hasRel = evBits & (1UL << EV_REL);
            const bool hasAbs = evBits & (1UL << EV_ABS);

            if (!hasKey) {
                ::close(fd);
                continue;
            }

            if (hasRel || hasAbs) {
                ::close(fd);
                continue;
            }

            std::array<unsigned char, (KEY_MAX / 8) + 1> keyBits{};
            if (::ioctl(fd, EVIOCGBIT(EV_KEY, keyBits.size()), keyBits.data()) < 0) {
                ::close(fd);
                continue;
            }

            const bool hasCapsKey = keyBits[KEY_CAPSLOCK / 8] & (1 << (KEY_CAPSLOCK % 8));
            if (!hasCapsKey) {
                ::close(fd);
                continue;
            }

            const bool hasAlpha = keyBits[KEY_A / 8] & (1 << (KEY_A % 8));
            if (!hasAlpha) {
                ::close(fd);
                continue;
            }

            devices.append({.fd = fd, .hasLED = hasLED});
        }

        return devices;
    }
}