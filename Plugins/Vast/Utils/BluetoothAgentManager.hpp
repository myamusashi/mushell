#pragma once

#include <qdbusconnection.h>
#include <qdbusmessage.h>
#include <qdbusservicewatcher.h>
#include <qhash.h>
#include <qobject.h>
#include <qqmlintegration.h>
#include <qstring.h>

class QDBusInterface;
class QDBusPendingCallWatcher;

namespace vast {

    class BluetoothAgentAdaptor;

    class BluetoothAgentManager : public QObject {
        Q_OBJECT
        QML_ELEMENT
        QML_SINGLETON
        Q_PROPERTY(bool active READ active NOTIFY activeChanged)
        Q_PROPERTY(bool busy READ busy NOTIFY busyChanged)

      public:
        explicit BluetoothAgentManager(QObject* parent = nullptr);
        ~BluetoothAgentManager() override;

        BluetoothAgentManager(const BluetoothAgentManager&)            = delete;
        BluetoothAgentManager& operator=(const BluetoothAgentManager&) = delete;
        BluetoothAgentManager(BluetoothAgentManager&&)                 = delete;
        BluetoothAgentManager& operator=(BluetoothAgentManager&&)      = delete;

        [[nodiscard]] bool     active() const noexcept {
            return mActive;
        }
        [[nodiscard]] bool busy() const noexcept {
            return !mPending.isEmpty();
        }

        Q_INVOKABLE void                  providePinCode(const QString& devicePath, const QString& pin);
        Q_INVOKABLE void                  providePasskey(const QString& devicePath, quint32 passkey);
        Q_INVOKABLE void                  confirmPairing(const QString& devicePath, bool accept);
        Q_INVOKABLE void                  authorizeService(const QString& devicePath, bool accept);

        Q_INVOKABLE [[nodiscard]] QString deviceNameForPath(const QString& devicePath) const;

        // Called by adaptor
        void handleRequestPinCode(const QString& devicePath, const QDBusMessage& msg);
        void handleRequestPasskey(const QString& devicePath, const QDBusMessage& msg);
        void handleDisplayPasskey(const QString& devicePath, quint32 passkey, quint16 entered);
        void handleRequestConfirmation(const QString& devicePath, quint32 passkey, const QDBusMessage& msg);
        void handleAuthorizeService(const QString& devicePath, const QString& uuid, const QDBusMessage& msg);
        void handleCancel();
        void handleRelease();

      signals:
        void activeChanged();
        void busyChanged();
        void pinCodeRequested(const QString& devicePath, const QString& deviceName);
        void passkeyRequested(const QString& devicePath, const QString& deviceName);
        void passkeyDisplayed(const QString& devicePath, quint32 passkey, quint16 entered);
        void confirmationRequested(const QString& devicePath, const QString& deviceName, quint32 passkey);
        void authorizationRequested(const QString& devicePath, const QString& deviceName, const QString& uuid);
        void pairingCancelled(const QString& devicePath);

      private:
        void                  ensureRegistered();
        void                  onRegisterAgentFinished(QDBusPendingCallWatcher* watcher);
        void                  onRequestDefaultAgentFinished(QDBusPendingCallWatcher* watcher);
        void                  reRegisterIfNeeded(const QString& newOwner);

        [[nodiscard]] QString resolveDeviceName(const QString& devicePath) const;

        // Shared find/erase/busyChanged tail for the four completion entry points
        // (providePinCode/providePasskey/confirmPairing/authorizeService). On a hit,
        // removes the pending message from mPending, emits busyChanged(), and returns
        // it via reply. On a miss, warns using callerName and returns false.
        bool                         takePending(const QString& devicePath, const char* callerName, QDBusMessage& reply);

        static constexpr const char* K_AGENT_PATH = "/io/quickshell/BluetoothAgent";
        static constexpr const char* K_CAPABILITY = "KeyboardDisplay";

        QDBusConnection              mSystemBus;
        QDBusInterface*              mAgentManager{nullptr};
        QDBusServiceWatcher*         mWatcher{nullptr};
        BluetoothAgentAdaptor*       mAdaptor{nullptr};

        bool                         mActive{false};
        bool                         mActivationInFlight{false};

        QHash<QString, QDBusMessage> mPending;
    };

} // namespace vast
