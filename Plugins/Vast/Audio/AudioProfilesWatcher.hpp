#pragma once
#include <qcontainerfwd.h>
#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qqmlintegration.h>
#include <qtimer.h>
#include <qtmetamacros.h>
#include <memory>
#include <qtypes.h>

#include "AudioProfilesModel.hpp"

class AudioProfilesWatcher : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(quint32 deviceId READ deviceId NOTIFY deviceInfoChanged)
    Q_PROPERTY(QString deviceName READ deviceName NOTIFY deviceInfoChanged)
    Q_PROPERTY(qsizetype activeIndex READ activeIndex NOTIFY activeProfileChanged)
    Q_PROPERTY(QVariantMap activeProfile READ activeProfile NOTIFY activeProfileChanged)
    Q_PROPERTY(AudioProfilesModel* profiles READ profiles CONSTANT)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

  public:
    static AudioProfilesWatcher* create(QQmlEngine* engine, QJSEngine* jsEngine);

    explicit AudioProfilesWatcher(QObject* parent = nullptr);
    ~AudioProfilesWatcher() override;
    AudioProfilesWatcher(const AudioProfilesWatcher&)            = delete;
    AudioProfilesWatcher& operator=(const AudioProfilesWatcher&) = delete;
    AudioProfilesWatcher(AudioProfilesWatcher&&)                 = delete;
    AudioProfilesWatcher& operator=(AudioProfilesWatcher&&)      = delete;

    [[nodiscard]] quint32 deviceId() const {
        return mDeviceId;
    }
    [[nodiscard]] QString deviceName() const {
        return mDeviceName;
    }
    [[nodiscard]] qsizetype activeIndex() const {
        return mActiveIndex;
    }
    [[nodiscard]] QVariantMap activeProfile() const {
        return mActiveProfile;
    }
    [[nodiscard]] AudioProfilesModel* profiles() const {
        return mModel;
    }
    [[nodiscard]] bool connected() const {
        return mConnected;
    }

  signals:
    void deviceInfoChanged();
    void activeProfileChanged();
    void connectedChanged();

  private:
    void                 poll();

    static constexpr int K_MIN_POLL_MS = 100;
    static constexpr int K_MAX_POLL_MS = 2000;

    quint32              mDeviceId = 0;
    QString              mDeviceName;
    qsizetype            mActiveIndex = -1;
    QVariantMap          mActiveProfile;
    AudioProfilesModel*  mModel          = nullptr;
    QTimer*              mTimer          = nullptr;
    int                  mPollIntervalMs = K_MIN_POLL_MS;
    bool                 mConnected      = false;

    struct PwState;
    std::unique_ptr<PwState>     mPw;

    [[nodiscard]] static QString formatProfileName(const QString& name);
};
