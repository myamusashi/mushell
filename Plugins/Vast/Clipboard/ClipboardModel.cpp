#include "ClipboardEntry.hpp"
#include "ClipboardModel.hpp"
#include "../FuzzyCore.hpp"
#include "../FuzzyMatcher.hpp"

#include <qabstractitemmodel.h>
#include <iterator>
#include <cstddef>
#include <qcontainerfwd.h>
#include <qdatetime.h>
#include <qfileinfo.h>
#include <qnamespace.h>
#include <qregularexpression.h>
#include <qset.h>

#include <algorithm>
#include <qobject.h>
#include <qvariant.h>
#include <qhash.h>
#include <qlist.h>
#include <utility>
#include <qtmetamacros.h>
#include <qtypes.h>

namespace vast {

    namespace {
        constexpr double K_CLIPBOARD_THRESHOLD_PER_CHAR = 0.35;
    }

    ClipboardModel::ClipboardModel(QObject* parent) : QAbstractListModel{parent} {}

    int ClipboardModel::rowCount(const QModelIndex& parent) const {
        if (parent.isValid())
            return 0;
        return visibleCount();
    }

    QVariant ClipboardModel::data(const QModelIndex& index, int role) const {
        if (!index.isValid() || index.row() >= visibleCount())
            return {};

        const auto& e = visibleAt(index.row());

        switch (static_cast<Roles>(role)) {
            case Roles::IdRole: return e.id;
            case Roles::TypeRole: return e.typeString();
            case Roles::PreviewRole: return makePreview(e);
            case Roles::TimestampRole: return e.timestamp;
            case Roles::PinnedRole: return e.pinned;
            case Roles::SourceAppRole: return e.sourceApp;
            case Roles::MimeTypeRole: return e.mimeType;
            case Roles::SizeBytesRole: return e.sizeBytes;
            case Roles::FileNameRole: return QFileInfo(e.fileName).fileName();
        }
        return {};
    }

    QHash<int, QByteArray> ClipboardModel::roleNames() const {
        return {
            {static_cast<int>(Roles::IdRole), "entryId"},          {static_cast<int>(Roles::TypeRole), "type"},           {static_cast<int>(Roles::PreviewRole), "preview"},
            {static_cast<int>(Roles::TimestampRole), "timestamp"}, {static_cast<int>(Roles::PinnedRole), "pinned"},       {static_cast<int>(Roles::SourceAppRole), "sourceApp"},
            {static_cast<int>(Roles::MimeTypeRole), "mimeType"},   {static_cast<int>(Roles::SizeBytesRole), "sizeBytes"}, {static_cast<int>(Roles::FileNameRole), "fileName"},
        };
    }

    void ClipboardModel::reset(QList<ClipboardEntry> entries) {
        beginResetModel();
        mEntries   = std::move(entries);
        mFiltering = false;
        mFilterQuery.clear();
        mFiltered.clear();
        endResetModel();
        emit countChanged();
    }

    void ClipboardModel::prepend(const ClipboardEntry& entry) {
        if (mFiltering) {
            beginResetModel();
            const int existing = indexById(entry.id);
            if (existing >= 0)
                mEntries.removeAt(existing);

            const auto insertPos = std::ranges::find_if(mEntries, [&](const ClipboardEntry& e) {
                if (entry.pinned && !e.pinned)
                    return true;
                if (!entry.pinned && e.pinned)
                    return false;
                return entry.timestamp >= e.timestamp;
            });

            mEntries.insert(insertPos, entry);
            rebuildFilter();
            endResetModel();
            emit countChanged();
            return;
        }

        const int existing = indexById(entry.id);
        if (existing >= 0) {
            const auto insertPos = std::ranges::find_if(mEntries, [&](const ClipboardEntry& e) {
                if (e.id == entry.id)
                    return false;
                if (entry.pinned && !e.pinned)
                    return true;
                if (!entry.pinned && e.pinned)
                    return false;
                return entry.timestamp >= e.timestamp;
            });

            const int  dest      = static_cast<int>(std::distance(mEntries.begin(), insertPos));
            const int  insertIdx = dest > existing ? dest - 1 : dest;

            if (existing != insertIdx) {
                beginMoveRows({}, existing, existing, {}, dest);
                auto item = mEntries.takeAt(existing);

                item.timestamp = entry.timestamp;
                mEntries.insert(insertIdx, std::move(item));
                endMoveRows();
                emit dataChanged(index(insertIdx, 0), index(insertIdx, 0));
            } else {
                mEntries[existing].timestamp = entry.timestamp;
                emit dataChanged(index(existing, 0), index(existing, 0));
            }
            return;
        }

        const auto insertPos = std::ranges::find_if(mEntries, [&](const ClipboardEntry& e) {
            if (entry.pinned && !e.pinned)
                return true;
            if (!entry.pinned && e.pinned)
                return false;
            return entry.timestamp >= e.timestamp;
        });

        const int  rawRow = static_cast<int>(std::distance(mEntries.begin(), insertPos));

        beginInsertRows({}, rawRow, rawRow);
        mEntries.insert(insertPos, entry);
        endInsertRows();

        emit countChanged();
    }

