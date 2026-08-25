#include "ClipboardManager.hpp"
#include "ClipboardDatabase.hpp"
#include "ClipboardContentClassifier.hpp"
#include "ClipboardPreviewCache.hpp"
#include "WaylandDataControl.hpp"
#include "../Jobs/JobExecutor.hpp"

#include <ClipboardModel.hpp>
#include <memory>
#include <ClipboardEntry.hpp>
#include <qcontainerfwd.h>
#include <qobject.h>
#include <qlogging.h>
#include <qnamespace.h>
#include <qlist.h>
#include <qobjectdefs.h>
#include <qtimer.h>
#include <qdatetime.h>
#include <qfileinfo.h>
#include <qhash.h>

#include <algorithm>
#include <qtypes.h>
#include <qtmetamacros.h>
#include <utility>

namespace vast {

    ClipboardManager::ClipboardManager(QObject* parent) :
        QObject{parent}, mModel{new ClipboardModel{this}}, mWayland{std::make_unique<WaylandDataControl>()}, mDatabase{std::make_unique<ClipboardDatabase>(this)} {
        qRegisterMetaType<ClipboardEntry>();
    }

    ClipboardManager::~ClipboardManager() {
        if (!mWayland)
            return;

        // Hand the object back to its own thread: deleteLater queues
        // destruction onto the shared executor's event loop, where
        // ~WaylandDataControl -> shutdown() tears the Wayland state down on
        // the same thread its socket notifier and roundtrips lived on.
        auto* wayland = mWayland.release();
        if (wayland->thread()->isRunning())
            wayland->deleteLater();
        else
            delete wayland;
    }

    [[nodiscard]] bool ClipboardManager::initialize(const QString& dbPath) {
        if (!mDatabase) {
            qWarning() << "[ClipboardManager] Database not initialized";
            return false;
        }

        if (auto result = mDatabase->open(dbPath); !result) {
            qWarning() << "[ClipboardManager] Database open failed:" << result.error();
            return false;
        }

        setupConnections();
        loadAllEntries();

        // The data-control object lives on the shared executor thread: its
        // socket notifier, reconnect timers and blocking registry roundtrips
        // stay off the UI thread. The serialized queue guarantees this init
        // job runs before any setClipboardContent posted afterwards.
        auto* wayland = mWayland.get();
        wayland->moveToThread(vast::JobExecutor::instance().thread());
        vast::JobExecutor::instance().post([wayland]() {
            if (!wayland->initialize())
                qWarning() << "[ClipboardManager] Wayland data control failed to initialize";
        });

        return true;
    }

    void ClipboardManager::setupConnections() {
        connect(mWayland.get(), &WaylandDataControl::selectionReceived, this, &ClipboardManager::onSelectionReceived, Qt::QueuedConnection);

        connect(mWayland.get(), &WaylandDataControl::deviceFinished, this, []() { qWarning() << "[ClipboardManager] Wayland data control device finished"; }, Qt::QueuedConnection);

        connect(
            mDatabase.get(), &ClipboardDatabase::entryInserted, this,
            [this](const ClipboardEntry& entry) {
                if (!mModel) [[unlikely]]
                    return;

                mModel->prepend(entry);
                pruneIfNeeded();

                if (entry.isImage() && !entry.data.isEmpty())
                    vast::JobExecutor::instance().post([id = entry.id, data = entry.data]() { ClipboardPreviewCache::write(id, data); });
            },
            Qt::DirectConnection);

        connect(
            mDatabase.get(), &ClipboardDatabase::entryRemoved, this,
            [this](qint64 id) {
                if (mModel)
                    mModel->removeById(id);
            },
            Qt::DirectConnection);

        connect(
            mDatabase.get(), &ClipboardDatabase::entryPinChanged, this,
            [this](qint64 id, bool pinned) {
                if (mModel)
                    mModel->setPinById(id, pinned);
            },
            Qt::DirectConnection);
    }

