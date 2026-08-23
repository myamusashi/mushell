#pragma once

#include <QAbstractListModel>
#include <qcontainerfwd.h>
#include <qlist.h>
#include <qmap.h>
#include <QtQmlIntegration/qqmlintegration.h>
#include <qtmetamacros.h>
#include <qtclasshelpermacros.h>
#include <qnamespace.h>
#include <qtypes.h>
#include <qvariant.h>

namespace vast {

    // Flat ranked file-search results speaking FileListView's exact role
    // names, so it can drop in wherever FolderListModel is used. Owned by
    // SearchEngine (C++ side); QML only reads.
    class FileSearchModel : public QAbstractListModel {
        Q_OBJECT
        QML_ELEMENT
        QML_UNCREATABLE("Access via SearchEngine.fileResults")
        Q_DISABLE_COPY(FileSearchModel)

      public:
        enum class Roles : uint16_t {
            FileNameRole = Qt::UserRole,
            FilePathRole,
            RelativePathRole,
            FileSizeRole,
            FileModifiedRole,
            FileIsDirRole,
        };
        Q_ENUM(Roles)

        explicit FileSearchModel(QObject* parent = nullptr);
        ~FileSearchModel() override                                       = default;
        FileSearchModel(FileSearchModel&&)                                = delete;
        FileSearchModel&                     operator=(FileSearchModel&&) = delete;

        [[nodiscard]] int                    rowCount(const QModelIndex& parent = {}) const override;
        [[nodiscard]] QVariant               data(const QModelIndex& index, int role = Qt::DisplayRole) const override;
        [[nodiscard]] QHash<int, QByteArray> roleNames() const override;

        void                                 setEntries(const QVariantList& entries);
        Q_INVOKABLE void                     clear();

      private:
        QList<QMap<QString, QVariant>> mEntries;
    };
}
