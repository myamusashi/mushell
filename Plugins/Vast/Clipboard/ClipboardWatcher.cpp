#include "ClipboardWatcher.hpp"
#include "ClipboardEntry.hpp"
#include "ClipboardManager.hpp"

#include <qguiapplication.h>
#include <qbuffer.h>
#include <qclipboard.h>
#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qimage.h>
#include <qmimedata.h>
#include <qthread.h>
#include <qthreadpool.h>
#include <qurl.h>

#include <algorithm>

namespace Vast {

    ClipboardWatcher::ClipboardWatcher(QObject* parent) : QObject{parent} {}

    ClipboardWatcher::~ClipboardWatcher() = default;

    void ClipboardWatcher::start() {
        if (m_started)
            return;

        auto* cb = QGuiApplication::clipboard();
        connect(cb, &QClipboard::dataChanged, this, &ClipboardWatcher::onDataChanged);

        m_started = true;
        m_enabled = true;
    }

    void ClipboardWatcher::setEnabled(bool enabled) noexcept {
        m_enabled = enabled;
    }

    void ClipboardWatcher::setSelfCopyHash(const QByteArray& hash) noexcept {
        m_selfCopyHashes[hash] += 2;
    }

    [[nodiscard]] bool ClipboardWatcher::isEnabled() const noexcept {
        return m_enabled;
    }

    void ClipboardWatcher::onDataChanged() {
        const qint64 capturedTimestamp = QDateTime::currentMSecsSinceEpoch();

        if (!m_enabled) [[unlikely]]
            return;

        const auto* cb   = QGuiApplication::clipboard();
        const auto* mime = cb->mimeData();

        if (!mime || mime->formats().isEmpty()) [[unlikely]]
            return;

        const quint64 seq = ++m_copySequence;

        const auto*   manager   = qobject_cast<ClipboardManager*>(parent());
        const QString sourceApp = manager ? manager->activeWindow() : QString{};

        const bool    hasImage = mime->hasImage();
        const bool    hasHtml  = mime->hasHtml();
        const bool    hasUrls  = mime->hasUrls();
        const bool    hasText  = mime->hasText();

        if (!m_selfCopyHashes.isEmpty()) {
            if (mime) {
                const QByteArray payload = hasImage ? QByteArray{} : hasHtml ? mime->html().toUtf8() : hasUrls ? mime->urls().first().toString().toUtf8() : mime->text().toUtf8();
                if (!payload.isEmpty()) {
                    const QByteArray h  = sha256(payload);
                    auto             it = m_selfCopyHashes.find(h);
                    if (it != m_selfCopyHashes.end()) {
                        if (--it.value() <= 0)
                            m_selfCopyHashes.erase(it);
                        return;
                    }
                }
            }
        }

        if (hasImage) {
            const QImage image = cb->image();
            if (image.isNull()) [[unlikely]]
                return;

            QThreadPool::globalInstance()->start([this, image, sourceApp, seq, capturedTimestamp]() {
                QThread::currentThread()->setPriority(QThread::LowPriority);

                const QByteArray png = compressImage(image);
                if (png.isEmpty()) [[unlikely]]
                    return;

                const QByteArray hash = sha256(png);

                QMetaObject::invokeMethod(
                    this,
                    [this, png, hash, sourceApp, seq, capturedTimestamp]() {
                        if (seq < m_lastProcessedSequence)
                            return;

                        auto it = m_selfCopyHashes.find(hash);
                        if (it != m_selfCopyHashes.end()) {
                            if (--it.value() <= 0)
                                m_selfCopyHashes.erase(it);
                            return;
                        }

                        if (hash == m_lastImageHash)
                            return;

                        m_lastProcessedSequence = seq;
                        m_lastImageHash         = hash;

                        ClipboardEntry entry{.id        = -1,
                                             .type      = ClipboardType::Image,
                                             .content   = {},
                                             .data      = png,
                                             .mimeType  = QStringLiteral("image/png"),
                                             .hash      = hash,
                                             .pinned    = false,
                                             .sourceApp = sourceApp,
                                             .sizeBytes = static_cast<qint64>(png.size()),
                                             .timestamp = capturedTimestamp};

                        emit           newEntry(entry);
                    },
                    Qt::QueuedConnection);
            });
            return;
        }

        m_lastProcessedSequence = seq;

        std::optional<ClipboardEntry> entry;
        if (hasHtml) {
            m_lastImageHash.clear();
            entry = buildHtmlEntry(cb, sourceApp, capturedTimestamp);
        } else if (hasUrls) {
            m_lastImageHash.clear();
            entry = buildFilesEntry(cb, sourceApp, capturedTimestamp);
        } else if (hasText) {
            m_lastImageHash.clear();
            entry = buildTextEntry(cb, sourceApp, capturedTimestamp);
        }

        if (entry.has_value())
            emit newEntry(std::move(*entry));
    }