    void ClipboardModel::removeById(qint64 id) {
        const int idx = indexById(id);
        if (idx < 0)
            return;

        if (mFiltering) {
            mEntries.removeAt(idx);
            rebuildFilter();
            emit countChanged();
        } else {
            beginRemoveRows({}, idx, idx);
            mEntries.removeAt(idx);
            endRemoveRows();
            emit countChanged();
        }
    }

    void ClipboardModel::removeByIds(const QVariantList& ids) {
        if (ids.isEmpty())
            return;

        QSet<qint64> toRemove;
        toRemove.reserve(ids.size());
        for (const QVariant& v : ids)
            toRemove.insert(v.toLongLong());

        if (mFiltering) {
            mEntries.removeIf([&](const ClipboardEntry& e) { return toRemove.contains(e.id); });
            rebuildFilter();
        } else {
            mEntries.removeIf([&](const ClipboardEntry& e) { return toRemove.contains(e.id); });
            beginResetModel();
            endResetModel();
        }
        emit countChanged();
    }

    void ClipboardModel::setPinById(qint64 id, bool pinned) {
        const int idx = indexById(id);
        if (idx < 0)
            return;

        mEntries[idx].pinned = pinned;

        std::ranges::stable_sort(mEntries, [](const ClipboardEntry& a, const ClipboardEntry& b) {
            if (a.pinned != b.pinned)
                return a.pinned > b.pinned;
            return a.timestamp > b.timestamp;
        });

        if (mFiltering)
            rebuildFilter();
        else {
            beginResetModel();
            endResetModel();
        }
        emit countChanged();
    }

    void ClipboardModel::setFilter(const QString& query) {
        beginResetModel();
        mFilterQuery = query;
        mFiltering   = !query.isEmpty();
        rebuildFilter();

        endResetModel();
        emit countChanged();
    }

    void ClipboardModel::bumpToTop(qint64 id) {
        const int existing = indexById(id);
        if (existing < 0)
            return;

        mEntries[existing].timestamp = QDateTime::currentMSecsSinceEpoch();

        if (mFiltering) {
            beginResetModel();
            auto       item      = mEntries.takeAt(existing);
            const auto insertPos = std::ranges::find_if(mEntries, [&](const ClipboardEntry& e) {
                if (item.pinned && !e.pinned)
                    return true;
                if (!item.pinned && e.pinned)
                    return false;
                return item.timestamp >= e.timestamp;
            });
            mEntries.insert(insertPos, std::move(item));
            rebuildFilter();
            endResetModel();
            emit countChanged();
            return;
        }

        const auto insertPos = std::ranges::find_if(mEntries, [&](const ClipboardEntry& e) {
            if (e.id == id)
                return false;
            const auto& item = mEntries[existing];
            if (item.pinned && !e.pinned)
                return true;
            if (!item.pinned && e.pinned)
                return false;
            return item.timestamp >= e.timestamp;
        });

        const int  dest = static_cast<int>(std::distance(mEntries.begin(), insertPos));
        if (existing != dest) {
            int const qtDest = (dest > existing) ? dest + 1 : dest;
            beginMoveRows({}, existing, existing, {}, qtDest);
            auto item = mEntries.takeAt(existing);
            mEntries.insert(dest, std::move(item));
            endMoveRows();
            emit dataChanged(index(std::min(existing, dest), 0), index(std::max(existing, dest), 0));
        } else {
            emit dataChanged(index(existing, 0), index(existing, 0));
        }
    }

