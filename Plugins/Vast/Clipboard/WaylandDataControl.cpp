#include "WaylandDataControl.hpp"
#include "ClipboardManager.hpp"

#include "ext-data-control-v1-client-protocol.h"

#include <qfileinfo.h>
#include <qguiapplication.h>
#include <qregularexpression.h>
#include <qtextdocument.h>
#include <qthreadpool.h>

#include <qtimer.h>
#include <qurl.h>

#include <algorithm>
#include <cerrno>
#include <cstring>
#include <utility>

#include <qthread.h>
#include <sys/types.h>
#include <unistd.h>

namespace Vast {

    namespace Constants {
        constexpr const char* kMimeImagePng  = "image/png";
        constexpr const char* kMimeHtml      = "text/html";
        constexpr const char* kMimeUriList   = "text/uri-list";
        constexpr const char* kMimeSuggested = "application/x-kde-suggestedfilename";
        constexpr const char* kMimeTextUtf8  = "text/plain;charset=utf-8";
        constexpr const char* kMimeText      = "text/plain";
        constexpr const char* kMimeX11String = "UTF8_STRING";
        constexpr const char* kPasswordHint  = "x-kde-passwordManagerHint";
    }
    using namespace Constants;

    void registryGlobal(void* data, wl_registry* registry, uint32_t name, const char* interface, uint32_t version) {
        auto* self = static_cast<WaylandDataControl*>(data);

        if (std::strcmp(interface, ext_data_control_manager_v1_interface.name) == 0) {
            self->m_manager = static_cast<ext_data_control_manager_v1*>(wl_registry_bind(registry, name, &ext_data_control_manager_v1_interface, std::min(version, 1u)));
        } else if (std::strcmp(interface, wl_seat_interface.name) == 0) {
            self->m_seat = static_cast<wl_seat*>(wl_registry_bind(registry, name, &wl_seat_interface, version));
        }
    }

    static void                           registryGlobalRemove(void*, wl_registry*, uint32_t) {}

    static constexpr wl_registry_listener registryListener = {
        .global        = registryGlobal,
        .global_remove = registryGlobalRemove,
    };

    void offerOffer(void* data, ext_data_control_offer_v1*, const char* mimeType) {
        auto* self = static_cast<WaylandDataControl*>(data);
        self->m_pendingMimeTypes.push_back(QString::fromUtf8(mimeType));
    }

    static constexpr ext_data_control_offer_v1_listener offerListener = {
        .offer = offerOffer,
    };

    void deviceDataOffer(void* data, ext_data_control_device_v1*, ext_data_control_offer_v1* offer) {
        auto* self = static_cast<WaylandDataControl*>(data);
        ext_data_control_offer_v1_add_listener(offer, &offerListener, self);
        self->m_pendingMimeTypes.clear();
    }

    void deviceSelection(void* data, ext_data_control_device_v1*, ext_data_control_offer_v1* offer) {
        auto* self = static_cast<WaylandDataControl*>(data);

        if (self->m_currentOffer && self->m_currentOffer != offer) {
            ext_data_control_offer_v1_destroy(self->m_currentOffer);
        }
        self->m_currentOffer = offer;

        if (!offer) {
            self->m_pendingMimeTypes.clear();
            return;
        }

        self->receiveSelection(offer);
        self->m_pendingMimeTypes.clear();
    }

    void devicePrimarySelection(void* data, ext_data_control_device_v1*, ext_data_control_offer_v1* offer) {
        auto* self = static_cast<WaylandDataControl*>(data);
        if (offer)
            ext_data_control_offer_v1_destroy(offer);
        self->m_pendingMimeTypes.clear();
    }

    void deviceFinished(void* data, ext_data_control_device_v1* device) {
        auto* self = static_cast<WaylandDataControl*>(data);
        ext_data_control_device_v1_destroy(device);
        self->m_device = nullptr;
        emit self->deviceFinished();

        if (!self->m_reconnecting) {
            self->m_reconnecting = true;
            QTimer::singleShot(0, self, [self]() { self->reconnect(); });
        }
    }

    static constexpr ext_data_control_device_v1_listener deviceListener = {
        .data_offer        = deviceDataOffer,
        .selection         = deviceSelection,
        .finished          = deviceFinished,
        .primary_selection = devicePrimarySelection,
    };