    void ClipboardManager::loadAllEntries() {
        if (!mDatabase || !mModel)
            return;

        auto result = mDatabase->fetchAll();
        if (!result) {
            qWarning() << "[ClipboardManager] fetchAll failed:" << result.error();
            return;
        }

        mModel->reset(std::move(*result));

        for (const auto& entry : mModel->allEntries()) {
            if (!entry.isImage())
                continue;

            if (ClipboardPreviewCache::exists(entry.id))
                continue;

            QTimer::singleShot(0, this, [this, id = entry.id]() {
                if (!mDatabase)
                    return;
                auto r = mDatabase->fetchById(id);
                if (!r || !r->isImage() || r->data.isEmpty())
                    return;

                QByteArray data = r->data;
                vast::JobExecutor::instance().post([id, data = std::move(data)]() { ClipboardPreviewCache::write(id, data); });
            });
        }
    }

    ClipboardModel* ClipboardManager::model() const noexcept {
        return mModel.get();
    }

    int ClipboardManager::maxEntries() const noexcept {
        return mMaxEntries;
    }

    int ClipboardManager::maxMegabytes() const noexcept {
        return mMaxMegabytes;
    }

    bool ClipboardManager::isEnabled() const noexcept {
        return mEnabled;
    }

    QString ClipboardManager::activeWindow() const noexcept {
        return mActiveWindow;
    }

    void ClipboardManager::setMaxEntries(int max) {
        if (mMaxEntries == max)
            return;

        mMaxEntries = max;
        emit maxEntriesChanged();
        pruneIfNeeded();
    }

    void ClipboardManager::setMaxMegabytes(int mb) {
        if (mMaxMegabytes == mb)
            return;

        mMaxMegabytes = mb;
        emit maxMegabytesChanged();
        pruneIfNeeded();
    }

    void ClipboardManager::setEnabled(bool enabled) {
        if (mEnabled == enabled)
            return;

        mEnabled = enabled;
        emit enabledChanged();
    }

    void ClipboardManager::setActiveWindow(const QString& window) {
        if (mActiveWindow == window)
            return;
        mActiveWindow = window;
        emit activeWindowChanged();
    }

    [[nodiscard]] bool ClipboardManager::copyToClipboard(qint64 id) {
        if (!mDatabase)
            return false;

        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        if (id == mLastCopyId && now - mLastCopyTimestamp < 500) {
            return true;
        }
        mLastCopyId        = id;
        mLastCopyTimestamp = now;

        auto result = mDatabase->fetchById(id);
        if (!result) {
            qWarning() << "[ClipboardManager] fetchById failed:" << result.error();
            return false;
        }

        ClipboardEntry const entry = std::move(*result);
        if (entry.id < 0)
            return false;

        QString    mimeType;
        QByteArray content;

        switch (entry.type) {
            case ClipboardType::Text:
                mimeType = QStringLiteral("text/plain;charset=utf-8");
                content  = entry.content.toUtf8();
                break;
            case ClipboardType::Html:
                mimeType = QStringLiteral("text/html");
                content  = entry.content.toUtf8();
                break;
            case ClipboardType::Image:
                mimeType = QStringLiteral("image/png");
                content  = entry.data;
                break;
            case ClipboardType::Files:
                mimeType = QStringLiteral("text/uri-list");
                content  = entry.content.toUtf8();
                break;
        }

        if (!mWayland) {
            qWarning() << "[ClipboardManager] wayland data control unavailable";
            return false;
        }

        if (!queueClipboardContent(mimeType, content, entry.fileName))
            return false;

        mLoopbackGuard.arm(content);

        const bool alreadyTop = mModel && mModel->idAtRow(0) == id;

        if (!alreadyTop && mModel)
            mModel->bumpToTop(id);

        QTimer::singleShot(0, this, [this, id, alreadyTop]() {
            if (!alreadyTop && mDatabase)
                if (auto r = mDatabase->bumpTimestamp(id); !r)
                    qWarning() << "[ClipboardManager] bumpTimestamp failed:" << r.error();
        });

        return true;
    }

