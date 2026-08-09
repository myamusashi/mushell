#include "LyricsCache.hpp"

#include <qcryptographichash.h>
#include <qdir.h>
#include <qfile.h>
#include <qstandardpaths.h>

namespace vast {

    QString LyricsCache::key(const QString& title, const QString& artist, double durationSecs) {
        const QString raw = artist + "|" + title + "|" + QString::number(qRound(durationSecs));
        return QCryptographicHash::hash(raw.toUtf8(), QCryptographicHash::Sha1).toHex();
    }

    QString LyricsCache::path(const QString& cacheKey) {
        const QString dir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/lyrics";
        QDir().mkpath(dir);
        return dir + "/" + cacheKey + ".json";
    }

    std::optional<QByteArray> LyricsCache::load(const QString& cacheKey) {
        QFile f(path(cacheKey));
        if (!f.open(QIODevice::ReadOnly))
            return std::nullopt;
        return f.readAll();
    }

    void LyricsCache::save(const QString& cacheKey, const QByteArray& data) {
        QFile f(path(cacheKey));
        if (f.open(QIODevice::WriteOnly))
            f.write(data);
    }
}