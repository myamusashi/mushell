#include "ClipboardManager.hpp"
#include "ClipboardDatabase.hpp"
#include "WaylandDataControl.hpp"
#include "../Search/FuzzyMatcher.hpp"

#include <qguiapplication.h>
#include <qthreadpool.h>
#include <qtimer.h>
#include <qimage.h>
#include <qdir.h>
#include <qdatetime.h>
#include <qcryptographichash.h>
#include <qfileinfo.h>

#include <algorithm>
#include <functional>

namespace Vast {

    ClipboardManager::ClipboardManager(QObject* parent) :
        QObject{parent}, m_model{new ClipboardModel{this}}, m_wayland{std::make_unique<WaylandDataControl>(this)}, m_database{std::make_unique<ClipboardDatabase>(this)},
        m_searchDebounce{new QTimer{this}} {
        qRegisterMetaType<ClipboardEntry>();

        m_searchDebounce->setSingleShot(true);
        m_searchDebounce->setInterval(150);
        connect(m_searchDebounce, &QTimer::timeout, this, [this]() { performSearch(m_pendingQuery); });
    }

    ClipboardManager::~ClipboardManager() = default;

    [[nodiscard]] bool ClipboardManager::initialize(const QString& dbPath) {
        if (!m_database) {
            qWarning() << "[ClipboardManager] Database not initialized";
            return false;
        }

        if (auto result = m_database->open(dbPath); !result) {
            qWarning() << "[ClipboardManager] Database open failed:" << result.error();
            return false;
        }

        setupConnections();
        loadAllEntries();

        if (!m_wayland->initialize())
            qWarning() << "[ClipboardManager] Wayland data control failed to initialize";

        return true;
    }

    void ClipboardManager::setupConnections() {
        connect(m_wayland.get(), &WaylandDataControl::selectionReceived, this, &ClipboardManager::onSelectionReceived, Qt::QueuedConnection);

        connect(
            m_wayland.get(), &WaylandDataControl::deviceFinished, this, []() { qWarning() << "[ClipboardManager] Wayland data control device finished"; }, Qt::DirectConnection);

        connect(
            m_database.get(), &ClipboardDatabase::entryInserted, this,
            [this](const ClipboardEntry& entry) {
                if (!m_model) [[unlikely]]
                    return;

                m_model->prepend(entry);
                pruneIfNeeded();

                if (entry.isImage() && !entry.data.isEmpty())
                    writePreviewFile(entry.id, entry.data);
            },
            Qt::DirectConnection);

        connect(
            m_database.get(), &ClipboardDatabase::entryRemoved, this,
            [this](qint64 id) {
                if (m_model)
                    m_model->removeById(id);
            },
            Qt::DirectConnection);

        connect(
            m_database.get(), &ClipboardDatabase::entryPinChanged, this,
            [this](qint64 id, bool pinned) {
                if (m_model)
                    m_model->setPinById(id, pinned);
            },
            Qt::DirectConnection);
    }

