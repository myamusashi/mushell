#pragma once

#include <qbytearray.h>
#include <qstring.h>
#include <qtypes.h>

namespace vast {

    /// Owns the on-disk PNG thumbnail cache for image clipboard entries.
    class ClipboardPreviewCache {
      public:
        [[nodiscard]] static QString path(qint64 id);
        [[nodiscard]] static bool    exists(qint64 id);
        static void                  write(qint64 id, const QByteArray& pngData);
        static void                  remove(qint64 id);

      private:
        static constexpr int         K_THUMB_MAX_DIM{400};

        [[nodiscard]] static QString cacheDir();
    };
}
