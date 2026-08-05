#include "KeylockState.hpp"

#include <qdir.h>
#include <fcntl.h>
#include <cerrno>
#include <algorithm>
#include <string_view>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <linux/kd.h>

static QList<KeyboardDevice> findKeyboards() {
    QList<KeyboardDevice> devices;
    QDir                  inputDir("/dev/input");
    const auto            entries = inputDir.entryList({"event*"}, QDir::System);

    for (const QString& entry : entries) {
        const QByteArray path = ("/dev/input/" + entry).toLocal8Bit();
        int              fd   = ::open(path.constData(), O_RDONLY | O_NONBLOCK);

        if (fd < 0)
            continue;

        char name[256] = {};
        if (::ioctl(fd, EVIOCGNAME(sizeof(name)), name) < 0) {
            ::close(fd);
            continue;
        }

        const std::string_view devName(name);
        const bool             isMouse = devName.find("Mouse") != std::string_view::npos || devName.find("mouse") != std::string_view::npos ||
            devName.find("Touchpad") != std::string_view::npos || devName.find("touchpad") != std::string_view::npos || devName.find("TrackPoint") != std::string_view::npos;

        if (isMouse) {
            ::close(fd);
            continue;
        }

        unsigned long evBits = 0;
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

        devices.append({fd, hasLED});
    }

    return devices;
}

Keylock::Keylock(QObject* parent) : QObject(parent) {
    openDevices();
}

Keylock::~Keylock() {
    std::ranges::for_each(m_open, [](const OpenDevice& d) {
        delete d.notifier;
        if (d.fd >= 0)
            ::close(d.fd);
    });
}

void Keylock::openDevices() {
    const auto devices = findKeyboards();

    qDebug() << "KeylockState: found" << devices.size() << "device(s)";

    if (devices.isEmpty()) {
        qWarning("KeylockState: no keyboard found — check /dev/input permissions");
        return;
    }

    for (const auto& dev : devices) {
        auto* notifier = new QSocketNotifier(dev.fd, QSocketNotifier::Read);
        connect(notifier, &QSocketNotifier::activated, this, [this, fd = dev.fd, hasLED = dev.hasLED] { onReadReady(fd, hasLED); });
        m_open.push_back({dev.fd, notifier});
        readInitialState(dev.fd, dev.hasLED);
    }
}

void Keylock::readInitialState(int fd, bool hasLED) {
    if (hasLED) {
        std::array<unsigned char, LED_MAX / 8 + 1> ledBits{};
        if (::ioctl(fd, EVIOCGLED(ledBits.size()), ledBits.data()) < 0)
            return;

        m_capsLock = ledBits[LED_CAPSL / 8] & (1 << (LED_CAPSL % 8));
        m_numLock  = ledBits[LED_NUML / 8] & (1 << (LED_NUML % 8));
    } else {
        int ttyFd = ::open("/dev/tty", O_RDONLY);
        if (ttyFd >= 0) {
            unsigned char flags = 0;
            if (::ioctl(ttyFd, KDGKBLED, &flags) == 0) {
                m_capsLock = flags & LED_CAP;
                m_numLock  = flags & LED_NUM;
            }
            ::close(ttyFd);
        } else {
            unsigned long keyState[(KEY_MAX / 8) + 1] = {};
            // EVIOCGKEY gives currently held keys, not toggle state
            // so we can only default to false here, no reliable fallback
            if (::ioctl(fd, EVIOCGKEY(sizeof(keyState)), keyState) == 0)
                qWarning("Keylock: /dev/tty unavailable, initial state unknown");
        }
    }
}

void Keylock::onReadReady(int fd, bool hasLED) {
    auto it = std::find_if(m_open.begin(), m_open.end(), [fd](const OpenDevice& d) { return d.fd == fd; });
    if (it == m_open.end())
        return;

    QSocketNotifier* notifier = it->notifier;
    if (notifier)
        notifier->setEnabled(false);

    input_event   ev{};
    constexpr int kMaxEventsPerBatch = 64;
    int           processed          = 0;
    bool          removeDevice       = false;

    while (processed < kMaxEventsPerBatch) {
        ssize_t bytes = ::read(fd, &ev, sizeof(ev));
        if (bytes == static_cast<ssize_t>(sizeof(ev))) {
            ++processed;

            if (hasLED) {
                if (ev.type != EV_LED)
                    continue; // read next event

                const bool val = ev.value != 0;
                if (ev.code == LED_CAPSL && m_capsLock != val) {
                    m_capsLock = val;
                    emit capsLockChanged();
                } else if (ev.code == LED_NUML && m_numLock != val) {
                    m_numLock = val;
                    emit numLockChanged();
                }
            } else {
                if (ev.type != EV_KEY || ev.value != 1)
                    continue; // read next event

                if (ev.code == KEY_CAPSLOCK) {
                    m_capsLock = !m_capsLock;
                    emit capsLockChanged();
                } else if (ev.code == KEY_NUMLOCK) {
                    m_numLock = !m_numLock;
                    emit numLockChanged();
                }
            }
        } else if (bytes < 0) {
            if (errno != EAGAIN && errno != EWOULDBLOCK)
                removeDevice = true; // error: ENODEV, EIO, etc.
            break;
        } else {
            // EOF / partial read — device disconnected
            removeDevice = true;
            break;
        }
    }

    if (removeDevice) {
        it->notifier = nullptr;
        delete notifier;
        ::close(fd);
        m_open.erase(it);
    } else if (notifier) {
        notifier->setEnabled(true);
    }
}
