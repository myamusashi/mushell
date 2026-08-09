#include "KeylockState.hpp"
#include "KeyboardDeviceScanner.hpp"

#include <linux/input-event-codes.h>
#include <array>
#include <algorithm>
#include <cerrno>
#include <cstdint>
#include <fcntl.h>
#include <qobject.h>
#include <qdebug.h>
#include <qlogging.h>
#include <qsocketnotifier.h>
#include <qtmetamacros.h>
#include <sys/types.h>
#include <utility>
#include <unistd.h>
#include <sys/ioctl.h>
#include <linux/input.h>
#include <linux/kd.h>

namespace vast {

    Keylock::Keylock(QObject* parent) : QObject(parent) {
        openDevices();
    }

    Keylock::~Keylock() {
        std::ranges::for_each(mOpen, [](const OpenDevice& d) {
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
            mOpen.push_back({dev.fd, notifier});
            readInitialState(dev.fd, dev.hasLED);
        }
    }

    void Keylock::readInitialState(int fd, bool hasLED) {
        if (hasLED) {
            std::array<unsigned char, LED_MAX / 8 + 1> ledBits{};
            if (::ioctl(fd, EVIOCGLED(ledBits.size()), ledBits.data()) < 0)
                return;

            mCapsLock = ledBits[LED_CAPSL / 8] & (1 << (LED_CAPSL % 8));
            mNumLock  = ledBits[LED_NUML / 8] & (1 << (LED_NUML % 8));
        } else {
            int const ttyFd = ::open("/dev/tty", O_RDONLY);
            if (ttyFd >= 0) {
                unsigned char flags = 0;
                if (::ioctl(ttyFd, KDGKBLED, &flags) == 0) {
                    mCapsLock = flags & LED_CAP;
                    mNumLock  = flags & LED_NUM;
                }
                ::close(ttyFd);
            } else {
                std::array<uint64_t, (KEY_MAX / 8) + 1> keyState{};
                // EVIOCGKEY gives currently held keys, not toggle state
                // so we can only default to false here, no reliable fallback
                if (::ioctl(fd, EVIOCGKEY(keyState.size() * sizeof(uint64_t)), keyState.data()) == 0)
                    qWarning("Keylock: /dev/tty unavailable, initial state unknown");
            }
        }
    }

    void Keylock::onReadReady(int fd, bool hasLED) {
        auto it = std::ranges::find_if(mOpen, [fd](const OpenDevice& d) { return d.fd == fd; });
        if (it == mOpen.end())
            return;

        QSocketNotifier* notifier = it->notifier;
        if (notifier)
            notifier->setEnabled(false);

        input_event   ev{};
        constexpr int kMaxEventsPerBatch = 64;
        int           processed          = 0;
        bool          removeDevice       = false;

        while (processed < kMaxEventsPerBatch) {
            ssize_t const bytes = ::read(fd, &ev, sizeof(ev));
            if (std::cmp_equal(bytes, sizeof(ev))) {
                ++processed;

                if (hasLED) {
                    if (ev.type != EV_LED)
                        continue; // read next event

                    const bool val = ev.value != 0;
                    if (ev.code == LED_CAPSL && mCapsLock != val) {
                        mCapsLock = val;
                        emit capsLockChanged();
                    } else if (ev.code == LED_NUML && mNumLock != val) {
                        mNumLock = val;
                        emit numLockChanged();
                    }
                } else {
                    if (ev.type != EV_KEY || ev.value != 1)
                        continue; // read next event

                    if (ev.code == KEY_CAPSLOCK) {
                        mCapsLock = !mCapsLock;
                        emit capsLockChanged();
                    } else if (ev.code == KEY_NUMLOCK) {
                        mNumLock = !mNumLock;
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
            mOpen.erase(it);
        } else if (notifier) {
            notifier->setEnabled(true);
        }
    }
} // namespace vast
