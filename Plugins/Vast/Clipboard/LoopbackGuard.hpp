#pragma once

#include <qbytearray.h>
#include <optional>
#include <qtypes.h>

namespace vast {

    /// Suppresses re-ingesting clipboard content just written by this manager.
    class LoopbackGuard {
      public:
        void               arm(const QByteArray& content) noexcept;

        [[nodiscard]] bool shouldSuppress(const QByteArray& content) noexcept;

      private:
        std::optional<QByteArray> mHash;
        qint64                    mArmedAtMs{0};

        static constexpr qint64   K_WINDOW_MS{60000};
    };
}
