#include "AudioDevicesModel.hpp"
#include <qobject.h>
#include <qabstractitemmodel.h>
#include <qvariant.h>
#include <qhash.h>
#include <qstringview.h>
#include <span>
#include <qcontainerfwd.h>
#include <qhashfunctions.h>
#include <utility>

AudioDevicesModel::AudioDevicesModel(QObject* parent) : QAbstractListModel(parent) {}

int AudioDevicesModel::rowCount(const QModelIndex& parent) const {
    if (parent.isValid())
        return 0;
    return static_cast<int>(mDevices.size());
}

QVariant AudioDevicesModel::data(const QModelIndex& index, int role) const {
    if (!index.isValid() || std::cmp_greater_equal(index.row(), mDevices.size()))
        return {};

    const auto& [id, name, desc, mclass, state, isMonitor, monitorOf] = mDevices.at(index.row());

    using enum Roles;
    switch (static_cast<Roles>(role)) {
        case IdRole: return id;
        case NameRole: return name;
        case DescriptionRole: return desc;
        case MediaClassRole: return mclass;
        case StateRole: return state;
        case IsMonitorRole: return isMonitor;
        case MonitorOfRole: return monitorOf;
        default: return {};
    }
}

QHash<int, QByteArray> AudioDevicesModel::roleNames() const {
    static const QHash<int, QByteArray> roles{
        {IdRole, QByteArrayLiteral("id")},
        {NameRole, QByteArrayLiteral("name")},
        {DescriptionRole, QByteArrayLiteral("description")},
        {MediaClassRole, QByteArrayLiteral("mediaClass")},
        {StateRole, QByteArrayLiteral("state")},
        {IsMonitorRole, QByteArrayLiteral("isMonitor")},
        {MonitorOfRole, QByteArrayLiteral("monitorOf")},
    };
    return roles;
}

void AudioDevicesModel::setDevices(std::span<const DeviceEntry> devices) {
    beginResetModel();
    mDevices.assign(devices.begin(), devices.end());
    endResetModel();
}

QVariantMap AudioDevicesModel::get(int row) const {
    if (std::cmp_less(row, 0) || std::cmp_greater_equal(row, mDevices.size()))
        return {};

    const auto& [id, name, desc, mclass, state, isMonitor, monitorOf] = mDevices.at(row);
    return {
        {QStringLiteral("id"), id},       {QStringLiteral("name"), name},           {QStringLiteral("description"), desc},    {QStringLiteral("mediaClass"), mclass},
        {QStringLiteral("state"), state}, {QStringLiteral("isMonitor"), isMonitor}, {QStringLiteral("monitorOf"), monitorOf},
    };
}
