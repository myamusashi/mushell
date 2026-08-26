#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

#include "AudioProfilesModel.hpp"

class AudioCard : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Access via AudioProfilesWatcher.cards")

    Q_PROPERTY(quint32 deviceId READ deviceId NOTIFY deviceIdChanged)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(QString description READ description NOTIFY descriptionChanged)
    Q_PROPERTY(qsizetype activeIndex READ activeIndex NOTIFY activeIndexChanged)
    Q_PROPERTY(QVariantMap activeProfile READ activeProfile NOTIFY activeIndexChanged)
    Q_PROPERTY(AudioProfilesModel* profiles READ profiles CONSTANT)

  public:
    explicit AudioCard(QObject* parent = nullptr);
    ~AudioCard() override;
    AudioCard(const AudioCard&)                  = delete;
    AudioCard& operator=(const AudioCard&)       = delete;
    AudioCard(AudioCard&&)                       = delete;
    AudioCard&            operator=(AudioCard&&) = delete;

    bool                  setDeviceInfo(quint32 deviceId, const QString& name, const QString& description);
    bool                  setActiveProfile(qsizetype index, const QVariantMap& profile);

    [[nodiscard]] quint32 deviceId() const {
        return mDeviceId;
    }
    [[nodiscard]] QString name() const {
        return mName;
    }
    [[nodiscard]] QString description() const {
        return mDescription;
    }
    [[nodiscard]] qsizetype activeIndex() const {
        return mActiveIndex;
    }
    [[nodiscard]] QVariantMap activeProfile() const {
        return mActiveProfile;
    }
    [[nodiscard]] AudioProfilesModel* profiles() const {
        return mProfiles;
    }

  signals:
    void deviceIdChanged();
    void nameChanged();
    void descriptionChanged();
    void activeIndexChanged();

  private:
    quint32             mDeviceId = 0;
    QString             mName;
    QString             mDescription;
    qsizetype           mActiveIndex = -1;
    QVariantMap         mActiveProfile;
    AudioProfilesModel* mProfiles = nullptr;
};
