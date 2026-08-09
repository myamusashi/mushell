#pragma once

#include "ClipboardEntry.hpp"

#include <qbytearray.h>
#include <qstring.h>

namespace vast {

    /// Classifies MIME content and builds entries without external side effects.
    class ClipboardContentClassifier {
      public:
        [[nodiscard]] static ClipboardType typeFromMime(const QString& mimeType);
        [[nodiscard]] static bool          isBlankTextOrHtml(ClipboardType type, const QByteArray& content);
        [[nodiscard]] static ClipboardEntry buildEntry(const QString& mimeType, const QByteArray& content, const QString& fileName, const QString& sourceApp);
    };
}