    void sourceSend(void* data, ext_data_control_source_v1* source, const char* mimeType, int32_t fd) {
        auto*      self = static_cast<WaylandDataControl*>(data);

        const auto srcIt = self->m_pendingSources.constFind(source);
        if (srcIt == self->m_pendingSources.cend()) {
            ::close(fd);
            return;
        }

        const auto contentIt = srcIt.value().constFind(QString::fromUtf8(mimeType));
        if (contentIt == srcIt.value().cend()) {
            qWarning() << "[WaylandDataControl] sourceSend: mime not offered, dropping request:" << mimeType << "offers:" << srcIt.value().keys();
            ::close(fd);
            return;
        }
        const QByteArray content = contentIt.value();

        // Offload the synchronous write to a dedicated worker so the main
        // thread (and therefore Qt's wl_display_roundtrip / dispatch) is never
        // blocked by a slow or stalled pipe reader. Deliberately NOT the
        // global QThreadPool: that pool is shared with unrelated background
        // work (preview thumbnailing, inbound offer reads), and a send queued
        // behind those can arrive too late for the requesting client's read
        // timeout, stalling the whole exchange.
        WaylandDataControl::sendPool()->start([content, fd]() {
            qint64 written = 0;
            while (written < content.size()) {
                const ssize_t n = ::write(fd, content.constData() + written, static_cast<size_t>(content.size() - written));
                if (n < 0) {
                    if (errno == EINTR)
                        continue;
                    if (errno != EPIPE)
                        qWarning() << "[WaylandDataControl] write failed:" << std::strerror(errno);
                    break;
                }
                written += n;
            }
            ::close(fd);
        });
    }

    void sourceCancelled(void* data, ext_data_control_source_v1* source) {
        auto* self = static_cast<WaylandDataControl*>(data);
        self->m_pendingSources.remove(source);
        ext_data_control_source_v1_destroy(source);
    }

    static constexpr ext_data_control_source_v1_listener sourceListener = {
        .send      = sourceSend,
        .cancelled = sourceCancelled,
    };

    QThreadPool* WaylandDataControl::sendPool() {
        static QThreadPool                 pool{};
        [[maybe_unused]] static const bool initialized = [] {
            pool.setMaxThreadCount(2);
            return true;
        }();
        return &pool;
    }

    WaylandDataControl::WaylandDataControl(ClipboardManager* parent) : QObject{parent} {}

    WaylandDataControl::~WaylandDataControl() {
        shutdown();
    }

    bool WaylandDataControl::initialize() {
        if (m_initialized)
            return true;

        if (QGuiApplication::platformName() != QStringLiteral("wayland")) {
            qWarning() << "[WaylandDataControl] Refusing to bind: running on non-Wayland platform" << QGuiApplication::platformName();
            return false;
        }

        auto* waylandApp = qApp->nativeInterface<QNativeInterface::QWaylandApplication>();
        if (!waylandApp) {
            qWarning() << "[WaylandDataControl] Qt Wayland native interface not available";
            return false;
        }
        m_display = waylandApp->display();
        if (!m_display) {
            qWarning() << "[WaylandDataControl] Qt's wl_display is null";
            return false;
        }

        m_registry = wl_display_get_registry(m_display);
        wl_registry_add_listener(m_registry, &registryListener, this);

        if (wl_display_roundtrip(m_display) < 0) {
            qWarning() << "[WaylandDataControl] initial registry roundtrip failed";
            shutdown();
            return false;
        }

        if (!m_manager) {
            qWarning() << "[WaylandDataControl] Compositor does not support ext_data_control_v1; clipboard history disabled";
            shutdown();
            return false;
        }
        if (!m_seat) {
            qWarning() << "[WaylandDataControl] No wl_seat advertised; clipboard history disabled";
            shutdown();
            return false;
        }

        m_device = ext_data_control_manager_v1_get_data_device(m_manager, m_seat);
        if (ext_data_control_device_v1_add_listener(m_device, &deviceListener, this) < 0) {
            qWarning() << "[WaylandDataControl] failed to add device listener";
            shutdown();
            return false;
        }

        if (wl_display_roundtrip(m_display) < 0) {
            qWarning() << "[WaylandDataControl] device roundtrip failed";
            shutdown();
            return false;
        }

        m_initialized = true;
        return true;
    }

    [[nodiscard]] bool WaylandDataControl::isAvailable() const noexcept {
        return m_initialized && m_display && m_manager && m_device;
    }

    void WaylandDataControl::reconnect() {
        if (!m_display) {
            m_reconnecting = false;
            return;
        }

        shutdown();

        m_registry = wl_display_get_registry(m_display);
        wl_registry_add_listener(m_registry, &registryListener, this);

        if (wl_display_roundtrip(m_display) < 0) {
            qWarning() << "[WaylandDataControl] reconnect registry roundtrip failed";
            shutdown();
            m_reconnecting = false;
            return;
        }

        if (m_manager && m_seat) {
            m_device = ext_data_control_manager_v1_get_data_device(m_manager, m_seat);
            if (ext_data_control_device_v1_add_listener(m_device, &deviceListener, this) == 0) {
                wl_display_roundtrip(m_display);
                m_initialized = true;
                qWarning() << "[WaylandDataControl] reconnected";
            }
        } else {
            qWarning() << "[WaylandDataControl] reconnect: compositor no longer supports ext_data_control_v1";
            shutdown();
        }

        m_reconnecting = false;
    }

