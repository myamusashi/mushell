#pragma once
#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qtimer.h>
#include <QtQml/qqmlregistration.h>
#include <memory>

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

    [[nodiscard]] AudioDevicesModel* devices() const {
        return m_model;
    }
    [[nodiscard]] bool connected() const {
        return m_connected;
    }

  signals:
    void connectedChanged();
    void devicesChanged();

  private:
    void                 poll();

    static constexpr int kMinPollMs = 200;
    static constexpr int kMaxPollMs = 2000;

    AudioDevicesModel*   m_model          = nullptr;
    QTimer*              m_timer          = nullptr;
    int                  m_pollIntervalMs = kMinPollMs;
    bool                 m_connected      = false;

    struct PwState;
    std::unique_ptr<PwState> m_pw;
};