    [[nodiscard]] bool ClipboardManager::copySelection(const QVariantList& ids) {
        if (!mModel || !mWayland || ids.isEmpty())
            return false;

        // Merge the selected text/html entries into a single plain-text paste,
        // skipping images and files.
        QStringList parts;
        parts.reserve(ids.size());

        const auto&                          entries = mModel->allEntries();
        QHash<qint64, const ClipboardEntry*> entryMap;
        entryMap.reserve(entries.size());
        for (const auto& entry : entries)
            entryMap.insert(entry.id, &entry);

        for (const QVariant& v : ids) {
            const qint64 id = v.toLongLong();
            const auto   it = entryMap.constFind(id);
            if (it == entryMap.cend())
                continue;

            const ClipboardEntry* entry = it.value();
            if (entry->type == ClipboardType::Text) {
                if (!entry->content.trimmed().isEmpty())
                    parts.append(entry->content.trimmed());
            } else if (entry->type == ClipboardType::Html) {
                const QString plain = QString::fromUtf8(WaylandDataControl::htmlToPlainText(entry->content.toUtf8()));
                if (!plain.isEmpty())
                    parts.append(plain);
            }
        }

        if (parts.isEmpty())
            return false;

        const QByteArray merged = parts.join(u'\n').toUtf8();

        if (!queueClipboardContent(QStringLiteral("text/plain;charset=utf-8"), merged, {}))
            return false;

        mLoopbackGuard.arm(merged);

        return true;
    }

    [[nodiscard]] bool ClipboardManager::queueClipboardContent(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (!mWayland)
            return false;

        return QMetaObject::invokeMethod(
            mWayland.get(), [wayland = mWayland.get(), mimeType, content, fileName]() { wayland->setClipboardContent(mimeType, content, fileName); }, Qt::QueuedConnection);
    }

    [[nodiscard]] int ClipboardManager::removeMany(const QVariantList& ids) {
        if (!mModel || !mDatabase || ids.isEmpty())
            return 0;

        QList<qint64> toRemove;
        toRemove.reserve(ids.size());
        for (const QVariant& v : ids)
            toRemove.append(v.toLongLong());

        // Skip pinned entries, mirroring the single-item delete behaviour.
        QList<qint64> unpinned;
        unpinned.reserve(toRemove.size());
        for (qint64 const id : toRemove) {
            const auto& entries = mModel->allEntries();
            const auto  it      = std::ranges::find_if(entries, [id](const ClipboardEntry& e) { return e.id == id; });
            if (it == entries.end() || !it->pinned)
                unpinned.append(id);
        }

        const int count = static_cast<int>(unpinned.size());
        if (count == 0)
            return 0;

        mModel->removeByIds(QVariantList(unpinned.begin(), unpinned.end()));

        for (qint64 const id : unpinned)
            ClipboardPreviewCache::remove(id);

        QTimer::singleShot(0, this, [this, unpinned = std::move(unpinned)]() {
            if (!mDatabase)
                return;
            if (auto r = mDatabase->removeMany(unpinned); !r)
                qWarning() << "[ClipboardManager] removeMany failed:" << r.error();
        });

        return count;
    }

    void ClipboardManager::pin(qint64 id, bool pinned) {
        if (mModel)
            mModel->setPinById(id, pinned);

        QTimer::singleShot(0, this, [this, id, pinned]() {
            if (mDatabase)
                if (auto r = mDatabase->setPin(id, pinned); !r)
                    qWarning() << "[ClipboardManager] setPin failed:" << r.error();
        });
    }

    void ClipboardManager::remove(qint64 id) {
        if (mModel)
            mModel->removeById(id);

        ClipboardPreviewCache::remove(id);

        QTimer::singleShot(0, this, [this, id]() {
            if (mDatabase)
                if (auto r = mDatabase->remove(id); !r)
                    qWarning() << "[ClipboardManager] remove failed:" << r.error();
        });
    }

    [[nodiscard]] bool ClipboardManager::clearUnpinned() {
        if (!mDatabase)
            return false;

        if (auto r = mDatabase->clearUnpinned(); !r) {
            qWarning() << "[ClipboardManager] clearUnpinned failed:" << r.error();
            return false;
        }

        QTimer::singleShot(0, this, &ClipboardManager::loadAllEntries);
        return true;
    }

    [[nodiscard]] bool ClipboardManager::clearAll() {
        if (!mDatabase)
            return false;

        if (auto r = mDatabase->clearAll(); !r) {
            qWarning() << "[ClipboardManager] clearAll failed:" << r.error();
            return false;
        }

        QTimer::singleShot(0, this, &ClipboardManager::loadAllEntries);
        return true;
    }