    void WaylandDataControl::shutdown() {
        for (auto it = m_pendingSources.cbegin(); it != m_pendingSources.cend(); ++it)
            ext_data_control_source_v1_destroy(it.key());
        m_pendingSources.clear();

        if (m_currentOffer) {
            ext_data_control_offer_v1_destroy(m_currentOffer);
            m_currentOffer = nullptr;
        }
        m_pendingMimeTypes.clear();

        if (m_device) {
            ext_data_control_device_v1_destroy(m_device);
            m_device = nullptr;
        }
        if (m_manager) {
            ext_data_control_manager_v1_destroy(m_manager);
            m_manager = nullptr;
        }
        if (m_seat) {
            wl_seat_destroy(m_seat);
            m_seat = nullptr;
        }
        if (m_registry) {
            wl_registry_destroy(m_registry);
            m_registry = nullptr;
        }

        m_initialized = false;
    }

    void WaylandDataControl::receiveSelection(ext_data_control_offer_v1* offer) {
        const QString mimeType = pickBestMimeType();
        if (mimeType.isEmpty()) {
            return;
        }

        const quint32 generation = ++m_metaGeneration;
        const QString metaMime   = pickMetaMimeType(mimeType);

        const auto    startPrimaryRead = [this, offer, mimeType, generation]() {
            if (!m_device || m_currentOffer != offer) {
                qWarning() << "[WaylandDataControl] offer invalidated before payload read; selection skipped";
                return;
            }

            int fds[2];
            if (::pipe(fds) != 0) {
                qWarning() << "[WaylandDataControl] pipe() failed:" << std::strerror(errno);
                return;
            }

            ext_data_control_offer_v1_receive(offer, mimeType.toUtf8().constData(), fds[1]);
            ::close(fds[1]);
            wl_display_flush(m_display);

            readOfferAsync(fds[0], [this, mimeType, generation](QByteArray content) {
                const QString fileName = m_metaGeneration == generation ? m_pendingMeta : QString{};
                emit          selectionReceived(mimeType, content, fileName);
            });
        };

        if (metaMime.isEmpty()) {
            startPrimaryRead();
            return;
        }

        int fds[2];
        if (::pipe(fds) != 0) {
            qWarning() << "[WaylandDataControl] pipe() failed:" << std::strerror(errno);
            startPrimaryRead();
            return;
        }

        ext_data_control_offer_v1_receive(offer, metaMime.toUtf8().constData(), fds[1]);
        ::close(fds[1]);
        wl_display_flush(m_display);

        readOfferAsync(fds[0], [this, generation, metaMime, startPrimaryRead](QByteArray meta) {
            m_pendingMeta    = extractFileName(metaMime, meta);
            m_metaGeneration = generation;
            startPrimaryRead();
        });
    }

    [[nodiscard]] QString WaylandDataControl::pickBestMimeType() const {
        for (const auto& mime : m_pendingMimeTypes) {
            if (mime == QLatin1StringView{kPasswordHint})
                return {};
        }

        static constexpr const char* kPriority[] = {
            kMimeImagePng, kMimeHtml, kMimeUriList, kMimeTextUtf8, kMimeText, kMimeX11String,
        };

        for (const char* wanted : kPriority) {
            const QLatin1StringView wantedView{wanted};
            for (const auto& offered : m_pendingMimeTypes) {
                if (offered == wantedView)
                    return offered;
            }
        }

        return {};
    }

    [[nodiscard]] QString WaylandDataControl::pickMetaMimeType(const QString& primaryMime) const {
        if (primaryMime != QLatin1StringView{kMimeImagePng})
            return {};

        static constexpr const char* kMetaPriority[] = {
            kMimeSuggested,
            kMimeUriList,
        };

        for (const char* wanted : kMetaPriority) {
            const QLatin1StringView wantedView{wanted};
            for (const auto& offered : m_pendingMimeTypes) {
                if (offered == wantedView)
                    return offered;
            }
        }

        return {};
    }

