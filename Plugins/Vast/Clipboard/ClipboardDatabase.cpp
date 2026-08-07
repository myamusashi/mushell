#include "ClipboardDatabase.hpp"
#include "ClipboardEntry.hpp"

#include <expected>
#include <qcontainerfwd.h>
#include <qdatetime.h>
#include <qsqldatabase.h>
#include <qsqlrecord.h>
#include <qlist.h>
#include <qsqlerror.h>
#include <qsqlquery.h>
#include <qtypes.h>
#include <qtmetamacros.h>
#include <quuid.h>
#include <qvariant.h>

#include <array>
#include <vector>

namespace vast {

    ClipboardDatabase::ClipboardDatabase(QObject* parent) :
        QObject{parent}, mConnectionName{QStringLiteral("VastClipboard_") % QUuid::createUuid().toString(QUuid::WithoutBraces)} {}

    ClipboardDatabase::~ClipboardDatabase() {
        close();
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::open(const QString& dbPath) {
        if (mOpen)
            return std::unexpected(QStringLiteral("Database already open"));

        mDb.emplace(QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), mConnectionName));
        mDb->setDatabaseName(dbPath);
        mDb->setConnectOptions(QStringLiteral("QSQLITE_BUSY_TIMEOUT=100"));

        if (!mDb->open())
            return std::unexpected(lastError());

        QSqlQuery                            pragma{*mDb};
        constexpr std::array<const char*, 4> pragmas{{"PRAGMA journal_mode=WAL", "PRAGMA foreign_keys=ON", "PRAGMA synchronous=NORMAL", "PRAGMA threads=0"}};

        for (const auto* sql : pragmas)
            pragma.exec(QString::fromUtf8(sql));

        if (auto result = createSchema(); !result)
            return std::unexpected(result.error());

