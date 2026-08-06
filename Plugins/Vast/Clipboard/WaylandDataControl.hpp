#pragma once

#include <qobject.h>
#include <qhash.h>
#include <qstring.h>
#include <qbytearray.h>
#include <qthreadpool.h>

#include <functional>

struct wl_display;
struct wl_registry;
struct wl_seat;
struct ext_data_control_manager_v1;
struct ext_data_control_device_v1;
struct ext_data_control_offer_v1;
struct ext_data_control_source_v1;

namespace Vast {

    class ClipboardManager;

    class WaylandDataControl : public QObject {
        Q_OBJECT
        Q_DISABLE_COPY(WaylandDataControl)

      public:
        explicit WaylandDataControl(ClipboardManager* parent);
        ~WaylandDataControl() override;

        [[nodiscard]] bool initialize();
        [[nodiscard]] bool isAvailable() const noexcept;

        void               setClipboardContent(const QString& mimeType, const QByteArray& content, const QString& fileName = {});

      signals:
        void selectionReceived(const QString& mimeType, const QByteArray& content, const QString& fileName = {});
        void deviceFinished();

      private:
        friend void                                                    registryGlobal(void*, wl_registry*, uint32_t, const char*, uint32_t);
        friend void                                                    deviceDataOffer(void*, ext_data_control_device_v1*, ext_data_control_offer_v1*);
        friend void                                                    deviceSelection(void*, ext_data_control_device_v1*, ext_data_control_offer_v1*);
        friend void                                                    devicePrimarySelection(void*, ext_data_control_device_v1*, ext_data_control_offer_v1*);
        friend void                                                    deviceFinished(void*, ext_data_control_device_v1*);
        friend void                                                    offerOffer(void*, ext_data_control_offer_v1*, const char*);
        friend void                                                    sourceSend(void*, ext_data_control_source_v1*, const char*, int32_t);
        friend void                                                    sourceCancelled(void*, ext_data_control_source_v1*);

        void                                                           shutdown();
        void                                                           reconnect();

        void                                                           receiveSelection(ext_data_control_offer_v1* offer);
        [[nodiscard]] QString                                          pickBestMimeType() const;
        [[nodiscard]] QString                                          pickMetaMimeType(const QString& primaryMime) const;
        [[nodiscard]] static QString                                   extractFileName(const QString& metaMime, const QByteArray& metaContent);
        [[nodiscard]] static QByteArray                                htmlToPlainText(const QByteArray& html);
        void                                                           readOfferAsync(int fd, std::function<void(QByteArray)> onRead);

        wl_display*                                                    m_display{nullptr};
        wl_registry*                                                   m_registry{nullptr};
        wl_seat*                                                       m_seat{nullptr};
        ext_data_control_manager_v1*                                   m_manager{nullptr};
        ext_data_control_device_v1*                                    m_device{nullptr};
        ext_data_control_offer_v1*                                     m_currentOffer{nullptr};
        QList<QString>                                                 m_pendingMimeTypes{};
        QHash<ext_data_control_source_v1*, QHash<QString, QByteArray>> m_pendingSources{};
        QString                                                        m_pendingMeta;
        quint32                                                        m_metaGeneration{0};

        bool                                                           m_initialized{false};
        bool                                                           m_reconnecting{false};

        static QThreadPool*                                            sendPool();
    };
}
