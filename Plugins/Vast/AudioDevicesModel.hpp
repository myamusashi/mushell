#pragma once

#include <QAbstractListModel>
#include <qlist.h>
#include <qvariantmap.h>
#include <QtQml/qqmlregistration.h>
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
    enum Roles {
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
        return m_devices.size();
    }

  private:
    QList<DeviceEntry> m_devices;
};
