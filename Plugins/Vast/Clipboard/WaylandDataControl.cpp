#include "WaylandDataControl.hpp"
#include "ClipboardManager.hpp"

#include "ext-data-control-v1-client-protocol.h"

#include <array>
#include <cstdint>
#include <functional>
#include <qfileinfo.h>
#include <qguiapplication.h>
#include <qhashfunctions.h>
#include <qobject.h>
#include <qlogging.h>
#include <qlatin1stringview.h>
#include <qobjectdefs.h>
#include <qnamespace.h>
#include <qhash.h>
#include <qregularexpression.h>
#include <qsocketnotifier.h>
#include <qstringview.h>
#include <qtextdocument.h>
#include <qthreadpool.h>

#include <qtimer.h>
#include <qtmetamacros.h>
#include <qtypes.h>
#include <qurl.h>

#include <algorithm>
#include <cerrno>
#include <cstring>
#include <span>
#include <string>
#include <system_error>
#include <utility>

#include <qthread.h>
#include <sys/types.h>
#include <unistd.h>
#include <wayland-client-protocol.h>
#include <wayland-client-core.h>

namespace vast {

    namespace {
        void registryGlobalRemove(void* /*unused*/, wl_registry* /*unused*/, uint32_t /*unused*/) {};
    }

    void WaylandDataControl::DisplayDeleter::operator()(wl_display* display) const {
        wl_display_disconnect(display);
    }
    void WaylandDataControl::RegistryDeleter::operator()(wl_registry* registry) const {
        wl_registry_destroy(registry);
    }
    void WaylandDataControl::SeatDeleter::operator()(wl_seat* seat) const {
        wl_seat_destroy(seat);
    }
    void WaylandDataControl::ManagerDeleter::operator()(ext_data_control_manager_v1* manager) const {
        ext_data_control_manager_v1_destroy(manager);
    }
    void WaylandDataControl::DeviceDeleter::operator()(ext_data_control_device_v1* device) const {
        ext_data_control_device_v1_destroy(device);
    }
    void WaylandDataControl::OfferDeleter::operator()(ext_data_control_offer_v1* offer) const {
        ext_data_control_offer_v1_destroy(offer);
    }

    namespace constants {
        constexpr const char* K_MIME_IMAGE_PNG  = "image/png";
        constexpr const char* K_MIME_HTML       = "text/html";
        constexpr const char* K_MIME_URI_LIST   = "text/uri-list";
        constexpr const char* K_MIME_SUGGESTED  = "application/x-kde-suggestedfilename";
        constexpr const char* K_MIME_TEXT_UTF8  = "text/plain;charset=utf-8";
        constexpr const char* K_MIME_TEXT       = "text/plain";
        constexpr const char* K_MIME_X11_STRING = "UTF8_STRING";
        constexpr const char* K_PASSWORD_HINT   = "x-kde-passwordManagerHint";

        inline const QString  K_MIME_TEXT_UTF8_Q  = QStringLiteral("text/plain;charset=utf-8");
        inline const QString  K_MIME_TEXT_Q       = QStringLiteral("text/plain");
        inline const QString  K_MIME_X11_STRING_Q = QStringLiteral("UTF8_STRING");
        inline const QString  K_MIME_URI_LIST_Q   = QStringLiteral("text/uri-list");
        inline const QString  K_MIME_SUGGESTED_Q  = QStringLiteral("application/x-kde-suggestedfilename");
    }
    using namespace constants;

    void registryGlobal(void* data, wl_registry* registry, uint32_t name, const char* interface, uint32_t version) {
        auto* self = static_cast<WaylandDataControl*>(data);

        if (std::strcmp(interface, ext_data_control_manager_v1_interface.name) == 0)
            self->mManager.reset(static_cast<ext_data_control_manager_v1*>(wl_registry_bind(registry, name, &ext_data_control_manager_v1_interface, std::min(version, 1u))));
        else if (std::strcmp(interface, wl_seat_interface.name) == 0)
            self->mSeat.reset(static_cast<wl_seat*>(wl_registry_bind(registry, name, &wl_seat_interface, version)));
    }

    static constexpr wl_registry_listener REGISTRY_LISTENER = {
        .global        = registryGlobal,
        .global_remove = registryGlobalRemove,
    };

    void offerOffer(void* data, ext_data_control_offer_v1* /*unused*/, const char* mimeType) {
        auto* self = static_cast<WaylandDataControl*>(data);
        self->mPendingMimeTypes.push_back(QString::fromUtf8(mimeType));
    }

