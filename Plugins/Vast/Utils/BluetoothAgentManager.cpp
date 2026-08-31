#include "BluetoothAgentManager.hpp"
#include "BluetoothAgentAdaptor.hpp"

#include <qdbusinterface.h>
#include <QDBusPendingCallWatcher>
#include <qdbuspendingreply.h>
#include <qloggingcategory.h>

namespace vast {

    BluetoothAgentManager::BluetoothAgentManager(QObject* parent) : QObject(parent), mSystemBus(QDBusConnection::systemBus()), mAdaptor(new BluetoothAgentAdaptor(this)) {

        mAgentManager = new QDBusInterface(QStringLiteral("org.bluez"), QStringLiteral("/org/bluez"), QStringLiteral("org.bluez.AgentManager1"), mSystemBus, this);

        mWatcher = new QDBusServiceWatcher(QStringLiteral("org.bluez"), mSystemBus, QDBusServiceWatcher::WatchForOwnerChange, this);
        connect(mWatcher, &QDBusServiceWatcher::serviceOwnerChanged, this, [this](const QString& service, const QString& oldOwner, const QString& newOwner) {
            Q_UNUSED(service);
            Q_UNUSED(oldOwner);
            reRegisterIfNeeded(newOwner);
        });

        ensureRegistered();
    }

    BluetoothAgentManager::~BluetoothAgentManager() {
        if (mActive && mSystemBus.isConnected()) {
            if (mAgentManager && mAgentManager->isValid())
                mAgentManager->asyncCall(QStringLiteral("UnregisterAgent"), QVariant::fromValue(QDBusObjectPath(QString::fromLatin1(K_AGENT_PATH))));
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
        }
        for (auto it = mPending.begin(); it != mPending.end(); ++it)
            mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Agent released")));

        mPending.clear();
    }

    void BluetoothAgentManager::ensureRegistered() {
        if (mActivationInFlight || mActive)
            return;
        if (!mSystemBus.isConnected()) {
            qWarning() << "[Vast.BluetoothAgentManager] System bus not connected";
            return;
        }

        mActivationInFlight = true;

        // Export this object (manager) which owns the Adaptor as org.bluez.Agent1.
        const bool registered = mSystemBus.registerObject(QString::fromLatin1(K_AGENT_PATH), this);
        if (!registered) {
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
            if (!mSystemBus.registerObject(QString::fromLatin1(K_AGENT_PATH), this)) {
                qWarning() << "[Vast.BluetoothAgentManager] registerObject failed:" << mSystemBus.lastError().message();
                mActivationInFlight = false;
                return;
            }
        }

        if (!mAgentManager->isValid()) {
            qWarning() << "[Vast.BluetoothAgentManager] AgentManager1 not available (is bluetoothd running?)";
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
            mActivationInFlight = false;
            return;
        }

        auto* watcher = new QDBusPendingCallWatcher(
            mAgentManager->asyncCall(QStringLiteral("RegisterAgent"), QVariant::fromValue(QDBusObjectPath(QString::fromLatin1(K_AGENT_PATH))), QString::fromLatin1(K_CAPABILITY)),
            this);
        connect(watcher, &QDBusPendingCallWatcher::finished, this, &BluetoothAgentManager::onRegisterAgentFinished);
    }

    void BluetoothAgentManager::onRegisterAgentFinished(QDBusPendingCallWatcher* watcher) {
        watcher->deleteLater();
        const auto& reply = *watcher;
        if (reply.isError()) {
            qWarning() << "[Vast.BluetoothAgentManager] RegisterAgent failed:" << reply.error().message();
            mSystemBus.unregisterObject(QString::fromLatin1(K_AGENT_PATH));
            mActivationInFlight = false;
            return;
        }

        auto* next = new QDBusPendingCallWatcher(
            mAgentManager->asyncCall(QStringLiteral("RequestDefaultAgent"), QVariant::fromValue(QDBusObjectPath(QString::fromLatin1(K_AGENT_PATH)))), this);
        connect(next, &QDBusPendingCallWatcher::finished, this, &BluetoothAgentManager::onRequestDefaultAgentFinished);
    }

    void BluetoothAgentManager::onRequestDefaultAgentFinished(QDBusPendingCallWatcher* watcher) {
        watcher->deleteLater();
        const auto& reply = *watcher;
        if (reply.isError())
            qWarning() << "[Vast.BluetoothAgentManager] RequestDefaultAgent failed:" << reply.error().message();

        mActive             = true;
        mActivationInFlight = false;
        emit activeChanged();
        qInfo() << "[Vast.BluetoothAgentManager] Registered KeyboardDisplay at" << K_AGENT_PATH;
    }

    void BluetoothAgentManager::reRegisterIfNeeded(const QString& newOwner) {
        if (newOwner.isEmpty()) {
            // bluetoothd went away; clear pending and mark inactive
            for (auto it = mPending.begin(); it != mPending.end(); ++it)
                emit pairingCancelled(it.key());

            mPending.clear();
            emit busyChanged();
            mActive = false;
            emit activeChanged();
            return;
        }
        // bluetoothd (re)appeared; re-register if not active
        if (!mActive && !mActivationInFlight)
            ensureRegistered();
    }