    [[nodiscard]] QString WaylandDataControl::extractFileName(const QString& metaMime, const QByteArray& metaContent) {
        if (metaMime == QLatin1StringView{kMimeSuggested}) {
            return QString::fromUtf8(metaContent).trimmed();
        }

        if (metaMime == QLatin1StringView{kMimeUriList}) {
            const auto lines = QString::fromUtf8(metaContent).split(QLatin1Char('\n'));
            for (const auto& line : lines) {
                const QString trimmed = line.trimmed();
                if (trimmed.isEmpty())
                    continue;

                const QUrl url = QUrl::fromEncoded(trimmed.toUtf8());
                if (url.isValid() && url.scheme() == QLatin1String("file"))
                    return url.toLocalFile();
                return {};
            }
        }

        return {};
    }

    [[nodiscard]] QByteArray WaylandDataControl::htmlToPlainText(const QByteArray& html) {
        QString              text = QString::fromUtf8(html);

        static const QString scriptBlock = QLatin1String("<script[^>]*>.*?</script>");
        static const QString styleBlock  = QLatin1String("<style[^>]*>.*?</style>");
        text.remove(QRegularExpression{scriptBlock, QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption});
        text.remove(QRegularExpression{styleBlock, QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption});

        text.replace(QRegularExpression{QStringLiteral("<br\\s*/?>"), QRegularExpression::CaseInsensitiveOption}, QStringLiteral("\n"));
        text.replace(QRegularExpression{QStringLiteral("</(p|div|li|tr|h[1-6]|pre|blockquote|section|article)>"), QRegularExpression::CaseInsensitiveOption}, QStringLiteral("\n"));

        QTextDocument doc;
        doc.setHtml(text);
        return doc.toPlainText().trimmed().toUtf8();
    }

    void WaylandDataControl::readOfferAsync(int fd, std::function<void(QByteArray)> onRead) {
        QThreadPool::globalInstance()->start([this, fd, onRead = std::move(onRead)]() {
            QThread::currentThread()->setPriority(QThread::LowPriority);

            QByteArray content;
            char       buf[65536];
            ssize_t    n;
            while ((n = ::read(fd, buf, sizeof(buf))) > 0)
                content.append(buf, static_cast<qsizetype>(n));
            ::close(fd);

            QMetaObject::invokeMethod(this, [onRead, content = std::move(content)]() mutable { onRead(std::move(content)); }, Qt::QueuedConnection);
        });
    }

    void WaylandDataControl::setClipboardContent(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (!m_manager || !m_device) {
            qWarning() << "[WaylandDataControl] setClipboardContent: not initialized";
            return;
        }

        auto*                      source = ext_data_control_manager_v1_create_data_source(m_manager);

        QHash<QString, QByteArray> payload;
        payload.insert(mimeType, content);

        if (mimeType == QLatin1StringView{kMimeTextUtf8} || mimeType == QLatin1StringView{kMimeText}) {
            payload.insert(QString::fromLatin1(kMimeTextUtf8), content);
            payload.insert(QString::fromLatin1(kMimeText), content);
            payload.insert(QString::fromLatin1(kMimeX11String), content);
        }

        if (mimeType == QLatin1StringView{kMimeHtml}) {
            QByteArray plain = htmlToPlainText(content);
            if (plain.isEmpty())
                plain = content;
            payload.insert(QString::fromLatin1(kMimeTextUtf8), plain);
            payload.insert(QString::fromLatin1(kMimeText), plain);
            payload.insert(QString::fromLatin1(kMimeX11String), plain);
        }

        if (mimeType == QLatin1StringView{kMimeUriList}) {
            const QString path = extractFileName(QString::fromLatin1(kMimeUriList), content);
            if (!path.isEmpty()) {
                const QByteArray pathBytes = path.toUtf8();
                payload.insert(QString::fromLatin1(kMimeTextUtf8), pathBytes);
                payload.insert(QString::fromLatin1(kMimeText), pathBytes);
                payload.insert(QString::fromLatin1(kMimeX11String), pathBytes);
            }
        }

        if (mimeType == QLatin1StringView{kMimeImagePng} && !fileName.isEmpty()) {
            if (QFileInfo::exists(fileName)) {
                payload.insert(QString::fromLatin1(kMimeUriList), QUrl::fromLocalFile(fileName).toString(QUrl::FullyEncoded).toUtf8());
            } else {
                payload.insert(QString::fromLatin1(kMimeSuggested), QFileInfo(fileName).fileName().toUtf8());
            }
        }

        for (auto it = payload.cbegin(); it != payload.cend(); ++it)
            ext_data_control_source_v1_offer(source, it.key().toUtf8().constData());

        m_pendingSources[source] = std::move(payload);

        ext_data_control_source_v1_add_listener(source, &sourceListener, this);
        ext_data_control_device_v1_set_selection(m_device, source);
        wl_display_flush(m_display);
    }
}