    static constexpr ext_data_control_offer_v1_listener OFFER_LISTENER = {
        .offer = offerOffer,
    };

    void deviceDataOffer(void* data, ext_data_control_device_v1* /*unused*/, ext_data_control_offer_v1* offer) {
        auto* self = static_cast<WaylandDataControl*>(data);
        ext_data_control_offer_v1_add_listener(offer, &OFFER_LISTENER, self);
        self->mPendingMimeTypes.clear();
    }

    void deviceSelection(void* data, ext_data_control_device_v1* /*unused*/, ext_data_control_offer_v1* offer) {
        auto* self = static_cast<WaylandDataControl*>(data);

        // Matches the original guard: only touch mCurrentOffer if the new offer differs
        // from the one already held. Re-sending the same offer is a no-op; reset(offer)
        // in that case would destroy the offer via the deleter and then immediately store
        // the now-dangling pointer, so it's skipped entirely rather than worked around.
        if (self->mCurrentOffer.get() != offer)
            self->mCurrentOffer.reset(offer);

        if (!offer) {
            self->mPendingMimeTypes.clear();
            return;
        }

        self->receiveSelection(offer);
        self->mPendingMimeTypes.clear();
    }

    void devicePrimarySelection(void* data, ext_data_control_device_v1* /*unused*/, ext_data_control_offer_v1* offer) {
        // This offer is discarded immediately and never passes through mCurrentOffer,
        // so it's destroyed directly rather than via the unique_ptr member.
        auto* self = static_cast<WaylandDataControl*>(data);
        if (offer)
            ext_data_control_offer_v1_destroy(offer);
        self->mPendingMimeTypes.clear();
    }

    void deviceFinished(void* data, ext_data_control_device_v1* device) {
        auto* self = static_cast<WaylandDataControl*>(data);
        // Per protocol, the client must still destroy the proxy on the finished event.
        // If this is the device we're tracking, reset() the unique_ptr its own deleter
        // performs the destroy, so nothing further is needed. Otherwise it's some other
        // (unexpected) device handle, which is destroyed directly.
        if (self->mDevice.get() == device)
            self->mDevice.reset();
        else
            ext_data_control_device_v1_destroy(device);

        emit self->deviceFinished();

        if (!self->mReconnecting) {
            self->mReconnecting = true;
            QTimer::singleShot(0, self, [self]() { self->reconnect(); });
        }
    }

    static constexpr ext_data_control_device_v1_listener DEVICE_LISTENER = {
        .data_offer        = deviceDataOffer,
        .selection         = deviceSelection,
        .finished          = deviceFinished,
        .primary_selection = devicePrimarySelection,
    };

    void sourceSend(void* data, ext_data_control_source_v1* source, const char* mimeType, int32_t fd) {
        auto*      self = static_cast<WaylandDataControl*>(data);

        const auto srcIt = self->mPendingSources.constFind(source);
        if (srcIt == self->mPendingSources.cend()) {
            ::close(fd);
            return;
        }

        const auto contentIt = srcIt.value().constFind(QString::fromUtf8(mimeType));
        if (contentIt == srcIt.value().cend()) {
            qWarning() << "[WaylandDataControl] sourceSend: mime not offered, dropping request:" << mimeType << "offers:" << srcIt.value().keys();
            ::close(fd);
            return;
        }
        const QByteArray& content = contentIt.value();

        WaylandDataControl::sendPool()->start([content, fd]() {
            const std::string msg     = std::system_category().message(errno);
            qint64            written = 0;
            while (written < content.size()) {
                const auto    remaining = std::span(content).subspan(static_cast<size_t>(written));
                const ssize_t n         = ::write(fd, remaining.data(), remaining.size());
                if (n < 0) {
                    if (errno == EINTR)
                        continue;
                    if (errno != EPIPE)
                        qWarning() << "[WaylandDataControl] write failed:" << QString::fromStdString(msg);
                    break;
                }
                written += n;
            }
            ::close(fd);
        });
    }

    void sourceCancelled(void* data, ext_data_control_source_v1* source) {
        // mPendingSources is intentionally not RAII-wrapped -- see the field comment in
        // the header. Destroy is still explicit and paired with the map removal here.
        auto* self = static_cast<WaylandDataControl*>(data);
        self->mPendingSources.remove(source);
        ext_data_control_source_v1_destroy(source);
    }

    static constexpr ext_data_control_source_v1_listener SOURCE_LISTENER = {
        .send      = sourceSend,
        .cancelled = sourceCancelled,
    };