    [[nodiscard]] std::optional<ClipboardEntry> ClipboardWatcher::buildTextEntry(const QClipboard* cb, const QString& sourceApp, qint64 capturedTimestamp) {
        const QString text = cb->text();

        const auto    isEmptyOrWhitespace = [](QStringView sv) noexcept { return sv.isEmpty() || std::ranges::all_of(sv, [](QChar c) { return c.isSpace(); }); };

        if (isEmptyOrWhitespace(text))
            return std::nullopt;

        ClipboardEntry entry{.id        = -1,
                             .type      = ClipboardType::Text,
                             .content   = text,
                             .data      = {},
                             .mimeType  = QStringLiteral("text/plain"),
                             .hash      = {},
                             .pinned    = false,
                             .sourceApp = {},
                             .sizeBytes = 0,
                             .timestamp = 0};

        finalise(entry, text.toUtf8(), sourceApp, capturedTimestamp);
        return entry;
    }

    [[nodiscard]] std::optional<ClipboardEntry> ClipboardWatcher::buildHtmlEntry(const QClipboard* cb, const QString& sourceApp, qint64 capturedTimestamp) {
        const auto*   mime  = cb->mimeData();
        const QString html  = mime->html();
        const QString plain = mime->hasText() ? mime->text() : QString{};

        const auto    isEmptyOrWhitespace = [](QStringView sv) noexcept { return sv.isEmpty() || std::ranges::all_of(sv, [](QChar c) { return c.isSpace(); }); };

        if (isEmptyOrWhitespace(html))
            return std::nullopt;

        ClipboardEntry entry{.id        = -1,
                             .type      = ClipboardType::Html,
                             .content   = plain.isEmpty() ? html : plain,
                             .data      = {},
                             .mimeType  = QStringLiteral("text/html"),
                             .hash      = {},
                             .pinned    = false,
                             .sourceApp = {},
                             .sizeBytes = 0,
                             .timestamp = 0};

        finalise(entry, html.toUtf8(), sourceApp, capturedTimestamp);
        return entry;
    }

    [[nodiscard]] std::optional<ClipboardEntry> ClipboardWatcher::buildFilesEntry(const QClipboard* cb, const QString& sourceApp, qint64 capturedTimestamp) {
        const auto* mime = cb->mimeData();
        const auto  urls = mime->urls();

        if (urls.isEmpty())
            return std::nullopt;

        QStringList paths;
        paths.reserve(urls.size());
        for (const auto& url : urls)
            paths.append(url.isLocalFile() ? url.toLocalFile() : url.toString());

        const QString  content = paths.join(u'\n');

        ClipboardEntry entry{.id        = -1,
                             .type      = ClipboardType::Files,
                             .content   = content,
                             .data      = {},
                             .mimeType  = QStringLiteral("text/uri-list"),
                             .hash      = {},
                             .pinned    = false,
                             .sourceApp = {},
                             .sizeBytes = 0,
                             .timestamp = 0};

        finalise(entry, content.toUtf8(), sourceApp, capturedTimestamp);
        return entry;
    }

    void ClipboardWatcher::finalise(ClipboardEntry& entry, const QByteArray& hashPayload, const QString& sourceApp, qint64 capturedTimestamp) {
        entry.hash      = sha256(hashPayload);
        entry.timestamp = capturedTimestamp;
        entry.sourceApp = sourceApp;
        entry.sizeBytes = entry.data.isEmpty() ? static_cast<qint64>(hashPayload.size()) : static_cast<qint64>(entry.data.size());
    }

    [[nodiscard]] QByteArray ClipboardWatcher::sha256(const QByteArray& data) {
        return QCryptographicHash::hash(data, QCryptographicHash::Sha256);
    }

    [[nodiscard]] QByteArray ClipboardWatcher::compressImage(const QImage& image) {
        // don't worry about this, we don't want this shit get overflow
        constexpr qint64 kMaxPixels = 4'000'000LL;

        const qint64     pixels = static_cast<qint64>(image.width()) * image.height();

        QImage           downscaled;
        if (pixels > kMaxPixels) {
            const qreal factor = qSqrt(static_cast<qreal>(kMaxPixels) / static_cast<qreal>(pixels));
            const int   w      = qMax(1, qRound(image.width() * factor));
            const int   h      = qMax(1, qRound(image.height() * factor));
            downscaled         = image.scaled(w, h, Qt::IgnoreAspectRatio, Qt::FastTransformation);
        }

        const QImage& src = downscaled.isNull() ? image : downscaled;

        QByteArray    bytes;
        QBuffer       buf{&bytes};
        buf.open(QIODevice::WriteOnly);

        if (!src.save(&buf, "PNG", 1))
            return {};

        return bytes;
    }
}
