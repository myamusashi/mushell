#pragma once

#include "ClipboardModel.hpp"
#include "ClipboardEntry.hpp"

#include <qcontainerfwd.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>
#include <qpointer.h>

#include <memory>
#include <optional>
#include <qtmetamacros.h>
#include <qtclasshelpermacros.h>
#include <qtypes.h>
#include <qthread.h>

namespace vast {

    class ClipboardDatabase;
    class WaylandDataControl;

    class ClipboardManager : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON
        Q_DISABLE_COPY(ClipboardManager)

        Q_PROPERTY(vast::ClipboardModel* model READ model CONSTANT)
        Q_PROPERTY(int maxEntries READ maxEntries WRITE setMaxEntries NOTIFY maxEntriesChanged)
        Q_PROPERTY(int maxMegabytes READ maxMegabytes WRITE setMaxMegabytes NOTIFY maxMegabytesChanged)
        Q_PROPERTY(bool enabled READ isEnabled WRITE setEnabled NOTIFY enabledChanged)
        Q_PROPERTY(QString activeWindow READ activeWindow WRITE setActiveWindow NOTIFY activeWindowChanged)

      public:
        explicit ClipboardManager(QObject* parent = nullptr);
        ~ClipboardManager() override;
        ClipboardManager(ClipboardManager&&)                         = delete;
        ClipboardManager&              operator=(ClipboardManager&&) = delete;

        Q_INVOKABLE [[nodiscard]] bool initialize(const QString& dbPath);

        [[nodiscard]] ClipboardModel*  model() const noexcept;
        [[nodiscard]] int              maxEntries() const noexcept;
        [[nodiscard]] int              maxMegabytes() const noexcept;
        [[nodiscard]] bool             isEnabled() const noexcept;
        [[nodiscard]] QString          activeWindow() const noexcept;

        void                           setMaxEntries(int max);
        void                           setMaxMegabytes(int mb);
        void                           setEnabled(bool enabled);
        void                           setActiveWindow(const QString& window);

        Q_INVOKABLE [[nodiscard]] bool copyToClipboard(qint64 id);
        Q_INVOKABLE [[nodiscard]] bool copySelection(const QVariantList& ids);
        Q_INVOKABLE [[nodiscard]] int  removeMany(const QVariantList& ids);
        Q_INVOKABLE void               pin(qint64 id, bool pinned);
        Q_INVOKABLE void               remove(qint64 id);
        Q_INVOKABLE [[nodiscard]] bool clearUnpinned();
        Q_INVOKABLE void               requestFullEntry(qint64 id);

      signals:
        void maxEntriesChanged();
        void maxMegabytesChanged();
        void enabledChanged();
        void activeWindowChanged();
        void fullEntryReady(QVariantMap entry);

      private:
        void                                setupConnections();
        void                                loadAllEntries();
        void                                pruneIfNeeded();
        static void                         writePreviewFile(qint64 id, const QByteArray& pngData);
        static void                         writePreviewFileBackground(qint64 id, const QByteArray& pngData);
        static void                         removePreviewFile(qint64 id);
        void                                onSelectionReceived(const QString& mimeType, const QByteArray& content, const QString& fileName);
        [[nodiscard]] bool                  queueClipboardContent(const QString& mimeType, const QByteArray& content, const QString& fileName);
        void                                persistToHistory(const QString& mimeType, const QByteArray& content, const QString& fileName);
        [[nodiscard]] static ClipboardType  mimeTypeToClipboardType(const QString& mimeType);

        QPointer<ClipboardModel>            mModel;
        QThread                             mWaylandThread;
        std::unique_ptr<WaylandDataControl> mWayland;
        std::unique_ptr<ClipboardDatabase>  mDatabase;

        std::optional<QByteArray>           mLastSelfSetContent;
        qint64                              mLastSelfSetTimestamp{0};

        qint64                              mLastCopyId{-1};
        qint64                              mLastCopyTimestamp{0};

        qint64                              mPendingEntryId{-1};
        int                                 mMaxEntries{500};
        int                                 mMaxMegabytes{64};
        bool                                mEnabled{true};

        QString                             mActiveWindow;
    };
}
