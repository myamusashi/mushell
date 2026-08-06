#include "ClipboardManager.hpp"
#include "ClipboardDatabase.hpp"
#include "WaylandDataControl.hpp"
#include "../Search/FuzzyMatcher.hpp"

#include <ClipboardModel.hpp>
#include <memory>
#include <ClipboardEntry.hpp>
#include <qcontainerfwd.h>
#include <cstddef>
#include <qobject.h>
#include <qlogging.h>
#include <qnamespace.h>
#include <qlist.h>
#include <qstringview.h>
#include <qthreadpool.h>
#include <qtimer.h>
#include <qimage.h>
#include <qdir.h>
#include <qdatetime.h>
#include <qcryptographichash.h>
#include <qfileinfo.h>

#include <algorithm>
#include <functional>
#include <qtypes.h>
#include <qtmetamacros.h>
#include <utility>
#include <vector>

namespace vast {

    ClipboardManager::ClipboardManager(QObject* parent) :
        QObject{parent}, mModel{new ClipboardModel{this}}, mWayland{std::make_unique<WaylandDataControl>(this)}, mDatabase{std::make_unique<ClipboardDatabase>(this)},
        mSearchDebounce{new QTimer{this}} {
        qRegisterMetaType<ClipboardEntry>();

        mSearchDebounce->setSingleShot(true);
        mSearchDebounce->setInterval(150);
        connect(mSearchDebounce, &QTimer::timeout, this, [this]() { performSearch(mPendingQuery); });
    }

    ClipboardManager::~ClipboardManager() = default;

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

        if (!mWayland->initialize())
            qWarning() << "[ClipboardManager] Wayland data control failed to initialize";

