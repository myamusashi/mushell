#include "ClipboardPreviewCache.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qimage.h>
#include <qnamespace.h>
#include <qtypes.h>

namespace vast {

    [[nodiscard]] QString ClipboardPreviewCache::cacheDir() {
        return QStringLiteral("/tmp/vast-shell/clipboard-preview");
    }

    [[nodiscard]] QString ClipboardPreviewCache::path(qint64 id) {
        return QStringLiteral("%1/%2.png").arg(cacheDir()).arg(id);
    }

    [[nodiscard]] bool ClipboardPreviewCache::exists(qint64 id) {
        return QFile::exists(path(id));
    }

    void ClipboardPreviewCache::write(qint64 id, const QByteArray& pngData) {
        QDir{}.mkpath(cacheDir());

        QImage img;
        if (!img.loadFromData(pngData, "PNG"))
            return;

        const QImage thumb =
            (img.width() > K_THUMB_MAX_DIM || img.height() > K_THUMB_MAX_DIM) ? img.scaled(K_THUMB_MAX_DIM, K_THUMB_MAX_DIM, Qt::KeepAspectRatio, Qt::SmoothTransformation) : img;

        thumb.save(path(id), "PNG");
    }

    void ClipboardPreviewCache::remove(qint64 id) {
        QFile::remove(path(id));
    }
}