        mOpen = true;
        return {};
    }

    void ClipboardDatabase::close() {
        if (!mOpen || !mDb)
            return;

        mDb->close();
        QSqlDatabase::removeDatabase(mConnectionName);
        mDb.reset();
        mOpen = false;
    }

    [[nodiscard]] bool ClipboardDatabase::isOpen() const noexcept {
        return mOpen && mDb && mDb->isOpen();
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::createSchema() {
        if (!mDb)
            return std::unexpected(QStringLiteral("Database not initialized"));

        QSqlQuery      q{*mDb};

        constexpr auto createTable = R"sql(
            CREATE TABLE IF NOT EXISTS clipboard_entries (
                id          INTEGER PRIMARY KEY AUTOINCREMENT,
                type        TEXT    NOT NULL,
                content     TEXT,
                data        BLOB,
                mime_type   TEXT    NOT NULL DEFAULT '',
                hash        TEXT    NOT NULL UNIQUE,
                pinned      INTEGER NOT NULL DEFAULT 0,
                source_app  TEXT             DEFAULT '',
                size_bytes  INTEGER NOT NULL DEFAULT 0,
                timestamp   INTEGER NOT NULL,
                filename    TEXT             DEFAULT ''
            )
        )sql";

        if (!q.exec(QString::fromUtf8(createTable)))
            return std::unexpected(lastError());

        {
            QSqlQuery columnQ{*mDb};
            if (!columnQ.exec(QStringLiteral("PRAGMA table_info(clipboard_entries)")))
                return std::unexpected(lastError());

            bool hasFilename = false;
            while (columnQ.next()) {
                if (columnQ.value(1).toString() == QLatin1StringView{"filename"}) {
                    hasFilename = true;
                    break;
                }
            }

            if (!hasFilename) {
                QSqlQuery migrateQ{*mDb};
                if (!migrateQ.exec(QStringLiteral("ALTER TABLE clipboard_entries ADD COLUMN filename TEXT DEFAULT ''")))
                    return std::unexpected(lastError());
            }
        }

        constexpr std::array<const char*, 2> indices{
            {"CREATE INDEX IF NOT EXISTS idx_ts ON clipboard_entries(timestamp DESC)", "CREATE INDEX IF NOT EXISTS idx_pinned ON clipboard_entries(pinned, timestamp DESC)"}};

        for (const auto* sql : indices)
            if (!q.exec(QString::fromUtf8(sql)))
                return std::unexpected(lastError());

        return {};
    }

    [[nodiscard]] std::expected<qint64, QString> ClipboardDatabase::insert(const ClipboardEntry& entry) {
        if (!mOpen || !mDb.has_value()) [[unlikely]]
            return std::unexpected(QStringLiteral("Database is not open"));

        const QSqlDatabase& db = *mDb;

        if (existsByHash(entry.hash))
            return std::unexpected(QStringLiteral("duplicate"));

        QSqlQuery q{db};
        q.prepare(QStringLiteral(R"sql(
            INSERT INTO clipboard_entries
                (type, content, data, mime_type, hash, pinned, source_app, size_bytes, timestamp, filename)
            VALUES
                (:type, :content, :data, :mime_type, :hash, :pinned, :source_app, :size_bytes, :timestamp, :filename)
        )sql"));

        q.bindValue(QStringLiteral(":type"), entry.typeString());
        q.bindValue(QStringLiteral(":content"), entry.content);
        // bind NULL, not empty QByteArray, to keep blob column semantically absent for text entries
        q.bindValue(QStringLiteral(":data"), entry.data.isEmpty() ? QVariant{QMetaType{QMetaType::QByteArray}} : QVariant{entry.data});
        q.bindValue(QStringLiteral(":mime_type"), entry.mimeType);
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(entry.hash.toHex()));
        q.bindValue(QStringLiteral(":pinned"), entry.pinned ? 1 : 0);
        q.bindValue(QStringLiteral(":source_app"), entry.sourceApp);
        q.bindValue(QStringLiteral(":size_bytes"), entry.sizeBytes);
        q.bindValue(QStringLiteral(":timestamp"), entry.timestamp > 0 ? entry.timestamp : QDateTime::currentMSecsSinceEpoch());
        q.bindValue(QStringLiteral(":filename"), entry.fileName);

        if (!q.exec())
            return std::unexpected(lastError());

        const qint64 newId = q.lastInsertId().toLongLong();

        auto         inserted = entry;
        inserted.id           = newId;
        inserted.data.clear();

        emit entryInserted(inserted);
        return newId;
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::remove(qint64 id) {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        q.prepare(QStringLiteral("DELETE FROM clipboard_entries WHERE id = :id"));
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        emit entryRemoved(id);
        return {};
    }

    [[nodiscard]] std::expected<qint64, QString> ClipboardDatabase::removeMany(const QList<qint64>& ids, bool skipPinned) {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        if (ids.isEmpty())
            return 0LL;

        const QSqlDatabase& db = *mDb;
        QSqlDatabase::database(mConnectionName, false).transaction();

        QStringList placeholders;
        placeholders.reserve(ids.size());
        for (int i = 0; i < ids.size(); ++i)
            placeholders.append(QStringLiteral(":id%1").arg(i));

        QString where = QStringLiteral("id IN (%1)").arg(placeholders.join(QStringLiteral(", ")));
        if (skipPinned)
            where += QStringLiteral(" AND pinned = 0");

        QSqlQuery q{db};
        q.prepare(QStringLiteral("DELETE FROM clipboard_entries WHERE %1").arg(where));
        for (int i = 0; i < ids.size(); ++i)
            q.bindValue(placeholders[i], ids[i]);

        qint64 removed = 0;
        if (q.exec()) {
            removed = q.numRowsAffected() > 0 ? q.numRowsAffected() : removed;
            for (qint64 const id : ids)
                emit entryRemoved(id);
        } else {
            QSqlDatabase::database(mConnectionName, false).rollback();
            return std::unexpected(lastError());
        }

        if (!QSqlDatabase::database(mConnectionName, false).commit())
            return std::unexpected(lastError());

        return removed;
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::setPin(qint64 id, bool pinned) {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        q.prepare(QStringLiteral("UPDATE clipboard_entries SET pinned = :pinned WHERE id = :id"));
        q.bindValue(QStringLiteral(":pinned"), pinned ? 1 : 0);
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        emit entryPinChanged(id, pinned);
        return {};
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::bumpTimestamp(qint64 id) {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        q.prepare(QStringLiteral("UPDATE clipboard_entries SET timestamp = :ts WHERE id = :id"));
        q.bindValue(QStringLiteral(":ts"), QDateTime::currentMSecsSinceEpoch());
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        return {};
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::clearUnpinned() {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        if (!q.exec(QStringLiteral("DELETE FROM clipboard_entries WHERE pinned = 0")))
            return std::unexpected(lastError());

        return {};
    }

    [[nodiscard]] std::expected<std::vector<qint64>, QString> ClipboardDatabase::pruneToLimit(int maxEntries, qint64 maxBytes) {
        if (!mOpen || !mDb.has_value()) [[unlikely]]
            return std::unexpected(QStringLiteral("Database is not open"));

        const QSqlDatabase& db = *mDb;
        std::vector<qint64> removedIds;

        if (maxEntries > 0) {
            QSqlQuery countQ{db};
            if (!countQ.exec(QStringLiteral("SELECT COUNT(*) FROM clipboard_entries WHERE pinned = 0")))
                return std::unexpected(lastError());

            if (countQ.next()) {
                const int excess = countQ.value(0).toInt() - maxEntries;
                if (excess > 0) {
                    QSqlQuery collectQ{db};
                    collectQ.prepare(QStringLiteral("SELECT id FROM clipboard_entries WHERE pinned = 0 ORDER BY timestamp ASC LIMIT :excess"));
                    collectQ.bindValue(QStringLiteral(":excess"), excess);

                    if (!collectQ.exec())
                        return std::unexpected(lastError());

                    while (collectQ.next())
                        removedIds.push_back(collectQ.value(0).toLongLong());

                    QSqlQuery pruneQ{db};
                    pruneQ.prepare(QStringLiteral(R"sql(
                        DELETE FROM clipboard_entries
                        WHERE id IN (
                            SELECT id FROM clipboard_entries
                            WHERE pinned = 0
                            ORDER BY timestamp ASC
                            LIMIT :excess
                        )
                    )sql"));
                    pruneQ.bindValue(QStringLiteral(":excess"), excess);
                    if (!pruneQ.exec())
                        return std::unexpected(lastError());
                }
            }
        }

        if (maxBytes > 0) {
            constexpr int maxIterations{100};

            for (int i = 0; i < maxIterations; ++i) {
                auto sizeResult = totalSizeBytes();
                if (!sizeResult || *sizeResult <= maxBytes)
                    break;

                QSqlQuery getQ{db};
                if (!getQ.exec(QStringLiteral("SELECT id FROM clipboard_entries WHERE pinned = 0 ORDER BY timestamp ASC LIMIT 1")))
                    return std::unexpected(lastError());

                if (!getQ.next())
                    break;

                const qint64 idToRemove = getQ.value(0).toLongLong();
                removedIds.push_back(idToRemove);

                QSqlQuery pruneQ{db};
                pruneQ.prepare(QStringLiteral("DELETE FROM clipboard_entries WHERE id = :id"));
                pruneQ.bindValue(QStringLiteral(":id"), idToRemove);

                if (!pruneQ.exec())
                    return std::unexpected(lastError());
            }
        }

        return removedIds;
    }

    [[nodiscard]] bool ClipboardDatabase::existsByHash(const QByteArray& hash) {
        if (!mOpen || !mDb) [[unlikely]]
            return false;

        QSqlQuery q{*mDb};
        q.prepare(QStringLiteral("SELECT 1 FROM clipboard_entries WHERE hash = :hash LIMIT 1"));
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(hash.toHex()));

        return q.exec() && q.next();
    }

    [[nodiscard]] std::expected<qint64, QString> ClipboardDatabase::fetchIdByHash(const QByteArray& hash) {
        if (!mOpen || !mDb) [[unlikely]]
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        q.prepare(QStringLiteral("SELECT id FROM clipboard_entries WHERE hash = :hash LIMIT 1"));
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(hash.toHex()));

        if (!q.exec())
            return std::unexpected(lastError());

        if (!q.next())
            return std::unexpected(QStringLiteral("No entry found for hash"));

        return q.value(0).toLongLong();
    }

    [[nodiscard]] std::expected<QList<ClipboardEntry>, QString> ClipboardDatabase::fetchAll() {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        if (!q.exec(QStringLiteral(R"sql(
				SELECT id, type, content, mime_type, hash, pinned, source_app, size_bytes, timestamp, filename
				FROM clipboard_entries
				ORDER BY pinned DESC, timestamp DESC
			)sql"))) {
            return std::unexpected(lastError());
        }

        QList<ClipboardEntry> entries;
        while (q.next())
            entries.append(rowToEntry(q, false));

        return entries;
    }

    [[nodiscard]] std::expected<ClipboardEntry, QString> ClipboardDatabase::fetchById(qint64 id) {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        q.prepare(QStringLiteral(R"sql(
            SELECT id, type, content, data, mime_type, hash, pinned, source_app, size_bytes, timestamp, filename
            FROM clipboard_entries
            WHERE id = :id
            LIMIT 1
        )sql"));
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        if (!q.next())
            return std::unexpected(QStringLiteral("No entry found with id %1").arg(id));

        return rowToEntry(q, true);
    }

    [[nodiscard]] std::expected<qint64, QString> ClipboardDatabase::totalSizeBytes() {
        if (!mOpen || !mDb)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*mDb};
        if (!q.exec(QStringLiteral("SELECT COALESCE(SUM(size_bytes), 0) FROM clipboard_entries")))
            return std::unexpected(lastError());

        if (!q.next())
            return 0LL;

        return q.value(0).toLongLong();
    }

    ClipboardEntry ClipboardDatabase::rowToEntry(const QSqlQuery& q, bool includeData) {
        ClipboardEntry   e;
        const QSqlRecord rec = q.record();

        const int        idIdx        = rec.indexOf("id");
        const int        typeIdx      = rec.indexOf("type");
        const int        contentIdx   = rec.indexOf("content");
        const int        dataIdx      = rec.indexOf("data");
        const int        mimeTypeIdx  = rec.indexOf("mime_type");
        const int        hashIdx      = rec.indexOf("hash");
        const int        pinnedIdx    = rec.indexOf("pinned");
        const int        sourceAppIdx = rec.indexOf("source_app");
        const int        sizeBytesIdx = rec.indexOf("size_bytes");
        const int        timestampIdx = rec.indexOf("timestamp");
        const int        fileNameIdx  = rec.indexOf("filename");

        e.id      = rec.value(idIdx).toLongLong();
        e.type    = ClipboardEntry::typeFromString(rec.value(typeIdx).toString());
        e.content = rec.value(contentIdx).toString();

        if (includeData && dataIdx != -1) {
            e.data = rec.value(dataIdx).toByteArray();
        }

        e.mimeType  = rec.value(mimeTypeIdx).toString();
        e.hash      = QByteArray::fromHex(rec.value(hashIdx).toByteArray());
        e.pinned    = rec.value(pinnedIdx).toBool();
        e.sourceApp = rec.value(sourceAppIdx).toString();
        e.sizeBytes = rec.value(sizeBytesIdx).toLongLong();
        e.timestamp = rec.value(timestampIdx).toLongLong();
        e.fileName  = rec.value(fileNameIdx).toString();

        return e;
    }

    [[nodiscard]] QString ClipboardDatabase::lastError() const {
        return mDb ? mDb->lastError().text() : QStringLiteral("Database not initialized");
    }
}
