#pragma once

#include "ClipboardEntry.hpp"

#include <QAbstractListModel>
#include <qlist.h>
#include <QtQmlIntegration/qqmlintegration.h>

#include <vector>

namespace Vast {

    class ClipboardModel : public QAbstractListModel {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Access via ClipboardManager.model")
        Q_DISABLE_COPY(ClipboardModel)

        Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

      public:
        enum class Roles : int {
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
        ~ClipboardModel() override = default;

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

        QList<ClipboardEntry>               m_entries{};
        std::vector<int>                    m_filtered{};
        QString                             m_filterQuery{};
        bool                                m_filtering{false};
    };
}
