#include "ClipboardDatabase.hpp"
#include "ClipboardEntry.hpp"

#include <qdatetime.h>
#include <qsqlerror.h>
#include <qsqlquery.h>
#include <quuid.h>
#include <qvariant.h>

#include <array>

namespace Vast {

    ClipboardDatabase::ClipboardDatabase(QObject* parent) :
        QObject{parent}, m_connectionName{QStringLiteral("VastClipboard_") % QUuid::createUuid().toString(QUuid::WithoutBraces)} {}

    ClipboardDatabase::~ClipboardDatabase() {
        close();
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::open(const QString& dbPath) {
        if (m_open)
            return std::unexpected(QStringLiteral("Database already open"));

        m_db.emplace(QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"), m_connectionName));
        m_db->setDatabaseName(dbPath);
        m_db->setConnectOptions(QStringLiteral("QSQLITE_BUSY_TIMEOUT=100"));

        if (!m_db->open())
            return std::unexpected(lastError());

        QSqlQuery                            pragma{*m_db};
        constexpr std::array<const char*, 4> pragmas{{"PRAGMA journal_mode=WAL", "PRAGMA foreign_keys=ON", "PRAGMA synchronous=NORMAL", "PRAGMA threads=0"}};

        for (const auto* sql : pragmas)
            pragma.exec(QString::fromUtf8(sql));

        if (auto result = createSchema(); !result)
            return std::unexpected(result.error());

        m_open = true;
        return {};
    }

    void ClipboardDatabase::close() {
        if (!m_open || !m_db)
            return;

        m_db->close();
        QSqlDatabase::removeDatabase(m_connectionName);
        m_db.reset();
        m_open = false;
    }

    [[nodiscard]] bool ClipboardDatabase::isOpen() const noexcept {
        return m_open && m_db && m_db->isOpen();
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::createSchema() {
        if (!m_db)
            return std::unexpected(QStringLiteral("Database not initialized"));

        QSqlQuery      q{*m_db};

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
                timestamp   INTEGER NOT NULL
            )
        )sql";

        if (!q.exec(QString::fromUtf8(createTable)))
            return std::unexpected(lastError());

        constexpr std::array<const char*, 2> indices{
            {"CREATE INDEX IF NOT EXISTS idx_ts ON clipboard_entries(timestamp DESC)", "CREATE INDEX IF NOT EXISTS idx_pinned ON clipboard_entries(pinned, timestamp DESC)"}};

        for (const auto* sql : indices)
            if (!q.exec(QString::fromUtf8(sql)))
                return std::unexpected(lastError());

        return {};
    }

    [[nodiscard]] std::expected<qint64, QString> ClipboardDatabase::insert(const ClipboardEntry& entry) {
        if (!m_open || !m_db) [[unlikely]]
            return std::unexpected(QStringLiteral("Database is not open"));

        if (existsByHash(entry.hash))
            return std::unexpected(QStringLiteral("duplicate"));

        QSqlQuery q{*m_db};
        q.prepare(QStringLiteral(R"sql(
            INSERT INTO clipboard_entries
                (type, content, data, mime_type, hash, pinned, source_app, size_bytes, timestamp)
            VALUES
                (:type, :content, :data, :mime_type, :hash, :pinned, :source_app, :size_bytes, :timestamp)
        )sql"));

        q.bindValue(QStringLiteral(":type"), entry.typeString());
        q.bindValue(QStringLiteral(":content"), entry.content);
        q.bindValue(QStringLiteral(":data"), entry.data.isEmpty() ? QVariant{QMetaType{QMetaType::QByteArray}} : QVariant{entry.data});
        q.bindValue(QStringLiteral(":mime_type"), entry.mimeType);
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(entry.hash.toHex()));
        q.bindValue(QStringLiteral(":pinned"), entry.pinned ? 1 : 0);
        q.bindValue(QStringLiteral(":source_app"), entry.sourceApp);
        q.bindValue(QStringLiteral(":size_bytes"), entry.sizeBytes);
        q.bindValue(QStringLiteral(":timestamp"), entry.timestamp > 0 ? entry.timestamp : QDateTime::currentMSecsSinceEpoch());

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
        if (!m_open || !m_db)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        q.prepare(QStringLiteral("DELETE FROM clipboard_entries WHERE id = :id"));
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        emit entryRemoved(id);
        return {};
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::setPin(qint64 id, bool pinned) {
        if (!m_open || !m_db)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        q.prepare(QStringLiteral("UPDATE clipboard_entries SET pinned = :pinned WHERE id = :id"));
        q.bindValue(QStringLiteral(":pinned"), pinned ? 1 : 0);
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        emit entryPinChanged(id, pinned);
        return {};
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::bumpTimestamp(qint64 id) {
        if (!m_open || !m_db)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        q.prepare(QStringLiteral("UPDATE clipboard_entries SET timestamp = :ts WHERE id = :id"));
        q.bindValue(QStringLiteral(":ts"), QDateTime::currentMSecsSinceEpoch());
        q.bindValue(QStringLiteral(":id"), id);

        if (!q.exec())
            return std::unexpected(lastError());

        return {};
    }

    [[nodiscard]] std::expected<void, QString> ClipboardDatabase::clearUnpinned() {
        if (!m_open || !m_db)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        if (!q.exec(QStringLiteral("DELETE FROM clipboard_entries WHERE pinned = 0")))
            return std::unexpected(lastError());

        return {};
    }

    [[nodiscard]] std::expected<std::vector<qint64>, QString> ClipboardDatabase::pruneToLimit(int maxEntries, qint64 maxBytes) {
        if (!m_open || !m_db) [[unlikely]]
            return std::unexpected(QStringLiteral("Database is not open"));

        std::vector<qint64> removedIds;

        if (maxEntries > 0) {
            QSqlQuery countQ{*m_db};
            if (!countQ.exec(QStringLiteral("SELECT COUNT(*) FROM clipboard_entries WHERE pinned = 0")))
                return std::unexpected(lastError());

            if (countQ.next()) {
                const int excess = countQ.value(0).toInt() - maxEntries;
                if (excess > 0) {
                    QSqlQuery collectQ{*m_db};
                    collectQ.prepare(QStringLiteral("SELECT id FROM clipboard_entries WHERE pinned = 0 ORDER BY timestamp ASC LIMIT :excess"));
                    collectQ.bindValue(QStringLiteral(":excess"), excess);

                    if (!collectQ.exec())
                        return std::unexpected(lastError());

                    while (collectQ.next())
                        removedIds.push_back(collectQ.value(0).toLongLong());

                    QSqlQuery pruneQ{*m_db};
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

                QSqlQuery getQ{*m_db};
                if (!getQ.exec(QStringLiteral("SELECT id FROM clipboard_entries WHERE pinned = 0 ORDER BY timestamp ASC LIMIT 1")))
                    return std::unexpected(lastError());

                if (!getQ.next())
                    break;

                const qint64 idToRemove = getQ.value(0).toLongLong();
                removedIds.push_back(idToRemove);

                QSqlQuery pruneQ{*m_db};
                pruneQ.prepare(QStringLiteral("DELETE FROM clipboard_entries WHERE id = :id"));
                pruneQ.bindValue(QStringLiteral(":id"), idToRemove);

                if (!pruneQ.exec())
                    return std::unexpected(lastError());
            }
        }

        return removedIds;
    }

    [[nodiscard]] bool ClipboardDatabase::existsByHash(const QByteArray& hash) {
        if (!m_open || !m_db) [[unlikely]]
            return false;

        QSqlQuery q{*m_db};
        q.prepare(QStringLiteral("SELECT 1 FROM clipboard_entries WHERE hash = :hash LIMIT 1"));
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(hash.toHex()));

        return q.exec() && q.next();
    }

    [[nodiscard]] std::expected<qint64, QString> ClipboardDatabase::fetchIdByHash(const QByteArray& hash) {
        if (!m_open || !m_db) [[unlikely]]
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        q.prepare(QStringLiteral("SELECT id FROM clipboard_entries WHERE hash = :hash LIMIT 1"));
        q.bindValue(QStringLiteral(":hash"), QString::fromLatin1(hash.toHex()));

        if (!q.exec())
            return std::unexpected(lastError());

        if (!q.next())
            return std::unexpected(QStringLiteral("No entry found for hash"));

        return q.value(0).toLongLong();
    }

    [[nodiscard]] std::expected<QList<ClipboardEntry>, QString> ClipboardDatabase::fetchAll() {
        if (!m_open || !m_db)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        if (!q.exec(QStringLiteral(R"sql(
				SELECT id, type, content, mime_type, hash, pinned, source_app, size_bytes, timestamp
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
        if (!m_open || !m_db)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        q.prepare(QStringLiteral(R"sql(
            SELECT id, type, content, data, mime_type, hash, pinned, source_app, size_bytes, timestamp
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
        if (!m_open || !m_db)
            return std::unexpected(QStringLiteral("Database is not open"));

        QSqlQuery q{*m_db};
        if (!q.exec(QStringLiteral("SELECT COALESCE(SUM(size_bytes), 0) FROM clipboard_entries")))
            return std::unexpected(lastError());

        if (!q.next())
            return 0LL;

        return q.value(0).toLongLong();
    }

    ClipboardEntry ClipboardDatabase::rowToEntry(const QSqlQuery& q, bool includeData) {
        ClipboardEntry e;
        const int      off = includeData ? 1 : 0;

        e.id      = q.value(0).toLongLong();
        e.type    = ClipboardEntry::typeFromString(q.value(1).toString());
        e.content = q.value(2).toString();

        if (includeData)
            e.data = q.value(3).toByteArray();

        e.mimeType  = q.value(3 + off).toString();
        e.hash      = QByteArray::fromHex(q.value(4 + off).toString().toLatin1());
        e.pinned    = q.value(5 + off).toInt() != 0;
        e.sourceApp = q.value(6 + off).toString();
        e.sizeBytes = q.value(7 + off).toLongLong();
        e.timestamp = q.value(8 + off).toLongLong();

        return e;
    }

    [[nodiscard]] QString ClipboardDatabase::lastError() const {
        return m_db ? m_db->lastError().text() : QStringLiteral("Database not initialized");
    }
}
