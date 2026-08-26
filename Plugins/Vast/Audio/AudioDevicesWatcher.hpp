#pragma once
#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qtimer.h>
#include <memory>
#include <qtmetamacros.h>

#include "AudioDevicesModel.hpp"

class AudioDevicesWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(AudioDevicesModel* devices READ devices CONSTANT)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

  public:
    static AudioDevicesWatcher* create(QQmlEngine* engine, QJSEngine* jsEngine);

    explicit AudioDevicesWatcher(QObject* parent = nullptr);
    ~AudioDevicesWatcher() override;
    AudioDevicesWatcher(const AudioDevicesWatcher&)                   = delete;
    AudioDevicesWatcher& operator=(const AudioDevicesWatcher&)        = delete;
    AudioDevicesWatcher(AudioDevicesWatcher&&)                        = delete;
    AudioDevicesWatcher&             operator=(AudioDevicesWatcher&&) = delete;

    [[nodiscard]] AudioDevicesModel* devices() const {
        return mModel;
    }
    [[nodiscard]] bool connected() const {
        return mConnected;
    }

    Q_INVOKABLE void setDefaultSink(const QString& nodeName);
    Q_INVOKABLE void setDefaultSource(const QString& nodeName);

  signals:
    void connectedChanged();
    void devicesChanged();

  private:
    void                 poll();

    static constexpr int K_MIN_POLL_MS = 200;
    static constexpr int K_MAX_POLL_MS = 2000;

    AudioDevicesModel*   mModel          = nullptr;
    QTimer*              mTimer          = nullptr;
    int                  mPollIntervalMs = K_MIN_POLL_MS;
    bool                 mConnected      = false;

    struct PwState;
    std::unique_ptr<PwState> mPw;
};