    const QList<ClipboardEntry>& ClipboardModel::allEntries() const noexcept {
        return mEntries;
    }

    void ClipboardModel::rebuildFilter() {
        mFiltered.clear();

        if (!mFiltering)
            return;

        static const QRegularExpression kWhiteSpace(R"(\s+)");

        const QString                   normQuery  = FuzzyMatcher::normalizeText(mFilterQuery).trimmed();
        const QStringList               queryWords = normQuery.split(kWhiteSpace, Qt::SkipEmptyParts);

        qsizetype                       queryChars = 0;
        for (const QString& word : queryWords)
            queryChars += word.length();

        if (queryChars == 0) {
            mFiltered.reserve(static_cast<size_t>(mEntries.size()));
            for (int i = 0; i < mEntries.size(); ++i)
                mFiltered.push_back(i);
            return;
        }

        const double threshold = K_CLIPBOARD_THRESHOLD_PER_CHAR * static_cast<double>(queryChars);

        auto         scoreField = [&](const QString& raw) { return FuzzyMatcher::multiWordScore(queryWords, FuzzyMatcher::normalizeText(raw)); };

        struct Hit {
            int    index;
            double score;
            bool   pinned;
        };
        QList<Hit> hits;
        hits.reserve(mEntries.size());

        for (int i = 0; i < mEntries.size(); ++i) {
            const auto& e = mEntries[i];

            // Long pastes: only the leading KMatchMaxLen chars are searchable
            // (fzy cannot align beyond that anyway).
            double best = scoreField(e.content.left(fzy::K_MATCH_MAX_LEN));
            best        = std::max(best, scoreField(e.sourceApp));
            best        = std::max(best, scoreField(e.fileName));
            best        = std::max(best, scoreField(e.mimeType));

            if (best >= threshold)
                hits.append({.index = i, .score = best, .pinned = e.pinned});
        }

        std::ranges::stable_sort(hits, [](const Hit& a, const Hit& b) {
            if (a.pinned != b.pinned)
                return b.pinned;
            return a.score > b.score;
        });

        mFiltered.reserve(static_cast<size_t>(hits.size()));
        for (const Hit& h : hits)
            mFiltered.push_back(h.index);
    }

    qint64 ClipboardModel::idAtRow(int row) const {
        if (row < 0 || row >= visibleCount())
            return -1;
        return visibleAt(row).id;
    }

    QVariantList ClipboardModel::entries() const {
        QVariantList out;
        out.reserve(mEntries.size());
        for (const auto& e : mEntries) {
            QVariantMap map;
            map[QStringLiteral("entryId")]   = e.id;
            map[QStringLiteral("type")]      = e.typeString();
            map[QStringLiteral("preview")]   = makePreview(e);
            map[QStringLiteral("timestamp")] = e.timestamp;
            map[QStringLiteral("pinned")]    = e.pinned;
            map[QStringLiteral("sourceApp")] = e.sourceApp;
            map[QStringLiteral("mimeType")]  = e.mimeType;
            map[QStringLiteral("sizeBytes")] = e.sizeBytes;
            map[QStringLiteral("fileName")]  = QFileInfo(e.fileName).fileName();
            out.append(map);
        }
        return out;
    }

    QString ClipboardModel::typeAtRow(int row) const {
        if (row < 0 || row >= visibleCount())
            return {};
        return visibleAt(row).typeString();
    }

    const ClipboardEntry& ClipboardModel::visibleAt(int row) const {
        return mFiltering ? mEntries[mFiltered[static_cast<size_t>(row)]] : mEntries[row];
    }

    int ClipboardModel::visibleCount() const {
        return mFiltering ? static_cast<int>(mFiltered.size()) : static_cast<int>(mEntries.size());
    }

    int ClipboardModel::indexById(qint64 id) const {
        const auto it = std::ranges::find_if(mEntries, [id](const ClipboardEntry& e) { return e.id == id; });
        if (it == mEntries.end())
            return -1;
        return static_cast<int>(std::distance(mEntries.begin(), it));
    }

    QString ClipboardModel::makePreview(const ClipboardEntry& e) {
        if (e.isImage())
            return {};

        constexpr int kMaxChars = 120;
        const QString collapsed = e.content.simplified();
        return collapsed.length() > kMaxChars ? collapsed.left(kMaxChars) + QStringLiteral("…") : collapsed;
    }
}