        return true;
    }

    void ClipboardManager::setupConnections() {
        connect(mWayland.get(), &WaylandDataControl::selectionReceived, this, &ClipboardManager::onSelectionReceived, Qt::QueuedConnection);

        connect(mWayland.get(), &WaylandDataControl::deviceFinished, this, []() { qWarning() << "[ClipboardManager] Wayland data control device finished"; }, Qt::DirectConnection);

        connect(
            mDatabase.get(), &ClipboardDatabase::entryInserted, this,
            [this](const ClipboardEntry& entry) {
                if (!mModel) [[unlikely]]
                    return;

                mModel->prepend(entry);
                pruneIfNeeded();

                if (entry.isImage() && !entry.data.isEmpty())
                    writePreviewFile(entry.id, entry.data);
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

            const QString path = QStringLiteral("/tmp/vast-shell/clipboard-preview/%1.png").arg(entry.id);
            if (QFile::exists(path))
                continue;

            QTimer::singleShot(0, this, [this, id = entry.id]() {
                if (!mDatabase)
                    return;
                auto r = mDatabase->fetchById(id);
                if (!r || !r->isImage() || r->data.isEmpty())
                    return;

                QByteArray data = r->data;
                QThreadPool::globalInstance()->start([id, data = std::move(data)]() {
                    QThread::currentThread()->setPriority(QThread::LowPriority);
                    writePreviewFileBackground(id, data);
                });
            });
        }
    }

    void ClipboardManager::writePreviewFile(qint64 id, const QByteArray& pngData) {
        QThreadPool::globalInstance()->start([id, pngData]() {
            QThread::currentThread()->setPriority(QThread::LowPriority);
            writePreviewFileBackground(id, pngData);
        });
    }

    void ClipboardManager::writePreviewFileBackground(qint64 id, const QByteArray& pngData) {
        const QString dir  = QStringLiteral("/tmp/vast-shell/clipboard-preview");
        const QString path = QStringLiteral("%1/%2.png").arg(dir).arg(id);

        QDir{}.mkpath(dir);

        QImage img;
        if (!img.loadFromData(pngData, "PNG"))
            return;

        constexpr int kThumbMaxDim = 400;
        const QImage  thumb =
            (img.width() > kThumbMaxDim || img.height() > kThumbMaxDim) ? img.scaled(kThumbMaxDim, kThumbMaxDim, Qt::KeepAspectRatio, Qt::SmoothTransformation) : img;

        thumb.save(path, "PNG");
    }

    void ClipboardManager::removePreviewFile(qint64 id) {
        QFile::remove(QStringLiteral("/tmp/vast-shell/clipboard-preview/%1.png").arg(id));
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

        mWayland->setClipboardContent(mimeType, content, entry.fileName);

        mLastSelfSetContent   = content;
        mLastSelfSetTimestamp = QDateTime::currentMSecsSinceEpoch();

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

        removePreviewFile(id);

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

    void ClipboardManager::requestFullEntry(qint64 id) {
        mPendingEntryId = id;
        if (id < 0 || !mDatabase)
            return;

        QTimer::singleShot(0, this, [this, id]() {
            auto result = mDatabase->fetchById(id);
            if (!result) {
                qWarning() << "[ClipboardManager] fetchById failed:" << result.error();
                return;
            }

            if (id != mPendingEntryId)
                return;

            auto        entry = std::move(*result);
            QVariantMap map;
            map[QStringLiteral("id")]        = entry.id;
            map[QStringLiteral("type")]      = entry.typeString();
            map[QStringLiteral("content")]   = entry.content;
            map[QStringLiteral("mimeType")]  = entry.mimeType;
            map[QStringLiteral("pinned")]    = entry.pinned;
            map[QStringLiteral("sourceApp")] = entry.sourceApp;
            map[QStringLiteral("sizeBytes")] = entry.sizeBytes;
            map[QStringLiteral("timestamp")] = entry.timestamp;
            map[QStringLiteral("fileName")]  = entry.fileName.isEmpty() ? QString{} : QFileInfo(entry.fileName).fileName();

            if (entry.isImage()) {
                const QString path = QStringLiteral("/tmp/vast-shell/clipboard-preview/%1.png").arg(entry.id);
                if (!QFile::exists(path)) {
                    if (!entry.data.isEmpty())
                        writePreviewFileBackground(entry.id, entry.data);
                    if (QFile::exists(path))
                        map[QStringLiteral("previewPath")] = path;
                } else {
                    map[QStringLiteral("previewPath")] = path;
                }
            }

            emit fullEntryReady(std::move(map));
        });
    }

    void ClipboardManager::search(const QString& query) {
        if (!mModel)
            return;

        if (query.isEmpty()) {
            if (mSearchDebounce)
                mSearchDebounce->stop();
            mModel->setFilter({}, {});
            return;
        }

        mPendingQuery = query;
        if (mSearchDebounce)
            mSearchDebounce->start();
    }

    void ClipboardManager::performSearch(const QString& query) {
        if (!mModel || query.isEmpty())
            return;

        const auto&                            entries = mModel->allEntries();
        std::vector<std::pair<double, qint64>> scored;
        scored.reserve(static_cast<size_t>(entries.size()));

        for (const auto& entry : entries) {
            QString haystack = entry.content.left(200) + u' ' + entry.sourceApp;
            if (entry.isImage())
                haystack = entry.fileName + u' ' + entry.sourceApp;

            const double score = FuzzyMatcher::fuzzyScore(query, haystack.trimmed());
            if (score > 0.0)
                scored.emplace_back(score, entry.id);
        }

        std::ranges::sort(scored, std::ranges::greater{}, [](const auto& pair) { return pair.first; });

        QList<qint64> orderedIds;
        orderedIds.reserve(static_cast<qsizetype>(scored.size()));
        for (const auto& [score, id] : scored)
            orderedIds.append(id);

        mModel->setFilter(query, orderedIds);
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
            removePreviewFile(droppedId);
        }
    }

    void ClipboardManager::onSelectionReceived(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (mLastSelfSetContent.has_value()) {
            constexpr qint64 kLoopbackWindowMs = 60000;
            const bool       withinWindow      = QDateTime::currentMSecsSinceEpoch() - mLastSelfSetTimestamp < kLoopbackWindowMs;
            const bool       contentMatches    = *mLastSelfSetContent == content;
            if (withinWindow && contentMatches) {
                qWarning() << "[ClipboardManager] loopback suppressed: mime=" << mimeType << "size=" << content.size();
                mLastSelfSetContent.reset();
                return;
            }
            mLastSelfSetContent.reset();
        }

        persistToHistory(mimeType, content, fileName);
    }

    [[nodiscard]] ClipboardType ClipboardManager::mimeTypeToClipboardType(const QString& mimeType) {
        if (mimeType == QStringLiteral("image/png"))
            return ClipboardType::Image;
        if (mimeType == QStringLiteral("text/html"))
            return ClipboardType::Html;
        if (mimeType == QStringLiteral("text/uri-list"))
            return ClipboardType::Files;
        return ClipboardType::Text;
    }

    void ClipboardManager::persistToHistory(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (!mDatabase) [[unlikely]]
            return;

        if (content.isEmpty())
            return;

        const ClipboardType type = mimeTypeToClipboardType(mimeType);

        if (type == ClipboardType::Text || type == ClipboardType::Html) {
            const auto text                = QString::fromUtf8(content);
            const auto isEmptyOrWhitespace = [](QStringView sv) noexcept { return sv.isEmpty() || std::ranges::all_of(sv, [](QChar c) { return c.isSpace(); }); };
            if (isEmptyOrWhitespace(text))
                return;
        }

        ClipboardEntry entry;
        entry.type                 = type;
        entry.content              = entry.isImage() ? QString{} : QString::fromUtf8(content);
        entry.data                 = entry.isImage() ? content : QByteArray{};
        entry.mimeType             = mimeType;
        entry.pinned               = false;
        entry.sourceApp            = mActiveWindow;
        entry.sizeBytes            = content.size();
        entry.timestamp            = QDateTime::currentMSecsSinceEpoch();
        const QByteArray hashInput = entry.isImage() ? content : entry.content.toUtf8();
        entry.hash                 = QCryptographicHash::hash(hashInput, QCryptographicHash::Sha256);
        entry.fileName             = entry.isImage() ? fileName : QString{};

        if (auto result = mDatabase->insert(entry); !result) {
            if (result.error() == QStringLiteral("duplicate")) {
                // §10: consecutive duplicate copy — bump the existing row.
                auto idResult = mDatabase->fetchIdByHash(entry.hash);
                if (idResult && mModel)
                    mModel->bumpToTop(*idResult);
            } else {
                qWarning() << "[ClipboardManager] insert failed:" << result.error();
            }
        }
    }
}