    QThreadPool* WaylandDataControl::sendPool() {
        // A pool bounded at 2 threads for clipboard-content writes. Previously this was a
        // Meyers singleton plus a second static bool whose only job was to run
        // setMaxThreadCount(2) exactly once -- more moving parts than the one line of
        // setup needed. A tiny self-configuring subclass does the same thing with one
        // static and no IIFE.
        struct BoundedSendPool : QThreadPool {
            BoundedSendPool() {
                setMaxThreadCount(2);
            }
        };
        static BoundedSendPool pool;
        return &pool;
    }

    WaylandDataControl::WaylandDataControl(ClipboardManager* parent) : QObject{parent} {}

    WaylandDataControl::~WaylandDataControl() {
        shutdown();
    }

    bool WaylandDataControl::initialize() {
        if (mInitialized)
            return true;

        if (QGuiApplication::platformName() != QStringLiteral("wayland")) {
            qWarning() << "[WaylandDataControl] Refusing to bind: running on non-Wayland platform" << QGuiApplication::platformName();
            return false;
        }

        return connectAndBind(/*isReconnect=*/false);
    }

    [[nodiscard]] bool WaylandDataControl::isAvailable() const noexcept {
        return mInitialized && mDisplay && mManager && mDevice;
    }

    // Connects to the Wayland display, binds the registry (waiting for the manager and
    // seat globals), and sets up the data device -- the full sequence initialize() and
    // reconnect() both need. isReconnect only changes log wording; every failure path
    // calls shutdown() so callers always end up in a clean, fully-torn-down state rather
    // than a partially-bound one.
    bool WaylandDataControl::connectAndBind(bool isReconnect) {
        const char* logPrefix = isReconnect ? "[WaylandDataControl] reconnect" : "[WaylandDataControl]";

        mDisplay.reset(wl_display_connect(nullptr));
        if (!mDisplay) {
            qWarning() << logPrefix << "failed to connect to Wayland display";
            return false;
        }

        mRegistry.reset(wl_display_get_registry(mDisplay.get()));
        wl_registry_add_listener(mRegistry.get(), &REGISTRY_LISTENER, this);

        if (wl_display_roundtrip(mDisplay.get()) < 0) {
            qWarning() << logPrefix << "registry roundtrip failed";
            shutdown();
            return false;
        }

        if (!mManager) {
            qWarning() << logPrefix << "compositor does not support ext_data_control_v1; clipboard history disabled";
            shutdown();
            return false;
        }
        if (!mSeat) {
            qWarning() << logPrefix << "no wl_seat advertised; clipboard history disabled";
            shutdown();
            return false;
        }

        mDisplayNotifier = new QSocketNotifier(wl_display_get_fd(mDisplay.get()), QSocketNotifier::Read, this);
        connect(mDisplayNotifier, &QSocketNotifier::activated, this, [this]() { dispatchWayland(); });

        mDevice.reset(ext_data_control_manager_v1_get_data_device(mManager.get(), mSeat.get()));
        if (ext_data_control_device_v1_add_listener(mDevice.get(), &DEVICE_LISTENER, this) < 0) {
            qWarning() << logPrefix << "failed to add device listener";
            shutdown();
            return false;
        }

        if (wl_display_roundtrip(mDisplay.get()) < 0) {
            qWarning() << logPrefix << "device roundtrip failed";
            shutdown();
            return false;
        }

        mInitialized = true;
        if (isReconnect)
            qWarning() << "[WaylandDataControl] reconnected";
        return true;
    }

    void WaylandDataControl::reconnect() {
        if (!mDisplay) {
            mReconnecting = false;
            return;
        }

        shutdown();
        connectAndBind(/*isReconnect=*/true);
        mReconnecting = false;
    }

    void WaylandDataControl::shutdown() {
        delete mDisplayNotifier;
        mDisplayNotifier = nullptr;

        // Not unique_ptr-wrapped -- see the field comment in the header.
        for (auto it = mPendingSources.cbegin(); it != mPendingSources.cend(); ++it)
            ext_data_control_source_v1_destroy(it.key());
        mPendingSources.clear();

        mCurrentOffer.reset();
        mPendingMimeTypes.clear();

        // Order matters here and is now enforced by declaration order in the header
        // (members are destroyed in reverse declaration order) for the destructor path;
        // for this explicit shutdown() call we still reset in the same dependency order
        // the original hand-written teardown used -- device before manager/seat before
        // registry before display, since later ones own or outlive the earlier ones.
        mDevice.reset();
        mManager.reset();
        mSeat.reset();
        mRegistry.reset();
        mDisplay.reset();

        mInitialized = false;
    }

