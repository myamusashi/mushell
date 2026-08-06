#pragma once

#include <QAbstractListModel>
#include <qhashfunctions.h>
#include <qhash.h>
#include <qcontainerfwd.h>
#include <qlist.h>
#include <qtmetamacros.h>
#include <qqmlintegration.h>
#include <qnamespace.h>
#include <qobject.h>
#include <qvariant.h>
#include <qstringview.h>
#include <qtypes.h>
#include <cstdint>
#include <span>

struct ProfileEntry {
    int     index = -1;
    QString name;
    QString description;
    QString available;
    QString readable;

    auto    operator<=>(const ProfileEntry&) const = default;
};

class AudioProfilesModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Access via AudioProfilesWatcher.profiles")

  public:
    enum Roles : uint16_t {
        IndexRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        AvailableRole,
        ReadableRole,
    };
    Q_ENUM(Roles)

    explicit AudioProfilesModel(QObject* parent = nullptr);

    [[nodiscard]] int                     rowCount(const QModelIndex& parent = {}) const override;
    [[nodiscard]] QVariant                data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray>  roleNames() const override;

    void                                  setProfiles(std::span<const ProfileEntry> profiles);

    [[nodiscard]] Q_INVOKABLE QVariantMap get(int row) const;
    [[nodiscard]] Q_INVOKABLE qsizetype   count() const {
        return mProfiles.size();
    }

  private:
    QList<ProfileEntry> mProfiles;
};
