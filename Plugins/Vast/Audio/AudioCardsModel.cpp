#include "AudioCardsModel.hpp"

#include <qabstractitemmodel.h>

#include <algorithm>
#include <utility>

AudioCardsModel::AudioCardsModel(QObject* parent) : QAbstractListModel(parent) {}

int AudioCardsModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return static_cast<int>(mCards.size());
}

QVariant AudioCardsModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || std::cmp_greater_equal(index.row(), mCards.size()))
        return {};

    AudioCard* card = mCards.at(index.row());

    using enum Roles;
    switch (static_cast<Roles>(role)) {
        case DeviceIdRole: return card->deviceId();
        case NameRole: return card->name();
        case DescriptionRole: return card->description();
        case ActiveIndexRole: return card->activeIndex();
        case ActiveProfileRole: return card->activeProfile();
        case ProfilesRole: return QVariant::fromValue(card->profiles());
        case CardRole: return QVariant::fromValue(card);
        default: return {};
    }
}

QHash<int, QByteArray> AudioCardsModel::roleNames() const {
    static const QHash<int, QByteArray> roles{
        {DeviceIdRole, QByteArrayLiteral("deviceId")},
        {NameRole, QByteArrayLiteral("name")},
        {DescriptionRole, QByteArrayLiteral("description")},
        {ActiveIndexRole, QByteArrayLiteral("activeIndex")},
        {ActiveProfileRole, QByteArrayLiteral("activeProfile")},
        {ProfilesRole, QByteArrayLiteral("profiles")},
        {CardRole, QByteArrayLiteral("card")},
    };
    return roles;
}

bool AudioCardsModel::upsertCard(const CardEntry& entry) {
    auto it = std::ranges::find_if(mCards, [entry](const AudioCard* card) { return card->deviceId() == entry.deviceId; });

    if (it == mCards.end()) {
        const int row = static_cast<int>(mCards.size());
        beginInsertRows({}, row, row);
        auto* card = new AudioCard(this);
        mCards.append(card);
        endInsertRows();
        card->setDeviceInfo(entry.deviceId, entry.name, entry.description);
        card->setActiveProfile(entry.activeIndex, entry.activeProfile);
        card->profiles()->setProfiles(entry.profiles);
        return true;
    }
    AudioCard* card    = *it;
    bool       changed = false;
    changed |= card->setDeviceInfo(entry.deviceId, entry.name, entry.description);
    changed |= card->setActiveProfile(entry.activeIndex, entry.activeProfile);
    changed |= card->profiles()->setProfiles(entry.profiles);
    if (changed) {
        const int         row = static_cast<int>(std::distance(mCards.begin(), it));
        const QModelIndex idx = index(row);
        emit              dataChanged(idx, idx);
    }
    return changed;
}

bool AudioCardsModel::removeCard(quint32 deviceId) {
    auto it = std::ranges::find_if(mCards, [deviceId](const AudioCard* card) { return card->deviceId() == deviceId; });
    if (it == mCards.end())
        return false;

    const int row = static_cast<int>(std::distance(mCards.begin(), it));
    beginRemoveRows({}, row, row);
    AudioCard* card = *it;
    mCards.erase(it);
    endRemoveRows();
    card->deleteLater();
    return true;
}

AudioCard* AudioCardsModel::card(int row) const {
    if (row < 0 || std::cmp_greater_equal(row, mCards.size()))
        return nullptr;
    return mCards.at(row);
}