    void WaylandDataControl::dispatchWayland() {
        if (!mDisplay || wl_display_dispatch(mDisplay.get()) >= 0)
            return;

        if (mDisplayNotifier)
            mDisplayNotifier->setEnabled(false);

        if (!mReconnecting) {
            mReconnecting = true;
            QTimer::singleShot(0, this, [this]() { reconnect(); });
        }
    }

    void WaylandDataControl::receiveSelection(ext_data_control_offer_v1* offer) {
        const QString mimeType = pickBestMimeType();
        if (mimeType.isEmpty()) {
            return;
        }

        const quint32 generation = ++mMetaGeneration;
        const QString metaMime   = pickMetaMimeType(mimeType);

        const auto    startPrimaryRead = [this, offer, mimeType, generation]() {
            if (!mDevice || mCurrentOffer.get() != offer) {
                qWarning() << "[WaylandDataControl] offer invalidated before payload read; selection skipped";
                return;
            }

            const std::string  msg = std::system_category().message(errno);
            std::array<int, 2> fds{};
            if (::pipe(fds.data()) != 0) {
                qWarning() << "[WaylandDataControl] pipe() failed:" << QString::fromStdString(msg);
                return;
            }

            ext_data_control_offer_v1_receive(offer, mimeType.toUtf8().constData(), fds[1]);
            ::close(fds[1]);
            wl_display_flush(mDisplay.get());

            readOfferAsync(fds[0], [this, mimeType, generation](const QByteArray& content) {
                const QString fileName = mMetaGeneration == generation ? mPendingMeta : QString{};
                emit          selectionReceived(mimeType, content, fileName);
            });
        };

        if (metaMime.isEmpty()) {
            startPrimaryRead();
            return;
        }

        const std::string  msg = std::system_category().message(errno);
        std::array<int, 2> fds{};
        if (::pipe(fds.data()) != 0) {
            qWarning() << "[WaylandDataControl] pipe() failed:" << QString::fromStdString(msg);
            startPrimaryRead();
            return;
        }

        ext_data_control_offer_v1_receive(offer, metaMime.toUtf8().constData(), fds[1]);
        ::close(fds[1]);
        wl_display_flush(mDisplay.get());

        readOfferAsync(fds[0], [this, generation, metaMime, startPrimaryRead](const QByteArray& meta) {
            mPendingMeta    = extractFileName(metaMime, meta);
            mMetaGeneration = generation;
            startPrimaryRead();
        });
    }

    [[nodiscard]] QString WaylandDataControl::pickBestMimeType() const {
        for (const auto& mime : mPendingMimeTypes) {
            if (mime == QLatin1StringView{K_PASSWORD_HINT})
                return {};
        }

        static constexpr std::array kPriority = {
            K_MIME_IMAGE_PNG, K_MIME_HTML, K_MIME_URI_LIST, K_MIME_TEXT_UTF8, K_MIME_TEXT, K_MIME_X11_STRING,
        };

        for (const char* wanted : kPriority) {
            const QLatin1StringView wantedView{wanted};
            for (const auto& offered : mPendingMimeTypes)
                if (offered == wantedView)
                    return offered;
        }

        return {};
    }

    [[nodiscard]] QString WaylandDataControl::pickMetaMimeType(const QString& primaryMime) const {
        if (primaryMime != QLatin1StringView{K_MIME_IMAGE_PNG})
            return {};

        static constexpr std::array kMetaPriority = {
            K_MIME_SUGGESTED,
            K_MIME_URI_LIST,
        };

        for (const char* wanted : kMetaPriority) {
            const QLatin1StringView wantedView{wanted};
            for (const auto& offered : mPendingMimeTypes)
                if (offered == wantedView)
                    return offered;
        }

        return {};
    }

    [[nodiscard]] QString WaylandDataControl::extractFileName(const QString& metaMime, const QByteArray& metaContent) {
        if (metaMime == QLatin1StringView{K_MIME_SUGGESTED})
            return QString::fromUtf8(metaContent).trimmed();

        if (metaMime == QLatin1StringView{K_MIME_URI_LIST}) {
            const auto lines = metaContent.split('\n');
            for (const auto& line : lines) {
                const QByteArray trimmed = line.trimmed();
                if (trimmed.isEmpty())
                    continue;

                const QUrl url = QUrl::fromEncoded(trimmed);
                if (url.isValid() && url.scheme() == QLatin1String("file"))
                    return url.toLocalFile();
                return {};
            }
        }

        return {};
    }

