#pragma once

#include "ClipboardEntry.hpp"

#include <QAbstractListModel>
#include <cstdint>
#include <qhash.h>
#include <qlist.h>
#include <QtQmlIntegration/qqmlintegration.h>

#include <qtmetamacros.h>
#include <qtclasshelpermacros.h>
#include <qnamespace.h>
#include <qtypes.h>
#include <vector>

namespace vast {

    class ClipboardModel : public QAbstractListModel {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Access via ClipboardManager.model")
        Q_DISABLE_COPY(ClipboardModel)

        Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

      public:
        enum class Roles : uint16_t {
            IdRole = Qt::UserRole,
            TypeRole,
            PreviewRole,
            TimestampRole,
            PinnedRole,
            SourceAppRole,
            MimeTypeRole,
            SizeBytesRole,
            FileNameRole,
        };
        Q_ENUM(Roles)

        explicit ClipboardModel(QObject* parent = nullptr);
        ~ClipboardModel() override                                             = default;
        ClipboardModel(ClipboardModel&&)                                       = delete;
        ClipboardModel&                            operator=(ClipboardModel&&) = delete;

        [[nodiscard]] int                          rowCount(const QModelIndex& parent = {}) const override;
        [[nodiscard]] QVariant                     data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
        [[nodiscard]] QHash<int, QByteArray>       roleNames() const override;
        [[nodiscard]] const QList<ClipboardEntry>& allEntries() const noexcept;

        void                                       reset(QList<ClipboardEntry> entries);
        void                                       prepend(const ClipboardEntry& entry);
        void                                       removeById(qint64 id);
        void                                       setPinById(qint64 id, bool pinned);
        void                                       setFilter(const QString& query, const QList<qint64>& orderedIds = {});

        void                                       bumpToTop(qint64 id);

        [[nodiscard]] Q_INVOKABLE qint64           idAtRow(int row) const;

      signals:
        void countChanged();

      private:
        [[nodiscard]] static QString        makePreview(const ClipboardEntry& e);
        [[nodiscard]] int                   indexById(qint64 id) const;

        void                                rebuildFilter();

        [[nodiscard]] const ClipboardEntry& visibleAt(int row) const;
        [[nodiscard]] int                   visibleCount() const;

        QList<ClipboardEntry>               mEntries;
        std::vector<int>                    mFiltered;
        QString                             mFilterQuery;
        bool                                mFiltering{false};
    };
}
