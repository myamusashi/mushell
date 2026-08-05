#pragma once

#include <qlist.h>
#include <qobject.h>
#include <qsocketnotifier.h>
#include <qqmlengine.h>
#include <linux/input.h>

struct KeyboardDevice {
    int  fd;
    bool hasLED;
};

struct OpenDevice {
    int              fd       = -1;
    QSocketNotifier* notifier = nullptr;
};

class Keylock : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool capsLock READ capsLock NOTIFY capsLockChanged)
    Q_PROPERTY(bool numLock READ numLock NOTIFY numLockChanged)

  public:
    explicit Keylock(QObject* parent = nullptr);
    ~Keylock();

    [[nodiscard]] bool capsLock() const {
        return m_capsLock;
    }
    [[nodiscard]] bool numLock() const {
        return m_numLock;
    }

  signals:
    void capsLockChanged();
    void numLockChanged();

  private:
    struct OpenDevice {
        int              fd       = -1;
        QSocketNotifier* notifier = nullptr;
    };

    void                    openDevices();
    void                    readInitialState(int fd, bool hasLED);
    void                    onReadReady(int fd, bool hasLED);

    std::vector<OpenDevice> m_open;
    bool                    m_capsLock     = false;
    bool                    m_numLock      = false;
    bool                    m_lastCapsLock = false;
    bool                    m_lastNumLock  = false;
};
