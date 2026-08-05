#pragma once
#include <qjsengine.h>
#include <qobject.h>
#include <qqmlengine.h>
#include <qtimer.h>
#include <qvariantmap.h>
#include <QtQml/qqmlregistration.h>
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

    [[nodiscard]] quint32 deviceId() const {
        return m_deviceId;
    }
    [[nodiscard]] QString deviceName() const {
        return m_deviceName;
    }
    [[nodiscard]] qsizetype activeIndex() const {
        return m_activeIndex;
    }
    [[nodiscard]] QVariantMap activeProfile() const {
        return m_activeProfile;
    }
    [[nodiscard]] AudioProfilesModel* profiles() const {
        return m_model;
    }
    [[nodiscard]] bool connected() const {
        return m_connected;
    }

  signals:
    void deviceInfoChanged();
    void activeProfileChanged();
    void connectedChanged();

  private:
    void                 poll();

    static constexpr int kMinPollMs = 100;
    static constexpr int kMaxPollMs = 2000;

    quint32              m_deviceId = 0;
    QString              m_deviceName;
    qsizetype            m_activeIndex = -1;
    QVariantMap          m_activeProfile;
    AudioProfilesModel*  m_model          = nullptr;
    QTimer*              m_timer          = nullptr;
    int                  m_pollIntervalMs = kMinPollMs;
    bool                 m_connected      = false;

    struct PwState;
    std::unique_ptr<PwState>     m_pw;

    [[nodiscard]] static QString formatProfileName(const QString& name);
};