    [[nodiscard]] QString BluetoothAgentManager::resolveDeviceName(const QString& devicePath) const { // NOLINT(readability-convert-member-functions-to-static)
        // Best-effort fallback only: derives a MAC-address-shaped label from the D-Bus
        // object path (e.g. .../dev_xx_xx_xx_xx_xx_xx -> xx_xx_xx_xx_xx_xx). This is not
        // the device's real name, QML should prefer Quickshell's Bluetooth device list
        // (matched by dbusPath) and only fall back to this when that lookup misses.
        if (devicePath.isEmpty())
            return {};
        QString tail = devicePath.section(QLatin1Char('/'), -1);
        if (tail.startsWith(QStringLiteral("dev_")))
            return tail.mid(4).replace(QLatin1Char('_'), QLatin1Char(':'));
        return tail;
    }

    QString BluetoothAgentManager::deviceNameForPath(const QString& devicePath) const {
        return resolveDeviceName(devicePath);
    }

    void BluetoothAgentManager::handleRequestPinCode(const QString& devicePath, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] RequestPinCode" << devicePath;
        mPending.insert(devicePath, msg);
        emit busyChanged();
        emit pinCodeRequested(devicePath, resolveDeviceName(devicePath));
    }

    void BluetoothAgentManager::handleRequestPasskey(const QString& devicePath, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] RequestPasskey" << devicePath;
        mPending.insert(devicePath, msg);
        emit busyChanged();
        emit passkeyRequested(devicePath, resolveDeviceName(devicePath));
    }

    void BluetoothAgentManager::handleDisplayPasskey(const QString& devicePath, quint32 passkey, quint16 entered) {
        qInfo() << "[Vast.BluetoothAgentManager] DisplayPasskey" << devicePath << passkey << entered;
        // Informational only, BlueZ does not wait on a reply for DisplayPasskey.
        emit passkeyDisplayed(devicePath, passkey, entered);
    }

    void BluetoothAgentManager::handleRequestConfirmation(const QString& devicePath, quint32 passkey, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] RequestConfirmation" << devicePath << passkey;
        mPending.insert(devicePath, msg);
        emit busyChanged();
        emit confirmationRequested(devicePath, resolveDeviceName(devicePath), passkey);
    }

    void BluetoothAgentManager::handleAuthorizeService(const QString& devicePath, const QString& uuid, const QDBusMessage& msg) {
        qInfo() << "[Vast.BluetoothAgentManager] AuthorizeService" << devicePath << uuid;
        mPending.insert(devicePath, msg);
        emit busyChanged();
        emit authorizationRequested(devicePath, resolveDeviceName(devicePath), uuid);
    }

    void BluetoothAgentManager::handleCancel() {
        qInfo() << "[Vast.BluetoothAgentManager] Cancel()";
        for (auto it = mPending.begin(); it != mPending.end(); ++it) {
            mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Canceled")));
            emit pairingCancelled(it.key());
        }
        const bool hadBusy = !mPending.isEmpty();
        mPending.clear();
        if (hadBusy)
            emit busyChanged();
    }

    void BluetoothAgentManager::handleRelease() {
        qInfo() << "[Vast.BluetoothAgentManager] Release() — agent released by bluetoothd";
        for (auto it = mPending.begin(); it != mPending.end(); ++it) {
            mSystemBus.send(it.value().createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Released")));
            emit pairingCancelled(it.key());
        }
        const bool hadBusy = !mPending.isEmpty();
        mPending.clear();
        if (hadBusy)
            emit busyChanged();
        mActive             = false;
        mActivationInFlight = false;
        emit activeChanged();
    }

    bool BluetoothAgentManager::takePending(const QString& devicePath, const char* callerName, QDBusMessage& reply) {
        auto it = mPending.find(devicePath);
        if (it == mPending.end()) {
            qWarning() << "[Vast.BluetoothAgentManager]" << callerName << "no pending for" << devicePath;
            return false;
        }
        reply = it.value();
        mPending.erase(it);
        emit busyChanged();
        return true;
    }

    void BluetoothAgentManager::providePinCode(const QString& devicePath, const QString& pin) {
        QDBusMessage msg;
        if (!takePending(devicePath, "providePinCode", msg))
            return;
        if (pin.isEmpty())
            mSystemBus.send(msg.createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Rejected by user")));
        else
            mSystemBus.send(msg.createReply(QVariant::fromValue(pin)));
    }

    void BluetoothAgentManager::providePasskey(const QString& devicePath, quint32 passkey) {
        QDBusMessage msg;
        if (!takePending(devicePath, "providePasskey", msg))
            return;
        mSystemBus.send(msg.createReply(QVariant::fromValue(passkey)));
    }

    void BluetoothAgentManager::confirmPairing(const QString& devicePath, bool accept) {
        QDBusMessage msg;
        if (!takePending(devicePath, "confirmPairing", msg))
            return;
        if (accept)
            mSystemBus.send(msg.createReply());
        else
            mSystemBus.send(msg.createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Rejected by user")));
    }

    void BluetoothAgentManager::authorizeService(const QString& devicePath, bool accept) {
        QDBusMessage msg;
        if (!takePending(devicePath, "authorizeService", msg))
            return;
        if (accept)
            mSystemBus.send(msg.createReply());
        else
            mSystemBus.send(msg.createErrorReply(QStringLiteral("org.bluez.Error.Rejected"), QStringLiteral("Rejected by user")));
    }

} // namespace vast