    void ClipboardManager::requestFullEntry(qint64 id) {
        mPendingEntryId = id;
        if (id < 0 || !mDatabase)
            return;

        QTimer::singleShot(0, this, [this, id]() {
            if (!mDatabase)
                return;
            auto result = mDatabase->fetchById(id);
            if (!result) {
                qWarning() << "[ClipboardManager] fetchById failed:" << result.error();
                return;
            }

            if (id != mPendingEntryId)
                return;

            if (result->isImage() && !ClipboardPreviewCache::exists(result->id) && !result->data.isEmpty()) {
                // The heavy PNG encode + disk write run on the shared worker.
                // fullEntryReady still fires exactly once, only after the
                // preview path exists -- same contract as the old synchronous
                // write, minus the UI-thread stall.
                auto entry = std::move(*result);
                vast::JobExecutor::instance().post([this, entry = std::move(entry)]() mutable {
                    ClipboardPreviewCache::write(entry.id, entry.data);

                    QMetaObject::invokeMethod(
                        this,
                        [this, entry = std::move(entry)]() mutable {
                            if (!mDatabase || entry.id != mPendingEntryId)
                                return;
                            QVariantMap map;
                            appendFullEntry(map, std::move(entry));
                            emit fullEntryReady(std::move(map));
                        },
                        Qt::QueuedConnection);
                });
                return;
            }

            QVariantMap map;
            appendFullEntry(map, std::move(*result));
            emit fullEntryReady(std::move(map));
        });
    }

    void ClipboardManager::appendFullEntry(QVariantMap& map, ClipboardEntry&& entry) {
        map.insert(QStringLiteral("id"), entry.id);
        map.insert(QStringLiteral("type"), entry.typeString());
        map.insert(QStringLiteral("content"), QVariant::fromValue(std::move(entry.content)));
        map.insert(QStringLiteral("mimeType"), QVariant::fromValue(std::move(entry.mimeType)));
        map.insert(QStringLiteral("pinned"), entry.pinned);
        map.insert(QStringLiteral("sourceApp"), QVariant::fromValue(std::move(entry.sourceApp)));
        map.insert(QStringLiteral("sizeBytes"), entry.sizeBytes);
        map.insert(QStringLiteral("timestamp"), entry.timestamp);
        map.insert(QStringLiteral("fileName"), entry.fileName.isEmpty() ? QString{} : QFileInfo(entry.fileName).fileName());

        if (entry.isImage() && (ClipboardPreviewCache::exists(entry.id) || !entry.data.isEmpty()))
            map.insert(QStringLiteral("previewPath"), ClipboardPreviewCache::path(entry.id));
    }

    void ClipboardManager::pruneIfNeeded() {
        const qint64 maxBytes   = static_cast<qint64>(mMaxMegabytes) * 1024 * 1024;
        const int    maxEntries = mMaxEntries;

        if (!mDatabase) [[unlikely]]
            return;

        auto prunedIds = mDatabase->pruneToLimit(maxEntries, maxBytes);
        if (!prunedIds) {
            qWarning() << "[ClipboardManager] pruneToLimit failed:" << prunedIds.error();
            return;
        }

        for (qint64 const droppedId : *prunedIds) {
            if (mModel)
                mModel->removeById(droppedId);
            ClipboardPreviewCache::remove(droppedId);
        }
    }

    void ClipboardManager::onSelectionReceived(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (mLoopbackGuard.shouldSuppress(content)) {
            qWarning() << "[ClipboardManager] loopback suppressed: mime=" << mimeType << "size=" << content.size();
            return;
        }

        persistToHistory(mimeType, content, fileName);
    }

    void ClipboardManager::persistToHistory(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (!mDatabase) [[unlikely]]
            return;

        if (content.isEmpty())
            return;

        const ClipboardType type = ClipboardContentClassifier::typeFromMime(mimeType);
        if (ClipboardContentClassifier::isBlankTextOrHtml(type, content))
            return;

        const ClipboardEntry entry = ClipboardContentClassifier::buildEntry(mimeType, content, fileName, mActiveWindow);

        if (auto result = mDatabase->insert(entry); !result) {
            if (result.error() == QStringLiteral("duplicate")) {
                auto idResult = mDatabase->fetchIdByHash(entry.hash);
                if (idResult && mModel)
                    mModel->bumpToTop(*idResult);
            } else {
                qWarning() << "[ClipboardManager] insert failed:" << result.error();
            }
        }
    }
}
