#pragma once

#include <QAbstractListModel>
#include <qhashfunctions.h>
#include <qhash.h>
#include <qcontainerfwd.h>
#include <qlist.h>
#include <qtypes.h>
#include <qtmetamacros.h>
#include <qqmlintegration.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qvariant.h>
#include <qstringview.h>
#include <cstdint>
#include <span>

struct DeviceEntry {
    quint32 id = 0;
    QString name;
    QString description;
    QString mediaClass; // "sink" | "source"
    QString state;      // "running" | "suspended" | "idle" | "error" | "creating" | "unknown"
    bool    isMonitor = false;
    QString monitorOf; // node.name of the sink this monitors; empty when not a monitor

    auto    operator<=>(const DeviceEntry&) const = default;
};

class AudioDevicesModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Access via AudioDevicesWatcher.devices")

  public:
    enum Roles : uint16_t {
        IdRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        MediaClassRole,
        StateRole,
        IsMonitorRole,
        MonitorOfRole,
    };
    Q_ENUM(Roles)

    explicit AudioDevicesModel(QObject* parent = nullptr);

    [[nodiscard]] int                     rowCount(const QModelIndex& parent = {}) const override;
    [[nodiscard]] QVariant                data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray>  roleNames() const override;

    void                                  setDevices(std::span<const DeviceEntry> devices);

    [[nodiscard]] Q_INVOKABLE QVariantMap get(int row) const;
    [[nodiscard]] Q_INVOKABLE qsizetype   count() const {
        return mDevices.size();
    }

  private:
    QList<DeviceEntry> mDevices;
};
