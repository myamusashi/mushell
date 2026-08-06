#include "AudioProfilesModel.hpp"
#include <qobject.h>
#include <qabstractitemmodel.h>
#include <qvariant.h>
#include <qhash.h>
#include <qstringview.h>
#include <span>
#include <qcontainerfwd.h>
#include <qhashfunctions.h>
#include <utility>

AudioProfilesModel::AudioProfilesModel(QObject* parent) : QAbstractListModel(parent) {}

int AudioProfilesModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return static_cast<int>(mProfiles.size());
}

QVariant AudioProfilesModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || std::cmp_greater_equal(index.row(), mProfiles.size()))
        return {};

    const auto& [idx, name, desc, avail, read] = mProfiles.at(index.row());

    using enum Roles;
    switch (static_cast<Roles>(role)) {
        case IndexRole: return idx;
        case NameRole: return name;
        case DescriptionRole: return desc;
        case AvailableRole: return avail;
        case ReadableRole: return read;
        default: return {};
    }
}

QHash<int, QByteArray> AudioProfilesModel::roleNames() const {
    static const QHash<int, QByteArray> roles{
        {IndexRole, QByteArrayLiteral("index")},         {NameRole, QByteArrayLiteral("name")},         {DescriptionRole, QByteArrayLiteral("description")},
        {AvailableRole, QByteArrayLiteral("available")}, {ReadableRole, QByteArrayLiteral("readable")},
    };
    return roles;
}

void AudioProfilesModel::setProfiles(std::span<const ProfileEntry> profiles) {
    beginResetModel();
    mProfiles.assign(profiles.begin(), profiles.end());
    endResetModel();
}

QVariantMap AudioProfilesModel::get(int row) const {
    if (std::cmp_less(row, 0) || std::cmp_greater_equal(row, mProfiles.size()))
        return {};

    const auto& [idx, name, desc, avail, read] = mProfiles.at(row);
    return {
        {QStringLiteral("index"), idx},       {QStringLiteral("name"), name},     {QStringLiteral("description"), desc},
        {QStringLiteral("available"), avail}, {QStringLiteral("readable"), read},
    };
}
