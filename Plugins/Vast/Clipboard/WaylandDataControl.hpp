#pragma once

#include <cstdint>
#include <qlist.h>
#include <qobject.h>
#include <qhash.h>
#include <qstring.h>
#include <qbytearray.h>
#include <qtclasshelpermacros.h>
#include <qthreadpool.h>

#include <functional>
#include <memory>
#include <qtmetamacros.h>
#include <qtypes.h>

struct wl_display;
struct wl_registry;
struct wl_seat;
struct ext_data_control_manager_v1;
struct ext_data_control_device_v1;
struct ext_data_control_offer_v1;
struct ext_data_control_source_v1;
class QSocketNotifier;

namespace vast {

    class ClipboardManager;

    class WaylandDataControl : public QObject {
        Q_OBJECT
        Q_DISABLE_COPY(WaylandDataControl)

      public:
        explicit WaylandDataControl(ClipboardManager* parent = nullptr);
        ~WaylandDataControl() override;
        WaylandDataControl(WaylandDataControl&&)                        = delete;
        WaylandDataControl&             operator=(WaylandDataControl&&) = delete;

        Q_INVOKABLE [[nodiscard]] bool  initialize();
        [[nodiscard]] bool              isAvailable() const noexcept;

        void                            setClipboardContent(const QString& mimeType, const QByteArray& content, const QString& fileName = {});

        [[nodiscard]] static QByteArray htmlToPlainText(const QByteArray& html);

      signals:
        void selectionReceived(const QString& mimeType, const QByteArray& content, const QString& fileName = {});
        void deviceFinished();

      private:
        friend void      registryGlobal(void* /*data*/, wl_registry* /*registry*/, uint32_t /*name*/, const char* /*interface*/, uint32_t /*version*/);
        friend void      deviceDataOffer(void* /*data*/, ext_data_control_device_v1* /*unused*/, ext_data_control_offer_v1* /*offer*/);
        friend void      deviceSelection(void* /*data*/, ext_data_control_device_v1* /*unused*/, ext_data_control_offer_v1* /*offer*/);
        friend void      devicePrimarySelection(void* /*data*/, ext_data_control_device_v1* /*unused*/, ext_data_control_offer_v1* /*offer*/);
        friend void      deviceFinished(void* /*data*/, ext_data_control_device_v1* /*device*/);
        friend void      offerOffer(void* /*data*/, ext_data_control_offer_v1* /*unused*/, const char* /*mimeType*/);
        friend void      sourceSend(void* /*data*/, ext_data_control_source_v1* /*source*/, const char* /*mimeType*/, int32_t /*fd*/);
        friend void      sourceCancelled(void* /*data*/, ext_data_control_source_v1* /*source*/);

        Q_INVOKABLE void shutdown();

        // connect to the display, bind the registry/manager/seat, and wire up the data device.
        // Both entry points used to duplicate this sequence; isReconnect only changes logging
        // and how mInitialized is left on failure.
        bool                         connectAndBind(bool isReconnect);
        void                         reconnect();

        void                         receiveSelection(ext_data_control_offer_v1* offer);
        void                         dispatchWayland();
        [[nodiscard]] QString        pickBestMimeType() const;
        [[nodiscard]] QString        pickMetaMimeType(const QString& primaryMime) const;
        [[nodiscard]] static QString extractFileName(const QString& metaMime, const QByteArray& metaContent);
        void                         readOfferAsync(int fd, std::function<void(QByteArray)> onRead);

        struct DisplayDeleter {
            void operator()(wl_display* display) const;
        };
        struct RegistryDeleter {
            void operator()(wl_registry* registry) const;
        };
        struct SeatDeleter {
            void operator()(wl_seat* seat) const;
        };
        struct ManagerDeleter {
            void operator()(ext_data_control_manager_v1* manager) const;
        };
        struct DeviceDeleter {
            void operator()(ext_data_control_device_v1* device) const;
        };
        struct OfferDeleter {
            void operator()(ext_data_control_offer_v1* offer) const;
        };

        using DisplayPtr  = std::unique_ptr<wl_display, DisplayDeleter>;
        using RegistryPtr = std::unique_ptr<wl_registry, RegistryDeleter>;
        using SeatPtr     = std::unique_ptr<wl_seat, SeatDeleter>;
        using ManagerPtr  = std::unique_ptr<ext_data_control_manager_v1, ManagerDeleter>;
        using DevicePtr   = std::unique_ptr<ext_data_control_device_v1, DeviceDeleter>;
        using OfferPtr    = std::unique_ptr<ext_data_control_offer_v1, OfferDeleter>;

        DisplayPtr                                                     mDisplay;
        QSocketNotifier*                                               mDisplayNotifier{nullptr};
        RegistryPtr                                                    mRegistry;
        SeatPtr                                                        mSeat;
        ManagerPtr                                                     mManager;
        DevicePtr                                                      mDevice;
        OfferPtr                                                       mCurrentOffer;
        QList<QString>                                                 mPendingMimeTypes;

        QHash<ext_data_control_source_v1*, QHash<QString, QByteArray>> mPendingSources;
        QString                                                        mPendingMeta;
        quint32                                                        mMetaGeneration{0};

        bool                                                           mInitialized{false};
        bool                                                           mReconnecting{false};

        static QThreadPool*                                            sendPool();
    };
}