    [[nodiscard]] QByteArray WaylandDataControl::htmlToPlainText(const QByteArray& html) {
        QString                         text = QString::fromUtf8(html);

        static const QRegularExpression scriptRegex{QStringLiteral("<script[^>]*>.*?</script>"),
                                                    QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption};
        static const QRegularExpression styleRegex{QStringLiteral("<style[^>]*>.*?</style>"),
                                                   QRegularExpression::CaseInsensitiveOption | QRegularExpression::DotMatchesEverythingOption};
        static const QRegularExpression brRegex{QStringLiteral("<br\\s*/?>"), QRegularExpression::CaseInsensitiveOption};
        static const QRegularExpression blockRegex{QStringLiteral("</(p|div|li|tr|h[1-6]|pre|blockquote|section|article)>"), QRegularExpression::CaseInsensitiveOption};
        text.remove(scriptRegex);
        text.remove(styleRegex);
        text.replace(brRegex, QStringLiteral("\n"));
        text.replace(blockRegex, QStringLiteral("\n"));

        QTextDocument doc;
        doc.setHtml(text);
        return doc.toPlainText().trimmed().toUtf8();
    }

    void WaylandDataControl::readOfferAsync(int fd, std::function<void(QByteArray)> onRead) {
        QThreadPool::globalInstance()->start([this, fd, onRead = std::move(onRead)]() {
            QThread::currentThread()->setPriority(QThread::LowPriority);

            QByteArray              content;
            std::array<char, 65536> buf; // NOLINT(cppcoreguidelines-pro-type-member-init): read() initializes the written range.
            ssize_t                 n = 0;
            while ((n = ::read(fd, buf.data(), buf.size())) > 0)
                content.append(buf.data(), static_cast<qsizetype>(n));
            ::close(fd);

            QMetaObject::invokeMethod(this, [onRead, content = std::move(content)]() mutable { onRead(std::move(content)); }, Qt::QueuedConnection);
        });
    }

    void WaylandDataControl::setClipboardContent(const QString& mimeType, const QByteArray& content, const QString& fileName) {
        if (!mManager || !mDevice) {
            qWarning() << "[WaylandDataControl] setClipboardContent: not initialized";
            return;
        }

        auto*                      source = ext_data_control_manager_v1_create_data_source(mManager.get());

        QHash<QString, QByteArray> payload;
        payload.insert(mimeType, content);

        if (mimeType == QLatin1StringView{K_MIME_TEXT_UTF8} || mimeType == QLatin1StringView{K_MIME_TEXT}) {
            payload.insert(K_MIME_TEXT_UTF8_Q, content);
            payload.insert(K_MIME_TEXT_Q, content);
            payload.insert(K_MIME_X11_STRING_Q, content);
        }

        if (mimeType == QLatin1StringView{K_MIME_HTML}) {
            QByteArray plain = htmlToPlainText(content);
            if (plain.isEmpty())
                plain = content;
            payload.insert(K_MIME_TEXT_UTF8_Q, plain);
            payload.insert(K_MIME_TEXT_Q, plain);
            payload.insert(K_MIME_X11_STRING_Q, plain);
        }

        if (mimeType == QLatin1StringView{K_MIME_URI_LIST}) {
            const QString path = extractFileName(K_MIME_URI_LIST_Q, content);
            if (!path.isEmpty()) {
                const QByteArray pathBytes = path.toUtf8();
                payload.insert(K_MIME_TEXT_UTF8_Q, pathBytes);
                payload.insert(K_MIME_TEXT_Q, pathBytes);
                payload.insert(K_MIME_X11_STRING_Q, pathBytes);
            }
        }

        if (mimeType == QLatin1StringView{K_MIME_IMAGE_PNG} && !fileName.isEmpty()) {
            if (QFileInfo::exists(fileName)) {
                payload.insert(K_MIME_URI_LIST_Q, QUrl::fromLocalFile(fileName).toString(QUrl::FullyEncoded).toUtf8());
            } else {
                payload.insert(K_MIME_SUGGESTED_Q, QFileInfo(fileName).fileName().toUtf8());
            }
        }

        for (auto it = payload.cbegin(); it != payload.cend(); ++it)
            ext_data_control_source_v1_offer(source, it.key().toUtf8().constData());

        mPendingSources[source] = std::move(payload);

        ext_data_control_source_v1_add_listener(source, &SOURCE_LISTENER, this);
        ext_data_control_device_v1_set_selection(mDevice.get(), source);
        wl_display_flush(mDisplay.get());
    }
}
