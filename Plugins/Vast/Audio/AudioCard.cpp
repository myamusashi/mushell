#include "AudioCard.hpp"

AudioCard::AudioCard(QObject* parent) : QObject(parent), mProfiles(new AudioProfilesModel(this)) {}

AudioCard::~AudioCard() = default;

bool AudioCard::setDeviceInfo(quint32 deviceId, const QString& name, const QString& description) {
    bool changed = false;
    if (mDeviceId != deviceId) {
        mDeviceId = deviceId;
        emit deviceIdChanged();
        changed = true;
    }
    if (mName != name) {
        mName = name;
        emit nameChanged();
        changed = true;
    }
    if (mDescription != description) {
        mDescription = description;
        emit descriptionChanged();
        changed = true;
    }
    return changed;
}

bool AudioCard::setActiveProfile(qsizetype index, const QVariantMap& profile) {
    if (mActiveIndex == index && mActiveProfile == profile)
        return false;
    mActiveIndex   = index;
    mActiveProfile = profile;
    emit activeIndexChanged();
    return true;
}
