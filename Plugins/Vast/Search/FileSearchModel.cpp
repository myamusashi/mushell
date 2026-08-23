#include "FileSearchModel.hpp"

#include <qabstractitemmodel.h>
#include <qbytearray.h>
#include <qcontainerfwd.h>
#include <qhash.h>
#include <qobject.h>
#include <qstring.h>
#include <qvariant.h>

namespace vast {

    FileSearchModel::FileSearchModel(QObject* parent) : QAbstractListModel(parent) {}

    int FileSearchModel::rowCount(const QModelIndex& parent) const {
        if (parent.isValid())
            return 0;
        return static_cast<int>(mEntries.size());
    }

    QVariant FileSearchModel::data(const QModelIndex& index, int role) const {
        if (!index.isValid() || index.row() >= mEntries.size())
            return {};

        const auto& entry = mEntries.at(index.row());

        switch (static_cast<Roles>(role)) {
            case Roles::FileNameRole: return entry.value(QStringLiteral("fileName")).toString();
            case Roles::FilePathRole: return entry.value(QStringLiteral("filePath")).toString();
            case Roles::RelativePathRole: return entry.value(QStringLiteral("relativePath")).toString();
            case Roles::FileSizeRole: return entry.value(QStringLiteral("fileSize")).toLongLong();
            case Roles::FileModifiedRole: return entry.value(QStringLiteral("fileModified"));
            case Roles::FileIsDirRole: return entry.value(QStringLiteral("fileIsDir")).toBool();
        }
        return {};
    }

    QHash<int, QByteArray> FileSearchModel::roleNames() const {
        return {
            {static_cast<int>(Roles::FileNameRole), "fileName"},         {static_cast<int>(Roles::FilePathRole), "filePath"},
            {static_cast<int>(Roles::RelativePathRole), "relativePath"}, {static_cast<int>(Roles::FileSizeRole), "fileSize"},
            {static_cast<int>(Roles::FileModifiedRole), "fileModified"}, {static_cast<int>(Roles::FileIsDirRole), "fileIsDir"},
        };
    }

    void FileSearchModel::setEntries(const QVariantList& entries) {
        beginResetModel();
        mEntries.clear();
        mEntries.reserve(entries.size());
        for (const QVariant& v : entries)
            mEntries.append(v.toMap());
        endResetModel();
    }

    void FileSearchModel::clear() {
        setEntries({});
    }
}
