#include "ClipboardContentClassifier.hpp"
#include "ClipboardEntry.hpp"

#include <qbytearray.h>
#include <qcryptographichash.h>
#include <qdatetime.h>
#include <qchar.h>
#include <qstring.h>

#include <algorithm>

namespace vast {

    [[nodiscard]] ClipboardType ClipboardContentClassifier::typeFromMime(const QString& mimeType) {
        if (mimeType == QStringLiteral("image/png"))
            return ClipboardType::Image;
        if (mimeType == QStringLiteral("text/html"))
            return ClipboardType::Html;
        if (mimeType == QStringLiteral("text/uri-list"))
            return ClipboardType::Files;
        return ClipboardType::Text;
    }

    [[nodiscard]] bool ClipboardContentClassifier::isBlankTextOrHtml(ClipboardType type, const QByteArray& content) {
        if (type != ClipboardType::Text && type != ClipboardType::Html)
            return false;

        const auto text = QString::fromUtf8(content);
        return text.isEmpty() || std::ranges::all_of(text, [](QChar c) { return c.isSpace(); });
    }

    [[nodiscard]] ClipboardEntry ClipboardContentClassifier::buildEntry(const QString& mimeType, const QByteArray& content, const QString& fileName, const QString& sourceApp) {
        ClipboardEntry entry;
        entry.type      = typeFromMime(mimeType);
        entry.content   = entry.isImage() ? QString{} : QString::fromUtf8(content);
        entry.data      = entry.isImage() ? content : QByteArray{};
        entry.mimeType  = mimeType;
        entry.pinned    = false;
        entry.sourceApp = sourceApp;
        entry.sizeBytes = content.size();
        entry.timestamp = QDateTime::currentMSecsSinceEpoch();
        entry.fileName  = entry.isImage() ? fileName : QString{};

        const QByteArray hashInput = entry.isImage() ? content : entry.content.toUtf8();
        entry.hash                 = QCryptographicHash::hash(hashInput, QCryptographicHash::Sha256);
        return entry;
    }
}
