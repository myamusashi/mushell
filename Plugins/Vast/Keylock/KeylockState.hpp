#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qsocketnotifier.h>
#include <qtmetamacros.h>
#include <vector>

class Keylock : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool capsLock READ capsLock NOTIFY capsLockChanged)
    Q_PROPERTY(bool numLock READ numLock NOTIFY numLockChanged)

  public:
    explicit Keylock(QObject* parent = nullptr);
    ~Keylock() override;
    Keylock(const Keylock&)                 = delete;
    Keylock& operator=(const Keylock&)      = delete;
    Keylock(Keylock&&)                      = delete;
    Keylock&           operator=(Keylock&&) = delete;

    [[nodiscard]] bool capsLock() const {
        return mCapsLock;
    }
    [[nodiscard]] bool numLock() const {
        return mNumLock;
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

    std::vector<OpenDevice> mOpen;
    bool                    mCapsLock     = false;
    bool                    mNumLock      = false;
    bool                    mLastCapsLock = false;
    bool                    mLastNumLock  = false;
};