    void ClipboardManager::loadAllEntries() {
        if (!m_database || !m_model)
            return;

        auto result = m_database->fetchAll();
        if (!result) {
            qWarning() << "[ClipboardManager] fetchAll failed:" << result.error();
            return;
        }

        m_model->reset(std::move(*result));

        for (const auto& entry : m_model->allEntries()) {
            if (!entry.isImage())
                continue;

            const QString path = QStringLiteral("/tmp/vast-shell/clipboard-preview/%1.png").arg(entry.id);
            if (QFile::exists(path))
                continue;

            QTimer::singleShot(0, this, [this, id = entry.id]() {
                if (!m_database)
                    return;
                auto r = m_database->fetchById(id);
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

    void ClipboardManager::writePreviewFileBackground(qint64 id, QByteArray pngData) {
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
        return m_model.get();
    }

    int ClipboardManager::maxEntries() const noexcept {
        return m_maxEntries;
    }

    int ClipboardManager::maxMegabytes() const noexcept {
        return m_maxMegabytes;
    }

    bool ClipboardManager::isEnabled() const noexcept {
        return m_enabled;
    }

    QString ClipboardManager::activeWindow() const noexcept {
        return m_activeWindow;
    }

    void ClipboardManager::setMaxEntries(int max) {
        if (m_maxEntries == max)
            return;

        m_maxEntries = max;
        emit maxEntriesChanged();
        pruneIfNeeded();
    }

    void ClipboardManager::setMaxMegabytes(int mb) {
        if (m_maxMegabytes == mb)
            return;

        m_maxMegabytes = mb;
        emit maxMegabytesChanged();
        pruneIfNeeded();
    }

    void ClipboardManager::setEnabled(bool enabled) {
        if (m_enabled == enabled)
            return;

        m_enabled = enabled;
        emit enabledChanged();
    }

    void ClipboardManager::setActiveWindow(const QString& window) {
        if (m_activeWindow == window)
            return;
        m_activeWindow = window;
        emit activeWindowChanged();
    }

    [[nodiscard]] bool ClipboardManager::copyToClipboard(qint64 id) {
        if (!m_database)
            return false;

        const qint64 now = QDateTime::currentMSecsSinceEpoch();
        if (id == m_lastCopyId && now - m_lastCopyTimestamp < 500) {
            return true;
        }
        m_lastCopyId        = id;
        m_lastCopyTimestamp = now;

        auto result = m_database->fetchById(id);
        if (!result) {
            qWarning() << "[ClipboardManager] fetchById failed:" << result.error();
            return false;
        }

        ClipboardEntry entry = std::move(*result);
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

        if (!m_wayland) {
            qWarning() << "[ClipboardManager] wayland data control unavailable";
            return false;
        }

        m_wayland->setClipboardContent(mimeType, content, entry.fileName);

        m_lastSelfSetContent   = content;
        m_lastSelfSetTimestamp = QDateTime::currentMSecsSinceEpoch();

        const bool alreadyTop = m_model && m_model->idAtRow(0) == id;

        if (!alreadyTop && m_model)
            m_model->bumpToTop(id);

        QTimer::singleShot(0, this, [this, id, alreadyTop]() {
            if (!alreadyTop && m_database)
                if (auto r = m_database->bumpTimestamp(id); !r)
                    qWarning() << "[ClipboardManager] bumpTimestamp failed:" << r.error();
        });

        return true;
    }

    void ClipboardManager::pin(qint64 id, bool pinned) {
        if (m_model)
            m_model->setPinById(id, pinned);

        QTimer::singleShot(0, this, [this, id, pinned]() {
            if (m_database)
                if (auto r = m_database->setPin(id, pinned); !r)
                    qWarning() << "[ClipboardManager] setPin failed:" << r.error();
        });
    }

    void ClipboardManager::remove(qint64 id) {
        if (m_model)
            m_model->removeById(id);

        removePreviewFile(id);

        QTimer::singleShot(0, this, [this, id]() {
            if (m_database)
                if (auto r = m_database->remove(id); !r)
                    qWarning() << "[ClipboardManager] remove failed:" << r.error();
        });
    }

    [[nodiscard]] bool ClipboardManager::clearUnpinned() {
        if (!m_database)
            return false;

        if (auto r = m_database->clearUnpinned(); !r) {
            qWarning() << "[ClipboardManager] clearUnpinned failed:" << r.error();
            return false;
        }

        QTimer::singleShot(0, this, &ClipboardManager::loadAllEntries);
        return true;
    }

    void ClipboardManager::requestFullEntry(qint64 id) {
        m_pendingEntryId = id;
        if (id < 0 || !m_database)
            return;

        QTimer::singleShot(0, this, [this, id]() {
            auto result = m_database->fetchById(id);
            if (!result) {
                qWarning() << "[ClipboardManager] fetchById failed:" << result.error();
                return;
            }

            if (id != m_pendingEntryId)
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
        if (!m_model)
            return;

        if (query.isEmpty()) {
            if (m_searchDebounce)
                m_searchDebounce->stop();
            m_model->setFilter({}, {});
            return;
        }

        m_pendingQuery = query;
        if (m_searchDebounce)
            m_searchDebounce->start();
    }

    void ClipboardManager::performSearch(const QString& query) {
        if (!m_model || query.isEmpty())
            return;

        const auto&                            entries = m_model->allEntries();
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

        m_model->setFilter(query, orderedIds);
    }

    void ClipboardManager::pruneIfNeeded() {
        const qint64 maxBytes   = static_cast<qint64>(m_maxMegabytes) * 1024 * 1024;
        const int    maxEntries = m_maxEntries;

        if (!m_database) [[unlikely]]
            return;

        auto prunedIds = m_database->pruneToLimit(maxEntries, maxBytes);
        if (!prunedIds) {
            qWarning() << "[ClipboardManager] pruneToLimit failed:" << prunedIds.error();
            return;
        }

        for (qint64 droppedId : *prunedIds) {
            if (m_model)
                m_model->removeById(droppedId);
            removePreviewFile(droppedId);
        }
    }

    void ClipboardManager::onSelectionReceived(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (m_lastSelfSetContent.has_value()) {
            constexpr qint64 kLoopbackWindowMs = 60000;
            const bool       withinWindow      = QDateTime::currentMSecsSinceEpoch() - m_lastSelfSetTimestamp < kLoopbackWindowMs;
            const bool       contentMatches    = *m_lastSelfSetContent == content;
            if (withinWindow && contentMatches) {
                qWarning() << "[ClipboardManager] loopback suppressed: mime=" << mimeType << "size=" << content.size();
                m_lastSelfSetContent.reset();
                return;
            }
            m_lastSelfSetContent.reset();
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
        if (!m_database) [[unlikely]]
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
        entry.sourceApp            = m_activeWindow;
        entry.sizeBytes            = content.size();
        entry.timestamp            = QDateTime::currentMSecsSinceEpoch();
        const QByteArray hashInput = entry.isImage() ? content : entry.content.toUtf8();
        entry.hash                 = QCryptographicHash::hash(hashInput, QCryptographicHash::Sha256);
        entry.fileName             = entry.isImage() ? fileName : QString{};

        if (auto result = m_database->insert(entry); !result) {
            if (result.error() == QStringLiteral("duplicate")) {
                // §10: consecutive duplicate copy — bump the existing row.
                auto idResult = m_database->fetchIdByHash(entry.hash);
                if (idResult && m_model)
                    m_model->bumpToTop(*idResult);
            } else {
                qWarning() << "[ClipboardManager] insert failed:" << result.error();
            }
        }
    }
}
