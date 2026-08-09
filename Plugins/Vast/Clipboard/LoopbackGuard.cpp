#include "LoopbackGuard.hpp"

#include <qcryptographichash.h>
#include <qdatetime.h>

namespace vast {

    void LoopbackGuard::arm(const QByteArray& content) noexcept {
        mHash      = QCryptographicHash::hash(content, QCryptographicHash::Sha256);
        mArmedAtMs = QDateTime::currentMSecsSinceEpoch();
    }

    [[nodiscard]] bool LoopbackGuard::shouldSuppress(const QByteArray& content) noexcept {
        if (!mHash.has_value())
            return false;

        const bool withinWindow = QDateTime::currentMSecsSinceEpoch() - mArmedAtMs < K_WINDOW_MS;
        const bool matches      = *mHash == QCryptographicHash::hash(content, QCryptographicHash::Sha256);

        mHash.reset();
        return withinWindow && matches;
    }
}
