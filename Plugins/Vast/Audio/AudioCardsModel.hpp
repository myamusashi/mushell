#pragma once

#include <QAbstractListModel>
#include <qcontainerfwd.h>
#include <qhash.h>
#include <qlist.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qvariant.h>

#include "AudioCard.hpp"
#include "AudioProfilesModel.hpp"

struct CardEntry {
    quint32             deviceId = 0;
    QString             name;
    QString             description;
    qsizetype           activeIndex = -1;
    QVariantMap         activeProfile;
    QList<ProfileEntry> profiles;

    auto                operator<=>(const CardEntry&) const = delete;
};

class AudioCardsModel : public QAbstractListModel {
    Q_OBJECT
    QML_ELEMENT
    QML_UNCREATABLE("Access via AudioProfilesWatcher.cards")

  public:
    enum Roles : uint16_t {
        DeviceIdRole = Qt::UserRole + 1,
        NameRole,
        DescriptionRole,
        ActiveIndexRole,
        ActiveProfileRole,
        ProfilesRole,
        CardRole,
    };
    Q_ENUM(Roles)

    explicit AudioCardsModel(QObject* parent = nullptr);

    [[nodiscard]] int                    rowCount(const QModelIndex& parent = {}) const override;
    [[nodiscard]] QVariant               data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
    [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

    bool                                 removeCard(quint32 deviceId);
    bool                                 upsertCard(const CardEntry& entry);

    [[nodiscard]] Q_INVOKABLE AudioCard* card(int row) const;
    [[nodiscard]] Q_INVOKABLE qsizetype  count() const {
        return mCards.size();
    }

  private:
    QList<AudioCard*> mCards;
};
