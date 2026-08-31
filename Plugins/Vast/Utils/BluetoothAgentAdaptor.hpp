#pragma once

#include <qdbusabstractadaptor.h>
#include <qdbuscontext.h>
#include <QDBusObjectPath>
#include <qobject.h>
#include <qstring.h>

namespace vast {

    class BluetoothAgentManager;

    // QDBusContext is on the adaptor, not the manager: D-Bus dispatches
    // incoming Agent1 calls to this object's slots directly, so the
    // per-call context (calledFromDBus/message/setDelayedReply) only
    // populates correctly here.
    class BluetoothAgentAdaptor : public QDBusAbstractAdaptor, public QDBusContext {
        Q_OBJECT
        Q_CLASSINFO("D-Bus Interface", "org.bluez.Agent1")

      public:
        explicit BluetoothAgentAdaptor(BluetoothAgentManager* manager);
        ~BluetoothAgentAdaptor() override = default;

        BluetoothAgentAdaptor(const BluetoothAgentAdaptor&)            = delete;
        BluetoothAgentAdaptor& operator=(const BluetoothAgentAdaptor&) = delete;
        BluetoothAgentAdaptor(BluetoothAgentAdaptor&&)                 = delete;
        BluetoothAgentAdaptor& operator=(BluetoothAgentAdaptor&&)      = delete;

      public slots:
        // NOTE: names must match org.bluez.Agent1 exactly (PascalCase),
        // QDBusAbstractAdaptor exports slots under their literal C++ name,
        // it does not translate requestPinCode -> RequestPinCode.
        // NOLINTBEGIN(readability-identifier-naming)
        QString RequestPinCode(const QDBusObjectPath& device);
        quint32 RequestPasskey(const QDBusObjectPath& device);
        void    DisplayPasskey(const QDBusObjectPath& device, quint32 passkey, quint16 entered);
        void    RequestConfirmation(const QDBusObjectPath& device, quint32 passkey);
        void    AuthorizeService(const QDBusObjectPath& device, const QString& uuid);
        void    Cancel();
        void    Release();
        // NOLINTEND(readability-identifier-naming)

      private:
        BluetoothAgentManager* mManager;
    };

} // namespace vast
