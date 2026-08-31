#include "BluetoothAgentAdaptor.hpp"
#include "BluetoothAgentManager.hpp"

#include <QDBusObjectPath>
#include <qloggingcategory.h>

namespace vast {
    BluetoothAgentAdaptor::BluetoothAgentAdaptor(BluetoothAgentManager* manager) : QDBusAbstractAdaptor(manager), mManager(manager) {
        setAutoRelaySignals(false);
    }

    QString BluetoothAgentAdaptor::RequestPinCode(const QDBusObjectPath& device) {
        if (!calledFromDBus()) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] RequestPinCode not from D-Bus, ignoring" << device.path();
            return {};
        }
        setDelayedReply(true);
        const auto msg = message();
        if (msg.type() == QDBusMessage::InvalidMessage) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] RequestPinCode message invalid";
            return {};
        }
        mManager->handleRequestPinCode(device.path(), msg);
        return {};
    }

    quint32 BluetoothAgentAdaptor::RequestPasskey(const QDBusObjectPath& device) {
        if (!calledFromDBus()) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] RequestPasskey not from D-Bus, ignoring" << device.path();
            return 0;
        }
        setDelayedReply(true);
        const auto msg = message();
        if (msg.type() == QDBusMessage::InvalidMessage) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] RequestPasskey message invalid";
            return 0;
        }
        mManager->handleRequestPasskey(device.path(), msg);
        return 0;
    }

    void BluetoothAgentAdaptor::DisplayPasskey(const QDBusObjectPath& device, quint32 passkey, quint16 entered) {
        mManager->handleDisplayPasskey(device.path(), passkey, entered);
    }

    void BluetoothAgentAdaptor::RequestConfirmation(const QDBusObjectPath& device, quint32 passkey) {
        if (!calledFromDBus()) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] RequestConfirmation not from D-Bus, ignoring" << device.path();
            return;
        }
        setDelayedReply(true);
        const auto msg = message();
        if (msg.type() == QDBusMessage::InvalidMessage) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] RequestConfirmation message invalid";
            return;
        }
        mManager->handleRequestConfirmation(device.path(), passkey, msg);
    }

    void BluetoothAgentAdaptor::AuthorizeService(const QDBusObjectPath& device, const QString& uuid) {
        if (!calledFromDBus()) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] AuthorizeService not from D-Bus, ignoring" << device.path();
            return;
        }
        setDelayedReply(true);
        const auto msg = message();
        if (msg.type() == QDBusMessage::InvalidMessage) {
            qWarning() << "[Vast.BluetoothAgentAdaptor] AuthorizeService message invalid";
            return;
        }
        mManager->handleAuthorizeService(device.path(), uuid, msg);
    }

    void BluetoothAgentAdaptor::Cancel() {
        mManager->handleCancel();
    }

    void BluetoothAgentAdaptor::Release() {
        mManager->handleRelease();
    }

} // namespace vast
