#include "LyricsCache.hpp"

#include <qcryptographichash.h>
#include <qdir.h>
#include <qfile.h>
#include <qjsondocument.h>
#include <qjsonobject.h>
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

    std::optional<LyricsCache::CachedLyrics> LyricsCache::load(const QString& cacheKey) {
        QFile f(path(cacheKey));
        if (!f.open(QIODevice::ReadOnly))
            return std::nullopt;

        const auto envelope = QJsonDocument::fromJson(f.readAll()).object();
        const auto rawB64   = envelope["raw"].toString().toUtf8();
        if (rawB64.isEmpty())
            return std::nullopt;

        return CachedLyrics{
            .rawJson      = QByteArray::fromBase64(rawB64),
            .durationSecs = envelope["duration"].toDouble(),
        };
    }

    void LyricsCache::save(const QString& cacheKey, const QByteArray& rawJson, double durationSecs) {
        QJsonObject envelope;
        envelope["raw"]      = QString::fromUtf8(rawJson.toBase64());
        envelope["duration"] = durationSecs;

        QFile f(path(cacheKey));
        if (f.open(QIODevice::WriteOnly))
            f.write(QJsonDocument(envelope).toJson(QJsonDocument::Compact));
    }
}